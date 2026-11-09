import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/location_service.dart';
import '../../data/repositories/emergency_repository.dart';
import '../../domain/models/incident.dart';

/// Provider pengelola status darurat SOS (countdown, pemicuan, penguncian relawan, dan resolusi)
class EmergencyProvider extends ChangeNotifier {
  final EmergencyRepository _repository;

  bool _isCountingDown = false;
  int _countdownRemaining = AppConstants.sosCountdownSeconds;
  Timer? _countdownTimer;
  bool _isDispatched = false;
  Incident? _activeIncident;
  List<Incident> _nearbyIncidents = <Incident>[];
  bool _isLoading = false;
  String? _errorMessage;
  String? _lockedIncidentId;

  EmergencyProvider({EmergencyRepository? repository})
      : _repository = repository ?? EmergencyRepository();

  bool get isCountingDown => _isCountingDown;
  int get countdownRemaining => _countdownRemaining;
  bool get isDispatched => _isDispatched;
  Incident? get activeIncident => _activeIncident;
  List<Incident> get nearbyIncidents => _nearbyIncidents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lockedIncidentId => _lockedIncidentId;

  /// 1. Memicu Countdown SOS 8 detik dengan feedback getar & audio
  void startSosCountdown({
    required String careReceiverId,
    String? senderName,
    String? emergencyContactNumber,
  }) {
    _isCountingDown = true;
    _countdownRemaining = AppConstants.sosCountdownSeconds;
    _isDispatched = false;
    notifyListeners();

    unawaited(FeedbackService.instance.triggerEmergencyVibration());
    unawaited(FeedbackService.instance.playAlertSound());

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownRemaining > 1) {
        _countdownRemaining--;
        notifyListeners();
        unawaited(FeedbackService.instance.triggerEmergencyVibration());
      } else {
        _countdownTimer?.cancel();
        _isCountingDown = false;
        notifyListeners();
        unawaited(dispatchEmergency(
          careReceiverId: careReceiverId,
          senderName: senderName,
          emergencyContactNumber: emergencyContactNumber,
        ));
      }
    });
  }

  /// 2. Membatalkan Countdown SOS sebelum waktu habis
  void cancelSosCountdown() {
    _countdownTimer?.cancel();
    unawaited(FeedbackService.instance.cancelVibration());
    _isCountingDown = false;
    _countdownRemaining = AppConstants.sosCountdownSeconds;
    notifyListeners();

    if (_activeIncident != null) {
      unawaited(_repository.cancelIncident(_activeIncident!.id));
      _activeIncident = null;
      _isDispatched = false;
      notifyListeners();
    }
  }

  /// 3. Mengirim sinyal darurat SOS instan ke server PostGIS & relawan terdekat
  Future<void> dispatchEmergency({
    required String careReceiverId,
    String? senderName,
    String? emergencyContactNumber,
  }) async {
    await FeedbackService.instance.cancelVibration();

    _isLoading = true;
    notifyListeners();

    // Mengambil koordinat GPS terkini (fallback ke last known location)
    final position = await LocationService.instance.getCurrentPosition();
    final double lat = position?.latitude ?? -6.2088;
    final double lng = position?.longitude ?? 106.8456;
    final bool isApproximate = position == null;

    try {
      final incident = await _repository.dispatchEmergency(
        careReceiverId: careReceiverId,
        latitude: lat,
        longitude: lng,
        gpsApproximate: isApproximate,
        senderName: senderName,
        emergencyContactNumber: emergencyContactNumber,
      );

      _activeIncident = incident;
      _isDispatched = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 4. Mengambil daftar insiden aktif di sekitar relawan
  Future<void> loadNearbyIncidents({
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _repository.getNearbyActiveIncidents(
        latitude: latitude,
        longitude: longitude,
      );
      _nearbyIncidents = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 5. Penguncian insiden oleh relawan ("Saya Meluncur")
  Future<bool> lockIncident({
    required String incidentId,
    required String responderId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.lockIncident(
        incidentId: incidentId,
        responderId: responderId,
      );

      if (success) {
        _lockedIncidentId = incidentId;
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 6. Menyelesaikan insiden darurat dan menambahkan catatan resolusi
  Future<bool> resolveIncident({
    required String incidentId,
    required String resolvedBy,
    required String resolutionNotes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.resolveIncident(
        incidentId: incidentId,
        resolvedBy: resolvedBy,
        resolutionNotes: resolutionNotes,
      );

      if (success) {
        if (_activeIncident?.id == incidentId) {
          _activeIncident = _activeIncident?.copyWith(
            status: IncidentStatus.resolved,
            resolvedAt: DateTime.now(),
            resolvedBy: resolvedBy,
            resolutionNotes: resolutionNotes,
          );
          _isDispatched = false;
        }
        if (_lockedIncidentId == incidentId) {
          _lockedIncidentId = null;
        }
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
