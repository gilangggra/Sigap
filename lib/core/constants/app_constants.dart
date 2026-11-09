/// Peran pengguna dalam ekosistem SIGAP
enum UserRole {
  careReceiver('care_receiver', 'Penerima Bantuan / Lansia'),
  guardian('guardian', 'Keluarga / Wali'),
  responder('responder', 'Relawan Warga'),
  civicAdmin('civic_admin', 'Pengurus RT/RW');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (element) => element.value == value,
      orElse: () => UserRole.careReceiver,
    );
  }
}

/// Status insiden darurat
enum IncidentStatus {
  dispatched('dispatched', 'Menunggu Relawan'),
  responding('responding', 'Relawan Menuju Lokasi'),
  onSite('on_site', 'Relawan di Lokasi'),
  resolved('resolved', 'Selesai'),
  cancelled('cancelled', 'Dibatalkan');

  final String value;
  final String label;
  const IncidentStatus(this.value, this.label);

  static IncidentStatus fromString(String value) {
    return IncidentStatus.values.firstWhere(
      (element) => element.value == value,
      orElse: () => IncidentStatus.dispatched,
    );
  }
}

/// Status check-in harian
enum CheckinStatus {
  baik('baik', 'Kondisi Baik', '😊'),
  kurangEnak('kurang_enak', 'Kurang Enak Badan', '😐'),
  butuhBantuan('butuh_bantuan', 'Butuh Bantuan Segera', '😟');

  final String value;
  final String label;
  final String emoji;
  const CheckinStatus(this.value, this.label, this.emoji);

  static CheckinStatus fromString(String value) {
    return CheckinStatus.values.firstWhere(
      (element) => element.value == value,
      orElse: () => CheckinStatus.baik,
    );
  }
}

/// Konstanta bisnis operasional SIGAP
abstract final class AppConstants {
  static const String appName = 'SIGAP';
  static const String appTagline = 'Jaringan Kesiapsiagaan & Saling Bantu Warga';

  /// Durasi countdown pembatalan darurat (detik)
  static const int sosCountdownSeconds = 8;

  /// Radius awal pencarian relawan terdekat (meter)
  static const double initialGeofenceRadiusMeters = 500.0;

  /// Radius ekspansi pencarian jika relawan aktif < 3 (meter)
  static const double expandedGeofenceRadiusMeters = 800.0;

  /// Jumlah maksimal responder terdekat yang dipanggil
  static const int maxTargetResponders = 5;

  /// Masa berlaku token darurat akses ICE Card (jam)
  static const int emergencyTokenDurationHours = 2;

  /// Ambang batas waktu deteksi offline (detik)
  static const int networkTimeoutSeconds = 5;
}

