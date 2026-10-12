import 'package:flutter_bloc/flutter_bloc.dart';
import 'signature_event.dart';
import 'signature_state.dart';

class SignatureBloc extends Bloc<SignatureEvent, SignatureState> {
  SignatureBloc() : super(SignatureInitial()) {
    on<LoadSignatureRequested>(_onLoadSignatureRequested);
  }

  Future<void> _onLoadSignatureRequested(
    LoadSignatureRequested event,
    Emitter<SignatureState> emit,
  ) async {
    try {
      // Placeholder para cargar datos de firma
    } catch (e) {
      emit(SignatureError('Error cargando firma'));
    }
  }
}
