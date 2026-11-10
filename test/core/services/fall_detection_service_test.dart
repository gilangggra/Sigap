import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sigap/core/services/fall_detection_service.dart';

class FakeSensorsPlatform extends SensorsPlatform {
  final StreamController<AccelerometerEvent> _accelController =
      StreamController<AccelerometerEvent>.broadcast();
  final StreamController<GyroscopeEvent> _gyroController =
      StreamController<GyroscopeEvent>.broadcast();

  @override
  Stream<AccelerometerEvent> accelerometerEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) => _accelController.stream;

  @override
  Stream<GyroscopeEvent> gyroscopeEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) => _gyroController.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SensorsPlatform.instance = FakeSensorsPlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('vibration'),
      (MethodCall methodCall) async => false,
    );
  });

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
