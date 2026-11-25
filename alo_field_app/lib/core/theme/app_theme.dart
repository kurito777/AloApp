import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData lightTheme() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.aloOrange,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.aloBlack,
      secondary: AppColors.aloBlack,
      onSecondary: AppColors.textOnDark,
      secondaryContainer: AppColors.infoSoft,
      onSecondaryContainer: AppColors.aloBlack,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,

      // App Bar Theme (ALO GROUP - Negro con texto blanco)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.aloBlack,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: AppDimensions.textXLarge,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),

      // Card Theme (ALO GROUP - Con borde naranja)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          side: const BorderSide(
            color: AppColors.aloOrange,
            width: 4,
          ),
        ),
      ),

      // Button Theme (ALO GROUP - Naranja con texto oscuro)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.aloOrange,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.aloOrange.withValues(alpha: 0.45),
          disabledForegroundColor: AppColors.aloBlack.withValues(alpha: 0.5),
          elevation: AppDimensions.elevationSmall,
          shadowColor: Colors.black38,
          minimumSize: const Size(64, AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
            vertical: AppDimensions.paddingMedium,
          ),
          textStyle: const TextStyle(
            fontSize: AppDimensions.textLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          ),
        ),
      ),

      // Outlined Button Theme (acciones secundarias)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.aloBlack,
          minimumSize: const Size(64, AppDimensions.buttonHeight),
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
            vertical: AppDimensions.paddingMedium,
          ),
          textStyle: const TextStyle(
            fontSize: AppDimensions.textLarge,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          ),
        ),
      ),

      // Text Button Theme (ALO GROUP)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
        ),
      ),

      // Input Decoration Theme (ALO GROUP)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingMedium,
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: AppDimensions.textSmall,
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return AppColors.error;
          }
          if (states.contains(WidgetState.focused)) {
            return AppColors.aloBlack;
          }
          return AppColors.textSecondary;
        }),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          borderSide: const BorderSide(
            color: AppColors.aloOrange,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
      ),

      // Cursor y selección de texto
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.aloBlack,
        selectionColor: AppColors.aloOrange.withValues(alpha: 0.35),
        selectionHandleColor: AppColors.aloBlack,
      ),

      // Bottom Navigation Bar Theme (ALO GROUP)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.aloBlack,
        selectedItemColor: AppColors.aloOrange,
        unselectedItemColor: Colors.white70,
        elevation: AppDimensions.elevationLarge,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.aloBlack,
        actionTextColor: AppColors.aloOrange,
        elevation: AppDimensions.elevationMedium,
        insetPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: AppDimensions.textMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),

      // Diálogos
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppDimensions.elevationLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXLarge),
        ),
        titleTextStyle: const TextStyle(
          fontSize: AppDimensions.textXLarge,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: AppDimensions.textMedium,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
      ),

      // Text Themes
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppDimensions.textHeading,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: AppDimensions.textTitle,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppDimensions.textXXLarge + 2,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: AppDimensions.textXXLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: AppDimensions.textXLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: AppDimensions.textLarge,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: AppDimensions.textMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: AppDimensions.textLarge,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: AppDimensions.textMedium,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: AppDimensions.textSmall,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: AppDimensions.textMedium,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: AppDimensions.textSmall,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: AppColors.textSecondary,
        ),
      ),

      // Other Theme Data
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: AppDimensions.paddingMedium,
      ),
    );
  }
}