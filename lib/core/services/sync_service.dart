import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../features/wellness/data/repositories/wellness_repository.dart';

/// Service Sinkronisasi Otomatis Data Offline-ke-Cloud (Autonomous Network Sync).
/// Memantau perubahan konektivitas jaringan (Wi-Fi, Seluler, Offline) secara real-time.
/// Ketika perangkat pulih dari kondisi offline, antrean obat dan check-in lansia
/// disinkronkan secara otomatis ke Supabase tanpa perlu intervensi manual.
class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  final WellnessRepository _wellnessRepository = WellnessRepository.instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isInitialized = false;

  /// Notifier status jaringan real-time
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  /// Notifier proses sinkronisasi background yang sedang aktif
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  /// Stempel waktu sinkronisasi terakhir yang berhasil
  final ValueNotifier<DateTime?> lastSyncTimeNotifier = ValueNotifier<DateTime?>(null);

  bool get isOnline => isOnlineNotifier.value;
  bool get isSyncing => isSyncingNotifier.value;

  /// 1. Inisialisasi Listener Konektivitas Jaringan
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Periksa status konektivitas awal
    try {
      final initialResults = await _connectivity.checkConnectivity();
      _handleConnectivityChange(initialResults);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [SyncService] Gagal memeriksa konektivitas awal: $e');
      }
    }

    // Dengarkan perubahan konektivitas jaringan
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (Object error) {
        if (kDebugMode) {
          print('⚠️ [SyncService] Error pada stream konektivitas: $error');
        }
      },
    );

    if (kDebugMode) {
      print('🌐 [SyncService] Autonomous Sync Manager aktif.');
    }
  }

  /// 2. Handler Perubahan Status Konektivitas
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final bool wasOnline = isOnlineNotifier.value;
    final bool currentlyOnline = results.any(
      (result) => result != ConnectivityResult.none,
    );

    isOnlineNotifier.value = currentlyOnline;

    if (kDebugMode) {
      print('📶 [SyncService] Status Jaringan: ${currentlyOnline ? "ONLINE" : "OFFLINE"} ($results)');
    }

    // Jika beralih dari OFFLINE ke ONLINE, picu sinkronisasi data otomatis
    if (!wasOnline && currentlyOnline) {
      if (kDebugMode) {
        print('🔄 [SyncService] Koneksi internet pulih! Menjalankan sinkronisasi antrean data...');
      }
      unawaited(syncPendingData());
    }
  }

  /// 3. Eksekusi Sinkronisasi Seluruh Data Tertunda (Medikasi & Check-in)
  Future<void> syncPendingData() async {
    if (!isOnlineNotifier.value || isSyncingNotifier.value) return;

    isSyncingNotifier.value = true;
    try {
      // 1. Sinkronisasi antrean log obat
      await _wellnessRepository.syncPendingMedicationLogs();

      // 2. Sinkronisasi antrean respons check-in lansia
      await _wellnessRepository.syncPendingCheckins();

      lastSyncTimeNotifier.value = DateTime.now();

      if (kDebugMode) {
        print('✅ [SyncService] Seluruh data offline berhasil disinkronkan ke Supabase Cloud.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SyncService] Gagal menjalankan sinkronisasi data: $e');
      }
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// 4. Pemicuan Sinkronisasi Manual (misal saat Pull-to-Refresh)
  Future<void> triggerManualSync() async {
    await syncPendingData();
  }

  /// 5. Pembersihan resource
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
  }
}

