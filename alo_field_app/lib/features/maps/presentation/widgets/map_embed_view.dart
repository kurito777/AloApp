import 'package:flutter/widgets.dart';

import 'map_embed_stub.dart'
    if (dart.library.html) 'map_embed_web.dart' as impl;

/// Mapa embebido con **Leaflet + OpenStreetMap** (gratis, sin API key).
///
/// Llena las restricciones de su padre (usar dentro de AspectRatio/SizedBox).
/// En web renderiza un `<iframe>` con Leaflet y un marcador en [lat]/[lng].
/// En otras plataformas muestra un placeholder.
class MapEmbedView extends StatelessWidget {
  final double lat;
  final double lng;
  final String label;

  const MapEmbedView({
    super.key,
    required this.lat,
    required this.lng,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) =>
      impl.buildMapEmbed(lat: lat, lng: lng, label: label);
}
