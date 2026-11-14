import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/wellness_repository.dart';
import '../../domain/models/medication_schedule.dart';
import '../../domain/models/wellness_log.dart';

/// Provider pengelola status check-in harian lansia dan kepatuhan minum obat
class WellnessProvider extends ChangeNotifier {
  final WellnessRepository _repository;

  WellnessLog? _todayCheckin;
  List<MedicationSchedule> _medicationSchedules = <MedicationSchedule>[];
  bool _isLoading = false;
  String? _errorMessage;

  WellnessProvider({WellnessRepository? repository})
      : _repository = repository ?? WellnessRepository();

  WellnessLog? get todayCheckin => _todayCheckin;
  List<MedicationSchedule> get medicationSchedules => _medicationSchedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 1. Memuat log check-in dan jadwal obat hari ini
  Future<void> loadTodayWellness(String careReceiverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final log = await _repository.getTodayCheckin(careReceiverId);
      final schedules = await _repository.getMedicationSchedules(careReceiverId);

      _todayCheckin = log;
      _medicationSchedules = schedules;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 2. Mengirim respons check-in harian
  Future<bool> submitCheckin({
    required String careReceiverId,
    required CheckinStatus status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final log = await _repository.submitDailyCheckin(
        careReceiverId: careReceiverId,
        status: status,
      );

      _todayCheckin = log;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 3. Menandai obat sudah diminum oleh lansia
  Future<void> markMedicationTaken({
    required String scheduleId,
    required String careReceiverId,
  }) async {
    try {
      await _repository.markMedicationTaken(
        scheduleId: scheduleId,
        careReceiverId: careReceiverId,
      );

      // Update state lokal instan (optimistic UI)
      final updatedList = _medicationSchedules.map((item) {
        if (item.id == scheduleId) {
          return item.copyWith(isTakenToday: true, takenAt: DateTime.now());
        }
        return item;
      }).toList();

      _medicationSchedules = updatedList;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 4. Menambahkan jadwal resep obat baru oleh keluarga
  Future<bool> addMedicationSchedule({
    required String careReceiverId,
    required String medicationName,
    required String dosage,
    required List<String> reminderTimes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newSchedule = await _repository.addMedicationSchedule(
        careReceiverId: careReceiverId,
        medicationName: medicationName,
        dosage: dosage,
        reminderTimes: reminderTimes,
      );

      _medicationSchedules = [..._medicationSchedules, newSchedule];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

