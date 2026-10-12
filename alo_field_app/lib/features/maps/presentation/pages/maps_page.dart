import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/obra_location.dart';
import '../../data/services/maps_launcher.dart';
import '../bloc/maps_bloc.dart';
import '../bloc/maps_state.dart';
import '../widgets/map_embed_view.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C24),
        title: const Text(
          'Mapa / Ruta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<MapsBloc, MapsState>(
        builder: (context, state) {
          if (state is MapsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MapsError) {
            return _Info(
              icon: Icons.error_outline,
              title: 'No se pudo obtener la ubicación',
              message: state.message,
            );
          }
          if (state is MapsObraLoaded) {
            return _ObraView(obra: state.obra);
          }
          return const _Info(
            icon: Icons.map_outlined,
            title: 'Mapa de rutas',
            message: 'Abre una orden y toca "Ver ubicación" para ver dónde está '
                'el equipo en el mapa.',
          );
        },
      ),
    );
  }
}

class _ObraView extends StatelessWidget {
  final ObraLocation obra;

  const _ObraView({required this.obra});

  @override
  Widget build(BuildContext context) {
    final isObra = obra.isObra;
    final typeColor =
        isObra ? const Color(0xFF00A650) : const Color(0xFFFF8C00);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Ubicación del equipo',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: typeColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(obra.typeLabel,
                                style: TextStyle(
                                    color: typeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _row('Equipo',
                          '${obra.equipoCode}${obra.equipoName != null ? ' · ${obra.equipoName}' : ''}'),
                      if (isObra) ...[
                        if (obra.contractNum != null)
                          _row('Contrato', obra.contractNum!),
                        if (obra.clientName != null)
                          _row('Cliente', obra.clientName!),
                        if (obra.siteName != null) _row('Obra', obra.siteName!),
                      ] else ...[
                        if (obra.siteName != null)
                          _row('Taller', obra.siteName!),
                        if (obra.clientName != null)
                          _row('Bodega', obra.clientName!),
                      ],
                      _row('Dirección', obra.displayAddress),
                      if (obra.comuna != null) _row('Comuna', obra.comuna!),
                      if (obra.ciudad != null) _row('Ciudad', obra.ciudad!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: obra.hasAddress
                      ? () => MapsLauncher.navigateTo(
                            address: obra.displayAddress,
                            lat: obra.lat,
                            lng: obra.lng,
                          )
                      : null,
                  icon: const Icon(Icons.directions),
                  label: const Text('Cómo llegar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A650),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (obra.hasCoords)
                AspectRatio(
                  aspectRatio: 1,
                  child: MapEmbedView(
                    lat: obra.lat!,
                    lng: obra.lng!,
                    label: obra.siteName ?? obra.displayAddress,
                  ),
                )
              else if (obra.hasAddress)
                const Text(
                  'No se pudo ubicar la dirección en el mapa. '
                  'Usa "Cómo llegar" para abrirla en tu navegador.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                const Text(
                  'Esta OM no tiene obra ni taller con dirección registrada en SAP.',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      );
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _Info({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
