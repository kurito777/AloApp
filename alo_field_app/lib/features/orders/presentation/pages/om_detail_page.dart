import 'package:flutter/material.dart';

import '../../../../core/config/sap_config.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/session/session_manager.dart';
import '../../../dashboard/data/repositories/dashboard_repository.dart';
import '../../data/models/order_model.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C24),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('OM-${widget.docNum}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFFFFCE00))),
                  SizedBox(height: 16),
                  Text('Cargando OM...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _error != null
              ? _ErrorBox(message: _error!, onRetry: _load)
              : _content(_order!),
    );
  }

  Widget _content(OrderModel o) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(o),
            if (!_editable) ...[
              const SizedBox(height: 12),
              _readOnlyBanner(o),
            ],
            const SizedBox(height: 16),
            _tasksCard(o),
            const SizedBox(height: 16),
            _materialsCard(o),
            const SizedBox(height: 24),
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x22000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _header(OrderModel o) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(o.clientDisplayName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (o.equipoDescripcion != null || o.equipoCode != null)
              _line(Icons.precision_manufacturing_outlined,
                  o.equipoDescripcion ?? o.equipoCode!),
            _line(Icons.location_on_outlined, o.fullAddress),
            if (o.tipoOM != null)
              _line(Icons.build_outlined, 'Tipo: ${o.tipoOM}'),
            if (o.descripcionProblema.isNotEmpty)
              _line(Icons.report_problem_outlined, o.descripcionProblema),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyBanner(OrderModel o) {
    final estado = SapConfig.translateOmState(o.estado) ?? 'Cerrada';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE08A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: Color(0xFF8A6D00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'OM $estado — solo lectura. No se puede modificar en SAP.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A6D00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tasksCard(OrderModel o) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_rtl_outlined,
                    size: 18, color: Color(0xFF1A1C24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tareas (${o.tasksPending} pend. / ${o.tasksTotal})',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_editable)
                  TextButton.icon(
                    onPressed: _busy ? null : _addTask,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0F6E56)),
                  ),
              ],
            ),
            if (o.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('La OM no tiene tareas. Agrega la primera.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ...o.tasks.map(_taskTile),
          ],
        ),
      ),
    );
  }

  Widget _taskTile(OrderTask t) {
    final est = (t.estado ?? 'N').toUpperCase();
    final (color, label, icon) = _estadoVisual(est);
    return InkWell(
      onTap: (_busy || !_editable) ? null : () => _pickEstado(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: est == 'T' ? Colors.grey : Colors.black87,
                  decoration: est == 'T' ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            if (_editable)
              const Icon(Icons.expand_more, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _pickEstado(OrderTask t) async {
    final current = (t.estado ?? 'N').toUpperCase();
    final estado = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Estado de la tarea',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            for (final e in const [
              ('N', 'No iniciada'),
              ('P', 'En proceso'),
              ('T', 'Terminada'),
            ])
              ListTile(
                leading: Icon(_estadoVisual(e.$1).$3, color: _estadoVisual(e.$1).$1),
                title: Text(e.$2),
                trailing: current == e.$1
                    ? const Icon(Icons.check, color: Color(0xFF00A650))
                    : null,
                onTap: () => Navigator.pop(ctx, e.$1),
              ),
          ],
        ),
      ),
    );
    if (estado != null && estado != current) _setEstado(t, estado);
  }

  Widget _materialsCard(OrderModel o) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 18, color: Color(0xFF1A1C24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Materiales (${o.materialCount})',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                if (_editable)
                  TextButton.icon(
                    onPressed: _busy ? null : _addMaterial,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0F6E56)),
                  ),
              ],
            ),
            if (o.visibleMaterials.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin materiales registrados.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ...o.visibleMaterials.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m.itemDescription ?? m.itemCode ?? 'Material',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text('x${m.quantity?.toStringAsFixed(0) ?? '1'}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  // ── Diálogos ────────────────────────────────────────────────────────────────

  Future<String?> _promptText({required String title, required String hint}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          decoration:
              InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCE00),
                foregroundColor: const Color(0xFF1A1C24)),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  (Color, String, IconData) _estadoVisual(String est) {
    switch (est) {
      case 'P':
        return (const Color(0xFF2196F3), 'En proceso', Icons.timelapse);
      case 'T':
        return (const Color(0xFF00A650), 'Terminada', Icons.check_circle);
      default:
        return (const Color(0xFFFF8C00), 'No iniciada',
            Icons.radio_button_unchecked);
    }
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: Color(0xFFE3000F)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCE00),
                  foregroundColor: const Color(0xFF1A1C24)),
            ),
          ],
        ),
      ),
    );
  }
}
