import '../../../../core/config/sap_config.dart';

/// Línea de material de una OM (colección `VID_MTOMMACollection` de VID_MTOM).
///
/// NOTA: el esquema de la colección usa IDs internos (U_Id) y cantidades; la
/// descripción del ítem no viene embebida. Parseo defensivo.
/// TODO(sap): resolver descripción del material vía U_Id si se requiere en UI.
class OrderDetailLine {
  final int? lineId;
  final String? itemCode;
  final String? itemDescription;
  final double? quantity;

  const OrderDetailLine({
    this.lineId,
    this.itemCode,
    this.itemDescription,
    this.quantity,
  });

  factory OrderDetailLine.fromJson(Map<String, dynamic> json) {
    return OrderDetailLine(
      lineId: (json['LineId'] ?? json['U_Id']) as int?,
      itemCode: (json['U_ItemCode'] ?? json['U_Codigo'] ?? json['ItemCode'])
          ?.toString(),
      itemDescription:
          (json['U_Dscription'] ?? json['U_ItemName'])?.toString(),
      quantity: _toDouble(json['U_Cantidad'] ?? json['U_QtySol']),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

/// Tarea de una OM (colección `VID_MTOMTACollection` de VID_MTOM).
///
/// Campos reales verificados en SAP: `U_Name` (descripción), `U_Code` (código
/// del catálogo de labores), `U_Estado` ('N'=pendiente / 'T'=terminada),
/// `U_UsrResp`/`U_UsrRespN` (técnico responsable de la tarea = OHEM.EmployeeID),
/// `U_FecIni`/`U_FecFin` (ejecución).
class OrderTask {
  final int? lineId;
  final String? code; // U_Code
  final String? description; // U_Name
  final String? estado; // U_Estado ('N' pendiente / 'T' terminada)
  final String? tecnicoCode; // U_UsrResp (EmployeeID)
  final String? tecnicoName; // U_UsrRespN

  const OrderTask({
    this.lineId,
    this.code,
    this.description,
    this.estado,
    this.tecnicoCode,
    this.tecnicoName,
  });

  /// Pendiente mientras no esté 'T' (terminada). Catálogo observado: N / T.
  bool get isPending => (estado ?? '').toUpperCase().trim() != 'T';

  String get statusLabel => isPending ? 'Pendiente' : 'Terminada';

  String get displayName =>
      (description?.trim().isNotEmpty ?? false)
          ? description!.trim()
          : (code ?? 'Tarea ${lineId ?? ''}');

  factory OrderTask.fromJson(Map<String, dynamic> json) => OrderTask(
        lineId: json['LineId'] as int?,
        code: _nz(json['U_Code']),
        description: _nz(json['U_Name']),
        estado: _nz(json['U_Estado']),
        tecnicoCode: _nz(json['U_UsrResp']?.toString()),
        tecnicoName: _nz(json['U_UsrRespN']),
      );

  static String? _nz(dynamic v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }
}

/// Modelo de **Orden de Mantención (OM)** mapeado al UDO `VID_MTOM` de SAP B1
/// Service Layer — el documento operativo/ejecutable que ve el técnico en terreno.
///
/// Se filtra por `U_Taller` (taller/zona del técnico). El responsable
/// `U_UsrRes` es el **supervisor**, no el técnico (a los técnicos se les asigna
/// trabajo a nivel de tarea, fuera de este documento).
///
/// Datos NO presentes en la OM (etapas siguientes):
///  - Dirección física de la obra y coordenadas → tabla OINS por [equipoCode].
class OrderModel {
  // ── Identificadores ──────────────────────────────────────────────────────
  final int? docEntry;
  final int? docNum;

  /// Estado del objeto SAP: 'O' abierta / 'C' cerrada.
  final String? status;

  /// Estado operativo propio del UDO (U_Estado).
  final String? estado;
  final String? canceled;

  // ── Cliente / asunto ─────────────────────────────────────────────────────
  final String? cliente; // U_Cliente
  final String? asunto; // U_Asunto
  final String? comentarios; // U_Comments

  // ── Equipo ───────────────────────────────────────────────────────────────
  final String? equipoCode; // U_Equipo
  final String? equipoDescripcion; // U_EquipoN
  final String? serie; // U_Serie
  final String? familia; // U_Familia
  final String? subFamilia; // U_sFamilia

  // ── Clasificación ────────────────────────────────────────────────────────
  final String? prioridad; // U_Priorid
  final String? tipoOM; // U_TipoOM
  final String? falla; // U_Falla
  final String? fallaNombre; // U_FallaN

  // ── Ubicación ────────────────────────────────────────────────────────────
  final String? taller; // U_Taller
  final String? ubicacion; // U_Ubica
  final String? proyecto; // U_Proy

  // ── Personas ─────────────────────────────────────────────────────────────
  final String? supervisorCode; // U_UsrRes
  final String? supervisorName; // U_UsrResN
  final String? creator; // Creator

  // ── Fechas ───────────────────────────────────────────────────────────────
  final DateTime? fechaOrden; // U_FecOrden
  final DateTime? fechaNecesaria; // U_FechaNec
  final DateTime? fechaEstimada; // U_FechaEst
  final DateTime? fechaCierre; // U_FechaCie
  final DateTime? fechaCreacion; // CreateDate

  // ── Checklist ────────────────────────────────────────────────────────────
  final String? checklistId; // U_CheckListID
  final String? checklistUrl; // U_CheckListUrl
  final String? checklistEstado; // U_EstadoCheckList

  // ── Documentos relacionados ──────────────────────────────────────────────
  final String? numSolicitud; // U_NumSol (VID_MTSOLREP)
  final String? docNumRtov; // U_DocNum_RTOV

  final List<OrderDetailLine> detailLines;

  /// Tareas asignadas de la OM (VID_MTOMTACollection).
  final List<OrderTask> tasks;

  const OrderModel({
    this.docEntry,
    this.docNum,
    this.status,
    this.estado,
    this.canceled,
    this.cliente,
    this.asunto,
    this.comentarios,
    this.equipoCode,
    this.equipoDescripcion,
    this.serie,
    this.familia,
    this.subFamilia,
    this.prioridad,
    this.tipoOM,
    this.falla,
    this.fallaNombre,
    this.taller,
    this.ubicacion,
    this.proyecto,
    this.supervisorCode,
    this.supervisorName,
    this.creator,
    this.fechaOrden,
    this.fechaNecesaria,
    this.fechaEstimada,
    this.fechaCierre,
    this.fechaCreacion,
    this.checklistId,
    this.checklistUrl,
    this.checklistEstado,
    this.numSolicitud,
    this.docNumRtov,
    this.detailLines = const [],
    this.tasks = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final lines = <OrderDetailLine>[];
    final rawLines = json['VID_MTOMMACollection'] as List<dynamic>?;
    if (rawLines != null) {
      for (final l in rawLines) {
        if (l is Map<String, dynamic>) lines.add(OrderDetailLine.fromJson(l));
      }
    }

    final taskList = <OrderTask>[];
    final rawTasks = json['VID_MTOMTACollection'] as List<dynamic>?;
    if (rawTasks != null) {
      for (final t in rawTasks) {
        if (t is Map<String, dynamic>) taskList.add(OrderTask.fromJson(t));
      }
    }

    return OrderModel(
      docEntry: json['DocEntry'] as int?,
      docNum: json['DocNum'] as int?,
      status: json['Status'] as String?,
      estado: json['U_Estado'] as String?,
      canceled: json['Canceled'] as String?,
      cliente: _nz(json['U_Cliente']),
      asunto: _nz(json['U_Asunto']),
      comentarios: _nz(json['U_Comments']),
      equipoCode: _nz(json['U_Equipo']),
      equipoDescripcion: _nz(json['U_EquipoN']),
      serie: _nz(json['U_Serie']),
      familia: _nz(json['U_Familia']),
      subFamilia: _nz(json['U_sFamilia']),
      prioridad: _nz(json['U_Priorid']),
      tipoOM: _nz(json['U_TipoOM']),
      falla: _nz(json['U_Falla']),
      fallaNombre: _nz(json['U_FallaN']),
      taller: _nz(json['U_Taller']),
      ubicacion: _nz(json['U_Ubica']),
      proyecto: _nz(json['U_Proy']),
      supervisorCode: _nz(json['U_UsrRes']),
      supervisorName: _nz(json['U_UsrResN']),
      creator: _nz(json['Creator']),
      fechaOrden: _toDate(json['U_FecOrden']),
      fechaNecesaria: _toDate(json['U_FechaNec']),
      fechaEstimada: _toDate(json['U_FechaEst']),
      fechaCierre: _toDate(json['U_FechaCie']),
      fechaCreacion: _toDate(json['CreateDate']),
      checklistId: _nz(json['U_CheckListID']?.toString()),
      checklistUrl: _nz(json['U_CheckListUrl']),
      checklistEstado: _nz(json['U_EstadoCheckList']?.toString()),
      numSolicitud: _nz(json['U_NumSol']?.toString()),
      docNumRtov: _nz(json['U_DocNum_RTOV']?.toString()),
      detailLines: lines,
      tasks: taskList,
    );
  }

  /// PATCH parcial (solo campos editables desde la app).
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (estado != null) m['U_Estado'] = estado;
    if (comentarios != null) m['U_Comments'] = comentarios;
    return m;
  }

  OrderModel copyWith({
    int? docEntry,
    int? docNum,
    String? status,
    String? estado,
    String? canceled,
    String? cliente,
    String? asunto,
    String? comentarios,
    String? equipoCode,
    String? equipoDescripcion,
    String? serie,
    String? familia,
    String? subFamilia,
    String? prioridad,
    String? tipoOM,
    String? falla,
    String? fallaNombre,
    String? taller,
    String? ubicacion,
    String? proyecto,
    String? supervisorCode,
    String? supervisorName,
    String? creator,
    DateTime? fechaOrden,
    DateTime? fechaNecesaria,
    DateTime? fechaEstimada,
    DateTime? fechaCierre,
    DateTime? fechaCreacion,
    String? checklistId,
    String? checklistUrl,
    String? checklistEstado,
    String? numSolicitud,
    String? docNumRtov,
    List<OrderDetailLine>? detailLines,
    List<OrderTask>? tasks,
  }) =>
      OrderModel(
        docEntry: docEntry ?? this.docEntry,
        docNum: docNum ?? this.docNum,
        status: status ?? this.status,
        estado: estado ?? this.estado,
        canceled: canceled ?? this.canceled,
        cliente: cliente ?? this.cliente,
        asunto: asunto ?? this.asunto,
        comentarios: comentarios ?? this.comentarios,
        equipoCode: equipoCode ?? this.equipoCode,
        equipoDescripcion: equipoDescripcion ?? this.equipoDescripcion,
        serie: serie ?? this.serie,
        familia: familia ?? this.familia,
        subFamilia: subFamilia ?? this.subFamilia,
        prioridad: prioridad ?? this.prioridad,
        tipoOM: tipoOM ?? this.tipoOM,
        falla: falla ?? this.falla,
        fallaNombre: fallaNombre ?? this.fallaNombre,
        taller: taller ?? this.taller,
        ubicacion: ubicacion ?? this.ubicacion,
        proyecto: proyecto ?? this.proyecto,
        supervisorCode: supervisorCode ?? this.supervisorCode,
        supervisorName: supervisorName ?? this.supervisorName,
        creator: creator ?? this.creator,
        fechaOrden: fechaOrden ?? this.fechaOrden,
        fechaNecesaria: fechaNecesaria ?? this.fechaNecesaria,
        fechaEstimada: fechaEstimada ?? this.fechaEstimada,
        fechaCierre: fechaCierre ?? this.fechaCierre,
        fechaCreacion: fechaCreacion ?? this.fechaCreacion,
        checklistId: checklistId ?? this.checklistId,
        checklistUrl: checklistUrl ?? this.checklistUrl,
        checklistEstado: checklistEstado ?? this.checklistEstado,
        numSolicitud: numSolicitud ?? this.numSolicitud,
        docNumRtov: docNumRtov ?? this.docNumRtov,
        detailLines: detailLines ?? this.detailLines,
        tasks: tasks ?? this.tasks,
      );

  // ── Helpers UI (getters estables) ──────────────────────────────────────────

  String get displayId => docNum != null ? 'OM-$docNum' : 'OM-?';

  /// Estado legible. TODO(sap): confirmar catálogo de U_Estado de VID_MTOM.
  String get displayStatus {
    final translated = SapConfig.translateOmState(estado);
    if (translated != null) return translated;
    switch (status?.toUpperCase().trim()) {
      case 'O':
        return 'Abierta';
      case 'C':
        return 'Cerrada';
      default:
        return estado ?? status ?? 'Sin estado';
    }
  }

  /// Nombre del supervisor responsable de la OM (no es el técnico de terreno).
  String get supervisorDisplay =>
      supervisorName ?? supervisorCode ?? 'Sin asignar';

  /// Compatibilidad con UI existente: muestra el supervisor de la OM.
  String get technicianName => supervisorDisplay;

  String get priorityLabel {
    switch (prioridad?.toUpperCase().trim()) {
      case 'A':
      case 'ALTA':
        return 'Alta';
      case 'M':
      case 'MEDIA':
        return 'Media';
      case 'B':
      case 'BAJA':
        return 'Baja';
      case 'N':
      case 'NORMAL':
        return 'Normal';
      default:
        return prioridad ?? 'Normal';
    }
  }

  String get clientDisplayName =>
      cliente ?? asunto ?? equipoDescripcion ?? 'Sin cliente';

  String get descripcionProblema => comentarios ?? asunto ?? '';

  String get tallerNombre {
    final code = taller?.trim();
    if (code == null || code.isEmpty) return 'Sin taller';
    return switch (code.toUpperCase()) {
      'IQU-01' => 'Iquique',
      'ANF-01' => 'Antofagasta',
      'COP-01' => 'Copiapó',
      'COQ-01' => 'Coquimbo',
      'QUI-01' => 'Quilpué',
      'STG-01' => 'Stgo. Eléctrico',
      'CMA-01' => 'Stgo. Combustión',
      'CUR-01' => 'Curicó',
      'PSU-01' => 'Rancagua',
      'CCP-01' => 'Concepción',
      'TEM-01' => 'Temuco',
      'PMO-01' => 'Puerto Montt',
      _ => code,
    };
  }

  /// Dirección para mostrar/llegar. La OM solo trae la ubicación/taller;
  /// la dirección física real está en OINS (etapa de mapas).
  /// TODO(sap): resolver dirección real desde OINS vía equipoCode.
  String get fullAddress => ubicacion ?? tallerNombre;

  bool get isActive =>
      (status?.toUpperCase().trim() == 'O') &&
      (canceled?.toUpperCase().trim() != 'Y');

  bool get isFinished => status?.toUpperCase().trim() == 'C';
  bool get isCancelled => canceled?.toUpperCase().trim() == 'Y';

  /// La OM admite escritura (agregar/ejecutar tareas y materiales) según su
  /// U_Estado real. Cerrada ('C') o Cancelada ('X') → no editable (SAP la rechaza).
  bool get isEditable => SapConfig.isOmEditableState(estado);

  bool get hasChecklist =>
      checklistId != null && checklistId != '0' && checklistId!.isNotEmpty;

  /// Materiales con contenido real (SAP suele traer una línea inicial vacía en
  /// la colección; se descarta para no mostrar un "• x0" fantasma).
  List<OrderDetailLine> get visibleMaterials => detailLines
      .where((m) =>
          (m.itemDescription?.trim().isNotEmpty ?? false) ||
          (m.itemCode?.trim().isNotEmpty ?? false))
      .toList();

  int get materialCount => visibleMaterials.length;

  // ── Tareas ─────────────────────────────────────────────────────────────────
  int get tasksTotal => tasks.length;
  int get tasksPending => tasks.where((t) => t.isPending).length;
  int get tasksDone => tasks.where((t) => !t.isPending).length;
  bool get hasTasks => tasks.isNotEmpty;

  DateTime? get fechaProgramada => fechaNecesaria ?? fechaOrden;

  static String? _nz(dynamic v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel &&
          runtimeType == other.runtimeType &&
          docEntry == other.docEntry;

  @override
  int get hashCode => docEntry.hashCode;

  @override
  String toString() =>
      'OrderModel($displayId | $clientDisplayName | $displayStatus)';
}
