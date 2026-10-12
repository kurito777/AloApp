/// Tipo de ubicación operacional del equipo.
enum LocationType { obra, taller, desconocida }

/// Ubicación operacional real del equipo de una OM.
///
/// Prioriza la OBRA (contrato de arriendo de la OM) sobre el TALLER:
///  - OBRA: `VID_MTOM.U_DocNum_RTOV` → `VID_RTOV` (U_Dest + U_DestAddr).
///  - TALLER: `VID_MTTALLER.U_WhsCode` → `Warehouses` (ciudad + nombre bodega).
///
/// SAP no almacena comuna/ciudad/coordenadas; [comuna], [ciudad], [lat], [lng]
/// se completan por geocodificación (Nominatim) de [address].
class ObraLocation {
  final String equipoCode;
  final String? equipoName;

  final LocationType type;

  /// Número de contrato de arriendo (VID_RTOV.DocNum) cuando type == obra.
  final String? contractNum;

  /// Nombre de la obra (U_Dest) o del taller.
  final String? siteName;
  final String? clientName;

  /// Dirección de texto (obra U_DestAddr, o ciudad del taller).
  final String? address;

  // ── Enriquecido por geocodificación ────────────────────────────────────────
  final String? comuna;
  final String? ciudad;
  final double? lat;
  final double? lng;

  const ObraLocation({
    required this.equipoCode,
    required this.type,
    this.equipoName,
    this.contractNum,
    this.siteName,
    this.clientName,
    this.address,
    this.comuna,
    this.ciudad,
    this.lat,
    this.lng,
  });

  bool get hasAddress => (address != null && address!.trim().isNotEmpty);
  bool get hasCoords => lat != null && lng != null;
  bool get isObra => type == LocationType.obra;

  String get typeLabel {
    switch (type) {
      case LocationType.obra:
        return 'OBRA';
      case LocationType.taller:
        return 'TALLER';
      case LocationType.desconocida:
        return 'SIN UBICACIÓN';
    }
  }

  String get displayAddress =>
      hasAddress ? address!.trim() : (siteName ?? 'Dirección no disponible');

  /// Copia con los datos de geocodificación.
  ObraLocation withGeo({
    double? lat,
    double? lng,
    String? comuna,
    String? ciudad,
  }) =>
      ObraLocation(
        equipoCode: equipoCode,
        type: type,
        equipoName: equipoName,
        contractNum: contractNum,
        siteName: siteName,
        clientName: clientName,
        address: address,
        comuna: comuna ?? this.comuna,
        ciudad: ciudad ?? this.ciudad,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}
