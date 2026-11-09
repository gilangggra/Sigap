import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/medication_schedule.dart';
import '../../domain/models/wellness_log.dart';

/// Repository pengelola rekaman kesehatan harian (Check-in, Dead-Man Switch, dan Kepatuhan Obat).
class WellnessRepository {
  final SupabaseService _supabaseService;

  WellnessRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// 1. Mencatat respons check-in harian lansia
  Future<WellnessLog> submitDailyCheckin({
    required String careReceiverId,
    required CheckinStatus status,
  }) async {
    final now = DateTime.now();
    final todayString = now.toIso8601String().split('T').first;

    final mockLog = WellnessLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      careReceiverId: careReceiverId,
      checkDate: now,
      status: status,
      escalationStatus: EscalationStatus.resolved,
      respondedAt: now,
      createdAt: now,
    );

    if (!_supabaseService.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [WellnessRepository] Mode demo: Check-in dicatat lokal (${status.label})');
      }
      return mockLog;
    }

    try {
      final dynamic response = await _client.from('wellness_logs').upsert({
        'care_receiver_id': careReceiverId,
        'check_date': todayString,
        'status': status.value,
        'escalation_status': EscalationStatus.resolved.value,
        'responded_at': now.toIso8601String(),
      }).select().maybeSingle();

      if (response != null && response is Map<String, dynamic>) {
        return WellnessLog.fromJson(response);
      }
      return mockLog;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [WellnessRepository] Gagal menyimpan check-in ke cloud: $e');
      }
      return mockLog;
    }
  }

  /// 2. Mengambil catatan check-in hari ini
  Future<WellnessLog?> getTodayCheckin(String careReceiverId) async {
    final now = DateTime.now();
    final todayString = now.toIso8601String().split('T').first;

    if (!_supabaseService.isInitialized) {
      return null;
    }

    try {
      final dynamic response = await _client
          .from('wellness_logs')
          .select()
          .eq('care_receiver_id', careReceiverId)
          .eq('check_date', todayString)
          .maybeSingle();

      if (response != null && response is Map<String, dynamic>) {
        return WellnessLog.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [WellnessRepository] Gagal mengambil log check-in: $e');
      }
      return null;
    }
  }

  /// 3. Mengambil jadwal obat aktif lansia
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

    if (!_supabaseService.isInitialized) {
      return defaultMockSchedules;
    }

    try {
      final dynamic response = await _client
          .from('medication_schedules')
          .select()
          .eq('care_receiver_id', careReceiverId)
          .eq('is_active', true);

      if (response is List && response.isNotEmpty) {
        return response
            .map((dynamic item) => MedicationSchedule.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return defaultMockSchedules;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [WellnessRepository] Menggunakan jadwal obat fallback: $e');
      }
      return defaultMockSchedules;
    }
  }

  /// 4. Konfirmasi konsumsi obat ("Sudah Diminum") oleh lansia
  Future<void> markMedicationTaken({
    required String scheduleId,
    required String careReceiverId,
  }) async {
    final now = DateTime.now();

    if (!_supabaseService.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [WellnessRepository] Konsumsi obat $scheduleId dicatat berhasil (Lokal)');
      }
      return;
    }

    try {
      await _client.from('medication_logs').insert({
        'schedule_id': scheduleId,
        'care_receiver_id': careReceiverId,
        'scheduled_time': now.toIso8601String(),
        'taken_at': now.toIso8601String(),
        'skipped': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WellnessRepository] Gagal mencatat log obat: $e');
      }
      rethrow;
    }
  }
}
