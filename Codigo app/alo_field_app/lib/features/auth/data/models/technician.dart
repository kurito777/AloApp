/// Identidad del técnico autenticado.
///
/// Se arma en dos pasos desde SAP B1:
///  1. OHEM (`EmployeesInfo`) por correo → identidad + [applicationUserId].
///  2. OUSR (`Users`) por `InternalKey == applicationUserId` → [taller] y
///     [isSupervisor] (campos custom U_VID_Taller / U_VID_MTSup).
///
/// El [code] (EmployeeID de OHEM) identifica al empleado; el [taller] es el
/// que se usa para filtrar las órdenes de mantención (VID_MTOM.U_Taller).
class Technician {
  /// EmployeeID de OHEM.
  final String code;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? jobTitle;
  final String? mobile;
  final String? phone;
  final String? departmentId;
  final String? branchId;

  /// OUSR.InternalKey enlazado (OHEM.ApplicationUserID).
  final String? applicationUserId;

  /// Código de taller/faena del técnico (OUSR.U_VID_Taller, ej. "ANF-01").
  final String? taller;

  /// true si es supervisor de mantención (OUSR.U_VID_MTSup == 'Y').
  final bool isSupervisor;

  const Technician({
    required this.code,
    required this.email,
    this.firstName,
    this.lastName,
    this.jobTitle,
    this.mobile,
    this.phone,
    this.departmentId,
    this.branchId,
    this.applicationUserId,
    this.taller,
    this.isSupervisor = false,
  });

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    final name = parts.join(' ').trim();
    return name.isEmpty ? email : name;
  }

  /// Construye desde una fila de `EmployeesInfo` (OHEM) del Service Layer.
  factory Technician.fromEmployeesInfo(Map<String, dynamic> json) {
    return Technician(
      code: (json['EmployeeID'] ?? '').toString(),
      firstName: _str(json['FirstName']),
      lastName: _str(json['LastName']),
      email: _str(json['eMail']) ?? _str(json['HomeEmail']) ?? '',
      jobTitle: _str(json['JobTitle']),
      mobile: _str(json['MobilePhone']),
      phone: _str(json['OfficePhone']) ?? _str(json['HomePhone']),
      departmentId: json['Department']?.toString(),
      branchId: json['Branch']?.toString(),
      applicationUserId: _str(json['ApplicationUserID']?.toString()),
    );
  }

  /// Copia agregando los datos del usuario SAP (OUSR).
  Technician withUser({String? taller, bool? isSupervisor}) => Technician(
        code: code,
        email: email,
        firstName: firstName,
        lastName: lastName,
        jobTitle: jobTitle,
        mobile: mobile,
        phone: phone,
        departmentId: departmentId,
        branchId: branchId,
        applicationUserId: applicationUserId,
        taller: taller ?? this.taller,
        isSupervisor: isSupervisor ?? this.isSupervisor,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'jobTitle': jobTitle,
        'mobile': mobile,
        'phone': phone,
        'departmentId': departmentId,
        'branchId': branchId,
        'applicationUserId': applicationUserId,
        'taller': taller,
        'isSupervisor': isSupervisor,
      };

  factory Technician.fromJson(Map<String, dynamic> json) => Technician(
        code: json['code'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        email: json['email'] as String? ?? '',
        jobTitle: json['jobTitle'] as String?,
        mobile: json['mobile'] as String?,
        phone: json['phone'] as String?,
        departmentId: json['departmentId'] as String?,
        branchId: json['branchId'] as String?,
        applicationUserId: json['applicationUserId'] as String?,
        taller: json['taller'] as String?,
        isSupervisor: json['isSupervisor'] as bool? ?? false,
      );

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
