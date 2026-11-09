/// Model domain untuk relasi keluarga antara Guardian dan Care-Receiver
/// sesuai tabel `guardian_relationships` pada database.
class GuardianRelationship {
  final String id;
  final String guardianId;
  final String careReceiverId;
  final bool isPrimary;
  final DateTime createdAt;

  const GuardianRelationship({
    required this.id,
    required this.guardianId,
    required this.careReceiverId,
    this.isPrimary = false,
    required this.createdAt,
  });

  factory GuardianRelationship.fromJson(Map<String, dynamic> json) {
    return GuardianRelationship(
      id: json['id'] as String,
      guardianId: json['guardian_id'] as String,
      careReceiverId: json['care_receiver_id'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'guardian_id': guardianId,
      'care_receiver_id': careReceiverId,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
