import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Service untuk umpan balik multi-sensory (Audio + Haptic/Getaran)
/// Wajib digunakan pada setiap aksi kritis mode lansia (SOS, Konfirmasi Obat, Check-in).
class FeedbackService {
  FeedbackService._internal();
  static final FeedbackService instance = FeedbackService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Menggetarkan ponsel secara kontinu dengan pola darurat selama countdown SOS
  Future<void> triggerEmergencyVibration() async {
    try {
      final bool hasCustomVibrations = await Vibration.hasCustomVibrationsSupport();
      if (hasCustomVibrations) {
        // Pola getar berulang: getar 500ms, jeda 200ms
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      } else {
        await Vibration.vibrate(duration: 1000);
      }
    } catch (e) {
      // Fallback ke sistem haptic bawaan jika library getaran spesifik gagal
      await HapticFeedback.heavyImpact();
    }
  }

  /// Menghentikan getaran darurat seketika (saat user membatalkan SOS)
  Future<void> cancelVibration() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  /// Getaran ketukan konfirmasi biasa (berhasil check-in, minum obat)
  Future<void> triggerSuccessFeedback() async {
    await HapticFeedback.mediumImpact();
  }

  /// Getaran peringatan / salah
  Future<void> triggerWarningFeedback() async {
    await HapticFeedback.heavyImpact();
  }

  /// Memainkan nada konfirmasi audio
  Future<void> playAlertSound() async {
    try {
      // Nada sistem bawaan untuk kompatibilitas lintas platform
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FeedbackService] Audio feedback gagal dimainkan: $e');
      }
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

