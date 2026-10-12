// ═══════════════════════════════════════════════════════════════════════════
// APP_DART_INTEGRATION_GUIDE.dart
// Guía de integración para main.dart, app.dart y service_locator.dart
// ALO Group Field App — SAP B1 Service Layer
// ═══════════════════════════════════════════════════════════════════════════
//
// ESTE ARCHIVO ES SOLO REFERENCIA — no copiarlo directamente al proyecto.
// Lee cada sección y aplica los cambios a los archivos correspondientes.
//
// ── Flujo de datos ────────────────────────────────────────────────────────
//
//  DashboardPageUpdated
//        │ add(LoadDashboardOrders)
//        ▼
//  DashboardBloc  ──────────────────────────────────────────────┐
//        │ fetchDashboardOrders()                               │
//        ▼                                                       │
//  DashboardRepository                                           │
//        │ fetchOrders()                                         │
//        ▼                                                       │
//  DashboardService ── getAuthHeaders() ── SapAuthService        │
//        │ GET /VID_RTOV                                         │
//        ▼                                                       │
//  SAP B1 Service Layer                                          │
//        │ JSON { value: [...] }                                 │
//        ▼                                                       │
//  List<OrderModel>  ──────────────────────────────────────────►│
//        │ emit(DashboardLoaded)                                 │
//        ▼
//  UI actualizada
//
// ═══════════════════════════════════════════════════════════════════════════


// ── SECCIÓN 1: main.dart ──────────────────────────────────────────────────
// Archivo: lib/main.dart
// CAMBIO: Asegurar que dotenv se carga ANTES de setupLocator()

/*
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANTE: dotenv DEBE cargarse antes de setupLocator()
  // porque SapConfig lee las variables de entorno en el constructor.
  await dotenv.load(fileName: ".env.dev");

  // Validar configuración SAP antes de iniciar la app
  final configErrors = SapConfig.validate();
  if (configErrors.isNotEmpty) {
    debugPrint('⚠️ Configuración SAP incompleta:');
    for (final err in configErrors) {
      debugPrint('  - $err');
    }
    // En desarrollo: continuar con advertencia
    // En producción: podrías mostrar pantalla de error
  }

  await setupLocator();
  runApp(const AloFieldApp());
}
*/


// ── SECCIÓN 2: service_locator.dart — OPCIÓN 1 (sencillo) ────────────────
// Archivo: lib/core/services/service_locator.dart
// La forma más simple de registrar los nuevos servicios con GetIt.

/*
import 'package:get_it/get_it.dart';
import '../../features/dashboard/data/services/sap_auth_service.dart';
import '../../features/dashboard/data/services/dashboard_service.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> setupLocator() async {
  // ── SAP ────────────────────────────────────────────────────────────────
  // Singleton: una sola instancia de auth compartida por toda la app.
  sl.registerLazySingleton<SapAuthService>(() => SapAuthService());

  sl.registerLazySingleton<DashboardService>(
    () => DashboardService(authService: sl<SapAuthService>()),
  );

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(service: sl<DashboardService>()),
  );

  // Factory: nueva instancia del BLoC cada vez que se solicita.
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(repository: sl<DashboardRepository>()),
  );

  // ── Resto de servicios existentes ──────────────────────────────────────
  // ... tus otros registros aquí
}
*/


// ── SECCIÓN 3: service_locator.dart — OPCIÓN 2 (con logout al cerrar) ────
// Si quieres que SAP cierre sesión cuando el usuario hace logout de la app.

/*
// En tu AuthBloc o pantalla de logout:
import '../../features/dashboard/data/services/sap_auth_service.dart';

// Al hacer logout del usuario:
Future<void> onUserLogout() async {
  final sapAuth = sl<SapAuthService>();
  await sapAuth.logout(); // Cierra sesión SAP limpiamente
  // ... resto de lógica de logout
}
*/


// ── SECCIÓN 4: app.dart — MultiBlocProvider ───────────────────────────────
// Archivo: lib/app.dart
// Asegurar que DashboardBloc está en el MultiBlocProvider.

/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/service_locator.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

