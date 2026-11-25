import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/session/session_manager.dart';
import '../../../dashboard/data/repositories/dashboard_repository.dart';
import '../../data/models/order_model.dart';
import '../widgets/om_detail_header.dart';
import '../widgets/om_detail_states.dart';
import '../widgets/om_dialogs.dart';
import '../widgets/om_materials_card.dart';
import '../widgets/om_tasks_card.dart';
import 'material_picker_page.dart';

/// Detalle de una **Orden de Mantención** con ejecución en terreno.
///
/// El técnico puede: agregar tareas, marcar su avance (No iniciada → En proceso
/// → Terminada) y registrar materiales usados. Todo se **escribe en la OM**
/// (`VID_MTOM`: colecciones de tareas y materiales) vía Service Layer,
/// protegido por el gate `SAP_WRITE_ENABLED`.
///
/// El "registro de tareas" contable (VID_MREGTAR) NO se hace aquí: lo realiza
/// el supervisor/administrativa dentro de SAP.
class OmDetailPage extends StatefulWidget {
  final int docEntry;
  final int docNum;

  const OmDetailPage({super.key, required this.docEntry, required this.docNum});

  @override
  State<OmDetailPage> createState() => _OmDetailPageState();
}

class _OmDetailPageState extends State<OmDetailPage> {
  final DashboardRepository _repo = getIt<DashboardRepository>();

  OrderModel? _order;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  /// La OM admite escritura (no está Cerrada/Cancelada en SAP).
  bool get _editable => _order?.isEditable ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final o = await _repo.fetchOrderDetail(widget.docEntry);
      if (!mounted) return;
      setState(() {
        _order = o;
        _loading = false;
      });
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar la OM.';
        _loading = false;
      });
    }
  }

  /// Ejecuta una acción de escritura y recarga; muestra feedback.
  Future<void> _write(Future<void> Function() action, String okMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      _snack(okMsg, ok: true);
    } on RepositoryException catch (e) {
      _snack(e.message, ok: false);
    } catch (e) {
      _snack('No se pudo guardar en SAP.', ok: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? const Color(0xFF00A650) : const Color(0xFFE3000F),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Acciones ────────────────────────────────────────────────────────────────

  Future<void> _addTask() async {
    final name = await _promptText(
      title: 'Agregar tarea',
      hint: 'Descripción de la tarea a realizar...',
    );
    if (name == null || name.isEmpty) return;
    final tech = getIt<SessionManager>().currentTechnician;
    final techName = tech == null
        ? null
        : [tech.firstName, tech.lastName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
    await _write(
      () => _repo.addOmTask(
        widget.docEntry,
        name: name,
        tecnicoCode: tech?.code,
        tecnicoName: techName,
      ),
      'Tarea agregada a la OM',
    );
  }

  Future<void> _setEstado(OrderTask t, String estado) async {
    if (t.lineId == null) return;
    await _write(
      () => _repo.setOmTaskEstado(widget.docEntry, t.lineId!, estado),
      'Tarea actualizada',
    );
  }

  Future<void> _addMaterial() async {
    final sel = await Navigator.of(context).push<MaterialSelection>(
      MaterialPageRoute(builder: (_) => const MaterialPickerPage()),
    );
    if (sel == null) return;
    await _write(
      () => _repo.addOmMaterial(
        widget.docEntry,
        itemCode: sel.code,
        itemName: sel.name,
        cantidad: sel.quantity,
      ),
      'Material agregado a la OM',
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final String viewKey = _loading
        ? 'loading'
        : _error != null
            ? 'error'
            : 'content';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.aloDarkBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('OM-${widget.docNum}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey<String>(viewKey),
          child: _loading
              ? const OmLoadingView()
              : _error != null
                  ? OmErrorView(message: _error!, onRetry: _load)
                  : _content(_order!),
        ),
      ),
    );
  }

  Widget _content(OrderModel o) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OmDetailHeader(order: o),
            if (!_editable) ...[
              const SizedBox(height: 12),
              OmReadOnlyBanner(order: o),
            ],
            const SizedBox(height: 16),
            OmTasksCard(
              order: o,
              editable: _editable,
              busy: _busy,
              onAdd: _addTask,
              onPickEstado: _pickEstado,
              onDelete: _deleteTask,
            ),
            const SizedBox(height: 16),
            OmMaterialsCard(
              order: o,
              editable: _editable,
              busy: _busy,
              onAdd: _addMaterial,
              onDelete: _deleteMaterial,
            ),
            const SizedBox(height: 24),
          ],
        ),
        if (_busy) const Positioned.fill(child: OmSavingOverlay()),
      ],
    );
  }

  Future<void> _deleteTask(OrderTask t) async {
    if (t.lineId == null) return;
    if (!await _confirm('¿Eliminar la tarea "${t.displayName}"?')) return;
    await _write(
      () => _repo.deleteOmTask(widget.docEntry, t.lineId!),
      'Tarea eliminada',
    );
  }

  Future<void> _deleteMaterial(OrderDetailLine m) async {
    if (m.lineId == null) return;
    final name = m.itemDescription ?? m.itemCode ?? 'material';
    if (!await _confirm('¿Eliminar "$name"?')) return;
    await _write(
      () => _repo.deleteOmMaterial(widget.docEntry, m.lineId!),
      'Material eliminado',
    );
  }

  Future<bool> _confirm(String msg) => showOmConfirmDialog(context, msg);

  Future<void> _pickEstado(OrderTask t) async {
    final current = (t.estado ?? 'N').toUpperCase();
    final estado = await showOmEstadoSheet(context: context, current: current);
    if (estado != null && estado != current) _setEstado(t, estado);
  }

  // ── Diálogos ────────────────────────────────────────────────────────────────

  /// Valida: no vacío, ≥3 caracteres y al menos una letra o dígito.
  static String? _validateText(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'Ingresa una descripción.';
    if (t.length < 3) return 'Mínimo 3 caracteres.';
    if (!RegExp(r'[A-Za-zÀ-ÿ0-9]').hasMatch(t)) {
      return 'Debe contener letras o números.';
    }
    return null;
  }

  Future<String?> _promptText({required String title, required String hint}) {
    return showOmPromptDialog(
      context: context,
      title: title,
      hint: hint,
      validate: _validateText,
    );
  }
}