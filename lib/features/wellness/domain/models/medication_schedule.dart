/// Model jadwal dan kepatuhan konsumsi obat harian (tabel `medication_schedules` & `medication_logs`).
class MedicationSchedule {
  final String id;
  final String careReceiverId;
  final String createdBy;
  final String medicationName;
  final String dosage;
  final List<String> reminderTimes;
  final bool isActive;
  final bool isTakenToday;
  final DateTime? takenAt;

  const MedicationSchedule({
    required this.id,
    required this.careReceiverId,
    required this.createdBy,
    required this.medicationName,
    required this.dosage,
    this.reminderTimes = const <String>[],
    this.isActive = true,
    this.isTakenToday = false,
    this.takenAt,
  });

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: json['id'] as String,
      careReceiverId: json['care_receiver_id'] as String,
      createdBy: json['created_by'] as String? ?? '',
      medicationName: json['medication_name'] as String,
      dosage: json['dosage'] as String? ?? '',
      reminderTimes: json['reminder_times'] is List
          ? (json['reminder_times'] as List).map((e) => e.toString()).toList()
          : <String>['08:00'],
      isActive: json['is_active'] as bool? ?? true,
      isTakenToday: json['is_taken_today'] as bool? ?? false,
      takenAt: json['taken_at'] != null ? DateTime.tryParse(json['taken_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'care_receiver_id': careReceiverId,
      'created_by': createdBy,
      'medication_name': medicationName,
      'dosage': dosage,
      'reminder_times': reminderTimes,
      'is_active': isActive,
      'is_taken_today': isTakenToday,
      'taken_at': takenAt?.toIso8601String(),
    };
  }

  MedicationSchedule copyWith({
    String? id,
    String? careReceiverId,
    String? createdBy,
    String? medicationName,
    String? dosage,
    List<String>? reminderTimes,
    bool? isActive,
    bool? isTakenToday,
    DateTime? takenAt,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      careReceiverId: careReceiverId ?? this.careReceiverId,
      createdBy: createdBy ?? this.createdBy,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      isActive: isActive ?? this.isActive,
      isTakenToday: isTakenToday ?? this.isTakenToday,
      takenAt: takenAt ?? this.takenAt,
    );
  }
}

