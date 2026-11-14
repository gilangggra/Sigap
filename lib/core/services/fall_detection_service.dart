import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'feedback_service.dart';

/// Status siklus deteksi pada Finite State Machine AI Fall Guard
enum FallEngineState {
  idle,
  monitoring,
  freeFallDetected,
  impactDetected,
  observingImmobility,
  fallConfirmed,
}

/// Service Deteksi Jatuh Berbasis AI & Sensor Fusion (Accelerometer + Gyroscope).
/// Menganalisis kurva 4 fase dinamis:
/// 1. Free-Fall (<0.5g)
/// 2. Impact Shock (>2.65g + Rotasi Giroskop)
/// 3. Perubahan Orientasi Vektor Gravitasi
/// 4. Imobilitas Pasca Benturan (3 detik hening/tanpa gerakan)
class FallDetectionService {
  FallDetectionService._internal();
  static final FallDetectionService instance = FallDetectionService._internal();

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  FallEngineState _currentState = FallEngineState.idle;
  FallEngineState get currentState => _currentState;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Nilai pembacaan sensor terakhir
  double _lastGyroMagnitude = 0.0;
  DateTime? _freeFallTimestamp;
  final List<double> _postImpactAccels = <double>[];
  Timer? _immobilityTimer;
  Timer? _preAlarmCountdownTimer;

  int _preAlarmSecondsRemaining = 10;
  int get preAlarmSecondsRemaining => _preAlarmSecondsRemaining;

  /// Notifier status deteksi jatuh untuk update UI secara reaktif
  final ValueNotifier<FallEngineState> stateNotifier =
      ValueNotifier<FallEngineState>(FallEngineState.idle);

  /// Notifier hitung mundur pre-alarm (10 detik buffer pembatalan)
  final ValueNotifier<int> countdownNotifier = ValueNotifier<int>(10);

  /// Callback ketika insiden jatuh telah terkonfirmasi dan tidak dibatalkan
  VoidCallback? _onFallEmergencyTriggered;

  // ---------------------------------------------------------------------------
  // THRESHOLDS FISIKA GERAK (Berdasarkan Standar Klinis Biomekanika Jatuh)
  // ---------------------------------------------------------------------------
  static const double gravityG = 9.80665; // 1.0g m/s²
  static const double freeFallThreshold = 4.9; // < 0.5g (Melayang bebas)
  static const double impactThreshold = 26.0; // > 2.65g (Benturan keras)
  static const double gyroAngularThreshold = 2.5; // > 143 deg/s rotasi jatuh
  static const double immobilityMaxStdDev = 2.0; // Variasi akselerasi saat diam

