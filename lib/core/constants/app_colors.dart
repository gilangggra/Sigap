import 'package:flutter/material.dart';

/// Palet warna resmi aplikasi SIGAP.
/// Mengikuti standar antarmuka mobile modern dan konsisten, dengan rasio kontras tinggi WCAG AA/AAA.
abstract final class AppColors {
  // --- Brand Colors (Teal Medis & Healthcare) ---
  static const Color primaryTeal = Color(0xFF00BFA5);
  static const Color primaryTealDark = Color(0xFF0D9488);
  static const Color primaryTealDeep = Color(0xFF115E59);
  static const Color primaryTealLight = Color(0xFFE6FFFA);
  static const Color primaryTealGlow = Color(0x3300BFA5);

  // --- Latar Belakang & Permukaan Standar Mobile ---
  /// Background kanvas mobile standar (Clean Slate 50)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color mintBackground = Color(0xFFF8FAFC);
  static const Color mintSurface = Color(0xFFF1F5F9);
  static const Color mintSurfaceHighlight = Color(0xFFE6FFFA);
  static const Color mintBorder = Color(0xFFE2E8F0);

  /// Permukaan kartu putih standar mobile
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderHighContrast = Color(0xFF00BFA5);
  static const Color cardShadow = Color(0x0A0F172A);

  // --- Palet Darurat & Status (Kontras Tinggi) ---
  static const Color emergencyRed = Color(0xFFDC2626);
  static const Color emergencyRedDark = Color(0xFF991B1B);
  static const Color emergencyRedLight = Color(0xFFF87171);
  static const Color emergencyRedGlow = Color(0x4DDC2626);

  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFFBBF24);
  static const Color warningAmberDark = Color(0xFFB45309);

  static const Color safeGreen = Color(0xFF059669);
  static const Color safeGreenLight = Color(0xFF34D399);
  static const Color safeGreenDark = Color(0xFF047857);

  static const Color infoBlue = Color(0xFF00BFA5);
  static const Color infoBlueLight = Color(0xFF5EEAD4);
  static const Color infoBlueDark = Color(0xFF0F766E);

  // --- Palet Tema Gelap (Dark Mode Khusus Lansia / Malam) ---
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF334155);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderHighContrast = Color(0xFF00BFA5);

  // --- Warna Tipografi Konsisten (Slate Modern & Poppins Hierarchy) ---
  /// Teks gelap pada latar belakang terang (Slate 800)
  static const Color textDarkPrimary = Color(0xFF1E293B);
  /// Teks sekunder untuk keterangan & sub-judul (Slate 500)
  static const Color textDarkSecondary = Color(0xFF64748B);
  /// Teks tersier untuk placeholder & hint (Slate 400)
  static const Color textDarkTertiary = Color(0xFF94A3B8);

  /// Teks terang untuk tombol primer atau latar gelap
  static const Color textLightPrimary = Color(0xFFFFFFFF);
  static const Color textLightSecondary = Color(0xFFF1F5F9);
  static const Color textLightTertiary = Color(0xFFCBD5E1);

  // --- Warna Khusus Role ---
  static const Color roleCareReceiver = Color(0xFF00BFA5);
  static const Color roleGuardian = Color(0xFF0284C7);
  static const Color roleResponder = Color(0xFF059669);
  static const Color roleAdmin = Color(0xFF7C3AED);
}
