/// Llamada de servicio (OSCL) asignada al técnico.
///
/// Fuente consultable HOY sin backend para "Ejecución" (filtrable por
/// TechnicianCode = EmployeeID / AssigneeCode = usuario). El historial fiel de
/// tareas (VID_MREGTAR) requiere un endpoint servidor y queda pendiente.
class ServiceCallItem {
  final int id;
  final String? subject;
  final String? description;

  /// Status SAP: -3 = abierta, -1/-2 = cerrada.
  final int? status;
  final String? priority;
  final String? customerCode;
  final String? customerName;
  final String? itemCode;
  final String? serial;
  final DateTime? creationDate;
  final DateTime? closingDate;
  final String? technicianCode;

  const ServiceCallItem({
    required this.id,
    this.subject,
    this.description,
    this.status,
    this.priority,
    this.customerCode,
    this.customerName,
    this.itemCode,
    this.serial,
    this.creationDate,
    this.closingDate,
    this.technicianCode,
  });

  bool get isOpen => status == -3;

  String get statusLabel => isOpen ? 'Abierta' : 'Cerrada';

  String get priorityLabel {
    switch (priority) {
      case 'scp_High':
        return 'Alta';
      case 'scp_Medium':
        return 'Media';
      case 'scp_Low':
        return 'Baja';
      default:
        return priority ?? '—';
    }
  }

  String get title => subject?.trim().isNotEmpty == true
      ? subject!.trim()
      : (description ?? 'Servicio $id');

  factory ServiceCallItem.fromJson(Map<String, dynamic> json) {
    return ServiceCallItem(
      id: (json['ServiceCallID'] ?? 0) as int,
      subject: _nz(json['Subject']),
      description: _nz(json['Description']),
      status: json['Status'] is int
          ? json['Status'] as int
          : int.tryParse('${json['Status']}'),
      priority: _nz(json['Priority']),
      customerCode: _nz(json['CustomerCode']),
      customerName: _nz(json['CustomerName']),
      itemCode: _nz(json['ItemCode']),
      serial: _nz(json['ManufacturerSerialNum']) ?? _nz(json['InternalSerialNum']),
      creationDate: _toDate(json['CreationDate']),
      closingDate: _toDate(json['ClosingDate']),
      technicianCode: _nz(json['TechnicianCode']?.toString()),
    );
  }

  static String? _nz(dynamic v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }

  static DateTime? _toDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
