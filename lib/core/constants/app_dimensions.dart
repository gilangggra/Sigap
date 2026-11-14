/// Konstanta ukuran, target sentuh (touch targets), dan jarak tata letak
/// dengan standar mobile modern yang konsisten dan aksesibel untuk seluruh pengguna SIGAP.
abstract final class AppDimensions {
  // --- Target Sentuh Aksesibilitas (Touch Targets) ---
  /// Target sentuh standar mobile proporsional & rapi (50dp)
  static const double seniorMinTouchTarget = 50.0;

  /// Target sentuh nyaman / medium untuk mode tindakan utama (56dp)
  static const double seniorRecommendedTouchTarget = 56.0;

  /// Ukuran tombol SOS utama yang proporsional dan elegan (128x128dp)
  static const double sosButtonSize = 128.0;

  /// Ukuran ikon pada tombol SOS utama
  static const double sosIconSize = 40.0;

  /// Target sentuh standar mobile Material/iOS (48dp)
  static const double standardMinTouchTarget = 48.0;

  // --- Spacing & Padding Standar Mobile ---
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 20.0;
  static const double spaceXL = 24.0;
  static const double space2XL = 32.0;
  static const double space3XL = 40.0;

  // --- Border Radius Standar Mobile ---
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusCard = 16.0;
  static const double radiusPill = 24.0;
  static const double radiusHeader = 24.0;
  static const double radiusXL = 20.0;
  static const double radiusFull = 999.0;

  // --- Ketebalan Border ---
  static const double highContrastBorderWidth = 2.0;
  static const double standardBorderWidth = 1.0;

  // --- Elevasi Bayangan Mobile ---
  static const double elevationLow = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationHigh = 4.0;
}
