import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Helper geolokasi terpusat untuk perizinan, pengambilan koordinat instan,
/// dan perhitungan radius jarak PostGIS/geofencing.
class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  /// Memeriksa status izin lokasi perangkat
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

  /// Mengambil posisi terkini dengan timeout cepat (maks 5 detik)
  /// untuk mematuhi target SLA SOS dispatch <= 3 detik.
  /// Jika gagal mendapatkan sinyal GPS akurat, otomatis fallback ke [getLastKnownPosition].
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

  /// Menghitung jarak lurus (meter) antara dua koordinat menggunakan algoritma Haversine
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

  /// Memformat angka jarak ke string manusiawi ("250 m" atau "1.4 km")
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Stream pembaruan lokasi langsung untuk relawan yang sedang aktif
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
}

