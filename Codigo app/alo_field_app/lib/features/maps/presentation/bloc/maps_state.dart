import 'package:equatable/equatable.dart';

import '../../data/models/obra_location.dart';

abstract class MapsState extends Equatable {
  const MapsState();

  @override
  List<Object?> get props => [];
}

class MapsInitial extends MapsState {
  const MapsInitial();
}

class MapsLoading extends MapsState {
  const MapsLoading();
}

/// Ubicación resuelta (obra o taller) con coordenadas ya geocodificadas.
class MapsObraLoaded extends MapsState {
  final ObraLocation obra;

  const MapsObraLoaded(this.obra);

  @override
  List<Object?> get props =>
      [obra.equipoCode, obra.type, obra.address, obra.lat, obra.lng];
}

class MapsError extends MapsState {
  final String message;

  const MapsError(this.message);

  @override
  List<Object?> get props => [message];
}
