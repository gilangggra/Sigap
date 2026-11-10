import 'dart:async';
import 'package:flutter/foundation.dart';
import 'feedback_service.dart';

/// Status siklus pengawasan pada fitur Cek Keselamatan Perjalanan (Walk-Safe Timer)
enum SafetyCheckStatus {
  idle,
  active,
  verificationPrompt,
  preAlarmTriggered,
  sosDispatched,
}

/// Service Cek Keselamatan Perjalanan Berwaktu (Safety Check / Walk-Safe Timer).
/// Mengadopsi standar Google Personal Safety "Safety Check" & Apple Watch Emergency Check-In.
/// Memungkinkan lansia mengatur batas waktu perjalanan (misal 15, 30, atau 45 menit).
/// Jika waktu habis tanpa konfirmasi "Saya Sudah Sampai", sistem otomatis memicu SOS darurat.
class SafetyCheckService {
  SafetyCheckService._internal();
  static final SafetyCheckService instance = SafetyCheckService._internal();

  SafetyCheckStatus _status = SafetyCheckStatus.idle;
  SafetyCheckStatus get status => _status;
  bool get isActive => _status != SafetyCheckStatus.idle;

  int _secondsRemaining = 0;
  int get secondsRemaining => _secondsRemaining;

  int _totalDurationSeconds = 0;
  int get totalDurationSeconds => _totalDurationSeconds;

  int _preAlarmSecondsRemaining = 15;
  int get preAlarmSecondsRemaining => _preAlarmSecondsRemaining;

  Timer? _countdownTimer;
  Timer? _preAlarmTimer;
  VoidCallback? _onEmergencyTriggered;

  /// Notifier status untuk antarmuka pengguna reaktif
  final ValueNotifier<SafetyCheckStatus> statusNotifier =
      ValueNotifier<SafetyCheckStatus>(SafetyCheckStatus.idle);

  /// Notifier detik tersisa hitung mundur perjalanan
  final ValueNotifier<int> secondsRemainingNotifier = ValueNotifier<int>(0);

  /// Notifier detik tersisa pre-alarm verifikasi darurat
  final ValueNotifier<int> preAlarmSecondsNotifier = ValueNotifier<int>(15);

