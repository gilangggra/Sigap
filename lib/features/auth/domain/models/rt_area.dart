/// Model domain untuk entitas wilayah RT/RW (sesuai tabel `rt_areas` pada database).
class RtArea {
  final String id;
  final String rtNumber;
  final String rwNumber;
  final String kelurahan;
  final String kecamatan;
  final String kota;
  final String inviteCode;
  final DateTime inviteCodeExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RtArea({
    required this.id,
    required this.rtNumber,
    required this.rwNumber,
    required this.kelurahan,
    required this.kecamatan,
    required this.kota,
    required this.inviteCode,
    required this.inviteCodeExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nama lengkap wilayah terformat
  String get formattedAreaName =>
      'RT $rtNumber / RW $rwNumber, Kel. $kelurahan, Kec. $kecamatan, $kota';

  /// Status apakah kode undangan masih berlaku
  bool get isInviteCodeActive => DateTime.now().isBefore(inviteCodeExpiresAt);

  factory RtArea.fromJson(Map<String, dynamic> json) {
    return RtArea(
      id: json['id'] as String,
      rtNumber: json['rt_number'] as String? ?? '',
      rwNumber: json['rw_number'] as String? ?? '',
      kelurahan: json['kelurahan'] as String? ?? '',
      kecamatan: json['kecamatan'] as String? ?? '',
      kota: json['kota'] as String? ?? '',
      inviteCode: json['invite_code'] as String? ?? '',
      inviteCodeExpiresAt: json['invite_code_expires_at'] != null
          ? DateTime.parse(json['invite_code_expires_at'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'rt_number': rtNumber,
      'rw_number': rwNumber,
      'kelurahan': kelurahan,
      'kecamatan': kecamatan,
      'kota': kota,
      'invite_code': inviteCode,
      'invite_code_expires_at': inviteCodeExpiresAt.toIso8601String(),
    };
  }
}

