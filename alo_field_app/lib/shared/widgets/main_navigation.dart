import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/service_locator.dart';
import '../../core/session/session_manager.dart';
import '../../features/dashboard/presentation/pages/dashboard_page_updated.dart';
import '../../features/execution/presentation/pages/execution_page.dart';
import '../../features/maps/presentation/pages/maps_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// Índice de la pestaña Mapa en el bottom-nav.
const int kMapsTabIndex = 1;

/// Índice de la pestaña Ejecución ("Mis Servicios") en el bottom-nav.
const int kExecutionTabIndex = 2;

/// Controla la pestaña activa del bottom-nav desde cualquier parte
/// (ej. "Ver ubicación" en una OM salta a la pestaña Mapa).
final ValueNotifier<int> mainTabIndex = ValueNotifier<int>(0);

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late final List<Widget> pages = [
    // Código del técnico autenticado (OHEM.EmployeeID) para filtrar las OM
    // por VID_MTOM.U_UsrRes.
    DashboardPageUpdated(
      tecnicoCode: getIt<SessionManager>().technicianCode,
    ),
    const MapsPage(),
    const ExecutionPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: mainTabIndex,
      builder: (context, currentIndex, _) {
        return Scaffold(
          body: IndexedStack(index: currentIndex, children: pages),
          bottomNavigationBar: _MainBottomBar(
            currentIndex: currentIndex,
            onTap: (index) => mainTabIndex.value = index,
          ),
        );
      },
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const List<_NavDestination> _destinations = [
  _NavDestination(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Inicio',
  ),
  _NavDestination(
    icon: Icons.map_outlined,
    activeIcon: Icons.map_rounded,
    label: 'Mapa',
  ),
  _NavDestination(
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment_rounded,
    label: 'Ejecución',
  ),
  _NavDestination(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Perfil',
  ),
];

class _MainBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MainBottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: const Border(
          top: BorderSide(color: AppColors.borderDark),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _destinations.length; i++)
                _NavItem(
                  destination: _destinations[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor =
        selected ? AppColors.textOnPrimary : AppColors.textOnDarkMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? AppColors.aloYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.aloYellow.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      selected ? destination.activeIcon : destination.icon,
                      key: ValueKey<bool>(selected),
                      size: 24,
                      color: contentColor,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerLeft,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              destination.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}