import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/catalog_service.dart';
import '../../../../core/session/session_manager.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// Muestra la información del técnico autenticado (desde [SessionManager]).
///
/// El cierre de sesión lo maneja [AuthBloc] (limpia sesión SAP + storage);
/// aquí solo se presenta la información. Los códigos de Departamento y Sucursal
/// se resuelven a su descripción vía [CatalogService].
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required SessionManager sessionManager,
    required CatalogService catalogService,
  })  : _session = sessionManager,
        _catalog = catalogService,
        super(ProfileInitial()) {
    on<LoadProfileRequested>(_onLoadProfileRequested);
  }

  final SessionManager _session;
  final CatalogService _catalog;

  Future<void> _onLoadProfileRequested(
    LoadProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final tech = _session.currentTechnician;
    if (tech == null) {
      emit(ProfileError('No hay una sesión activa.'));
      return;
    }

    // Resuelve código → descripción (con fallback al código si SAP falla).
    final department = await _catalog.departmentName(tech.departmentId);
    final branch = await _catalog.branchName(tech.branchId);

    emit(ProfileLoaded({
      'name': tech.fullName,
      'email': tech.email,
      'code': tech.code,
      'role': tech.jobTitle ?? 'Técnico',
      'phone': tech.mobile ?? tech.phone ?? 'No disponible',
      'department': department,
      'branch': branch,
    }));
  }
}
