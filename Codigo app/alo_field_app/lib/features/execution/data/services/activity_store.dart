import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/started_activity.dart';

/// Almacén local persistente de las **actividades (OM) iniciadas** por el
/// técnico, fuente de verdad de "Mis Servicios" para las órdenes de mantención.
///
/// Motivo (ver memoria SAP): no existe hoy forma de consultar desde el Service
/// Layer las OMs iniciadas/asignadas a un técnico (VID_MTOM no tiene campo de
/// técnico; VID_MREGTAR no es filtrable por OData). Hasta que exista un endpoint
/// servidor, el seguimiento vive en el dispositivo, por técnico.
///
/// Expone [revision] para que la UI (pestaña Ejecución) se refresque cuando el
/// dashboard inicia/avanza/finaliza una actividad.
class ActivityStore {
  ActivityStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'started_activities_v1';

  final FlutterSecureStorage _storage;

  /// Incrementa en cada cambio; la UI escucha para recargar.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  List<StartedActivity> _items = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items = decoded
              .whereType<Map<String, dynamic>>()
              .map(StartedActivity.fromJson)
              .toList();
        }
      }
    } catch (e) {
      dev.log('[ActivityStore] Error leyendo storage: $e');
      _items = [];
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    try {
      final raw = jsonEncode(_items.map((a) => a.toJson()).toList());
      await _storage.write(key: _key, value: raw);
    } catch (e) {
      dev.log('[ActivityStore] Error escribiendo storage: $e');
    }
    revision.value++;
  }

  /// Actividades del técnico. [open] null = todas; true = abiertas; false = cerradas.
  Future<List<StartedActivity>> forTechnician(
    String technicianCode, {
    bool? open,
  }) async {
    await _ensureLoaded();
    final tech = technicianCode.trim();
    var result = _items.where((a) => a.technicianCode == tech);
    if (open != null) {
      result = result.where((a) => a.isOpen == open);
    }
    final list = result.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// Inserta o actualiza (por docEntry + técnico) una actividad.
  Future<void> upsert(StartedActivity activity) async {
    await _ensureLoaded();
    final i = _items.indexWhere((a) =>
        a.docEntry == activity.docEntry &&
        a.technicianCode == activity.technicianCode);
    if (i >= 0) {
      _items[i] = activity;
    } else {
      _items.add(activity);
    }
    await _persist();
  }

  /// Avanza el estado de una actividad ya iniciada (o la crea si [base] se da).
  Future<void> setEstado(
    int docEntry,
    String technicianCode,
    String estado, {
    String? finishComments,
  }) async {
    await _ensureLoaded();
    final i = _items.indexWhere(
        (a) => a.docEntry == docEntry && a.technicianCode == technicianCode);
    if (i < 0) return;
    final now = DateTime.now();
    final isFinish = estado.toUpperCase().trim() == 'F';
    _items[i] = _items[i].copyWith(
      estado: estado,
      updatedAt: now,
      finishedAt: isFinish ? now : null,
      finishComments: finishComments,
    );
    await _persist();
  }

  Future<void> remove(int docEntry, String technicianCode) async {
    await _ensureLoaded();
    _items.removeWhere(
        (a) => a.docEntry == docEntry && a.technicianCode == technicianCode);
    await _persist();
  }

  /// Devuelve una actividad puntual (o null) por docEntry + técnico.
  Future<StartedActivity?> findOne(int docEntry, String technicianCode) async {
    await _ensureLoaded();
    for (final a in _items) {
      if (a.docEntry == docEntry && a.technicianCode == technicianCode) return a;
    }
    return null;
  }

  Future<void> _mutate(
    int docEntry,
    String technicianCode,
    StartedActivity Function(StartedActivity) change,
  ) async {
    await _ensureLoaded();
    final i = _items.indexWhere(
        (a) => a.docEntry == docEntry && a.technicianCode == technicianCode);
    if (i < 0) return;
    _items[i] = change(_items[i]).copyWith(updatedAt: DateTime.now());
    await _persist();
  }

  // ── Tareas realizadas ──────────────────────────────────────────────────────

  Future<void> addTask(
    int docEntry,
    String technicianCode,
    ActivityTask task,
  ) =>
      _mutate(docEntry, technicianCode,
          (a) => a.copyWith(tasks: [...a.tasks, task]));

  Future<void> removeTask(
    int docEntry,
    String technicianCode,
    String taskId,
  ) =>
      _mutate(docEntry, technicianCode,
          (a) => a.copyWith(tasks: a.tasks.where((t) => t.id != taskId).toList()));

  // ── Materiales usados ──────────────────────────────────────────────────────

  Future<void> addMaterial(
    int docEntry,
    String technicianCode,
    ActivityMaterial material,
  ) =>
      _mutate(docEntry, technicianCode,
          (a) => a.copyWith(materials: [...a.materials, material]));

  Future<void> removeMaterial(
    int docEntry,
    String technicianCode,
    String materialId,
  ) =>
      _mutate(
          docEntry,
          technicianCode,
          (a) => a.copyWith(
              materials: a.materials.where((m) => m.id != materialId).toList()));
}
