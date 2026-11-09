import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../domain/models/ice_card.dart';

/// Repository untuk pengelolaan profil medis darurat (ICE Card)
/// dan otorisasi akses token darurat bagi penolong pertama.
class ProfileRepository {
  final SupabaseService _supabaseService;

  ProfileRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// 1. Mengambil data ICE Card milik Care-Receiver tertentu
  Future<IceCard?> getIceCard(String careReceiverId) async {
    // Data mock default untuk demonstrasi atau saat offline
    final defaultMockCard = IceCard(
      id: 'mock-ice-card-001',
      careReceiverId: careReceiverId,
      bloodType: 'B+',
      allergies: const ['Alergi Penicillin', 'Alergi Seafood (Udang/Kepiting)'],
      chronicConditions: const ['Hipertensi Tingkat 1', 'Diabetes Melitus Tipe 2'],
      doctorName: 'dr. Hendra Kusuma, Sp.PD',
      doctorPhone: '+6281233445566',
      doctorNotes: 'Penderita rutin mengonsumsi Amlodipine 5mg. Hindari obat analgesik jenis NSAID tanpa pengawasan.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

    if (!_supabaseService.isInitialized) {
      return defaultMockCard;
    }

    try {
      final dynamic response = await _client
          .from('ice_cards')
          .select()
          .eq('care_receiver_id', careReceiverId)
          .maybeSingle();

      if (response != null && response is Map<String, dynamic>) {
        return IceCard.fromJson(response);
      }
      return defaultMockCard;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ProfileRepository] Menggunakan data ICE Card fallback: $e');
      }
      return defaultMockCard;
    }
  }

  /// 2. Menyimpan atau memperbarui data ICE Card
  Future<void> saveIceCard(IceCard iceCard) async {
    if (!_supabaseService.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [ProfileRepository] Mode demo: ICE Card disimpan secara lokal');
      }
      return;
    }

    try {
      await _client.from('ice_cards').upsert(iceCard.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProfileRepository] Gagal menyimpan data ICE Card: $e');
      }
      rethrow;
    }
  }

  /// 3. Mengakses data medis korban saat situasi darurat aktif menggunakan token darurat
  /// Token divalidasi di server (berlaku 2 jam) dan dicatat dalam audit log
  Future<IceCard?> getIceCardWithEmergencyToken({
    required String token,
    required String responderId,
  }) async {
    // Mode demo token
    if (token == 'DEMO-EMERGENCY-TOKEN' || !_supabaseService.isInitialized) {
      return IceCard(
        id: 'emergency-ice-victim',
        careReceiverId: 'victim-001',
        bloodType: 'O+',
        allergies: const ['Alergi Paracetamol', 'Alergi Antibiotik Sefalosporin'],
        chronicConditions: const ['Aritmia Jantung', 'Hipertensi Ringan'],
        doctorName: 'dr. Siti Rahayu, Sp.JP',
        doctorPhone: '+6281122334455',
        doctorNotes: 'Pasien menggunakan alat pacu jantung. Waspada saat resusitasi defibrilasi manual.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      final String? careReceiverId = await _supabaseService.validateEmergencyToken(
        token: token,
        responderId: responderId,
      );

      if (careReceiverId != null && careReceiverId.isNotEmpty) {
        return await getIceCard(careReceiverId);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProfileRepository] Token darurat tidak valid atau kedaluwarsa: $e');
      }
      return null;
    }
  }

  /// 4. Menghubungkan akun Wali dengan Lansia
  Future<void> linkGuardianRelationship({
    required String guardianId,
    required String careReceiverId,
    bool isPrimary = true,
  }) async {
    if (!_supabaseService.isInitialized) {
      return;
    }

    try {
      await _client.from('guardian_relationships').upsert({
        'guardian_id': guardianId,
        'care_receiver_id': careReceiverId,
        'is_primary': isPrimary,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProfileRepository] Gagal menghubungkan wali: $e');
      }
      rethrow;
    }
  }

  /// 5. Mengambil daftar lansia yang dipantau oleh Guardian
  Future<List<UserProfile>> getMonitoredLansia(String guardianId) async {
    if (!_supabaseService.isInitialized) {
      return <UserProfile>[
        UserProfile(
          id: 'lansia-001',
          fullName: 'Ibu Aminah',
          phoneNumber: '+6281211112222',
          role: UserRole.careReceiver,
          rtAreaId: '00000000-0000-0000-0000-000000000001',
          isVerified: true,
          simplifiedMode: true,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    try {
      final dynamic response = await _client
          .from('guardian_relationships')
          .select('care_receiver_id, profiles!care_receiver_id(*)')
          .eq('guardian_id', guardianId);

      if (response is List) {
        final list = <UserProfile>[];
        for (final item in response) {
          if (item is Map && item['profiles'] != null) {
            list.add(UserProfile.fromJson(Map<String, dynamic>.from(item['profiles'] as Map)));
          }
        }
        return list;
      }
      return <UserProfile>[];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ProfileRepository] Gagal mengambil lansia yang dipantau: $e');
      }
      return <UserProfile>[];
    }
  }
}

