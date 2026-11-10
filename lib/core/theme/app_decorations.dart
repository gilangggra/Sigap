import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Koleksi preset dekorasi, bayangan (shadows), dan gradien standar mobile modern.
/// Memberikan kedalaman visual yang halus dan elegan sesuai standar aplikasi kelas dunia.
abstract final class AppShadows {
  /// Bayangan kartu standar yang lembut dan modern (ambient card shadow)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 10.0,
      offset: Offset(0, 3),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 4.0,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  /// Bayangan halus untuk elemen kecil (chips, search bar, button)
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 8.0,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Bayangan melayang (floating / modal / sticky bottom bar)
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 20.0,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 8.0,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Pendaran halus warna Teal Brand untuk tombol primer atau status aktif
  static const List<BoxShadow> tealGlow = [
    BoxShadow(
      color: Color(0x3300BFA5),
      blurRadius: 16.0,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  /// Pendaran merah darurat untuk tombol SOS atau status bahaya
  static const List<BoxShadow> emergencyGlow = [
    BoxShadow(
      color: Color(0x38DC2626),
      blurRadius: 20.0,
      offset: Offset(0, 8),
      spreadRadius: 2,
    ),
  ];
}

/// Koleksi gradien warna resmi aplikasi SIGAP.
abstract final class AppGradients {
  /// Gradien Brand Utama (Teal Healthcare ke Dark Teal)
  static const LinearGradient brandTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryTeal,
      AppColors.primaryTealDark,
    ],
  );

  /// Gradien Header Hero Atas (Teal ke Deep Teal dengan kurva halus)
  static const LinearGradient headerBanner = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF00BFA5),
      Color(0xFF0E998B),
    ],
  );

  /// Gradien Darurat Merah (SOS Alert)
  static const LinearGradient emergency = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444),
      AppColors.emergencyRed,
    ],
  );

  /// Gradien Kartu Permukaan Lembut (Putih ke Slate 50)
  static const LinearGradient cardSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      Color(0xFFF8FAFC),
    ],
  );
}

/// Preset Border standar mobile
abstract final class AppBorders {
  static final Border standard = Border.all(
    color: AppColors.lightBorder,
    width: AppDimensions.standardBorderWidth,
  );

  static final Border subtle = Border.all(
    color: const Color(0xFFF1F5F9),
    width: AppDimensions.standardBorderWidth,
  );

  static final Border tealActive = Border.all(
    color: AppColors.primaryTeal,
    width: 1.5,
  );

  static final Border emergency = Border.all(
    color: AppColors.emergencyRed,
    width: AppDimensions.highContrastBorderWidth,
  );
}
