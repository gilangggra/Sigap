import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Konfigurasi tipografi standar mobile dengan font [Poppins] untuk seluruh aplikasi SIGAP.
/// Menjamin konsistensi hierarki, warna teks kontras tinggi, dan ramah pembacaan lansia (WCAG AA).
abstract final class AppTypography {
  // ===========================================================================
  // TIPOGRAFI KHUSUS LANSIA (CARE-RECEIVER / SIMPLIFIED MODE)
  // Aturan mutlak: Tidak ada ukuran font di bawah 18sp dengan font Poppins.
  // ===========================================================================

  /// Judul utama halaman lansia (32sp, tebal)
  static TextStyle seniorHeadingLarge({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 32.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.3,
      color: color,
    );
  }

  /// Judul bagian kartu atau dialog konfirmasi (26sp, tebal)
  static TextStyle seniorHeadingMedium({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 26.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.3,
      color: color,
    );
  }

  /// Subtitle / Keterangan penting kartu (20sp, semi-bold)
  static TextStyle seniorTitle({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: color,
    );
  }

  /// Teks body utama lansia (19sp, jelas dan terbaca dari jarak pandang menengah)
  static TextStyle seniorBodyPrimary({Color color = AppColors.textDarkPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 19.0,
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: color,
    );
  }

  /// Teks body pendukung lansia - BATAS MINIMUM MUTLAK (18sp)
  static TextStyle seniorBodySecondary({Color color = AppColors.textDarkSecondary}) {
    return GoogleFonts.poppins(
      fontSize: 18.0,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: color,
    );
  }

  /// Label tombol lansia (20sp, tebal kontras tinggi)
  static TextStyle seniorButtonLabel({Color color = Colors.white}) {
    return GoogleFonts.poppins(
      fontSize: 20.0,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: color,
    );
  }

  /// Teks pada tombol SOS utama (26sp, ekstra tebal)
  static TextStyle seniorSosLabel({Color color = Colors.white}) {
    return GoogleFonts.poppins(
      fontSize: 26.0,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.0,
      color: color,
    );
  }

  /// Angka hitung mundur besar (48sp, ekstra tebal) untuk dialog darurat
  static TextStyle countdownDisplay({Color color = Colors.white}) {
    return GoogleFonts.poppins(
      fontSize: 48.0,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  // ===========================================================================
  // TIPOGRAFI STANDAR MOBILE (POPPINS HIERARCHY)
  // ===========================================================================

  static TextStyle standardDisplayLarge({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: color ?? AppColors.textDarkPrimary,
    );
  }

  static TextStyle standardHeadline({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 20.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: color ?? AppColors.textDarkPrimary,
    );
  }

  static TextStyle standardTitle({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textDarkPrimary,
    );
  }

  static TextStyle standardBody({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color ?? AppColors.textDarkPrimary,
    );
  }

  static TextStyle standardCaption({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color ?? AppColors.textDarkSecondary,
    );
  }

  static TextStyle standardButtonLabel({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 15.0,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.white,
    );
  }

  /// Judul Bagian / Kategori Standar Mobile
  static TextStyle categoryHeadline({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 17.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: color ?? AppColors.textDarkPrimary,
    );
  }

  /// Label Tab Pill / Segmented Control
  static TextStyle pillTabLabel({required bool isSelected}) {
    return GoogleFonts.poppins(
      fontSize: 13.0,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: isSelected ? Colors.white : AppColors.textDarkSecondary,
    );
  }
}
