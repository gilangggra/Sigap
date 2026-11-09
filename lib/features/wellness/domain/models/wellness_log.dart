import '../../../../core/constants/app_constants.dart';

/// Status eskalasi Dead-Man Switch (PRD F2.2)
enum EscalationStatus {
  pending('pending', 'Menunggu Check-in'),
  reminderSent('reminder_sent', 'Pengingat Kedua Terkirim (90m)'),
  guardianAlerted('guardian_alerted', 'Keluarga Dinotifikasi (120m)'),
  adminAlerted('admin_alerted', 'Pengurus RT Dinotifikasi (150m)'),
  resolved('resolved', 'Lansia Telah Merespons');

  final String value;
  final String label;
  const EscalationStatus(this.value, this.label);

  static EscalationStatus fromString(String value) {
    return EscalationStatus.values.firstWhere(
      (element) => element.value == value,
      orElse: () => EscalationStatus.pending,
    );
  }
}

/// Model log check-in harian lansia (sesuai tabel `wellness_logs` pada database).
class WellnessLog {
  final String id;
  final String careReceiverId;
  final DateTime checkDate;
  final CheckinStatus? status;
  final EscalationStatus escalationStatus;
  final DateTime? respondedAt;
  final DateTime? reminderSentAt;
  final DateTime? guardianAlertedAt;
  final DateTime? adminAlertedAt;
  final DateTime createdAt;

  const WellnessLog({
    required this.id,
    required this.careReceiverId,
    required this.checkDate,
    this.status,
    this.escalationStatus = EscalationStatus.pending,
    this.respondedAt,
    this.reminderSentAt,
    this.guardianAlertedAt,
    this.adminAlertedAt,
    required this.createdAt,
  });

  factory WellnessLog.fromJson(Map<String, dynamic> json) {
    return WellnessLog(
      id: json['id'] as String,
      careReceiverId: json['care_receiver_id'] as String,
      checkDate: json['check_date'] != null
          ? DateTime.parse(json['check_date'] as String)
          : DateTime.now(),
      status: json['status'] != null ? CheckinStatus.fromString(json['status'] as String) : null,
      escalationStatus: EscalationStatus.fromString(
        json['escalation_status'] as String? ?? 'pending',
      ),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'] as String)
          : null,
      reminderSentAt: json['reminder_sent_at'] != null
          ? DateTime.tryParse(json['reminder_sent_at'] as String)
          : null,
      guardianAlertedAt: json['guardian_alerted_at'] != null
          ? DateTime.tryParse(json['guardian_alerted_at'] as String)
          : null,
      adminAlertedAt: json['admin_alerted_at'] != null
          ? DateTime.tryParse(json['admin_alerted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'care_receiver_id': careReceiverId,
      'check_date': checkDate.toIso8601String().split('T').first,
      'status': status?.value,
      'escalation_status': escalationStatus.value,
      'responded_at': respondedAt?.toIso8601String(),
      'reminder_sent_at': reminderSentAt?.toIso8601String(),
      'guardian_alerted_at': guardianAlertedAt?.toIso8601String(),
      'admin_alerted_at': adminAlertedAt?.toIso8601String(),
    };
  }
}
