import 'package:flutter/material.dart';

/// Placeholder para plataformas no-web (Windows/móvil). Llena su padre.
Widget buildMapEmbed({
  required double lat,
  required double lng,
  required String label,
}) {
  return Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Mapa disponible en web.\nEn móvil se usará el mapa nativo.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    ),
  );
}
