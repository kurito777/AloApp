import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../errors/exceptions.dart';

/// Configuración centralizada para SAP B1 Service Layer.
///
/// Lee variables de entorno desde .env usando flutter_dotenv.
/// Llamar [validate] al inicio de la app para verificar la configuración antes
/// de realizar cualquier operación de red.
class SapConfig {
  SapConfig._();

  // ── Credenciales SAP ───────────────────────────────────────────────────────
  static String get baseUrl =>
      dotenv.env['SAP_BASE_URL'] ?? 'https://sap.alo-group.com:50000/b1s/v1';

  static String get company => dotenv.env['SAP_COMPANY'] ?? '';

  static String get serviceUser =>
      dotenv.env['SAP_SERVICE_USER'] ?? 'SVCMOBILE';

  static String get servicePassword =>
      dotenv.env['SAP_SERVICE_PASSWORD'] ?? '';

  // ── Timeouts y reintentos ──────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// SAP B1 Service Layer expira sesión a los 30 min; se refresca a los 25.
  static const Duration sessionRefreshThreshold = Duration(minutes: 25);

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ── Seguridad de red y escritura ────────────────────────────────────────────
  /// Verificación TLS del certificado del Service Layer.
  ///
  /// Por defecto `true` (se valida el certificado). Solo debe ponerse en
  /// `false` en entornos on-premise con certificado auto-firmado y de forma
  /// explícita vía `.env` (`SAP_VERIFY_TLS=false`). NUNCA en producción con
  /// certificado válido. Patrón tomado del backend CRM (`verifyTls`).
  static bool get verifyTls =>
      (dotenv.env['SAP_VERIFY_TLS'] ?? 'true').toLowerCase().trim() != 'false';

  /// Gate global de escritura contra SAP (PATCH/POST/PUT).
  ///
  /// Por defecto `false`: toda operación de escritura queda bloqueada con
  /// [SapWriteGateException] y la BD de SAP no se toca. Para habilitar cambios
  /// reales debe ponerse `SAP_WRITE_ENABLED=true` en `.env` de forma explícita.
  /// Réplica del gate `ALO_SAP_WRITE_ENABLED` / `SAP_WRITE_GATE_CLOSED` del
  /// backend CRM, para evitar escrituras accidentales durante pruebas.
  static bool get writeEnabled =>
      (dotenv.env['SAP_WRITE_ENABLED'] ?? 'false').toLowerCase().trim() ==
      'true';

  /// UDOs/entidades sobre los que esta app tiene permitido escribir (PATCH).
  ///
  /// Defensa en profundidad: aunque el gate esté abierto, solo estos objetos
  /// pueden recibir escrituras. Réplica del `WRITE_ENTITIES` del backend CRM.
  static const Set<String> writableUdos = {udoRtov, udoMtsolrep, udoMtom};

  /// Valida que una escritura sea permitida (gate abierto + entidad en allowlist).
  ///
  /// Lanza [SapWriteGateException] si el gate está cerrado, o
  /// [SapWriteNotAllowedException] si el UDO no está en [writableUdos].
  static void assertWritable(String udo) {
    if (!writeEnabled) {
      throw SapWriteGateException(udo);
    }
    if (!writableUdos.contains(udo)) {
      throw SapWriteNotAllowedException(udo);
    }
  }

  // ── Paginación ─────────────────────────────────────────────────────────────
  static const int defaultPageSize = 50;
  static const int maxPageSize = 200;

  // ── Dashboard ──────────────────────────────────────────────────────────────
  /// Ventana de días hacia atrás (por U_FecOrden) para las OMs del dashboard.
  /// Evita traer miles de OMs históricas abiertas. Configurable por .env.
  /// En producción usar ~90; en la BD de prueba la data es de 2024, así que
  /// conviene un valor alto (ej. DASHBOARD_RECENT_DAYS=2000) para ver datos.
  static int get dashboardRecentDays =>
      int.tryParse(dotenv.env['DASHBOARD_RECENT_DAYS'] ?? '') ?? 90;

  // ── UDOs conocidos ─────────────────────────────────────────────────────────
  /// Órdenes de Taller (OT) — Rental.
  static const String udoRtov = 'VID_RTOV';