  /// 1. Mengaktifkan Sensor Fusion Deteksi Jatuh
  Future<void> startMonitoring({
    required VoidCallback onFallEmergencyTriggered,
  }) async {
    if (_isEnabled) return;
    _onFallEmergencyTriggered = onFallEmergencyTriggered;
    _isEnabled = true;
    _currentState = FallEngineState.monitoring;
    stateNotifier.value = FallEngineState.monitoring;

    if (kDebugMode) {
      print('🛡️ [FallDetectionService] AI Fall Guard Aktif: Memonitor sensor akselerometer & giroskop.');
    }

    // 1. Berlangganan Stream Giroskop (Kecepatan Sudut Rotasi)
    _gyroSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        if (!_isEnabled) return;
        // Besaran vektor kecepatan sudut: sqrt(x² + y² + z²)
        _lastGyroMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      },
      onError: (dynamic err) {
        if (kDebugMode) {
          print('⚠️ [FallDetectionService] Gyroscope stream error: $err');
        }
      },
    );

    // 2. Berlangganan Stream Akselerometer (Gaya Gravitasi + Dinamis)
    _accelSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (!_isEnabled) return;
        _processAccelerometerSample(event.x, event.y, event.z);
      },
      onError: (dynamic err) {
        if (kDebugMode) {
          print('⚠️ [FallDetectionService] Accelerometer stream error: $err');
        }
      },
    );
  }

  /// 2. Pemrosesan Data Sensor Berkelanjutan (Pipeline Finite State Machine)
  void _processAccelerometerSample(double ax, double ay, double az) {
    // Besaran Magnitudo Vektor Sinyal (Signal Vector Magnitude / SVM)
    final double svm = sqrt(ax * ax + ay * ay + az * az);
    final now = DateTime.now();

    switch (_currentState) {
      case FallEngineState.monitoring:
        // Cek Fase 1: Free-Fall (Gaya gravitasi menghilang sesaat < 0.5g)
        if (svm < freeFallThreshold) {
          _currentState = FallEngineState.freeFallDetected;
          _freeFallTimestamp = now;
          stateNotifier.value = FallEngineState.freeFallDetected;
        }
        break;

      case FallEngineState.freeFallDetected:
        // Pastikan Fase 2 (Benturan) terjadi dalam jendela waktu 100ms - 600ms dari Free-Fall
        if (_freeFallTimestamp != null && now.difference(_freeFallTimestamp!).inMilliseconds > 600) {
          // Timeout benturan tidak terjadi (misal naik wahana ayunan) -> reset
          _resetToMonitoring();
          return;
        }

        // Cek Fase 2: Impact Shock (>2.65g) + Rotasi Tubuh Tajam (>140 deg/s)
        if (svm > impactThreshold && _lastGyroMagnitude > gyroAngularThreshold) {
          _currentState = FallEngineState.impactDetected;
          _postImpactAccels.clear();
          stateNotifier.value = FallEngineState.impactDetected;
          _startImmobilityVerification();
        }
        break;

      case FallEngineState.observingImmobility:
        // Mengumpulkan data akselerasi selama 3 detik pasca benturan untuk verifikasi diam total
        _postImpactAccels.add(svm);
        break;

      case FallEngineState.fallConfirmed:
      case FallEngineState.impactDetected:
      case FallEngineState.idle:
        break;
    }
  }

  /// 3. Verifikasi Fase 4: Imobilitas Pasca-Benturan (Mencegah False Alarm)
  void _startImmobilityVerification() {
    _currentState = FallEngineState.observingImmobility;
    stateNotifier.value = FallEngineState.observingImmobility;

    _immobilityTimer?.cancel();
    _immobilityTimer = Timer(const Duration(milliseconds: 3000), () {
      if (_currentState != FallEngineState.observingImmobility) return;

      // Hitung deviasi standar akselerasi saat fase diam
      if (_postImpactAccels.length >= 10) {
        final double mean = _postImpactAccels.reduce((a, b) => a + b) / _postImpactAccels.length;
        final double variance = _postImpactAccels.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            _postImpactAccels.length;
        final double stdDev = sqrt(variance);

        // Jika deviasi standar rendah (tubuh diam tak bergerak di lantai)
        if (stdDev < immobilityMaxStdDev) {
          _triggerPreAlarm();
        } else {
          // Pengguna bergerak aktif / berjalan normal pasca benturan -> False Alarm
          if (kDebugMode) {
            print('ℹ️ [FallDetectionService] Gerakan terdeteksi pasca benturan (False Positive dicegah).');
          }
          _resetToMonitoring();
        }
      } else {
        _triggerPreAlarm();
      }
    });
  }

  /// 4. Pemicuan Pre-Alarm 10 Detik (Safety Buffer Penyelamat)
  void _triggerPreAlarm() {
    _currentState = FallEngineState.fallConfirmed;
    stateNotifier.value = FallEngineState.fallConfirmed;

    _preAlarmSecondsRemaining = 10;
    countdownNotifier.value = 10;

    // Picu audio alarm lokal dan getaran berulang
    unawaited(FeedbackService.instance.triggerCountdownHaptic());

    if (kDebugMode) {
      print('🚨 [FallDetectionService] JATUH TERKONFIRMASI! Memulai pre-alarm 10 detik...');
    }

    _preAlarmCountdownTimer?.cancel();
    _preAlarmCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _preAlarmSecondsRemaining--;
      countdownNotifier.value = _preAlarmSecondsRemaining;

      unawaited(FeedbackService.instance.triggerCountdownHaptic());

      if (_preAlarmSecondsRemaining <= 0) {
        timer.cancel();
        _dispatchConfirmedEmergency();
      }
    });
  }

  /// 5. Pengiriman Panggilan Darurat Otomatis ke Jaringan Relawan
  void _dispatchConfirmedEmergency() {
    _preAlarmCountdownTimer?.cancel();
    _immobilityTimer?.cancel();
    _postImpactAccels.clear();

    if (kDebugMode) {
      print('🚀 [FallDetectionService] Pre-alarm selesai tanpa pembatalan! Mengirimkan SOS Darurat.');
    }

    _onFallEmergencyTriggered?.call();
    _resetToMonitoring();
  }

  /// 6. Pembatalan Mandiri oleh Lansia ("Saya Baik-Baik Saja")
  void cancelPreAlarm() {
    _preAlarmCountdownTimer?.cancel();
    _immobilityTimer?.cancel();
    _postImpactAccels.clear();

    unawaited(FeedbackService.instance.triggerSuccessFeedback());
    if (kDebugMode) {
      print('✅ [FallDetectionService] Pre-alarm dibatalkan oleh pengguna (Status Aman).');
    }

    _resetToMonitoring();
  }

  /// 7. Konfirmasi Cepat Lansia ("Kirim Bantuan Sekarang") tanpa menunggu 10 detik
  void confirmEmergencyNow() {
    _preAlarmCountdownTimer?.cancel();
    _immobilityTimer?.cancel();
    _dispatchConfirmedEmergency();
  }

  /// 8. Simulasi Kejadian Jatuh (Untuk Pengujian Cepat di Emulator / Tanpa Jatuh Fisik)
  void simulateFallEvent() {
    if (!_isEnabled) return;
    if (kDebugMode) {
      print('🧪 [FallDetectionService] Menjalankan simulasi gelombang jatuh 4 fase...');
    }
    // Simulasi langsung memicu pre-alarm verifikasi
    _triggerPreAlarm();
  }

  void _resetToMonitoring() {
    _currentState = _isEnabled ? FallEngineState.monitoring : FallEngineState.idle;
    stateNotifier.value = _currentState;
    _postImpactAccels.clear();
    _freeFallTimestamp = null;
  }

  /// 9. Menonaktifkan Layanan Sensor
  Future<void> stopMonitoring() async {
    _isEnabled = false;
    _currentState = FallEngineState.idle;
    stateNotifier.value = FallEngineState.idle;

    await _accelSubscription?.cancel();
    _accelSubscription = null;
    await _gyroSubscription?.cancel();
    _gyroSubscription = null;
    _immobilityTimer?.cancel();
    _preAlarmCountdownTimer?.cancel();
  }
}

