import 'package:flutter/material.dart';

/// Palet warna resmi aplikasi SIGAP.
/// Dirancang memenuhi standar aksesibilitas kontras tinggi WCAG AA / AAA
/// untuk memudahkan pembacaan oleh pengguna lansia (Care-Receiver).
abstract final class AppColors {
  // --- Palet Darurat & Status ---
  /// Merah darurat utama untuk tombol SOS dan status darurat aktif (Kontras Tinggi)
  static const Color emergencyRed = Color(0xFFDC2626);
  static const Color emergencyRedDark = Color(0xFF991B1B);
  static const Color emergencyRedLight = Color(0xFFF87171);
  static const Color emergencyRedGlow = Color(0x66DC2626);

  /// Kuning peringatan (Kontras Tinggi untuk teks dan background)
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFFBBF24);
  static const Color warningAmberDark = Color(0xFFB45309);

  /// Hijau aman / berhasil (WCAG AA compliant)
  static const Color safeGreen = Color(0xFF059669);
  static const Color safeGreenLight = Color(0xFF34D399);
  static const Color safeGreenDark = Color(0xFF047857);

  /// Biru informasi & netral aktif
  static const Color infoBlue = Color(0xFF2563EB);
  static const Color infoBlueLight = Color(0xFF60A5FA);
  static const Color infoBlueDark = Color(0xFF1D4ED8);

  // --- Palet Tema Gelap (Dark Mode Khusus Lansia) ---
  /// Background gelap murni untuk rasio kontras maksimal terhadap teks putih
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2C);
  static const Color darkCard = Color(0xFF252525);
  static const Color darkBorder = Color(0xFF4A4A4A);
  static const Color darkBorderHighContrast = Color(0xFF9E9E9E);

  // --- Palet Tema Terang (Light Mode) ---
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF3F4F6);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightBorderHighContrast = Color(0xFF1F2937);

  // --- Warna Teks Berstandar Aksesibilitas ---
  static const Color textDarkPrimary = Color(0xFFFFFFFF);
  static const Color textDarkSecondary = Color(0xFFD1D5DB);
  static const Color textDarkTertiary = Color(0xFF9CA3AF);

  static const Color textLightPrimary = Color(0xFF111827);
  static const Color textLightSecondary = Color(0xFF374151);
  static const Color textLightTertiary = Color(0xFF6B7280);

  // --- Warna Khusus Role ---
  static const Color roleCareReceiver = Color(0xFFE11D48); // Rose
  static const Color roleGuardian = Color(0xFF0D9488);     // Teal
  static const Color roleResponder = Color(0xFF2563EB);    // Blue
  static const Color roleAdmin = Color(0xFF7C3AED);        // Purple
}

