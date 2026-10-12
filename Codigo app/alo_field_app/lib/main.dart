import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/services/service_locator.dart';
import 'core/session/session_manager.dart';
import 'app.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar el archivo de entorno primero
  await dotenv.load(fileName: ".env.dev");

  // 2. Inicializar los servicios (GetIt)
  await setupLocator();

  // 3. Restaurar sesión persistida (si existe) para decidir la ruta inicial.
  await getIt<SessionManager>().restore();

  runApp(const AloFieldApp());
}