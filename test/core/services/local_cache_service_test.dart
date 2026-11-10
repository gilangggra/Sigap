import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigap/core/constants/app_constants.dart';
import 'package:sigap/core/services/local_cache_service.dart';
import 'package:sigap/features/wellness/domain/models/medication_schedule.dart';
import 'package:sigap/features/wellness/domain/models/wellness_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalCacheService Offline Cache Tests', () {
    final cacheService = LocalCacheService.instance;

    test('Instance singleton is persistent', () {
      expect(cacheService, isNotNull);
      expect(identical(cacheService, LocalCacheService.instance), isTrue);
    });

    test('Medication schedules can be cached and retrieved offline', () async {
      const careReceiverId = 'test-receiver-123';
      final schedules = [
        const MedicationSchedule(
          id: 'med-test-1',
          careReceiverId: careReceiverId,
          createdBy: 'guardian-1',
          medicationName: 'Amlodipine 5mg',
          dosage: '1 tablet pagi',
          reminderTimes: ['08:00'],
          isActive: true,
          isTakenToday: false,
        ),
      ];

      await cacheService.saveMedicationSchedules(careReceiverId, schedules);
      final retrieved = await cacheService.getMedicationSchedules(careReceiverId);

      expect(retrieved, isNotNull);
      expect(retrieved!.length, equals(1));
      expect(retrieved.first.medicationName, equals('Amlodipine 5mg'));
    });

    test('Offline medication taken records pending log and updates local schedule', () async {
      const careReceiverId = 'test-receiver-123';
      final schedules = [
        const MedicationSchedule(
          id: 'med-test-1',
          careReceiverId: careReceiverId,
          createdBy: 'guardian-1',
          medicationName: 'Amlodipine 5mg',
          dosage: '1 tablet pagi',
          reminderTimes: ['08:00'],
          isActive: true,
          isTakenToday: false,
        ),
      ];

      await cacheService.saveMedicationSchedules(careReceiverId, schedules);
      await cacheService.recordOfflineMedicationTaken(
        scheduleId: 'med-test-1',
        careReceiverId: careReceiverId,
      );

      final pending = await cacheService.getPendingMedicationLogs();
      expect(pending.length, equals(1));
      expect(pending.first['schedule_id'], equals('med-test-1'));

      final updated = await cacheService.getMedicationSchedules(careReceiverId);
      expect(updated!.first.isTakenToday, isTrue);

      await cacheService.clearPendingMedicationLogs();
      final afterClear = await cacheService.getPendingMedicationLogs();
      expect(afterClear.isEmpty, isTrue);
    });

    test('Today wellness check-in can be cached and retrieved', () async {
      const careReceiverId = 'test-receiver-123';
      final log = WellnessLog(
        id: 'log-001',
        careReceiverId: careReceiverId,
        checkDate: DateTime.now(),
        status: CheckinStatus.baik,
        escalationStatus: EscalationStatus.resolved,
        respondedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await cacheService.saveTodayCheckin(log);
      final retrieved = await cacheService.getTodayCheckin(careReceiverId);

      expect(retrieved, isNotNull);
      expect(retrieved!.status, equals(CheckinStatus.baik));
    });
  });
}

