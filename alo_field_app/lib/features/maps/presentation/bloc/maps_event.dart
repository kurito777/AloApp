import 'package:equatable/equatable.dart';

abstract class MapsEvent extends Equatable {
  const MapsEvent();

  @override
  List<Object?> get props => [];
}

/// Resuelve y carga la ubicación operacional de una OM.
class LoadObraForEquipo extends MapsEvent {
  final String equipoCode;
  final String? equipoName;

  /// Contrato de arriendo de la OM (VID_MTOM.U_DocNum_RTOV) → obra.
  final String? docNumRtov;

  /// Taller de la OM (U_Taller) → dirección real del taller si no hay obra.
  final String? tallerCode;

  const LoadObraForEquipo(
    this.equipoCode, {
    this.equipoName,
    this.docNumRtov,
    this.tallerCode,
  });

  @override
  List<Object?> get props => [equipoCode, equipoName, docNumRtov, tallerCode];
}
