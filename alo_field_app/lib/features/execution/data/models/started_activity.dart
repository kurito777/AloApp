import '../../../../core/config/sap_config.dart';

/// Tarea/trabajo realizado dentro de una actividad ("qué hicimos").
///
/// Equivalente local de una línea de `VID_MTOMTACollection` / registro de
/// tareas (VID_MREGTAR) — se persiste en el dispositivo hasta que exista el
/// endpoint SAP de contabilización.
class ActivityTask {
  final String id;
  final String description;
  final DateTime createdAt;

  const ActivityTask({
    required this.id,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ActivityTask.fromJson(Map<String, dynamic> json) => ActivityTask(
        id: (json['id'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      );
}

/// Material/repuesto usado en la mantención ("qué usamos").
///
/// Equivalente local de una línea de la colección de materiales `MA` de la OM.
class ActivityMaterial {
  final String id;
  final String description;
  final double quantity;
  final DateTime createdAt;

  const ActivityMaterial({
    required this.id,
    required this.description,
    required this.quantity,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ActivityMaterial.fromJson(Map<String, dynamic> json) {
    final q = json['quantity'];
    return ActivityMaterial(
      id: (json['id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      quantity: q is num ? q.toDouble() : (double.tryParse('$q') ?? 1),
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    );
  }
}

/// Actividad (OM) que el técnico **inició** desde el dashboard.
///
/// Es la fuente de verdad local de "Mis Servicios" para las órdenes de
/// mantención en curso. Se persiste por técnico (ver `ActivityStore`) porque
/// SAP no permite hoy consultar las OMs asignadas/iniciadas por un técnico
/// (VID_MTOM no tiene campo de técnico y VID_MREGTAR no es filtrable por OData).
///
/// El ciclo de estados replica el de la tarjeta del dashboard:
/// EC (En Camino) → EA (En Área) → EP (En Proceso) → F (Finalizada).
class StartedActivity {
  final int docEntry;
  final int docNum;

  /// EmployeeID del técnico dueño de la actividad (OHEM.EmployeeID).
  final String technicianCode;

  /// Estado operativo local: 'EC' | 'EA' | 'EP' | 'F'.
  final String estado;

  final String? cliente;
  final String? equipoCode;
  final String? equipoName;
  final String? direccion;
  final String? taller;
  final String? docNumRtov;

  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;
  final String? finishComments;

  /// Tareas realizadas y materiales usados registrados por el técnico.
  final List<ActivityTask> tasks;
  final List<ActivityMaterial> materials;

  const StartedActivity({
    required this.docEntry,
    required this.docNum,
    required this.technicianCode,
    required this.estado,
    this.cliente,
    this.equipoCode,
    this.equipoName,
    this.direccion,
    this.taller,
    this.docNumRtov,
    required this.startedAt,
    required this.updatedAt,
    this.finishedAt,
    this.finishComments,
    this.tasks = const [],
    this.materials = const [],
  });

  /// Abierta mientras no esté finalizada.
  bool get isOpen => estado.toUpperCase().trim() != 'F';

  String get displayId => 'OM-$docNum';

  String get statusLabel => SapConfig.translateState(estado);

  StartedActivity copyWith({
    String? estado,
    String? cliente,
    String? equipoCode,
    String? equipoName,
    String? direccion,
    String? taller,
    String? docNumRtov,
    DateTime? updatedAt,
    DateTime? finishedAt,
    String? finishComments,
    List<ActivityTask>? tasks,
    List<ActivityMaterial>? materials,
  }) {
    return StartedActivity(
      docEntry: docEntry,
      docNum: docNum,
      technicianCode: technicianCode,
      estado: estado ?? this.estado,
      cliente: cliente ?? this.cliente,
      equipoCode: equipoCode ?? this.equipoCode,
      equipoName: equipoName ?? this.equipoName,
      direccion: direccion ?? this.direccion,
      taller: taller ?? this.taller,
      docNumRtov: docNumRtov ?? this.docNumRtov,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      finishComments: finishComments ?? this.finishComments,
      tasks: tasks ?? this.tasks,
      materials: materials ?? this.materials,
    );
  }

  Map<String, dynamic> toJson() => {
        'docEntry': docEntry,
        'docNum': docNum,
        'technicianCode': technicianCode,
        'estado': estado,
        'cliente': cliente,
        'equipoCode': equipoCode,
        'equipoName': equipoName,
        'direccion': direccion,
        'taller': taller,
        'docNumRtov': docNumRtov,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'finishComments': finishComments,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'materials': materials.map((m) => m.toJson()).toList(),
      };

  factory StartedActivity.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic v, {DateTime? fallback}) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? (fallback ?? DateTime.now());
      }
      return fallback ?? DateTime.now();
    }

    final started = parse(json['startedAt']);
    return StartedActivity(
      docEntry: (json['docEntry'] ?? 0) as int,
      docNum: (json['docNum'] ?? 0) as int,
      technicianCode: (json['technicianCode'] ?? '').toString(),
      estado: (json['estado'] ?? 'EC').toString(),
      cliente: json['cliente'] as String?,
      equipoCode: json['equipoCode'] as String?,
      equipoName: json['equipoName'] as String?,
      direccion: json['direccion'] as String?,
      taller: json['taller'] as String?,
      docNumRtov: json['docNumRtov'] as String?,
      startedAt: started,
      updatedAt: parse(json['updatedAt'], fallback: started),
      finishedAt: json['finishedAt'] is String
          ? DateTime.tryParse(json['finishedAt'] as String)
          : null,
      finishComments: json['finishComments'] as String?,
      tasks: (json['tasks'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ActivityTask.fromJson)
              .toList() ??
          const [],
      materials: (json['materials'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ActivityMaterial.fromJson)
              .toList() ??
          const [],
    );
  }
}
