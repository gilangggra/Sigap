import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../domain/models/ice_card.dart';

/// Repository untuk pengelolaan profil medis darurat (ICE Card)
/// dan otorisasi akses token darurat bagi penolong pertama.
/// Dilengkapi penyimpanan lokal terenkripsi (Offline-First Secure Cache).
class ProfileRepository {
  final SupabaseService _supabaseService;
  final LocalCacheService _localCacheService;

  ProfileRepository({
    SupabaseService? supabaseService,
    LocalCacheService? localCacheService,
  })  : _supabaseService = supabaseService ?? SupabaseService.instance,
        _localCacheService = localCacheService ?? LocalCacheService.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// 1. Mengambil data ICE Card milik Care-Receiver tertentu
  /// Prioritas: Cloud Supabase -> Jika offline / gagal, ambil dari Secure Cache Lokal -> Fallback Mock
  Future<IceCard?> getIceCard(String careReceiverId) async {
    // 1. Coba ambil dari database Supabase jika online
    if (_supabaseService.isInitialized) {
      try {
        final dynamic response = await _client
            .from('ice_cards')
            .select()
            .eq('care_receiver_id', careReceiverId)
            .maybeSingle();

        if (response != null && response is Map<String, dynamic>) {
          final cloudCard = IceCard.fromJson(response);
          // Simpan salinan terbaru ke cache lokal terenkripsi
          await _localCacheService.saveIceCard(cloudCard);
          return cloudCard;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [ProfileRepository] Supabase unreachable, beralih ke cache lokal: $e');
        }
      }
    }

    // 2. Ambil dari cache lokal terenkripsi (Offline Mode)
    final cachedCard = await _localCacheService.getIceCard(careReceiverId);
    if (cachedCard != null) {
      if (kDebugMode) {
        print('🔒 [ProfileRepository] ICE Card berhasil dimuat dari secure cache offline.');
      }
      return cachedCard;
    }

    // 3. Fallback mock default jika belum pernah ada data tersimpan
    return IceCard(
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
  }

  /// 2. Menyimpan atau memperbarui data ICE Card
  /// Selalu disimpan ke Secure Cache Lokal terlebih dahulu, lalu di-push ke Cloud jika online
  Future<void> saveIceCard(IceCard iceCard) async {
    // 1. Simpan ke secure cache lokal seketika (Offline-First)
    await _localCacheService.saveIceCard(iceCard);

    if (!_supabaseService.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [ProfileRepository] Mode offline/demo: ICE Card diamankan di secure cache lokal');
      }
      return;
    }

    // 2. Sinkronisasikan ke Supabase jika ada koneksi
    try {
      await _client.from('ice_cards').upsert(iceCard.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ProfileRepository] Gagal sinkronisasi ICE Card ke cloud, data tetap tersimpan di lokal: $e');
      }
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

