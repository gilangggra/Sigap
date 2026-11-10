import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/medication_schedule.dart';
import '../../domain/models/wellness_log.dart';

/// Repository pengelola rekaman kesehatan harian (Check-in, Dead-Man Switch, dan Kepatuhan Obat).
/// Dilengkapi sistem penyimpanan offline-first dan sinkronisasi otomatis.
class WellnessRepository {
  final SupabaseService _supabaseService;
  final LocalCacheService _localCacheService;

  WellnessRepository({
    SupabaseService? supabaseService,
    LocalCacheService? localCacheService,
  })  : _supabaseService = supabaseService ?? SupabaseService.instance,
        _localCacheService = localCacheService ?? LocalCacheService.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// 1. Mencatat respons check-in harian lansia (Disimpan lokal seketika + di-push ke cloud)
  Future<WellnessLog> submitDailyCheckin({
    required String careReceiverId,
    required CheckinStatus status,
  }) async {
    final now = DateTime.now();
    final todayString = now.toIso8601String().split('T').first;

    final localLog = WellnessLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      careReceiverId: careReceiverId,
      checkDate: now,
      status: status,
      escalationStatus: EscalationStatus.resolved,
      respondedAt: now,
      createdAt: now,
    );

    // 1. Simpan ke cache lokal terlebih dahulu (Offline-First)
    await _localCacheService.saveTodayCheckin(localLog);

    if (!_supabaseService.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [WellnessRepository] Mode offline: Check-in diamankan di cache lokal (${status.label})');
      }
      return localLog;
    }

    // 2. Kirim ke Supabase jika online
    try {
      final dynamic response = await _client.from('wellness_logs').upsert({
        'care_receiver_id': careReceiverId,
        'check_date': todayString,
        'status': status.value,
        'escalation_status': EscalationStatus.resolved.value,
        'responded_at': now.toIso8601String(),
      }).select().maybeSingle();

      if (response != null && response is Map<String, dynamic>) {
        final cloudLog = WellnessLog.fromJson(response);
        await _localCacheService.saveTodayCheckin(cloudLog);
        return cloudLog;
      }
      return localLog;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [WellnessRepository] Gagal menyimpan check-in ke cloud, log lokal tetap aman: $e');
      }
      return localLog;
    }
  }

  /// 2. Mengambil catatan check-in hari ini (Cloud -> Cache Lokal)
  Future<WellnessLog?> getTodayCheckin(String careReceiverId) async {
    final now = DateTime.now();
    final todayString = now.toIso8601String().split('T').first;

    if (_supabaseService.isInitialized) {
      try {
        final dynamic response = await _client
            .from('wellness_logs')
            .select()
            .eq('care_receiver_id', careReceiverId)
            .eq('check_date', todayString)
            .maybeSingle();

        if (response != null && response is Map<String, dynamic>) {
          final log = WellnessLog.fromJson(response);
          await _localCacheService.saveTodayCheckin(log);
          return log;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [WellnessRepository] Supabase offline, membaca check-in dari cache lokal: $e');
        }
      }
    }

    // Baca dari cache lokal
    return await _localCacheService.getTodayCheckin(careReceiverId);
  }

  /// 3. Mengambil jadwal obat aktif lansia (Cloud -> Cache Lokal -> Fallback Mock)
  Future<List<MedicationSchedule>> getMedicationSchedules(String careReceiverId) async {
    final defaultMockSchedules = <MedicationSchedule>[
      MedicationSchedule(
        id: 'med-001',
        careReceiverId: careReceiverId,
        createdBy: 'guardian-001',
        medicationName: 'Amlodipine 5mg',
        dosage: '1 tablet sesudah makan',
        reminderTimes: const ['08:00'],
        isActive: true,
        isTakenToday: true,
        takenAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      MedicationSchedule(
        id: 'med-002',
        careReceiverId: careReceiverId,
        createdBy: 'guardian-001',
        medicationName: 'Metformin 500mg',
        dosage: '1 tablet bersama makan siang',
        reminderTimes: const ['12:30'],
        isActive: true,
        isTakenToday: false,
      ),
    ];

    // 1. Coba ambil dari cloud jika online
    if (_supabaseService.isInitialized) {
      try {
        // Sinkronisasikan antrian offline yang tertunda jika ada
        await syncPendingMedicationLogs();

        final dynamic response = await _client
            .from('medication_schedules')
            .select()
            .eq('care_receiver_id', careReceiverId)
            .eq('is_active', true);

        if (response is List && response.isNotEmpty) {
          final cloudList = response
              .map((dynamic item) => MedicationSchedule.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          await _localCacheService.saveMedicationSchedules(careReceiverId, cloudList);
          return cloudList;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [WellnessRepository] Supabase unreachable, memuat jadwal obat dari cache lokal: $e');
        }
      }
    }

    // 2. Muat dari cache lokal jika offline
    final cachedList = await _localCacheService.getMedicationSchedules(careReceiverId);
    if (cachedList != null && cachedList.isNotEmpty) {
      return cachedList;
    }

    // 3. Fallback mock dan simpan ke cache lokal
    await _localCacheService.saveMedicationSchedules(careReceiverId, defaultMockSchedules);
    return defaultMockSchedules;
  }

  /// 4. Konfirmasi konsumsi obat ("Sudah Diminum") oleh lansia
  Future<void> markMedicationTaken({
    required String scheduleId,
    required String careReceiverId,
  }) async {
    final now = DateTime.now();

    // 1. Catat seketika di cache lokal dan tandai antrean sinkronisasi
    await _localCacheService.recordOfflineMedicationTaken(
      scheduleId: scheduleId,
      careReceiverId: careReceiverId,
    );

    if (!_supabaseService.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [WellnessRepository] Konsumsi obat $scheduleId disimpan di cache offline.');
      }
      return;
    }

    // 2. Kirim ke Supabase jika online
    try {
      await _client.from('medication_logs').insert({
        'schedule_id': scheduleId,
        'care_receiver_id': careReceiverId,
        'scheduled_time': now.toIso8601String(),
        'taken_at': now.toIso8601String(),
        'skipped': false,
      });
      // Bersihkan antrian jika berhasil
      await _localCacheService.clearPendingMedicationLogs();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [WellnessRepository] Gagal kirim log obat ke cloud, tetap aman di antrian offline: $e');
      }
    }
  }

  /// 5. Sinkronisasi otomatis log obat yang tercatat saat offline ke Cloud
  Future<void> syncPendingMedicationLogs() async {
    if (!_supabaseService.isInitialized) return;

    final pending = await _localCacheService.getPendingMedicationLogs();
    if (pending.isEmpty) return;

    try {
      for (final item in pending) {
        await _client.from('medication_logs').insert({
          'schedule_id': item['schedule_id'],
          'care_receiver_id': item['care_receiver_id'],
          'scheduled_time': item['taken_at'],
          'taken_at': item['taken_at'],
          'skipped': false,
        });
      }
      await _localCacheService.clearPendingMedicationLogs();
      if (kDebugMode) {
        print('✅ [WellnessRepository] ${pending.length} log obat offline berhasil disinkronkan ke Cloud Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [WellnessRepository] Sinkronisasi log obat tertunda ditunda: $e');
      }
    }
  }
}

