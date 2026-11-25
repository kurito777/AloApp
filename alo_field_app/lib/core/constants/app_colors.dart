import 'package:flutter/material.dart';

class AppColors {
  // ALO GROUP - Colores principales (naranja del logo)
  static const Color primary = Color(0xFFE66A10);
  static const Color primaryDark = Color(0xFFE25A11);
  static const Color primaryLight = Color(0xFFE97B0C);

  // ALO GROUP - Colores secundarios (negro)
  static const Color secondary = Color(0xFF141414);
  static const Color secondaryDark = Color(0xFF0A0A0A);

  // Colores de fondo
  static const Color background = Color(0xFFF4F4F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFAFAFA);

  // Colores de texto
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);

  // Colores de estado
  static const Color success = Color(0xFF00A650);
  static const Color error = Color(0xFFE3000F);
  static const Color warning = Color(0xFFFFC800);
  static const Color info = Color(0xFF141414);

  // Colores de prioridad
  static const Color priorityHigh = Color(0xFFE3000F);
  static const Color priorityMedium = Color(0xFFFFB020);
  static const Color priorityLow = Color(0xFF999999);

  // Colores neutros
  static const Color divider = Color(0xFFE8E8E8);
  static const Color border = Color(0xFFD8D8D8);

  // Colores de marca ALO GROUP
  static const Color aloOrange = primary;
  static const Color aloBlack = secondary;
  static const Color aloRed = Color(0xFFE3000F);
  static const Color aloGreen = Color(0xFF00A650);

  // Alias de los nombres anteriores; se quitan al terminar el cambio de nombres.
  static const Color aloYellow = aloOrange;
  static const Color aloDarkBlue = aloBlack;

  // Degradado de la flecha del logo
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDark],
  );

  // Texto sobre fondos oscuros y sobre naranja
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFB3B3B3);
  static const Color textOnPrimary = Color(0xFF141414);

  // Superficies oscuras
  static const Color surfaceDark = secondary;
  static const Color surfaceDarkElevated = Color(0xFF1F1F1F);
  static const Color borderDark = Color(0xFF333333);

  // Tonos suaves para fondos de estado, chips y avisos
  static const Color primarySoft = Color(0xFFFCEBDD);
  static const Color successSoft = Color(0xFFE5F6EC);
  static const Color errorSoft = Color(0xFFFCE5E7);
  static const Color warningSoft = Color(0xFFFFF4CC);
  static const Color infoSoft = Color(0xFFEBEBEB);
}