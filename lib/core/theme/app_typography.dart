import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Konfigurasi tipografi berstandar WCAG AA untuk aplikasi SIGAP.
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
    return GoogleFonts.inter(
      fontSize: 34.0,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.25,
      color: color,
    );
  }

  /// Judul bagian kartu atau dialog konfirmasi (28sp, tebal)
  static TextStyle seniorHeadingMedium({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.inter(
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.3,
      color: color,
    );
  }

  /// Subtitle / Keterangan penting kartu (22sp, semi-bold)
  static TextStyle seniorTitle({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.inter(
      fontSize: 22.0,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: color,
    );
  }

  /// Teks body utama lansia (20sp, jelas dan terbaca dari jarak pandang menengah)
  static TextStyle seniorBodyPrimary({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.inter(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: color,
    );
  }

  /// Teks body pendukung lansia - BATAS MINIMUM MUTLAK (18sp)
  static TextStyle seniorBodySecondary({Color color = AppColors.textDarkSecondary}) {
    return GoogleFonts.inter(
      fontSize: 18.0,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: color,
    );
  }

  /// Label tombol lansia (22sp, tebal kontras tinggi)
  static TextStyle seniorButtonLabel({Color color = Colors.white}) {
    return GoogleFonts.inter(
      fontSize: 22.0,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: color,
    );
  }

  /// Teks pada tombol SOS utama (26sp, ekstra tebal)
  static TextStyle seniorSosLabel({Color color = Colors.white}) {
    return GoogleFonts.inter(
      fontSize: 26.0,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
      color: color,
    );
  }

  /// Angka hitung mundur besar (48sp, ekstra tebal) untuk dialog darurat / SOS countdown
  static TextStyle countdownDisplay({Color color = Colors.white}) {
    return GoogleFonts.inter(
      fontSize: 48.0,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  // ===========================================================================
  // TIPOGRAFI STANDAR (RESPONDER, GUARDIAN, CIVIC ADMIN)
  // ===========================================================================

  static TextStyle standardDisplayLarge({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 30.0,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static TextStyle standardHeadline({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 22.0,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle standardTitle({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle standardBody({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 15.0,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color,
    );
  }

  static TextStyle standardCaption({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 13.0,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle standardButtonLabel({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}