  /// Solicitud de reparación (documento inicial, previo a la orden).
  static const String udoMtsolrep = 'VID_MTSOLREP';

  /// Orden de Mantención (documento operativo/ejecutable que ve el técnico).
  static const String udoMtom = 'VID_MTOM';

  /// Maestro de equipos del CMMS (Code = código de equipo, ej. "BAP-0397").
  static const String udoMtequipos = 'VID_MTEQUIPOS';

  /// Catálogo de ubicaciones/estado del equipo (ej. 005 = "En ALO").
  static const String udoMtubica = 'VID_MTUBICA';

  /// Maestro de talleres del CMMS (Code = "ANF-01"; U_WhsCode → bodega OWHS).
  static const String udoMttaller = 'VID_MTTALLER';

  /// Bodegas (OWHS): dirección real del taller (City, Street si existe).
  static String get warehousesEndpoint => '$baseUrl/Warehouses';

  /// Departamentos (ODPT): Code → Name (ej. 13 = "TI").
  static String get departmentsEndpoint => '$baseUrl/Departments';

  /// Sucursales/Branches: Code → Name (ej. -2 = "SANTIAGO").
  static String get branchesEndpoint => '$baseUrl/Branches';

  /// Maestro de artículos (OITM): catálogo de materiales/repuestos.
  static String get itemsEndpoint => '$baseUrl/Items';

  // ── Endpoints ──────────────────────────────────────────────────────────────
  static String get loginEndpoint => '$baseUrl/Login';
  static String get logoutEndpoint => '$baseUrl/Logout';

  /// Datos maestros de empleado (tabla OHEM). Fuente de identidad del técnico.
  /// El correo vive en `eMail` y el `EmployeeID` identifica al empleado.
  /// `ApplicationUserID` enlaza con el usuario SAP (OUSR.InternalKey).
  static String get employeesInfoEndpoint => '$baseUrl/EmployeesInfo';

  /// Usuarios del sistema (tabla OUSR). Contiene el taller del técnico en
  /// `U_VID_Taller` y si es supervisor de mantención en `U_VID_MTSup`.
  static String get usersEndpoint => '$baseUrl/Users';

  /// Llamadas de servicio (OSCL). `TechnicianCode` = OHEM.EmployeeID del técnico
  /// asignado; `AssigneeCode` = OUSR del usuario. Status -3 abierta / -1 cerrada.
  static String get serviceCallsEndpoint => '$baseUrl/ServiceCalls';

  /// Endpoint de lista para un UDO (GET / POST).
  static String udoListEndpoint(String udo) => '$baseUrl/$udo';

  /// Endpoint de entrada individual para un UDO (GET / PATCH / DELETE).
  static String udoEntryEndpoint(String udo, int docEntry) =>
      '$baseUrl/$udo($docEntry)';

  // ── Validación ─────────────────────────────────────────────────────────────
  /// Retorna lista de mensajes de error. Lista vacía = configuración válida.
  static List<String> validate() {
    final errors = <String>[];
    if (baseUrl.isEmpty) errors.add('SAP_BASE_URL no definido en .env');
    if (company.isEmpty) errors.add('SAP_COMPANY no definido en .env');
    if (serviceUser.isEmpty) errors.add('SAP_SERVICE_USER no definido en .env');
    if (servicePassword.isEmpty) {
      errors.add('SAP_SERVICE_PASSWORD no definido en .env');
    }
    return errors;
  }

  /// Ciudad legible de un código de taller (U_Taller / OUSR.U_VID_Taller).
  static String tallerCityName(String? code) {
    switch (code?.toUpperCase().trim()) {
      case 'IQU-01':
        return 'Iquique';
      case 'ANF-01':
        return 'Antofagasta';
      case 'COP-01':
        return 'Copiapó';
      case 'COQ-01':
        return 'Coquimbo';
      case 'QUI-01':
        return 'Quilpué';
      case 'STG-01':
        return 'Santiago';
      case 'CMA-01':
        return 'Santiago';
      case 'CUR-01':
        return 'Curicó';
      case 'PSU-01':
        return 'Rancagua';
      case 'CCP-01':
        return 'Concepción';
      case 'TEM-01':
        return 'Temuco';
      case 'PMO-01':
        return 'Puerto Montt';
      default:
        return code ?? '';
    }
  }

