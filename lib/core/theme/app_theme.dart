import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_typography.dart';

/// Konfigurasi tema Material 3 untuk SIGAP.
/// Menyertakan tema khusus [seniorTheme] dengan rasio kontras maksimal dan target sentuh besar.
abstract final class AppTheme {
  /// Tema Khusus Lansia (Care-Receiver / Simplified Mode)
  /// Menggunakan latar belakang gelap OLED kontras tinggi untuk ketegasan teks.
  static ThemeData get seniorTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emergencyRed,
        secondary: AppColors.infoBlueLight,
        surface: AppColors.darkSurface,
        error: AppColors.emergencyRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textDarkPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
        toolbarHeight: 72.0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: AppDimensions.elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          side: const BorderSide(
            color: AppColors.darkBorderHighContrast,
            width: AppDimensions.highContrastBorderWidth,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emergencyRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            double.infinity,
            AppDimensions.seniorRecommendedTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceLG,
            vertical: AppDimensions.spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            side: const BorderSide(color: Colors.white, width: 2.0),
          ),
          textStyle: AppTypography.seniorButtonLabel(),
          elevation: AppDimensions.elevationHigh,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDarkPrimary,
          minimumSize: const Size(
            double.infinity,
            AppDimensions.seniorRecommendedTouchTarget,
          ),
          side: const BorderSide(
            color: AppColors.textDarkPrimary,
            width: AppDimensions.highContrastBorderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: AppTypography.seniorButtonLabel(color: AppColors.textDarkPrimary),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.seniorHeadingLarge(),
        headlineMedium: AppTypography.seniorHeadingMedium(),
        titleLarge: AppTypography.seniorTitle(),
        bodyLarge: AppTypography.seniorBodyPrimary(),
        bodyMedium: AppTypography.seniorBodySecondary(),
      ),
    );
  }

  /// Tema Gelap Standar (Responder, Guardian, Admin)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.infoBlue,
        secondary: AppColors.safeGreen,
        surface: AppColors.darkSurface,
        error: AppColors.emergencyRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textDarkPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: 0,
        titleTextStyle: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: AppDimensions.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.infoBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            double.infinity,
            AppDimensions.standardMinTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          textStyle: AppTypography.standardButtonLabel(color: Colors.white),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.standardDisplayLarge(color: AppColors.textDarkPrimary),
        headlineMedium: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
        titleMedium: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
        bodyLarge: AppTypography.standardBody(color: AppColors.textDarkPrimary),
        bodyMedium: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
      ),
    );
  }

  /// Tema Terang Standar (Opsional untuk lingkungan luar ruangan)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.infoBlue,
        secondary: AppColors.safeGreen,
        surface: AppColors.lightSurface,
        error: AppColors.emergencyRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textLightPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.textLightPrimary,
        elevation: 0,
        titleTextStyle: AppTypography.standardHeadline(color: AppColors.textLightPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: AppDimensions.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.standardDisplayLarge(color: AppColors.textLightPrimary),
        headlineMedium: AppTypography.standardHeadline(color: AppColors.textLightPrimary),
        titleMedium: AppTypography.standardTitle(color: AppColors.textLightPrimary),
        bodyLarge: AppTypography.standardBody(color: AppColors.textLightPrimary),
        bodyMedium: AppTypography.standardCaption(color: AppColors.textLightSecondary),
      ),
    );
  }
}

