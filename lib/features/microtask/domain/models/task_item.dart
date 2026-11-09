/// Kategori tugas bantuan mikro warga (PRD Feature 3 & Database Schema)
enum TaskCategory {
  ambilResep('ambil_resep', 'Ambil Resep Obat', '💊'),
  belanjaLogistik('belanja_logistik', 'Belanja Kebutuhan Pokok', '🛒'),
  pendampinganMobilitas('pendampingan_mobilitas', 'Pendampingan Mobilitas', '🚶'),
  lainnya('lainnya', 'Bantuan Lainnya', '🤝');

  final String value;
  final String label;
  final String emoji;
  const TaskCategory(this.value, this.label, this.emoji);

  static TaskCategory fromString(String value) {
    return TaskCategory.values.firstWhere(
      (element) => element.value == value,
      orElse: () => TaskCategory.lainnya,
    );
  }
}

/// Status alur tugas bantuan mikro warga
enum TaskStatus {
  open('open', 'Menunggu Relawan'),
  accepted('accepted', 'Sedang Diambil'),
  inProgress('in_progress', 'Dalam Proses'),
  completed('completed', 'Selesai'),
  cancelled('cancelled', 'Dibatalkan');

  final String value;
  final String label;
  const TaskStatus(this.value, this.label);

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (element) => element.value == value,
      orElse: () => TaskStatus.open,
    );
  }
}

/// Model data tiket tugas bantuan mikro antartetangga (tabel `tasks`)
class TaskItem {
  final String id;
  final String createdBy;
  final String careReceiverId;
  final String careReceiverName;
  final TaskCategory category;
  final String description;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String destinationAddress;
  final DateTime? neededBefore;
  final TaskStatus status;
  final String? responderId;
  final String? responderName;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? completionNotes;
  final String? rtAreaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distanceMeters;

  const TaskItem({
    required this.id,
    required this.createdBy,
    required this.careReceiverId,
    required this.careReceiverName,
    required this.category,
    required this.description,
    this.destinationLatitude,
    this.destinationLongitude,
    required this.destinationAddress,
    this.neededBefore,
    this.status = TaskStatus.open,
    this.responderId,
    this.responderName,
    this.acceptedAt,
    this.completedAt,
    this.completionNotes,
    this.rtAreaId,
    required this.createdAt,
    required this.updatedAt,
    this.distanceMeters,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      createdBy: json['created_by'] as String? ?? '',
      careReceiverId: json['care_receiver_id'] as String? ?? '',
      careReceiverName: json['care_receiver_name'] as String? ?? 'Warga Lansia',
      category: TaskCategory.fromString(json['category'] as String? ?? 'lainnya'),
      description: json['description'] as String? ?? '',
      destinationLatitude: json['destination_lat'] != null
          ? (json['destination_lat'] as num).toDouble()
          : null,
      destinationLongitude: json['destination_lng'] != null
          ? (json['destination_lng'] as num).toDouble()
          : null,
      destinationAddress: json['destination_address'] as String? ?? '',
      neededBefore: json['needed_before'] != null
          ? DateTime.tryParse(json['needed_before'] as String)
          : null,
      status: TaskStatus.fromString(json['status'] as String? ?? 'open'),
      responderId: json['responder_id'] as String?,
      responderName: json['responder_name'] as String?,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      completionNotes: json['completion_notes'] as String?,
      rtAreaId: json['rt_area_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      distanceMeters: json['distance_meters'] != null
          ? (json['distance_meters'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'created_by': createdBy,
      'care_receiver_id': careReceiverId,
      'care_receiver_name': careReceiverName,
      'category': category.value,
      'description': description,
      'destination_lat': destinationLatitude,
      'destination_lng': destinationLongitude,
      'destination_address': destinationAddress,
      'needed_before': neededBefore?.toIso8601String(),
      'status': status.value,
      'responder_id': responderId,
      'responder_name': responderName,
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'completion_notes': completionNotes,
      'rt_area_id': rtAreaId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskItem copyWith({
    String? id,
    String? createdBy,
    String? careReceiverId,
    String? careReceiverName,
    TaskCategory? category,
    String? description,
    double? destinationLatitude,
    double? destinationLongitude,
    String? destinationAddress,
    DateTime? neededBefore,
    TaskStatus? status,
    String? responderId,
    String? responderName,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? completionNotes,
    String? rtAreaId,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distanceMeters,
  }) {
    return TaskItem(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      careReceiverId: careReceiverId ?? this.careReceiverId,
      careReceiverName: careReceiverName ?? this.careReceiverName,
      category: category ?? this.category,
      description: description ?? this.description,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      neededBefore: neededBefore ?? this.neededBefore,
      status: status ?? this.status,
      responderId: responderId ?? this.responderId,
      responderName: responderName ?? this.responderName,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
      rtAreaId: rtAreaId ?? this.rtAreaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}

