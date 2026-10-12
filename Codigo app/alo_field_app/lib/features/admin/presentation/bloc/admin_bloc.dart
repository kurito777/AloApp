import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc() : super(AdminInitial()) {
    on<LoadAdminRequested>(_onLoadAdminRequested);
  }

  Future<void> _onLoadAdminRequested(
    LoadAdminRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    try {
      await Future.delayed(const Duration(seconds: 1));

      final stats = {
        "totalOrders": 156,
        "completedOrders": 98,
        "pendingOrders": 35,
        "inProgressOrders": 23,
        "totalTechnicians": 12,
        "averageCompletionTime": "2.5 horas",
        "satisfactionRate": "96%",
      };

      emit(AdminLoaded(stats));
    } catch (e) {
      emit(AdminError('Error cargando panel de administración'));
    }
  }
}
