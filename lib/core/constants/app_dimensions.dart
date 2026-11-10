/// Konstanta ukuran, target sentuh (touch targets), dan jarak tata letak
/// dengan fokus utama pada standar aksesibilitas lansia dan sistem desain modern SIGAP.
abstract final class AppDimensions {
  // --- Target Sentuh Aksesibilitas (Touch Targets) ---
  /// Target sentuh minimum mutlak untuk tombol lansia (sesuai spesifikasi min 64dp)
  static const double seniorMinTouchTarget = 64.0;

  /// Target sentuh yang direkomendasikan untuk mode care-receiver (72x72dp)
  static const double seniorRecommendedTouchTarget = 72.0;

  /// Ukuran tombol SOS utama (PRD F1.1 mensyaratkan minimum 120x120dp)
  static const double sosButtonSize = 120.0;

  /// Ukuran ikon pada tombol SOS utama
  static const double sosIconSize = 56.0;

  /// Target sentuh standar untuk peran relawan, guardian, dan admin (Material standard 48dp)
  static const double standardMinTouchTarget = 48.0;

  // --- Spacing & Padding ---
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double space2XL = 40.0;
  static const double space3XL = 48.0;

  // --- Border Radius Modern Healthcare ---
  static const double radiusSM = 8.0;
  static const double radiusMD = 14.0;
  static const double radiusLG = 18.0;
  static const double radiusCard = 24.0;
  static const double radiusPill = 28.0;
  static const double radiusHeader = 32.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  // --- Ketebalan Border Kontras Tinggi ---
  static const double highContrastBorderWidth = 2.0;
  static const double standardBorderWidth = 1.0;

  // --- Elevasi Bayangan ---
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;
}
