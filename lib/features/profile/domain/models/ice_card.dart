/// Model domain untuk Kartu Informasi Darurat Medis (ICE Card)
/// sesuai tabel `ice_cards` pada database SIGAP.
class IceCard {
  final String id;
  final String careReceiverId;
  final String bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? doctorName;
  final String? doctorPhone;
  final String? doctorNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IceCard({
    required this.id,
    required this.careReceiverId,
    required this.bloodType,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.doctorName,
    this.doctorPhone,
    this.doctorNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory untuk membuat IceCard dari JSON / Map database
  factory IceCard.fromJson(Map<String, dynamic> json) {
    return IceCard(
      id: json['id'] as String,
      careReceiverId: json['care_receiver_id'] as String,
      bloodType: json['blood_type'] as String? ?? 'Tidak Diketahui',
      allergies: json['allergies'] is List
          ? (json['allergies'] as List).map((e) => e.toString()).toList()
          : <String>[],
      chronicConditions: json['chronic_conditions'] is List
          ? (json['chronic_conditions'] as List).map((e) => e.toString()).toList()
          : <String>[],
      doctorName: json['doctor_name'] as String?,
      doctorPhone: json['doctor_phone'] as String?,
      doctorNotes: json['doctor_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Serialisasi model ke Map untuk upsert ke Supabase
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'care_receiver_id': careReceiverId,
      'blood_type': bloodType,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'doctor_name': doctorName,
      'doctor_phone': doctorPhone,
      'doctor_notes': doctorNotes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  IceCard copyWith({
    String? id,
    String? careReceiverId,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? doctorName,
    String? doctorPhone,
    String? doctorNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IceCard(
      id: id ?? this.id,
      careReceiverId: careReceiverId ?? this.careReceiverId,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

