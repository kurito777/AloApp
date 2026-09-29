import 'package:go_router/go_router.dart';

import '../services/service_locator.dart';
import '../session/session_manager.dart';
import '../../features/admin/presentation/pages/admin_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/execution/presentation/pages/execution_page.dart';
import '../../features/maps/presentation/pages/maps_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/signature/presentation/pages/signature_page.dart';
import '../../shared/widgets/main_navigation.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  // Guard de sesión: sin sesión → login; con sesión no se vuelve al login.
  redirect: (context, state) {
    final loggedIn = getIt<SessionManager>().isAuthenticated;
    final atLogin = state.matchedLocation == '/login';

    if (!loggedIn) return atLogin ? null : '/login';
    if (atLogin) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const MainNavigation(),
    ),
    GoRoute(
      path: '/maps',
      name: 'maps',
      builder: (context, state) => const MapsPage(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/signature',
      name: 'signature',
      builder: (context, state) => const SignaturePage(),
    ),
    GoRoute(
      path: '/execution',
      name: 'execution',
      builder: (context, state) => const ExecutionPage(),
    ),
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminPage(),
    ),
    GoRoute(
      path: '/orders/:id',
      name: 'order_detail',
      builder: (context, state) => const OrderDetailPage(),
    ),
  ],
);