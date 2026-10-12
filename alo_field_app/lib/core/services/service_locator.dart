import 'package:get_it/get_it.dart';

import '../../features/admin/presentation/bloc/admin_bloc.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/auth/data/services/employee_service.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/data/services/dashboard_service.dart';
import '../../features/dashboard/data/services/sap_auth_service.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

import '../../features/execution/data/services/activity_store.dart';
import '../../features/execution/data/services/execution_service.dart';
import '../../features/execution/presentation/bloc/execution_bloc.dart';
import '../../features/maps/data/services/geocoding_service.dart';
import '../../features/maps/data/services/location_service.dart';
import '../../features/maps/presentation/bloc/maps_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/signature/presentation/bloc/signature_bloc.dart';

import '../network/dio_client.dart';
import '../session/session_manager.dart';
import 'catalog_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // ── Infraestructura base ───────────────────────────────────────────────────
  getIt.registerLazySingleton<DioClient>(() => DioClient());

  getIt.registerLazySingleton<SessionManager>(() => SessionManager());

  // Sesión SAP compartida (login/cookies) — usada por auth y dashboard.
  getIt.registerLazySingleton<SapAuthService>(() => SapAuthService());

  // Store local de actividades (OM) iniciadas por el técnico. Fuente de verdad
  // compartida entre el Dashboard (escribe al iniciar/avanzar) y Mis Servicios.
  getIt.registerLazySingleton<ActivityStore>(() => ActivityStore());

  // Catálogos (Departamentos, Sucursales): resuelven código → descripción.
  getIt.registerLazySingleton<CatalogService>(
    () => CatalogService(authService: getIt<SapAuthService>()),
  );

  // ── AUTH ────────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<EmployeeService>(
    () => EmployeeService(authService: getIt<SapAuthService>()),
  );

  getIt.registerLazySingleton<AuthService>(
    () => AuthService(getIt<EmployeeService>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<AuthService>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      repository: getIt<AuthRepository>(),
      sessionManager: getIt<SessionManager>(),
      sapAuth: getIt<SapAuthService>(),
    ),
  );

  // ── DASHBOARD — SAP B1 Service Layer ────────────────────────────────────────
  getIt.registerLazySingleton<DashboardService>(
    () => DashboardService(authService: getIt<SapAuthService>()),
  );

  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(service: getIt<DashboardService>()),
  );

  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      repository: getIt<DashboardRepository>(),
      activityStore: getIt<ActivityStore>(),
      sessionManager: getIt<SessionManager>(),
    ),
  );

  // ── PROFILE ──────────────────────────────────────────────────────────────────
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      sessionManager: getIt<SessionManager>(),
      catalogService: getIt<CatalogService>(),
    ),
  );

  // ── MAPS ─────────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<LocationService>(
    () => LocationService(authService: getIt<SapAuthService>()),
  );
  getIt.registerLazySingleton<GeocodingService>(() => GeocodingService());
  getIt.registerFactory<MapsBloc>(
    () => MapsBloc(
      locationService: getIt<LocationService>(),
      geocodingService: getIt<GeocodingService>(),
    ),
  );

  // ── EXECUTION (Mis Servicios) ────────────────────────────────────────────────
  getIt.registerLazySingleton<ExecutionService>(
    () => ExecutionService(authService: getIt<SapAuthService>()),
  );
  getIt.registerFactory<ExecutionBloc>(
    () => ExecutionBloc(
      service: getIt<ExecutionService>(),
      activityStore: getIt<ActivityStore>(),
    ),
  );

  // ── Otros módulos ────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<SignatureBloc>(() => SignatureBloc());
  getIt.registerLazySingleton<AdminBloc>(() => AdminBloc());
}
