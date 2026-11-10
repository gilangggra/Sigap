import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Konfigurasi tipografi modern berstandar WCAG AA untuk aplikasi SIGAP.
/// Menggunakan font [Plus Jakarta Sans] yang ramah, jelas, dan modern (Healthcare Style).
/// Menyediakan dua set gaya:
/// 1. [CareReceiverTypography]: Khusus lansia dengan ukuran font minimum 18sp-20sp,
///    ketebalan ekstra, dan line-height longgar untuk mencegah kelelahan mata.
/// 2. [StandardTypography]: Tipografi standar untuk Guardian, Responder, dan Admin.
abstract final class AppTypography {
  // ===========================================================================
  // TIPOGRAFI KHUSUS LANSIA (CARE-RECEIVER / SIMPLIFIED MODE)
  // Aturan mutlak: Tidak ada ukuran font di bawah 18sp.
  // ===========================================================================

  /// Judul utama halaman lansia (34sp, tebal)
  static TextStyle seniorHeadingLarge({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 34.0,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.25,
      color: color,
    );
  }

  /// Judul bagian kartu atau dialog konfirmasi (28sp, tebal)
  static TextStyle seniorHeadingMedium({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.3,
      color: color,
    );
  }

  /// Subtitle / Keterangan penting kartu (22sp, semi-bold)
  static TextStyle seniorTitle({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 22.0,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: color,
    );
  }

  /// Teks body utama lansia (20sp, jelas dan terbaca dari jarak pandang menengah)
  static TextStyle seniorBodyPrimary({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: color,
    );
  }

  /// Teks body pendukung lansia - BATAS MINIMUM MUTLAK (18sp)
  static TextStyle seniorBodySecondary({Color color = AppColors.textDarkSecondary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 18.0,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: color,
    );
  }

  /// Label tombol lansia (22sp, tebal kontras tinggi)
  static TextStyle seniorButtonLabel({Color color = Colors.white}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 22.0,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: color,
    );
  }

  /// Teks pada tombol SOS utama (26sp, ekstra tebal)
  static TextStyle seniorSosLabel({Color color = Colors.white}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 26.0,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
      color: color,
    );
  }

  /// Angka hitung mundur besar (48sp, ekstra tebal) untuk dialog darurat / SOS countdown
  static TextStyle countdownDisplay({Color color = Colors.white}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 48.0,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  // ===========================================================================
  // TIPOGRAFI STANDAR (RESPONDER, GUARDIAN, CIVIC ADMIN & HEALTHCARE DESIGN)
  // ===========================================================================

  static TextStyle standardDisplayLarge({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 30.0,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: color ?? AppColors.textDarkPrimary,
    );
  }

  static TextStyle standardHeadline({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 22.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: color ?? AppColors.textDarkPrimary,
    );
  }

  static TextStyle standardTitle({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textDarkPrimary,
    );
  }

  static TextStyle standardBody({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: color ?? AppColors.textDarkPrimary,
    );
  }

  static TextStyle standardCaption({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 13.0,
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.textDarkSecondary,
    );
  }

  static TextStyle standardButtonLabel({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16.0,
      fontWeight: FontWeight.w700,
      color: color ?? Colors.white,
    );
  }

  /// Judul Kategori Medis (Sesuai Referensi Gambar "Categories", "Doctors")
  static TextStyle categoryHeadline({Color color = AppColors.primaryTealDark}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 20.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: color,
    );
  }

  /// Label Tab Pill ("Info", "Booking" pada referensi)
  static TextStyle pillTabLabel({required bool isSelected}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14.0,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
      color: isSelected ? Colors.white : AppColors.textDarkSecondary,
    );
  }
}
