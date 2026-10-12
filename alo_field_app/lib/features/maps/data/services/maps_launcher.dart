import 'launcher_stub.dart'
    if (dart.library.html) 'launcher_web.dart'
    if (dart.library.io) 'launcher_io.dart' as impl;

/// Abre Google Maps para navegar hacia una obra (deep link universal).
///
/// Usa la Google Maps URL API (`/maps/dir/?api=1`) que NO requiere API key ni
/// billing, y un lanzador propio por plataforma (web: window.open; escritorio:
/// start/open/xdg-open) para no depender de plugins con requisitos de build.
class MapsLauncher {
  const MapsLauncher._();

  /// Abre la navegación hacia [address] (o hacia lat/lng si se proveen).
  /// Retorna false si no se pudo abrir.
  static Future<bool> navigateTo({
    String? address,
    double? lat,
    double? lng,
  }) async {
    final destination =
        (lat != null && lng != null) ? '$lat,$lng' : (address ?? '').trim();
    if (destination.isEmpty) return false;

    final url = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    }).toString();

    return impl.openExternalUrl(url);
  }
}
