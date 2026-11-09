import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/rt_area.dart';
import '../../domain/models/user_profile.dart';

/// Repository autentikasi dan integrasi profil pengguna dengan database Supabase.
class AuthRepository {
  final SupabaseService _supabaseService;

  AuthRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// 1. Mengirim kode verifikasi OTP ke nomor telepon pengguna
  Future<void> signInWithOtp(String phoneNumber) async {
    if (!_supabaseService.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [AuthRepository] Mode demo aktif: OTP disimulasikan untuk $phoneNumber');
      }
      return;
    }

    try {
      await _supabaseService.auth.signInWithOtp(
        phone: phoneNumber,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthRepository] Gagal mengirim OTP: $e');
      }
      rethrow;
    }
  }

  /// 2. Memverifikasi kode OTP yang diinput pengguna
  Future<UserProfile> verifyOtp({
    required String phoneNumber,
    required String token,
  }) async {
    if (!_supabaseService.isInitialized) {
      // Return profil demo terverifikasi
      return UserProfile(
        id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        fullName: 'Warga SIGAP (Demo)',
        phoneNumber: phoneNumber,
        role: UserRole.careReceiver,
        simplifiedMode: true,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      final AuthResponse response = await _supabaseService.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );

      final User? user = response.user;
      if (user == null) {
        throw Exception('Verifikasi OTP gagal: Pengguna tidak ditemukan');
      }

      // Ambil atau buat profil pengguna jika belum ada
      UserProfile? profile = await getUserProfile(user.id);
      if (profile == null) {
        profile = UserProfile(
          id: user.id,
          fullName: 'Warga SIGAP',
          phoneNumber: phoneNumber,
          role: UserRole.careReceiver,
          simplifiedMode: true,
          isVerified: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await upsertProfile(profile);
      }

      return profile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthRepository] Gagal verifikasi OTP: $e');
      }
      rethrow;
    }
  }

  /// 3. Mengambil data profil pengguna berdasarkan user ID
  Future<UserProfile?> getUserProfile(String userId) async {
    if (!_supabaseService.isInitialized) {
      return null;
    }

    try {
      final dynamic response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response is Map<String, dynamic>) {
        return UserProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthRepository] Gagal mengambil profil: $e');
      }
      return null;
    }
  }

  /// 4. Menyimpan atau memperbarui profil pengguna
  Future<void> upsertProfile(UserProfile profile) async {
    if (!_supabaseService.isInitialized) {
      return;
    }

    try {
      await _client.from('profiles').upsert(profile.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthRepository] Gagal upsert profil: $e');
      }
      rethrow;
    }
  }

  /// 5. Validasi kode undangan RT/RW (30 hari aktif)
  Future<RtArea?> validateRtInviteCode(String inviteCode) async {
    final String cleanCode = inviteCode.trim().toUpperCase();

    // Mock data untuk kode RT default saat offline / pengujian cepat
    if (cleanCode == 'SIGAP-RT03-26') {
      return RtArea(
        id: '00000000-0000-0000-0000-000000000001',
        rtNumber: '03',
        rwNumber: '05',
        kelurahan: 'Menteng',
        kecamatan: 'Menteng',
        kota: 'Jakarta Pusat',
        inviteCode: 'SIGAP-RT03-26',
        inviteCodeExpiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    if (!_supabaseService.isInitialized) {
      return null;
    }

    try {
      final dynamic response = await _client
          .from('rt_areas')
          .select()
          .eq('invite_code', cleanCode)
          .maybeSingle();

      if (response != null && response is Map<String, dynamic>) {
        final rtArea = RtArea.fromJson(response);
        if (rtArea.isInviteCodeActive) {
          return rtArea;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthRepository] Gagal validasi kode RT: $e');
      }
      return null;
    }
  }

  /// 6. Menghubungkan pengguna ke wilayah RT/RW tertentu
  Future<void> joinRtArea({
    required String userId,
    required String rtAreaId,
  }) async {
    if (!_supabaseService.isInitialized) {
      return;
    }

    try {
      await _client.from('profiles').update({
        'rt_area_id': rtAreaId,
        'is_verified': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthRepository] Gagal bergabung ke wilayah RT: $e');
      }
      rethrow;
    }
  }

  /// 7. Mengambil daftar warga yang menunggu verifikasi di RT terkait
  Future<List<UserProfile>> getPendingResidents(String rtAreaId) async {
    if (!_supabaseService.isInitialized) {
      return <UserProfile>[
        UserProfile(
          id: 'mock-resident-1',
          fullName: 'Budi Santoso',
          phoneNumber: '+6281299887766',
          role: UserRole.responder,
          rtAreaId: rtAreaId,
          isVerified: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'mock-resident-2',
          fullName: 'Siti Rahmawati',
          phoneNumber: '+6281311223344',
          role: UserRole.careReceiver,
          rtAreaId: rtAreaId,
          isVerified: false,
          simplifiedMode: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    try {
      final dynamic response = await _client
          .from('profiles')
          .select()
          .eq('rt_area_id', rtAreaId)
          .eq('is_verified', false)
          .order('created_at', ascending: false);

      if (response is List) {
        return response
            .map((dynamic item) => UserProfile.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return <UserProfile>[];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthRepository] Gagal mengambil daftar warga pending: $e');
      }
      return <UserProfile>[];
    }
  }

  /// 8. Menyetujui atau menolak pendaftaran warga oleh Civic Admin
  Future<void> verifyResident({
    required String residentId,
    required String adminId,
    required bool isApproved,
  }) async {
    if (!_supabaseService.isInitialized) {
      return;
    }

    try {
      if (isApproved) {
        await _client.from('profiles').update({
          'is_verified': true,
          'verified_at': DateTime.now().toIso8601String(),
          'verified_by': adminId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', residentId);
      } else {
        await _client.from('profiles').update({
          'rt_area_id': null,
          'is_verified': false,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', residentId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthRepository] Gagal memverifikasi warga: $e');
      }
      rethrow;
    }
  }

  /// 9. Memperbarui kode undangan lingkungan RT (30 hari masa aktif)
  Future<void> refreshRtInviteCode({
    required String rtAreaId,
    required String newInviteCode,
  }) async {
    if (!_supabaseService.isInitialized) {
      return;
    }

    try {
      await _client.from('rt_areas').update({
        'invite_code': newInviteCode.trim().toUpperCase(),
        'invite_code_expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', rtAreaId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthRepository] Gagal memperbarui kode undangan RT: $e');
      }
      rethrow;
    }
  }
}
