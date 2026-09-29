import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dashboard/data/services/sap_auth_service.dart';
import '../../data/services/geocoding_service.dart';
import '../../data/services/location_service.dart';
import 'maps_event.dart';
import 'maps_state.dart';

class MapsBloc extends Bloc<MapsEvent, MapsState> {
  MapsBloc({
    required LocationService locationService,
    required GeocodingService geocodingService,
  })  : _service = locationService,
        _geocoding = geocodingService,
        super(const MapsInitial()) {
    on<LoadObraForEquipo>(_onLoadObra);
  }

  final LocationService _service;
  final GeocodingService _geocoding;

  Future<void> _onLoadObra(
    LoadObraForEquipo event,
    Emitter<MapsState> emit,
  ) async {
    if (event.equipoCode.trim().isEmpty) {
      emit(const MapsError('La OM no tiene un equipo asociado.'));
      return;
    }

    emit(const MapsLoading());
    try {
      var obra = await _service.resolveObra(
        event.equipoCode,
        equipoName: event.equipoName,
        docNumRtov: event.docNumRtov,
        tallerCode: event.tallerCode,
      );
      if (obra == null) {
        emit(MapsError('Equipo ${event.equipoCode} no encontrado en SAP.'));
        return;
      }

      // Geocodifica la dirección → coordenadas + comuna/ciudad (Nominatim).
      if (obra.hasAddress) {
        final geo = await _geocoding.geocode(obra.displayAddress);
        if (geo != null) {
          obra = obra.withGeo(
            lat: geo.lat,
            lng: geo.lng,
            comuna: geo.comuna,
            ciudad: geo.ciudad,
          );
        }
      }

      emit(MapsObraLoaded(obra));
    } on SapAuthException catch (e) {
      emit(MapsError('Sesión SAP: ${e.message}'));
    } on SapNetworkException catch (e) {
      emit(MapsError('Sin conexión: ${e.message}'));
    } on SapServiceException catch (e) {
      emit(MapsError('Error SAP: ${e.message}'));
    } catch (e) {
      dev.log('[MapsBloc] Error inesperado: $e');
      emit(const MapsError('Error inesperado al obtener la ubicación.'));
    }
  }
}
