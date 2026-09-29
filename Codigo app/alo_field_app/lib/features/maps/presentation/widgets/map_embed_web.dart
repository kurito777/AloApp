// Implementación web: mapa Leaflet + OpenStreetMap dentro de un <iframe srcdoc>.
// Gratis, sin API key ni facturación. Llena las restricciones del padre.
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

final Set<String> _registered = {};

Widget buildMapEmbed({
  required double lat,
  required double lng,
  required String label,
}) {
  final popup = jsonEncode(label.isEmpty ? 'Obra' : label);
  final viewType = 'leaflet-${lat.toStringAsFixed(5)}-${lng.toStringAsFixed(5)}';

  final srcdoc = '''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<style>html,body,#m{height:100%;width:100%;margin:0}</style>
</head><body><div id="m"></div>
<script>
  var map = L.map('m').setView([$lat, $lng], 15);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; <a href="https://openstreetmap.org">OpenStreetMap</a>'
  }).addTo(map);
  L.marker([$lat, $lng]).addTo(map).bindPopup($popup).openPopup();
  // Reajusta el tamaño cuando el iframe cambia de dimensiones (responsive) y
  // varias veces al inicio (evita el mapa gris si el contenedor mide 0 al cargar).
  window.addEventListener('resize', function(){ map.invalidateSize(); });
  [100,400,800,1500,2500].forEach(function(t){
    setTimeout(function(){ map.invalidateSize(); }, t);
  });
</script></body></html>
''';

  if (!_registered.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final el = html.IFrameElement()
        ..srcdoc = srcdoc
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      return el;
    });
    _registered.add(viewType);
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: HtmlElementView(viewType: viewType),
  );
}
