import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Pantalla de verificación de código OTP. Se muestra tras ingresar un correo
/// válido; el código llega al Google Sheet (y al correo en producción).
class OtpPage extends StatefulWidget {
  final String email;

  const OtpPage({super.key, required this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _verify() {
    final code = _ctrl.text.trim();
    if (code.length != 6) return;
    context.read<AuthBloc>().add(VerifyOtpRequested(code));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C24),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Cierra esta pantalla; el login (debajo) redirige al dashboard.
            Navigator.of(context).pop();
          } else if (state is AuthOtpError) {
            _ctrl.clear();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFE3000F),
            ));
          } else if (state is AuthOtpSent && state.resent) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Código reenviado.'),
              backgroundColor: Color(0xFF00A650),
            ));
          }
        },
        builder: (context, state) {
          final busy = state is AuthLoading || state is AuthOtpVerifying;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_read_outlined,
                        size: 72, color: Color(0xFFFFCE00)),
                    const SizedBox(height: 16),
                    const Text('Verifica tu código',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa el código de 6 dígitos enviado a\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _ctrl,
                      enabled: !busy,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                          fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '______',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => busy ? null : _verify(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            (busy || _ctrl.text.trim().length != 6) ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCE00),
                          foregroundColor: const Color(0xFF1A1C24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF1A1C24)))
                            : const Text('Verificar',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const ResendOtpRequested()),
                      child: const Text('Reenviar código'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
