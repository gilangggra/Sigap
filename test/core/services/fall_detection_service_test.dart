import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/core/services/fall_detection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FallDetectionService AI Fall Guard Unit Tests', () {
    final fallService = FallDetectionService.instance;

    setUp(() async {
      await fallService.stopMonitoring();
    });

    test('Instance singleton is persistent', () {
      expect(fallService, isNotNull);
      expect(identical(fallService, FallDetectionService.instance), isTrue);
    });

    test('Initial state is idle and disabled', () {
      expect(fallService.isEnabled, isFalse);
      expect(fallService.currentState, equals(FallEngineState.idle));
      expect(fallService.preAlarmSecondsRemaining, equals(10));
    });

    test('Start and stop monitoring transitions state correctly', () async {
      bool emergencyTriggered = false;
      await fallService.startMonitoring(
        onFallEmergencyTriggered: () {
          emergencyTriggered = true;
        },
      );

      expect(fallService.isEnabled, isTrue);
      expect(fallService.currentState, equals(FallEngineState.monitoring));
      expect(emergencyTriggered, isFalse);

      await fallService.stopMonitoring();
      expect(fallService.isEnabled, isFalse);
      expect(fallService.currentState, equals(FallEngineState.idle));
    });

    test('Simulate fall event triggers pre-alarm countdown', () async {
      bool emergencyTriggered = false;
      await fallService.startMonitoring(
        onFallEmergencyTriggered: () {
          emergencyTriggered = true;
        },
      );

      fallService.simulateFallEvent();

      expect(fallService.currentState, equals(FallEngineState.fallConfirmed));
      expect(fallService.preAlarmSecondsRemaining, equals(10));
      expect(fallService.countdownNotifier.value, equals(10));

      // User cancels pre-alarm ("Saya Baik-Baik Saja")
      fallService.cancelPreAlarm();

      expect(fallService.currentState, equals(FallEngineState.monitoring));
      expect(emergencyTriggered, isFalse);

      await fallService.stopMonitoring();
    });

    test('Confirm emergency now dispatches immediately', () async {
      bool emergencyTriggered = false;
      await fallService.startMonitoring(
        onFallEmergencyTriggered: () {
          emergencyTriggered = true;
        },
      );

      fallService.simulateFallEvent();
      expect(emergencyTriggered, isFalse);

      fallService.confirmEmergencyNow();
      expect(emergencyTriggered, isTrue);

      await fallService.stopMonitoring();
    });
  });
}
