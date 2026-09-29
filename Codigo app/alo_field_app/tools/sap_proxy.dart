// ═══════════════════════════════════════════════════════════════════════════
// SAP CORS Proxy — Proxy de desarrollo para SAP B1 Service Layer
// Replica la arquitectura de N8N: recibe HTTP local, reenvía a SAP por HTTPS.
//
// Uso: dart run tools/sap_proxy.dart
// Luego en la app, apuntar SAP_BASE_URL a http://localhost:8080
//
// Características:
//   - Agrega headers CORS a todas las respuestas
//   - Reenvía requests al SAP B1 Service Layer real
//   - Ignora certificados SSL auto-firmados (como N8N)
//   - Maneja cookies de sesión automáticamente (sin exponerlas al cliente)
//   - Maneja peticiones OPTIONS (CORS preflight)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

const String targetUrl = 'https://sap.alo-group.com:50000';
const int proxyPort = 8080;

// Cookie jar simple para mantener la sesión SAP
String? _b1Session;
String? _routeId;

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, proxyPort);
  print('========================================');
  print('  SAP CORS Proxy — Modo N8N');
  print('========================================');
  print('  Proxy:   http://localhost:$proxyPort');
  print('  SAP:     $targetUrl');
  print('  SSL:     Ignorado (badCertificateCallback)');
  print('  Cookies: Administradas por el proxy');
  print('');
  print('  Configura SAP_BASE_URL=http://localhost:$proxyPort/b1s/v1');
  print('  en tu archivo .env.dev');
  print('========================================');
  print('');

  await for (final request in server) {
    if (request.method == 'OPTIONS') {
      _handleOptions(request.response);
    } else {
      await _handleRequest(request);
    }
  }
}

/// Maneja peticiones OPTIONS (CORS preflight) sin reenviar a SAP.
void _handleOptions(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', '*');
  response.headers.set('Access-Control-Allow-Credentials', 'true');
  response.statusCode = 204;
  response.close();
}

/// Reenvía un request HTTP al SAP y devuelve la respuesta con CORS headers.
Future<void> _handleRequest(HttpRequest request) async {
  final uri = request.uri;
  final targetUri = Uri.parse('$targetUrl${uri.path}${uri.query.isNotEmpty ? '?${uri.query}' : ''}');

  print('[${request.method}] ${uri.path}');

  try {
    // 1. Leer body completo del request original
    final bodyBytes = await request.fold<List<int>>(<int>[], (prev, chunk) => prev..addAll(chunk));

    // 2. Crear cliente HTTP con bypass SSL (como N8N)
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..autoUncompress = true // Dart descomprime automáticamente
      ..badCertificateCallback = (cert, host, port) => true;

    // 3. Conectar a SAP
    final sapRequest = await client.openUrl(request.method, targetUri);

    // 4. Copiar headers del cliente, EXCEPTO Cookie (lo manejamos nosotros)
    request.headers.forEach((name, values) {
      final lowerName = name.toLowerCase();
      if (lowerName != 'host' && 
          lowerName != 'content-length' && 
          lowerName != 'transfer-encoding' &&
          lowerName != 'cookie') { // NO reenviar cookie del cliente
        for (final value in values) {
          sapRequest.headers.add(name, value);
        }
      }
    });

    // 5. Inyectar cookie de sesión SAP si existe (manejada por el proxy)
    if (_b1Session != null) {
      final cookie = 'B1SESSION=$_b1Session${_routeId != null ? '; ROUTEID=$_routeId' : ''}';
      sapRequest.headers.set('Cookie', cookie);
      print('  🍪 Cookie enviada: B1SESSION=${_b1Session!.substring(0, 8)}...');
    }

    // 6. Enviar body a SAP
    if (bodyBytes.isNotEmpty) {
      sapRequest.contentLength = bodyBytes.length;
      sapRequest.add(bodyBytes);
    }

    // 7. Esperar respuesta de SAP
    final sapResponse = await sapRequest.close();

    // 8. Leer body de la respuesta de SAP (ya descomprimido por Dart)
    final sapBody = await sapResponse.fold<List<int>>(<int>[], (prev, chunk) => prev..addAll(chunk));

    // 9. Extraer y guardar cookies de SAP (Set-Cookie)
    final rawCookies = sapResponse.headers['set-cookie'];
    if (rawCookies != null) {
      for (final cookie in rawCookies) {
        final b1Match = RegExp(r'B1SESSION=([^;]+)').firstMatch(cookie);
        final routeMatch = RegExp(r'ROUTEID=([^;]+)').firstMatch(cookie);
        if (b1Match != null) {
          _b1Session = b1Match.group(1);
          print('  🍪 Cookie guardada: B1SESSION=${_b1Session!.substring(0, 8)}...');
        }
        if (routeMatch != null) {
          _routeId = routeMatch.group(1);
          print('  🍪 Cookie guardada: ROUTEID=$_routeId');
        }
      }
    }

    print('  <- ${sapResponse.statusCode} (${sapBody.length} bytes)');

    // 10. Configurar respuesta con CORS headers
    request.response.statusCode = sapResponse.statusCode;
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', '*');
    request.response.headers.set('Access-Control-Allow-Credentials', 'true');

    // 11. Copiar headers de SAP, pero NO reenviar cookies al cliente
    final skipHeaders = {'content-encoding', 'transfer-encoding', 'content-length', 'set-cookie'};
    sapResponse.headers.forEach((name, values) {
      final lowerName = name.toLowerCase();
      if (!skipHeaders.contains(lowerName)) {
        for (final value in values) {
          request.response.headers.add(name, value);
        }
      }
    });

    // 12. Setear Content-Length manual
    request.response.contentLength = sapBody.length;

    // 13. Enviar body al cliente
    request.response.add(sapBody);
    await request.response.close();

  } catch (e) {
    print('  ❌ Error: $e');
    try {
      request.response.statusCode = 502;
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Content-Type', 'application/json');
      request.response.write(jsonEncode({
        'error': {
          'message': {
            'value': 'SAP CORS Proxy: No se pudo conectar con SAP. Error: $e'
          }
        }
      }));
      await request.response.close();
    } catch (_) {}
  }
}