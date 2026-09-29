import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/routes/app_router.dart';
import 'core/services/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/execution/presentation/bloc/execution_bloc.dart';
import 'features/maps/presentation/bloc/maps_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/signature/presentation/bloc/signature_bloc.dart';

class AloFieldApp extends StatelessWidget {
  const AloFieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>(),
        ),
        BlocProvider<DashboardBloc>(
          create: (_) => getIt<DashboardBloc>(),
        ),
        BlocProvider<MapsBloc>(
          create: (_) => getIt<MapsBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => getIt<ProfileBloc>(),
        ),
        BlocProvider<SignatureBloc>(
          create: (_) => getIt<SignatureBloc>(),
        ),
        BlocProvider<ExecutionBloc>(
          create: (_) => getIt<ExecutionBloc>(),
        ),
        BlocProvider<AdminBloc>(
          create: (_) => getIt<AdminBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'ALO Field',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        routerConfig: appRouter,
      ),
    );
  }
}