class AloFieldApp extends StatelessWidget {
  const AloFieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(
          // lazy: false carga el BLoC inmediatamente (útil para pre-cargar datos)
          lazy: true,
          create: (_) => sl<DashboardBloc>(),
        ),
        // ... otros BLoCs existentes (Auth, Maps, Profile, etc.)
      ],
      child: MaterialApp.router(
        title: 'ALO Field App',
        routerConfig: router,
        // ...
      ),
    );
  }
}
*/


// ── SECCIÓN 5: app_router.dart — Ruta del dashboard ──────────────────────
// Archivo: lib/core/routes/app_router.dart
// Reemplazar la ruta '/dashboard' para usar la nueva página.

/*
import '../../features/dashboard/presentation/pages/dashboard_page_updated.dart';
// MANTENER también el import de dashboard_page.dart si lo sigues usando.

// En tu GoRouter:
GoRoute(
  path: '/dashboard',
  builder: (context, state) {
    // Opción A: sin filtro de técnico (muestra todas las OTs)
    return const DashboardPageUpdated();

    // Opción B: con código del técnico autenticado
    // final techCode = context.read<AuthBloc>().state.user?.technicianCode;
    // return DashboardPageUpdated(technicianCode: techCode);
  },
),
*/


// ── SECCIÓN 6: BlocListener global para errores de actualización ──────────
// Opción: Envolver toda la app con un BlocListener para capturar errores
// de actualización de OTs en cualquier parte de la app.

/*
// En app.dart o en la navegación principal:
BlocListener<DashboardBloc, DashboardState>(
  listenWhen: (prev, curr) => curr is OrderUpdateError,
  listener: (context, state) {
    if (state is OrderUpdateError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en OT-${state.docNum}: ${state.message}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  },
  child: // ... tu widget hijo
)
*/


// ── SECCIÓN 7: Disparar eventos desde otras partes de la app ──────────────
// Ejemplos de cómo usar el BLoC desde cualquier widget con BuildContext.

/*
// Cargar órdenes del técnico autenticado:
context.read<DashboardBloc>().add(
  const LoadDashboardOrders(
    technicianCode: 'TEC001',
    estados: ['P', 'EC', 'EA', 'EP'],
  ),
);

// Buscar en tiempo real:
context.read<DashboardBloc>().add(
  SearchOrders(searchText),
);

// Filtrar por estado:
context.read<DashboardBloc>().add(
  const FilterOrdersByStatus('P'), // Solo Pendientes
);

// Quitar filtro:
context.read<DashboardBloc>().add(
  const FilterOrdersByStatus(null), // Todos
);

// Iniciar una OT:
context.read<DashboardBloc>().add(
  InitiateOrder(docEntry: 1234, docNum: 567),
);

// Registrar llegada con GPS:
context.read<DashboardBloc>().add(
  MarkOrderAsArrived(
    docEntry: 1234,
    docNum: 567,
    gpsLat: 4.7109886,
    gpsLng: -74.072092,
  ),
);

// Finalizar OT:
context.read<DashboardBloc>().add(
  FinishOrder(
    docEntry: 1234,
    docNum: 567,
    comments: 'Se reemplazó router Cisco. Cliente conforme.',
  ),
);
*/


// ── SECCIÓN 8: Leer el estado del BLoC ────────────────────────────────────
// Ejemplo de BlocBuilder para reaccionar a cambios de estado.

/*
BlocBuilder<DashboardBloc, DashboardState>(
  builder: (context, state) {
    if (state is DashboardLoading) {
      return const CircularProgressIndicator();
    }
    if (state is DashboardLoaded) {
      return Text('${state.orders.length} órdenes');
    }
    if (state is DashboardError) {
      return Text('Error: ${state.message}');
    }
    return const SizedBox.shrink();
  },
)

// Para escuchar sin reconstruir widgets:
BlocListener<DashboardBloc, DashboardState>(
  listenWhen: (prev, curr) => curr is OrderUpdateSuccess,
  listener: (context, state) {
    if (state is OrderUpdateSuccess) {
      print('OT actualizada: ${state.message}');
    }
  },
  child: MyWidget(),
)
*/


// ═══════════════════════════════════════════════════════════════════════════
// FIN DE APP_DART_INTEGRATION_GUIDE.dart
// ═══════════════════════════════════════════════════════════════════════════