  // ── Traducción de estados SAP ──────────────────────────────────────────────
  /// Convierte código SAP (P, EC, EA, EP, F, C) a texto legible para la UI.
  static String translateState(String? sapState) {
    switch (sapState?.toUpperCase().trim()) {
      case 'P':
        return 'Pendiente';
      case 'EC':
        return 'En Camino';
      case 'EA':
        return 'En Área';
      case 'EP':
        return 'En Proceso';
      case 'F':
        return 'Finalizada';
      case 'C':
        return 'Cancelada';
      default:
        return sapState ?? 'Sin Estado';
    }
  }

  /// Traduce el estado de la OM (U_Estado de VID_MTOM) a texto.
  ///
  /// Catálogo real confirmado en SAP (UserFieldsMD @VID_MTOM.Estado):
  /// P=Planificada, L=Liberada, C=Cerrada, X=Cancelada.
  /// Retorna `null` si el código no está en el catálogo, para que la UI pueda
  /// caer al estado estándar del objeto (Status O/C).
  static String? translateOmState(String? omState) {
    switch (omState?.toUpperCase().trim()) {
      case 'P':
        return 'Planificada';
      case 'L':
        return 'Liberada';
      case 'C':
        return 'Cerrada';
      case 'X':
        return 'Cancelada';
      default:
        return null;
    }
  }

  /// Estados de OM sobre los que el técnico puede escribir (agregar/ejecutar
  /// tareas y materiales). Las Cerradas ('C') y Canceladas ('X') las rechaza
  /// SAP con su Transaction Notification, así que se excluyen/bloquean.
  static const Set<String> omEditableStates = {'P', 'L'};

  /// True si la OM (por su U_Estado) admite escritura desde la app.
  /// Trata null/desconocido como editable (no bloquear de más).
  static bool isOmEditableState(String? omState) {
    final s = omState?.toUpperCase().trim();
    if (s == null || s.isEmpty) return true;
    return s != 'C' && s != 'X';
  }

  /// Color hex sugerido para el estado de la OM (P/L/C/X).
  static String omStateColorHex(String? omState) {
    switch (omState?.toUpperCase().trim()) {
      case 'P':
        return '#FF8C00'; // Naranja - Planificada
      case 'L':
        return '#2196F3'; // Azul - Liberada
      case 'C':
        return '#00A650'; // Verde - Cerrada
      case 'X':
        return '#E3000F'; // Rojo - Cancelada
      default:
        return '#9E9E9E';
    }
  }

  /// Convierte texto de UI a código SAP para operaciones PATCH.
  static String stateToSapCode(String displayState) {
    switch (displayState.toLowerCase().trim()) {
      case 'pendiente':
        return 'P';
      case 'en camino':
        return 'EC';
      case 'en área':
        return 'EA';
      case 'en proceso':
        return 'EP';
      case 'finalizada':
        return 'F';
      case 'cancelada':
        return 'C';
      default:
        return displayState;
    }
  }

  /// Lista de estados válidos para mostrar en filtros de UI.
  static List<String> get validDisplayStates => const [
        'Pendiente',
        'En Camino',
        'En Área',
        'En Proceso',
        'Finalizada',
        'Cancelada',
      ];

  /// Códigos SAP considerados "activos" (órdenes abiertas).
  static List<String> get activeStateCodes => const ['P', 'EC', 'EA', 'EP'];

  /// Retorna el color hex sugerido para un estado SAP (uso en UI).
  static String stateColorHex(String? sapState) {
    switch (sapState?.toUpperCase().trim()) {
      case 'P':
        return '#FF8C00'; // Naranja - Pendiente
      case 'EC':
        return '#FFCE00'; // Amarillo ALO - En Camino
      case 'EA':
        return '#2196F3'; // Azul - En Área
      case 'EP':
        return '#9C27B0'; // Púrpura - En Proceso
      case 'F':
        return '#00A650'; // Verde ALO - Finalizada
      case 'C':
        return '#E3000F'; // Rojo ALO - Cancelada
      default:
        return '#9E9E9E'; // Gris - Desconocido
    }
  }
}