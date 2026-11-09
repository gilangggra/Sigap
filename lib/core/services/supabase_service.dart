import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service untuk inisialisasi dan interaksi terpusat dengan backend Supabase.
/// Memastikan semua panggilan RPC PostGIS dan autentikasi menggunakan konfigurasi seragam.
class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Helper akses autentikasi
  GoTrueClient get auth => client.auth;

  /// Mengambil user yang sedang aktif
  User? get currentUser => auth.currentUser;

  /// Mengambil session yang sedang aktif
  Session? get currentSession => auth.currentSession;

  /// Status apakah user sedang login
  bool get isAuthenticated => currentUser != null;

  /// Inisialisasi koneksi Supabase
  Future<void> initialize() async {
    if (_isInitialized) return;

    final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://placeholder.supabase.co';
    final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'placeholder-anon-key';

    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 10,
        ),
      );
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ [SupabaseService] Berhasil terhubung ke Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [SupabaseService] Inisialisasi menggunakan fallback/mock mode: $e');
      }
      _isInitialized = false;
    }
  }

  /// Sign out dari sesi aktif
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SupabaseService] Error saat sign out: $e');
      }
      rethrow;
    }
  }

  // ===========================================================================
  // STORED FUNCTIONS / RPC GEOSPASIAL & POSTGIS WRAPPERS
  // ===========================================================================

  /// Pemicu darurat: Memanggil stored function PostGIS `dispatch_emergency`
  /// Menghitung relawan terdekat dalam radius 500m (ekspansi ke 800m jika < 3)
  Future<Map<String, dynamic>> dispatchEmergency({
    required String careReceiverId,
    required double latitude,
    required double longitude,
    bool gpsApproximate = false,
  }) async {
    final dynamic response = await client.rpc<dynamic>(
      'dispatch_emergency',
      params: {
        'p_care_receiver_id': careReceiverId,
        'p_lat': latitude,
        'p_lng': longitude,
        'p_gps_approximate': gpsApproximate,
      },
    );

    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    return <String, dynamic>{'incident_id': null, 'nearby_responders': <dynamic>[]};
  }

  /// Responder Lock: Mengunci penanganan insiden oleh relawan pertama (optimistic lock)
  Future<bool> lockIncident({
    required String incidentId,
    required String responderId,
  }) async {
    final dynamic response = await client.rpc<dynamic>(
      'lock_incident',
      params: {
        'p_incident_id': incidentId,
        'p_responder_id': responderId,
      },
    );

    return response == true;
  }

  /// Validasi Token Darurat untuk membuka data medis ICE Card
  Future<String?> validateEmergencyToken({
    required String token,
    required String responderId,
  }) async {
    final dynamic response = await client.rpc<dynamic>(
      'validate_emergency_token',
      params: {
        'p_token': token,
        'p_responder_id': responderId,
      },
    );

    return response as String?;
  }

  /// Mengambil daftar tugas bantuan mikro terdekat berdasarkan geolokasi relawan
  Future<List<Map<String, dynamic>>> getNearbyTasks({
    required String responderId,
    int radiusMeters = 800,
  }) async {
    final dynamic response = await client.rpc<dynamic>(
      'get_nearby_tasks',
      params: {
        'p_responder_id': responderId,
        'p_radius_meters': radiusMeters,
      },
    );

    if (response is List) {
      return response.map((dynamic item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return <Map<String, dynamic>>[];
  }
}