  /// 1. Memulai Pengawasan Perjalanan Aman (Durasi dalam Menit)
  void startSafetyCheck({
    required int durationMinutes,
    required VoidCallback onEmergencyTriggered,
  }) {
    cancelSafetyCheck();

    _onEmergencyTriggered = onEmergencyTriggered;
    _totalDurationSeconds = durationMinutes * 60;
    _secondsRemaining = _totalDurationSeconds;
    _status = SafetyCheckStatus.active;
    statusNotifier.value = SafetyCheckStatus.active;
    secondsRemainingNotifier.value = _secondsRemaining;

    unawaited(FeedbackService.instance.triggerSuccessFeedback());

    if (kDebugMode) {
      print('🚶 [SafetyCheckService] Memulai pengawasan perjalanan: $durationMinutes menit.');
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        secondsRemainingNotifier.value = _secondsRemaining;

        // Saat tersisa 60 detik, beri getaran & suara pengingat ramah
        if (_secondsRemaining == 60) {
          _status = SafetyCheckStatus.verificationPrompt;
          statusNotifier.value = SafetyCheckStatus.verificationPrompt;
          unawaited(FeedbackService.instance.playAlertSound());
          unawaited(FeedbackService.instance.triggerCountdownHaptic());
        }
      } else {
        // Waktu perjalanan habis! Picu fase Pre-Alarm 15 detik
        timer.cancel();
        _triggerPreAlarm();
      }
    });
  }

  /// 2. Pemicuan Fase Pre-Alarm (Buffer 15 Detik Sebelum SOS Dikirim ke Relawan)
  void _triggerPreAlarm() {
    _status = SafetyCheckStatus.preAlarmTriggered;
    statusNotifier.value = SafetyCheckStatus.preAlarmTriggered;
    _preAlarmSecondsRemaining = 15;
    preAlarmSecondsNotifier.value = 15;

    unawaited(FeedbackService.instance.triggerEmergencyVibration());

    if (kDebugMode) {
      print('⚠️ [SafetyCheckService] Waktu perjalanan habis! Memulai pre-alarm 15 detik...');
    }

    _preAlarmTimer?.cancel();
    _preAlarmTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_preAlarmSecondsRemaining > 1) {
        _preAlarmSecondsRemaining--;
        preAlarmSecondsNotifier.value = _preAlarmSecondsRemaining;
        unawaited(FeedbackService.instance.triggerEmergencyVibration());
      } else {
        // Pre-alarm habis tanpa konfirmasi -> Otomatis kirim SOS
        timer.cancel();
        _dispatchSosEmergency();
      }
    });
  }

  /// 3. Pengiriman Panggilan Darurat Otomatis ke Jaringan Relawan & Keluarga
  void _dispatchSosEmergency() {
    _status = SafetyCheckStatus.sosDispatched;
    statusNotifier.value = SafetyCheckStatus.sosDispatched;

    unawaited(FeedbackService.instance.cancelVibration());

    if (kDebugMode) {
      print('🚨 [SafetyCheckService] Waktu habis tanpa konfirmasi! Mengirimkan panggilan SOS.');
    }

    _onEmergencyTriggered?.call();
    cancelSafetyCheck();
  }

  /// 4. Konfirmasi Aman oleh Lansia ("Saya Sudah Sampai di Rumah")
  void confirmSafe() {
    if (!isActive) return;

    unawaited(FeedbackService.instance.cancelVibration());
    unawaited(FeedbackService.instance.triggerSuccessFeedback());

    if (kDebugMode) {
      print('✅ [SafetyCheckService] Pengguna mengonfirmasi aman. Pengawasan perjalanan selesai.');
    }

    cancelSafetyCheck();
  }

  /// 5. Menambahkan Durasi Perjalanan (+15 Menit)
  void extendDuration({int additionalMinutes = 15}) {
    if (!isActive) return;

    _preAlarmTimer?.cancel();
    unawaited(FeedbackService.instance.cancelVibration());
    unawaited(FeedbackService.instance.triggerSuccessFeedback());

    _secondsRemaining += additionalMinutes * 60;
    _totalDurationSeconds += additionalMinutes * 60;
    secondsRemainingNotifier.value = _secondsRemaining;

    _status = SafetyCheckStatus.active;
    statusNotifier.value = SafetyCheckStatus.active;

    if (kDebugMode) {
      print('⏱️ [SafetyCheckService] Durasi diperpanjang +$additionalMinutes menit.');
    }

    // Lanjutkan timer jika sebelumnya sempat terhenti di pre-alarm
    if (_countdownTimer == null || !_countdownTimer!.isActive) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
          secondsRemainingNotifier.value = _secondsRemaining;
        } else {
          timer.cancel();
          _triggerPreAlarm();
        }
      });
    }
  }

  /// 6. Membatalkan Sesi Pengawasan
  void cancelSafetyCheck() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _preAlarmTimer?.cancel();
    _preAlarmTimer = null;

    unawaited(FeedbackService.instance.cancelVibration());

    _secondsRemaining = 0;
    _totalDurationSeconds = 0;
    _preAlarmSecondsRemaining = 15;
    _status = SafetyCheckStatus.idle;

    statusNotifier.value = SafetyCheckStatus.idle;
    secondsRemainingNotifier.value = 0;
    preAlarmSecondsNotifier.value = 15;
  }

  /// Helper untuk memformat detik ke string digital "MM:SS"
  static String formatSecondsToMinutes(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String minStr = minutes.toString().padLeft(2, '0');
    final String secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }
}
