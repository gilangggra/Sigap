import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/profile/domain/models/ice_card.dart';
import '../../features/wellness/domain/models/medication_schedule.dart';
import '../../features/wellness/domain/models/wellness_log.dart';

/// Layanan penyimpanan cache lokal aman (Offline-First Secure Cache).
/// Menggunakan `flutter_secure_storage` untuk data medis sensitif (ICE Card)
/// dan `shared_preferences` untuk antrian sinkronisasi offline.
class LocalCacheService {
  LocalCacheService._internal();
  static final LocalCacheService instance = LocalCacheService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyIceCardPrefix = 'sigap_ice_card_';
  static const String _keyMedSchedulesPrefix = 'sigap_med_schedules_';
  static const String _keyWellnessCheckinPrefix = 'sigap_wellness_checkin_';
  static const String _keyPendingMedLogs = 'sigap_pending_med_logs';
  static const String _keyPendingCheckinLogs = 'sigap_pending_checkin_logs';

  // ===========================================================================
  // 1. DATA MEDIS DARURAT (ICE CARD) — CACHE TERENKRIPSI
  // ===========================================================================

  /// Menyimpan data ICE Card ke secure storage lokal
  Future<void> saveIceCard(IceCard iceCard) async {
    try {
      final jsonString = jsonEncode(iceCard.toJson());
      await _secureStorage.write(
        key: '$_keyIceCardPrefix${iceCard.careReceiverId}',
        value: jsonString,
      );
      if (kDebugMode) {
        print('🔒 [LocalCacheService] ICE Card berhasil disimpan di secure cache lokal (${iceCard.careReceiverId})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocalCacheService] Gagal menyimpan ICE Card ke secure cache: $e');
      }
    }
  }

  /// Mengambil data ICE Card dari secure storage lokal
  Future<IceCard?> getIceCard(String careReceiverId) async {
    try {
      final jsonString = await _secureStorage.read(
        key: '$_keyIceCardPrefix$careReceiverId',
      );
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
        return IceCard.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocalCacheService] Gagal membaca ICE Card dari cache: $e');
      }
    }
    return null;
  }

  // ===========================================================================
  // 2. JADWAL OBAT & STATUS KONSUMSI LANSIA
  // ===========================================================================

  /// Menyimpan daftar jadwal obat aktif ke cache lokal
  Future<void> saveMedicationSchedules(String careReceiverId, List<MedicationSchedule> schedules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = schedules.map((s) => s.toJson()).toList();
      await prefs.setString('$_keyMedSchedulesPrefix$careReceiverId', jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocalCacheService] Gagal menyimpan jadwal obat lokal: $e');
      }
    }
  }

  /// Mengambil jadwal obat aktif dari cache lokal
  Future<List<MedicationSchedule>?> getMedicationSchedules(String careReceiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_keyMedSchedulesPrefix$careReceiverId');
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
        return list
            .map((item) => MedicationSchedule.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocalCacheService] Gagal membaca jadwal obat dari cache: $e');
      }
    }
    return null;
  }

  /// Menandai obat sudah diminum di cache lokal dan mencatat ke antrian sinkronisasi offline
  Future<void> recordOfflineMedicationTaken({
    required String scheduleId,
    required String careReceiverId,
  }) async {
    try {
      // 1. Perbarui status jadwal lokal
      final schedules = await getMedicationSchedules(careReceiverId);
      if (schedules != null) {
        final updatedList = schedules.map((s) {
          if (s.id == scheduleId) {
            return s.copyWith(
              isTakenToday: true,
              takenAt: DateTime.now(),
            );
          }
          return s;
        }).toList();
        await saveMedicationSchedules(careReceiverId, updatedList);
      }

      // 2. Catat ke antrean sinkronisasi
      final prefs = await SharedPreferences.getInstance();
      final pendingRaw = prefs.getString(_keyPendingMedLogs);
      final List<dynamic> pendingList = pendingRaw != null ? jsonDecode(pendingRaw) as List<dynamic> : [];

      pendingList.add({
        'schedule_id': scheduleId,
        'care_receiver_id': careReceiverId,
        'taken_at': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_keyPendingMedLogs, jsonEncode(pendingList));
      if (kDebugMode) {
        print('📥 [LocalCacheService] Konsumsi obat $scheduleId diantrikan untuk sinkronisasi cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocalCacheService] Gagal mencatat konsumsi obat offline: $e');
      }
    }
  }

  /// Mengambil antrean log obat yang belum tersinkronisasi ke cloud
  Future<List<Map<String, dynamic>>> getPendingMedicationLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyPendingMedLogs);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Menghapus antrean log obat setelah berhasil disinkronisasi ke Supabase
  Future<void> clearPendingMedicationLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingMedLogs);
    } catch (_) {}
  }

  // ===========================================================================
  // 3. LOG CHECK-IN HARIAN (DEAD-MAN SWITCH CACHE)
  // ===========================================================================

  /// Menyimpan log respons check-in hari ini ke cache lokal
  Future<void> saveTodayCheckin(WellnessLog log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = '$_keyWellnessCheckinPrefix${log.careReceiverId}_${log.checkDate.toIso8601String().split('T').first}';
      await prefs.setString(todayKey, jsonEncode(log.toJson()));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocalCacheService] Gagal menyimpan check-in harian lokal: $e');
      }
    }
  }

  /// Mengambil log respons check-in hari ini dari cache lokal
  Future<WellnessLog?> getTodayCheckin(String careReceiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T').first;
      final todayKey = '$_keyWellnessCheckinPrefix${careReceiverId}_$today';
      final raw = prefs.getString(todayKey);
      if (raw != null && raw.isNotEmpty) {
        return WellnessLog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Mencatat respons check-in ke antrean sinkronisasi offline (jika gagal tersambung ke Cloud)
  Future<void> recordOfflineCheckin(WellnessLog log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyPendingCheckinLogs);
      final List<dynamic> list = raw != null ? jsonDecode(raw) as List<dynamic> : [];
      list.add(log.toJson());
      await prefs.setString(_keyPendingCheckinLogs, jsonEncode(list));
      if (kDebugMode) {
        print('📥 [LocalCacheService] Check-in (${log.status?.label ?? "Respons Sehat"}) diantrikan untuk sinkronisasi cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocalCacheService] Gagal mengantrikan check-in offline: $e');
      }
    }
  }

  /// Mengambil daftar check-in tertunda yang perlu disinkronkan ke Supabase
  Future<List<Map<String, dynamic>>> getPendingCheckins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyPendingCheckinLogs);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Menghapus antrean check-in setelah berhasil disinkronkan ke Cloud
  Future<void> clearPendingCheckins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingCheckinLogs);
    } catch (_) {}
  }
}

