import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/sap_config.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../shared/widgets/main_navigation.dart';
import '../../data/models/service_call_item.dart';
import '../../data/models/started_activity.dart';
import '../../data/services/activity_store.dart';
import '../bloc/execution_bloc.dart';
import '../bloc/execution_event.dart';
import '../bloc/execution_state.dart';
import '../../../orders/presentation/pages/om_detail_page.dart';

/// "Mis Servicios": llamadas de servicio (OSCL) asignadas al técnico logueado.
/// Pestañas Pendientes (abiertas) e Historial (cerradas).
class ExecutionPage extends StatefulWidget {
  const ExecutionPage({super.key});

  @override
  State<ExecutionPage> createState() => _ExecutionPageState();
}

class _ExecutionPageState extends State<ExecutionPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final ActivityStore _store = getIt<ActivityStore>();

  String get _empId => getIt<SessionManager>().technicianCode ?? '';
  String? get _userId => getIt<SessionManager>().applicationUserId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)..addListener(_onTab);
    // Refresca al volver a la pestaña (IndexedStack mantiene la página viva) y
    // cuando el dashboard inicia/avanza/finaliza una actividad.
    mainTabIndex.addListener(_onMainTab);
    _store.revision.addListener(_reloadCurrent);
    _load(onlyOpen: true);
  }

  @override
  void dispose() {
    mainTabIndex.removeListener(_onMainTab);
    _store.revision.removeListener(_reloadCurrent);
    _tab
      ..removeListener(_onTab)
      ..dispose();
    super.dispose();
  }

  void _onTab() {
    if (_tab.indexIsChanging) return;
    _load(onlyOpen: _tab.index == 0);
  }

  void _onMainTab() {
    if (mainTabIndex.value == kExecutionTabIndex) _reloadCurrent();
  }

  void _reloadCurrent() {
    if (!mounted) return;
    _load(onlyOpen: _tab.index == 0);
  }

  void _load({required bool onlyOpen}) {
    context.read<ExecutionBloc>().add(
          LoadMyExecutions(empId: _empId, userId: _userId, onlyOpen: onlyOpen),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C24),
        title: const Text('Mis Servicios',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFFFFCE00),
          labelColor: const Color(0xFFFFCE00),
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Pendientes'), Tab(text: 'Historial')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _ExecutionList(onlyOpen: true, onRetry: () => _load(onlyOpen: true)),
          _ExecutionList(onlyOpen: false, onRetry: () => _load(onlyOpen: false)),
        ],
      ),
    );
  }
}

class _ExecutionList extends StatelessWidget {
  final bool onlyOpen;
  final VoidCallback onRetry;

  const _ExecutionList({required this.onlyOpen, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExecutionBloc, ExecutionState>(
      builder: (context, state) {
        // Solo reacciona al estado de esta pestaña.
        final matches = (state is ExecutionLoading && state.onlyOpen == onlyOpen) ||
            (state is ExecutionLoaded && state.onlyOpen == onlyOpen) ||
            (state is ExecutionError && state.onlyOpen == onlyOpen);
        if (!matches) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ExecutionLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ExecutionError) {
          return _Message(
            icon: Icons.error_outline,
            title: 'Error',
            message: state.message,
            onRetry: onRetry,
          );
        }
        final loaded = state as ExecutionLoaded;
        final activities = loaded.activities;
        final items = loaded.items;
        if (loaded.isEmpty) {
          return _Message(
            icon: Icons.inbox_outlined,
            title: onlyOpen ? 'Sin servicios pendientes' : 'Sin historial',
            message: onlyOpen
                ? 'No tienes actividades iniciadas ni llamadas de servicio '
                    'abiertas. Inicia una OM desde el Dashboard.'
                : 'No hay actividades finalizadas ni servicios cerrados.',
            onRetry: onRetry,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (activities.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.engineering_outlined,
                label: onlyOpen
                    ? 'Actividades en curso (${activities.length})'
                    : 'Actividades finalizadas (${activities.length})',
              ),
              const SizedBox(height: 10),
              ...activities.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ActivityCard(activity: a),
                  )),
            ],
            if (items.isNotEmpty) ...[
              if (activities.isNotEmpty) const SizedBox(height: 8),
              _SectionHeader(
                icon: Icons.support_agent_outlined,
                label: 'Llamadas de servicio (${items.length})',
              ),
              const SizedBox(height: 10),
              ...items.map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ServiceCard(item: it),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1A1C24)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1C24),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de una actividad (OM) iniciada por el técnico (fuente local).
class _ActivityCard extends StatelessWidget {
  final StartedActivity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(
        SapConfig.stateColorHex(activity.estado).replaceFirst('#', '0xFF'),
      ),
    );
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OmDetailPage(
              docEntry: activity.docEntry,
              docNum: activity.docNum,
            ),
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(activity.displayId,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(activity.statusLabel,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (activity.cliente != null) ...[
              const SizedBox(height: 8),
              Text(activity.cliente!,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
            if (activity.equipoName != null || activity.equipoCode != null)
              _row(Icons.precision_manufacturing_outlined,
                  activity.equipoName ?? activity.equipoCode!),
            if (activity.direccion != null && activity.direccion!.isNotEmpty)
              _row(Icons.location_on_outlined, activity.direccion!),
            _row(
              Icons.play_circle_outline,
              'Iniciada: ${_fmtDT(activity.startedAt)}',
            ),
            if (!activity.isOpen && activity.finishedAt != null)
              _row(Icons.check_circle_outline,
                  'Finalizada: ${_fmtDT(activity.finishedAt!)}'),
            if (!activity.isOpen &&
                (activity.finishComments?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 6),
              Text(activity.finishComments!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.assignment_outlined,
                    size: 15, color: Color(0xFF0F6E56)),
                const SizedBox(width: 6),
                Text(
                  activity.isOpen
                      ? 'Ver detalle y ejecutar tareas'
                      : 'Ver detalle de la OM',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0F6E56),
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 18, color: Color(0xFF0F6E56)),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      );

  String _fmtDT(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _ServiceCard extends StatelessWidget {
  final ServiceCallItem item;

  const _ServiceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isOpen ? const Color(0xFFFF8C00) : const Color(0xFF00A650);
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
                Text('SC-${item.id}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(item.statusLabel,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            if (item.customerName != null) ...[
              const SizedBox(height: 6),
              _row(Icons.business_outlined, item.customerName!),
            ],
            if (item.itemCode != null)
              _row(Icons.precision_manufacturing_outlined,
                  '${item.itemCode}${item.serial != null ? ' · ${item.serial}' : ''}'),
            _row(
              Icons.event_outlined,
              item.isOpen
                  ? 'Creada: ${_fmt(item.creationDate)}'
                  : 'Cerrada: ${_fmt(item.closingDate)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      );

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCE00),
                  foregroundColor: const Color(0xFF1A1C24),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
