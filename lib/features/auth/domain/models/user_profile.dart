import '../../../../core/constants/app_constants.dart';

/// Model domain untuk profil pengguna SIGAP (sesuai tabel `profiles` pada database).
class UserProfile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final String? rtAreaId;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final bool simplifiedMode;
  final String? fcmToken;
  final String? apnsToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.rtAreaId,
    this.isVerified = false,
    this.verifiedAt,
    this.verifiedBy,
    this.simplifiedMode = false,
    this.fcmToken,
    this.apnsToken,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory untuk membuat UserProfile dari JSON / Map Supabase
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Warga SIGAP',
      phoneNumber: json['phone_number'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'care_receiver'),
      rtAreaId: json['rt_area_id'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at'] as String) : null,
      verifiedBy: json['verified_by'] as String?,
      simplifiedMode: json['simplified_mode'] as bool? ?? false,
      fcmToken: json['fcm_token'] as String?,
      apnsToken: json['apns_token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Konversi model ke Map untuk INSERT / UPDATE ke Supabase
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role.value,
      'rt_area_id': rtAreaId,
      'is_verified': isVerified,
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'simplified_mode': simplifiedMode,
      'fcm_token': fcmToken,
      'apns_token': apnsToken,
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    String? rtAreaId,
    bool? isVerified,
    DateTime? verifiedAt,
    String? verifiedBy,
    bool? simplifiedMode,
    String? fcmToken,
    String? apnsToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      rtAreaId: rtAreaId ?? this.rtAreaId,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      simplifiedMode: simplifiedMode ?? this.simplifiedMode,
      fcmToken: fcmToken ?? this.fcmToken,
      apnsToken: apnsToken ?? this.apnsToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

