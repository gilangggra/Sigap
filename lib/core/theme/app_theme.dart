import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_typography.dart';

/// Konfigurasi tema Material 3 untuk SIGAP berdasarkan Sistem Desain Medis & Healthcare Modern.
/// Terinspirasi dari estetika Teal & Mint dengan tombol pill dan sudut melengkung halus.
abstract final class AppTheme {
  /// Tema Terang Utama (Healthcare & Medical Teal-Mint Theme - Standar SIGAP)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.mintBackground,
      primaryColor: AppColors.primaryTeal,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryTeal,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryTealLight,
        onPrimaryContainer: AppColors.primaryTealDeep,
        secondary: AppColors.primaryTealDark,
        onSecondary: Colors.white,
        surface: AppColors.cardWhite,
        onSurface: AppColors.textDarkPrimary,
        error: AppColors.emergencyRed,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
        iconTheme: const IconThemeData(color: AppColors.textDarkPrimary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.mintBorder, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppDimensions.seniorMinTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceLG,
            vertical: AppDimensions.spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          textStyle: AppTypography.standardButtonLabel(color: Colors.white),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTealDark,
          minimumSize: const Size(double.infinity, AppDimensions.seniorMinTouchTarget),
          side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          textStyle: AppTypography.standardButtonLabel(color: AppColors.primaryTealDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLG,
          vertical: AppDimensions.spaceMD,
        ),
        hintStyle: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: const BorderSide(color: AppColors.mintBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: const BorderSide(color: AppColors.mintBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2.0),
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

  /// Tema Khusus Lansia (Care-Receiver / Simplified Healthcare Mode)
  /// Dirancang dengan keterbacaan tinggi, kontras tajam, dan target sentuh >= 72dp
  static ThemeData get seniorTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.mintBackground,
      primaryColor: AppColors.primaryTeal,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryTealDark,
        secondary: AppColors.primaryTeal,
        surface: AppColors.cardWhite,
        error: AppColors.emergencyRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textDarkPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
        toolbarHeight: 72.0,
        iconTheme: const IconThemeData(color: AppColors.textDarkPrimary, size: 28),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: AppDimensions.elevationLow,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(
            color: AppColors.primaryTeal,
            width: AppDimensions.highContrastBorderWidth,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
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
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          textStyle: AppTypography.seniorButtonLabel(),
          elevation: AppDimensions.elevationLow,
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
            color: AppColors.primaryTealDark,
            width: AppDimensions.highContrastBorderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
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

  /// Tema Gelap Opsional (Night / High-Contrast Dark Mode)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryTeal,
        secondary: AppColors.safeGreen,
        surface: AppColors.darkSurface,
        error: AppColors.emergencyRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textLightPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textLightPrimary,
        elevation: 0,
        titleTextStyle: AppTypography.standardHeadline(color: AppColors.textLightPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            double.infinity,
            AppDimensions.standardMinTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          textStyle: AppTypography.standardButtonLabel(color: Colors.white),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.standardDisplayLarge(color: AppColors.textLightPrimary),
        headlineMedium: AppTypography.standardHeadline(color: AppColors.textLightPrimary),
        titleMedium: AppTypography.standardTitle(color: AppColors.textLightPrimary),
        bodyLarge: AppTypography.standardBody(color: AppColors.textLightPrimary),
        bodyMedium: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
      ),
    );
  }
}
