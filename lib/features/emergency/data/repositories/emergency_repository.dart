import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/sms_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/incident.dart';

/// Repository untuk penanganan orkestrasi panggilan darurat (Emergency Dispatch),
/// klaim insiden oleh responder, dan resolusi laporan.
class EmergencyRepository {
  final SupabaseService _supabaseService;

  EmergencyRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// 1. Memicu Alarm Darurat SOS (Dispatched)
  /// Memanggil stored function PostGIS untuk mencari 5 relawan terdekat dalam radius 500m-800m.
  /// Jika koneksi offline, otomatis memicu SMS fallback darurat.
  Future<Incident> dispatchEmergency({
    required String careReceiverId,
    required double latitude,
    required double longitude,
    bool gpsApproximate = false,
    String? senderName,
    String? emergencyContactNumber,
  }) async {
    final String incidentId = 'inc-${DateTime.now().millisecondsSinceEpoch}';

    // Fallback SMS jika backend belum terkoneksi / offline
    if (!_supabaseService.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [EmergencyRepository] Mode offline/demo: Mengaktifkan SMS Fallback');
      }

      final smsBody = SmsService.instance.buildEmergencyMessage(
        senderName: senderName ?? 'Lansia SIGAP',
        latitude: latitude,
        longitude: longitude,
      );

      await SmsService.instance.sendEmergencySms(
        recipientPhoneNumber: emergencyContactNumber ?? '+62811000000',
        message: smsBody,
      );

      return Incident(
        id: incidentId,
        careReceiverId: careReceiverId,
        careReceiverName: senderName ?? 'Lansia SIGAP',
        latitude: latitude,
        longitude: longitude,
        gpsApproximate: gpsApproximate,
        status: IncidentStatus.dispatched,
        smsSent: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      final response = await _supabaseService.dispatchEmergency(
        careReceiverId: careReceiverId,
        latitude: latitude,
        longitude: longitude,
        gpsApproximate: gpsApproximate,
      );

      final returnedId = response['incident_id'] as String? ?? incidentId;

      return Incident(
        id: returnedId,
        careReceiverId: careReceiverId,
        careReceiverName: senderName ?? 'Lansia SIGAP',
        latitude: latitude,
        longitude: longitude,
        gpsApproximate: gpsApproximate,
        status: IncidentStatus.dispatched,
        smsSent: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [EmergencyRepository] RPC error, mengalihkan ke SMS fallback: $e');
      }

      await SmsService.instance.sendEmergencySms(
        recipientPhoneNumber: emergencyContactNumber ?? '+62811000000',
        message: SmsService.instance.buildEmergencyMessage(
          senderName: senderName ?? 'Lansia SIGAP',
          latitude: latitude,
          longitude: longitude,
        ),
      );

      return Incident(
        id: incidentId,
        careReceiverId: careReceiverId,
        careReceiverName: senderName ?? 'Lansia SIGAP',
        latitude: latitude,
        longitude: longitude,
        gpsApproximate: gpsApproximate,
        status: IncidentStatus.dispatched,
        smsSent: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// 2. Responder Lock: Mengunci penanganan insiden ("Saya Meluncur")
  Future<bool> lockIncident({
    required String incidentId,
    required String responderId,
  }) async {
    if (!_supabaseService.isInitialized ||
        _supabaseService.currentUser == null ||
        !AppConstants.isValidUuid(incidentId) ||
        !AppConstants.isValidUuid(responderId)) {
      if (kDebugMode) {
        print('ℹ️ [EmergencyRepository] Mode simulasi/demo aktif: Lock incident $incidentId oleh $responderId');
      }
      return true;
    }

    try {
      return await _supabaseService.lockIncident(
        incidentId: incidentId,
        responderId: responderId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [EmergencyRepository] Gagal mengunci insiden: $e');
      }
      return false;
    }
  }

  /// 3. Resolusi Insiden: Menandai selesai dan mencatat catatan penanganan
  Future<bool> resolveIncident({
    required String incidentId,
    required String resolvedBy,
    required String resolutionNotes,
  }) async {
    if (!_supabaseService.isInitialized ||
        _supabaseService.currentUser == null ||
        !AppConstants.isValidUuid(incidentId) ||
        !AppConstants.isValidUuid(resolvedBy)) {
      if (kDebugMode) {
        print('ℹ️ [EmergencyRepository] Mode simulasi/demo aktif: Resolve incident $incidentId');
      }
      return true;
    }

    try {
      await _client.from('incidents').update({
        'status': IncidentStatus.resolved.value,
        'resolved_at': DateTime.now().toIso8601String(),
        'resolved_by': resolvedBy,
        'resolution_notes': resolutionNotes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', incidentId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [EmergencyRepository] Gagal menyelesaikan insiden: $e');
      }
      return false;
    }
  }

  /// 4. Pembatalan Insiden oleh Korban (dalam masa countdown / darurat palsu)
  Future<void> cancelIncident(String incidentId) async {
    if (!_supabaseService.isInitialized ||
        _supabaseService.currentUser == null ||
        !AppConstants.isValidUuid(incidentId)) {
      if (kDebugMode) {
        print('ℹ️ [EmergencyRepository] Mode simulasi/demo aktif: Cancel incident $incidentId');
      }
      return;
    }

    try {
      await _client.from('incidents').update({
        'status': IncidentStatus.cancelled.value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', incidentId);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [EmergencyRepository] Gagal membatalkan insiden di database: $e');
      }
    }
  }

  /// 5. Mengambil daftar insiden aktif di sekitar relawan
  Future<List<Incident>> getNearbyActiveIncidents({
    required double latitude,
    required double longitude,
    double radiusMeters = 500.0,
  }) async {
    final mockIncident = Incident(
      id: 'inc-001',
      careReceiverId: 'victim-001',
      careReceiverName: 'Ibu Aminah (71 thn)',
      careReceiverPhone: '+628123456789',
      latitude: latitude + 0.002,
      longitude: longitude + 0.002,
      address: 'Jl. Kenanga No. 14, RT 03 / RW 05',
      status: IncidentStatus.dispatched,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      updatedAt: DateTime.now(),
    );

    if (!_supabaseService.isInitialized) {
      return [mockIncident];
    }

    try {
      final dynamic response = await _client
          .from('incidents')
          .select()
          .inFilter('status', [IncidentStatus.dispatched.value, IncidentStatus.responding.value])
          .order('created_at', ascending: false);

      if (response is List) {
        final list = response
            .map((dynamic item) => Incident.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        // Filter berdasarkan jarak radius menggunakan helper LocationService
        return list.where((inc) {
          final distance = LocationService.instance.calculateDistanceMeters(
            startLatitude: latitude,
            startLongitude: longitude,
            endLatitude: inc.latitude,
            endLongitude: inc.longitude,
          );
          return distance <= radiusMeters;
        }).toList();
      }

      return <Incident>[];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [EmergencyRepository] Gagal mengambil insiden aktif: $e');
      }
      return <Incident>[];
    }
  }
}

