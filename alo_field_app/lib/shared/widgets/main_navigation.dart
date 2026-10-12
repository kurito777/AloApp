import 'package:flutter/material.dart';
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
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => mainTabIndex.value = index,
            selectedItemColor: const Color(0xFF0F6E56),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.assignment), label: 'Ejecución'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        );
      },
    );
  }
}
