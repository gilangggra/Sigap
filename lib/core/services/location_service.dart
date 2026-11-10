import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'supabase_service.dart';

/// Helper geolokasi terpusat untuk perizinan, pengambilan koordinat instan,
/// perhitungan radius PostGIS, dan pelacakan latar belakang (Standby Mode) relawan.
class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  bool _isStandbyTrackingActive = false;
  bool get isStandbyTrackingActive => _isStandbyTrackingActive;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _periodicFallbackTimer;
  Position? _lastSentPosition;
  Position? get lastStandbyPosition => _lastSentPosition;
  Position? get currentPosition => standbyPositionNotifier.value ?? _lastSentPosition;

  /// Notifier posisi siaga terkini untuk update UI relawan secara reaktif
  final ValueNotifier<Position?> standbyPositionNotifier = ValueNotifier<Position?>(null);

  /// 1. Memeriksa status izin lokasi perangkat
  Future<bool> checkPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) {
        print('⚠️ [LocationService] Layanan GPS perangkat dinonaktifkan.');
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// 2. Mengambil posisi terkini dengan timeout cepat (maks 4 detik)
  /// untuk mematuhi target SLA SOS dispatch <= 3 detik.
  Future<Position?> getCurrentPosition({bool fallbackToLastKnown = true}) async {
    final bool hasPermission = await checkPermission();
    if (!hasPermission) {
      if (fallbackToLastKnown) {
        return await Geolocator.getLastKnownPosition();
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocationService] GPS real-time gagal/timeout, beralih ke posisi terakhir: $e');
      }
      if (fallbackToLastKnown) {
        return await Geolocator.getLastKnownPosition();
      }
      return null;
    }
  }

  /// 3. Menghitung jarak lurus (meter) antara dua koordinat menggunakan algoritma Haversine
  double calculateDistanceMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 4. Memformat angka jarak ke string manusiawi ("250 m" atau "1.4 km")
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// 5. Stream pembaruan lokasi langsung untuk relawan yang sedang aktif
  Stream<Position> getPositionStream({
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  // ===========================================================================
  // 6. STANDBY TRACKING MODE (Latar Belakang Relawan Siaga)
  // ===========================================================================

  /// Mengaktifkan pelacakan berkala koordinat relawan saat toggle "Siaga" aktif.
  /// Koordinat disinkronkan ke tabel `profiles.last_known_location` Supabase
  /// agar fungsi PostGIS `dispatch_emergency()` selalu memiliki posisi akurat.
  Future<void> startStandbyTracking({
    required String responderId,
    int distanceFilterMeters = 30,
    Duration periodicInterval = const Duration(minutes: 5),
  }) async {
    if (_isStandbyTrackingActive) return;

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      if (kDebugMode) {
        print('⚠️ [LocationService] Izin lokasi ditolak, tracking siaga tidak dapat dimulai.');
      }
      return;
    }

    _isStandbyTrackingActive = true;
    if (kDebugMode) {
      print('🛰️ [LocationService] Mode Siaga Relawan diaktifkan: Memulai pelacakan berkala.');
    }

    // 1. Ambil dan kirim posisi awal seketika
    final initialPos = await getCurrentPosition();
    if (initialPos != null) {
      _lastSentPosition = initialPos;
      standbyPositionNotifier.value = initialPos;
      await syncLocationToCloud(
        responderId: responderId,
        latitude: initialPos.latitude,
        longitude: initialPos.longitude,
      );
    }

    // 2. Berlangganan stream perpindahan jarak signifikan (≥30m)
    _positionSubscription = getPositionStream(distanceFilter: distanceFilterMeters).listen(
      (Position newPos) async {
        if (!_isStandbyTrackingActive) return;
        _lastSentPosition = newPos;
        standbyPositionNotifier.value = newPos;
        await syncLocationToCloud(
          responderId: responderId,
          latitude: newPos.latitude,
          longitude: newPos.longitude,
        );
      },
      onError: (dynamic error) {
        if (kDebugMode) {
          print('⚠️ [LocationService] Error pada stream posisi siaga: $error');
        }
      },
    );

    // 3. Timer cadangan berkala (setiap 5 menit) untuk memperbarui timestamp siaga
    _periodicFallbackTimer = Timer.periodic(periodicInterval, (timer) async {
      if (!_isStandbyTrackingActive) {
        timer.cancel();
        return;
      }
      final current = await getCurrentPosition();
      if (current != null) {
        _lastSentPosition = current;
        standbyPositionNotifier.value = current;
        await syncLocationToCloud(
          responderId: responderId,
          latitude: current.latitude,
          longitude: current.longitude,
        );
      }
    });
  }

  /// Menonaktifkan pelacakan siaga saat relawan beralih ke mode "Istirahat" (Offline).
  /// Menghapus koordinat terakhir dari cloud demi privasi relawan saat tidak bertugas.
  Future<void> stopStandbyTracking({
    required String responderId,
    bool clearCloudLocation = true,
  }) async {
    _isStandbyTrackingActive = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _periodicFallbackTimer?.cancel();
    _periodicFallbackTimer = null;
    standbyPositionNotifier.value = null;

    if (kDebugMode) {
      print('🛑 [LocationService] Mode Siaga Relawan dinonaktifkan: Pelacakan dihentikan.');
    }

    if (clearCloudLocation) {
      await clearLocationFromCloud(responderId);
    }
  }

  /// Mengunggah koordinat PostGIS `POINT(lng lat)` ke Supabase `profiles`
  Future<void> syncLocationToCloud({
    required String responderId,
    required double latitude,
    required double longitude,
  }) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [LocationService] Mode offline: Koordinat siaga ($latitude, $longitude) dicatat lokal.');
      }
      return;
    }

    try {
      final pointWkt = 'POINT($longitude $latitude)';
      await supabase.client.from('profiles').update({
        'last_known_location': pointWkt,
        'last_location_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', responderId);

      if (kDebugMode) {
        print('📍 [LocationService] Koordinat siaga relawan disinkronkan ke PostGIS: $pointWkt');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocationService] Gagal update lokasi ke database Supabase: $e');
      }
    }
  }

  /// Menghapus lokasi dari Supabase saat relawan offline demi menjaga privasi
  Future<void> clearLocationFromCloud(String responderId) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) return;

    try {
      await supabase.client.from('profiles').update({
        'last_known_location': null,
        'last_location_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', responderId);

      if (kDebugMode) {
        print('🔒 [LocationService] Lokasi relawan di cloud berhasil dibersihkan (Offline Privacy).');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LocationService] Gagal menghapus lokasi offline di cloud: $e');
      }
    }
  }
}
