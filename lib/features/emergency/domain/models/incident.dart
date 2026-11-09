import '../../../../core/constants/app_constants.dart';

/// Model domain untuk insiden darurat (sesuai tabel `incidents` pada database SIGAP).
class Incident {
  final String id;
  final String careReceiverId;
  final String? careReceiverName;
  final String? careReceiverPhone;
  final double latitude;
  final double longitude;
  final String? address;
  final bool gpsApproximate;
  final IncidentStatus status;
  final String? responderId;
  final String? responderName;
  final DateTime? responderLockedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;
  final bool smsSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Incident({
    required this.id,
    required this.careReceiverId,
    this.careReceiverName,
    this.careReceiverPhone,
    required this.latitude,
    required this.longitude,
    this.address,
    this.gpsApproximate = false,
    this.status = IncidentStatus.dispatched,
    this.responderId,
    this.responderName,
    this.responderLockedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
    this.smsSent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory untuk membuat Incident dari Map / JSON Supabase
  factory Incident.fromJson(Map<String, dynamic> json) {
    double lat = 0.0;
    double lng = 0.0;

    // Parsing koordinat geospasial PostGIS
    if (json['location'] != null) {
      if (json['location'] is Map) {
        final loc = json['location'] as Map;
        if (loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
          lng = (loc['coordinates'][0] as num).toDouble();
          lat = (loc['coordinates'][1] as num).toDouble();
        }
      } else if (json['latitude'] != null && json['longitude'] != null) {
        lat = (json['latitude'] as num).toDouble();
        lng = (json['longitude'] as num).toDouble();
      }
    } else {
      lat = (json['latitude'] as num?)?.toDouble() ?? -6.2088;
      lng = (json['longitude'] as num?)?.toDouble() ?? 106.8456;
    }

    return Incident(
      id: json['id'] as String,
      careReceiverId: json['care_receiver_id'] as String,
      careReceiverName: json['care_receiver_name'] as String?,
      careReceiverPhone: json['care_receiver_phone'] as String?,
      latitude: lat,
      longitude: lng,
      address: json['location_address'] as String? ?? json['address'] as String?,
      gpsApproximate: json['gps_approximate'] as bool? ?? false,
      status: IncidentStatus.fromString(json['status'] as String? ?? 'dispatched'),
      responderId: json['responder_id'] as String?,
      responderName: json['responder_name'] as String?,
      responderLockedAt: json['responder_locked_at'] != null
          ? DateTime.tryParse(json['responder_locked_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      smsSent: json['sms_sent'] as bool? ?? false,
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
      'care_receiver_id': careReceiverId,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': address,
      'gps_approximate': gpsApproximate,
      'status': status.value,
      'responder_id': responderId,
      'responder_locked_at': responderLockedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'resolution_notes': resolutionNotes,
      'sms_sent': smsSent,
    };
  }

  Incident copyWith({
    String? id,
    String? careReceiverId,
    String? careReceiverName,
    String? careReceiverPhone,
    double? latitude,
    double? longitude,
    String? address,
    bool? gpsApproximate,
    IncidentStatus? status,
    String? responderId,
    String? responderName,
    DateTime? responderLockedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? resolutionNotes,
    bool? smsSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Incident(
      id: id ?? this.id,
      careReceiverId: careReceiverId ?? this.careReceiverId,
      careReceiverName: careReceiverName ?? this.careReceiverName,
      careReceiverPhone: careReceiverPhone ?? this.careReceiverPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      gpsApproximate: gpsApproximate ?? this.gpsApproximate,
      status: status ?? this.status,
      responderId: responderId ?? this.responderId,
      responderName: responderName ?? this.responderName,
      responderLockedAt: responderLockedAt ?? this.responderLockedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      smsSent: smsSent ?? this.smsSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

