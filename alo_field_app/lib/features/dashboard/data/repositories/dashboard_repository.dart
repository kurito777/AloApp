import 'dart:developer' as dev;

import '../../../orders/data/models/order_model.dart';
import '../services/dashboard_service.dart';
import '../services/sap_auth_service.dart';

/// Repositorio de órdenes del dashboard.
///
/// Capa intermedia entre [DashboardService] (datos crudos de SAP) y el BLoC.
/// Responsabilidades:
/// - Transformar `Map<String,dynamic>` → [OrderModel]
/// - Traducir excepciones SAP a mensajes amigables para la UI
/// - Exponer una API limpia orientada al dominio
class DashboardRepository {
  DashboardRepository({required DashboardService service})
      : _service = service;

  final DashboardService _service;

  // ── Consultas ──────────────────────────────────────────────────────────────

  /// Carga las OM del dashboard filtradas por el **técnico** responsable.
  ///
  /// Relación SAP verificada: `VID_MTOM.U_UsrRes` = `OHEM.EmployeeID` del técnico
  /// ([tecnicoCode]). Solo trae las abiertas (`Status eq 'O'`). Cada OM incluye
  /// su colección de tareas (VID_MTOMTACollection).
  /// Retorna lista vacía si no hay órdenes para los criterios dados.
  /// Lanza [RepositoryException] si SAP responde con error.
  Future<List<OrderModel>> fetchDashboardOrders({
    required String tecnicoCode,
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final rawList = await _service.fetchMtomByTecnico(
        tecnicoCode: tecnicoCode,
        top: pageSize,
        skip: page * pageSize,
      );
      return rawList.map(OrderModel.fromJson).toList();
    } on SapAuthException catch (e) {
      throw RepositoryException(
        'Error de autenticación SAP: ${e.message}',
        isRetryable: true,
      );
    } on SapServiceException catch (e) {
      throw RepositoryException(
        'Error del servidor SAP: ${e.message}',
        isRetryable: e.statusCode != 404,
      );
    } on SapNetworkException catch (e) {
      throw RepositoryException(
        'Sin conexión a SAP. Verifica tu red: ${e.message}',
        isRetryable: true,
      );
    } catch (e) {
      throw RepositoryException('Error inesperado: $e', isRetryable: false);
    }
  }

  /// Carga el detalle completo de una OT, incluyendo materiales
  Future<OrderModel> fetchOrderDetail(int docEntry) async {
    try {
      final raw = await _service.fetchMtomDetail(docEntry);
      return OrderModel.fromJson(raw);
    } on SapAuthException catch (e) {
      throw RepositoryException(
        'Error de autenticación: ${e.message}',
        isRetryable: true,
      );
    } on SapServiceException catch (e) {
      if (e.statusCode == 404) {
        throw RepositoryException(
          'La orden no fue encontrada en SAP.',
          isRetryable: false,
        );
      }
      throw RepositoryException('Error SAP: ${e.message}', isRetryable: true);
    } on SapNetworkException catch (e) {
      throw RepositoryException('Sin conexión: ${e.message}', isRetryable: true);
    } catch (e) {
      throw RepositoryException('Error inesperado: $e', isRetryable: false);
    }
  }

  // ── Actualizaciones de estado (ciclo de la actividad) ──────────────────────
  //
  // IMPORTANTE: el ciclo Iniciar/Llegué/Finalizar de una OM (VID_MTOM) NO se
  // persiste todavía en SAP. El código anterior hacía PATCH sobre `VID_RTOV`
  // usando el `docEntry` de la OM: entidad equivocada (VID_RTOV son OTs de
  // arriendo, no OMs) y con un catálogo de `U_Estado` de la OM que aún no está
  // confirmado (ver memoria SAP). Escribir un estado adivinado en la entidad
  // equivocada corrompería datos, así que el avance de estado se mantiene
  // localmente (ActivityStore → "Mis Servicios") y estos métodos quedan como
  // punto único de integración para cuando se confirme el campo/catálogo real.
  //
  // TODO(sap): al confirmar el campo de estado de VID_MTOM y su catálogo,
  // implementar aquí el PATCH real contra VID_MTOM(docEntry) y quitar el no-op.
  // La escritura seguirá protegida por el gate `SAP_WRITE_ENABLED`.

