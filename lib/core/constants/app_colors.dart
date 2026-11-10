import 'package:flutter/material.dart';

/// Palet warna resmi aplikasi SIGAP.
/// Dirancang dengan sistem desain modern layanan kesehatan (Healthcare & Medical Teal-Mint aesthetic)
/// dengan standar aksesibilitas kontras tinggi WCAG AA / AAA untuk pengguna lansia maupun relawan.
abstract final class AppColors {
  // --- Palet Utama Medis / Healthcare Teal & Mint (Sesuai Referensi Desain) ---
  /// Hijau toska / Teal medis primer untuk aksi utama, tombol pill, dan branding
  static const Color primaryTeal = Color(0xFF00BFA5);
  static const Color primaryTealDark = Color(0xFF00897B);
  static const Color primaryTealDeep = Color(0xFF004D40);
  static const Color primaryTealLight = Color(0xFFE0F7F4);
  static const Color primaryTealGlow = Color(0x4D00BFA5);

  /// Latar belakang kanvas mint lembut (Soft Mint Canvas)
  static const Color mintBackground = Color(0xFFEAF7F5);
  static const Color mintSurface = Color(0xFFF3FBF9);
  static const Color mintSurfaceHighlight = Color(0xFFC7F2EB);
  static const Color mintBorder = Color(0xFFCCECE6);

  /// Permukaan kartu putih bersih (Crisp White Card Surface)
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x0F0F172A);

  // --- Palet Darurat & Status (Tetap Kontras Tinggi untuk Keamanan) ---
  /// Merah darurat utama untuk tombol SOS dan status darurat aktif (WCAG AAA)
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

  /// Biru informasi & netral aktif (Harmonis dengan Teal)
  static const Color infoBlue = Color(0xFF00BFA5);
  static const Color infoBlueLight = Color(0xFF5EEAD4);
  static const Color infoBlueDark = Color(0xFF0F766E);

  // --- Palet Tema Terang (Healthcare Light Mode - Standar) ---
  static const Color lightBackground = Color(0xFFEAF7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF3FBF9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderHighContrast = Color(0xFF00BFA5);

  // --- Palet Tema Gelap (Dark Mode Khusus Lansia / Malam) ---
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color darkSurfaceElevated = Color(0xFF334155);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderHighContrast = Color(0xFF00BFA5);

  // --- Warna Teks Berstandar Aksesibilitas & Modern Slate ---
  /// Teks gelap pada latar belakang terang (Slate modern)
  static const Color textDarkPrimary = Color(0xFF1E293B);   // Slate 800
  static const Color textDarkSecondary = Color(0xFF475569); // Slate 600
  static const Color textDarkTertiary = Color(0xFF94A3B8);  // Slate 400

  /// Teks terang pada latar belakang gelap atau tombol primer
  static const Color textLightPrimary = Color(0xFFFFFFFF);
  static const Color textLightSecondary = Color(0xFFF1F5F9);
  static const Color textLightTertiary = Color(0xFFCBD5E1);

  // --- Warna Khusus Role ---
  static const Color roleCareReceiver = Color(0xFF00BFA5); // Teal Medical
  static const Color roleGuardian = Color(0xFF0284C7);     // Sky Blue
  static const Color roleResponder = Color(0xFF059669);    // Emerald Green
  static const Color roleAdmin = Color(0xFF7C3AED);        // Purple
}
