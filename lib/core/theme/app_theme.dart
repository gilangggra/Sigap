import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_typography.dart';

/// Konfigurasi tema Material 3 standar mobile dengan tipografi [Poppins] yang konsisten.
abstract final class AppTheme {
  /// Tema Terang Standar Mobile (Clean Slate & Teal Healthcare)
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final poppinsTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
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
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textDarkPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textDarkPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppDimensions.standardMinTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: AppTypography.standardButtonLabel(color: Colors.white),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTealDark,
          minimumSize: const Size(double.infinity, AppDimensions.standardMinTouchTarget),
          side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: AppTypography.standardButtonLabel(color: AppColors.primaryTealDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD,
          vertical: AppDimensions.spaceMD,
        ),
        hintStyle: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1.0,
        space: 1.0,
      ),
      textTheme: poppinsTheme.copyWith(
        displayLarge: AppTypography.standardDisplayLarge(color: AppColors.textDarkPrimary),
        headlineMedium: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
        titleMedium: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
        bodyLarge: AppTypography.standardBody(color: AppColors.textDarkPrimary),
        bodyMedium: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
      ),
    );
  }

  /// Tema Khusus Lansia (Care-Receiver / Simplified Mode Ramah Lansia)
  static ThemeData get seniorTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final poppinsTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
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
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textDarkPrimary,
        ),
        toolbarHeight: 64.0,
        iconTheme: const IconThemeData(color: AppColors.textDarkPrimary, size: 26),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
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
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: AppTypography.seniorButtonLabel(),
          elevation: 0,
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
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: AppTypography.seniorButtonLabel(color: AppColors.textDarkPrimary),
        ),
      ),
      textTheme: poppinsTheme.copyWith(
        displayLarge: AppTypography.seniorHeadingLarge(),
        headlineMedium: AppTypography.seniorHeadingMedium(),
        titleLarge: AppTypography.seniorTitle(),
        bodyLarge: AppTypography.seniorBodyPrimary(),
        bodyMedium: AppTypography.seniorBodySecondary(),
      ),
    );
  }

  /// Tema Gelap Standar (Opsi Kontras Gelap)
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final poppinsTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);

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
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textLightPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      textTheme: poppinsTheme.copyWith(
        displayLarge: AppTypography.standardDisplayLarge(color: AppColors.textLightPrimary),
        headlineMedium: AppTypography.standardHeadline(color: AppColors.textLightPrimary),
        titleMedium: AppTypography.standardTitle(color: AppColors.textLightPrimary),
        bodyLarge: AppTypography.standardBody(color: AppColors.textLightPrimary),
        bodyMedium: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
      ),
    );
  }
}