  /// Inicia la actividad (paso local a "En Camino").
  Future<void> initiateOrder(int docEntry) async {
    _logPendingOmWrite(docEntry, 'EC');
  }

  /// Registra llegada del técnico (paso local a "En Área").
  Future<void> markArrived(
    int docEntry, {
    double? lat,
    double? lng,
  }) async {
    _logPendingOmWrite(docEntry, 'EA', extra: 'gps=$lat,$lng');
  }

  /// Marca inicio de trabajo en sitio (paso local a "En Proceso").
  Future<void> startWork(int docEntry) async {
    _logPendingOmWrite(docEntry, 'EP');
  }

  /// Finaliza la actividad (paso local a "Finalizada").
  Future<void> finishOrder(
    int docEntry, {
    String? solucion,
    String? comentarios,
  }) async {
    _logPendingOmWrite(docEntry, 'F');
  }

  void _logPendingOmWrite(int docEntry, String estado, {String? extra}) {
    dev.log('[DashboardRepository] OM $docEntry → $estado '
        '(persistencia SAP pendiente de catálogo VID_MTOM)'
        '${extra != null ? ' [$extra]' : ''}');
  }

  /// Actualiza campos arbitrarios de una OT.
  Future<void> updateOrderFields(
    int docEntry,
    Map<String, dynamic> fields,
  ) async {
    await _patchSafe(docEntry, () => _service.patchOrder(docEntry, fields));
  }

  // ── Escritura de tareas/materiales en la OM (VID_MTOM) ──────────────────────

  /// Agrega una tarea a la OM (la ejecuta el técnico en terreno).
  Future<void> addOmTask(
    int docEntry, {
    required String name,
    String? tecnicoCode,
    String? tecnicoName,
  }) =>
      _patchSafe(
        docEntry,
        () => _service.addOmTask(
          docEntry,
          name: name,
          tecnicoCode: tecnicoCode,
          tecnicoName: tecnicoName,
        ),
      );

  /// Marca el avance de una tarea de la OM ('N'/'P'/'T').
  Future<void> setOmTaskEstado(int docEntry, int lineId, String estado) =>
      _patchSafe(
        docEntry,
        () => _service.setOmTaskEstado(docEntry, lineId, estado),
      );

  /// Agrega un material usado a la OM.
  Future<void> addOmMaterial(
    int docEntry, {
    required String itemName,
    required double cantidad,
    String? itemCode,
    String? um,
  }) =>
      _patchSafe(
        docEntry,
        () => _service.addOmMaterial(
          docEntry,
          itemName: itemName,
          cantidad: cantidad,
          itemCode: itemCode,
          um: um,
        ),
      );

  // ── Helper privado ─────────────────────────────────────────────────────────

  Future<void> _patchSafe(int docEntry, Future<void> Function() action) async {
    try {
      await action();
    } on SapAuthException catch (e) {
      throw RepositoryException(
        'Sesión SAP expirada. Intenta de nuevo: ${e.message}',
        isRetryable: true,
      );
    } on SapServiceException catch (e) {
      throw RepositoryException(
        'SAP rechazó la actualización: ${e.message}',
        isRetryable: false,
      );
    } on SapNetworkException catch (e) {
      throw RepositoryException(
        'Sin conexión al actualizar OT-$docEntry: ${e.message}',
        isRetryable: true,
      );
    } catch (e) {
      throw RepositoryException(
        'Error al actualizar OT-$docEntry: $e',
        isRetryable: false,
      );
    }
  }
}

/// Excepción del repositorio con mensaje listo para mostrar en UI.
class RepositoryException implements Exception {
  final String message;

  /// true si tiene sentido reintentar la operación (red, timeout, auth).
  final bool isRetryable;

  const RepositoryException(this.message, {required this.isRetryable});

  @override
  String toString() => 'RepositoryException: $message';
}
