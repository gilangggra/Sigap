import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service untuk fallback SMS otomatis ketika tidak ada koneksi internet.
/// Mengirimkan pesan darurat berformat koordinat GPS dan tautan Google Maps.
class SmsService {
  SmsService._internal();
  static final SmsService instance = SmsService._internal();

  /// Menyiapkan teks pesan darurat sesuai standar PRD F1.6
  String buildEmergencyMessage({
    required String senderName,
    required double latitude,
    required double longitude,
    String? address,
  }) {
    final String mapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';
    return '[DARURAT SIGAP]\n'
        '$senderName membutuhkan bantuan darurat segera!\n'
        'Lokasi: ${address ?? "Koordinat ($latitude, $longitude)"}\n'
        'Peta: $mapsUrl';
  }

  /// Membuka aplikasi SMS dengan nomor tujuan dan pesan darurat yang telah diisi otomatis
  Future<bool> sendEmergencySms({
    required String recipientPhoneNumber,
    required String message,
  }) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: recipientPhoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri);
      } else {
        if (kDebugMode) {
          print('❌ [SmsService] Tidak dapat membuka intent SMS untuk nomor: $recipientPhoneNumber');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SmsService] Gagal memicu SMS fallback: $e');
      }
      return false;
    }
  }
}

