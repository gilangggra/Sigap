import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/core/services/safety_check_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
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

  group('SafetyCheckService Walk-Safe Timer Unit Tests', () {
    final service = SafetyCheckService.instance;

    setUp(() {
      service.cancelSafetyCheck();
    });

    tearDown(() {
      service.cancelSafetyCheck();
    });

    test('Instance singleton is persistent', () {
      expect(service, isNotNull);
      expect(identical(service, SafetyCheckService.instance), isTrue);
    });

    test('Initial state is idle and inactive', () {
      expect(service.status, equals(SafetyCheckStatus.idle));
      expect(service.isActive, isFalse);
      expect(service.secondsRemaining, equals(0));
      expect(service.totalDurationSeconds, equals(0));
    });

    test('Start safety check initializes duration and transitions to active', () {
      bool emergencyDispatched = false;
      service.startSafetyCheck(
        durationMinutes: 30,
        onEmergencyTriggered: () {
          emergencyDispatched = true;
        },
      );

      expect(service.status, equals(SafetyCheckStatus.active));
      expect(service.isActive, isTrue);
      expect(service.totalDurationSeconds, equals(1800));
      expect(service.secondsRemaining, equals(1800));
      expect(emergencyDispatched, isFalse);
    });

    test('Extend duration increments seconds and total duration correctly', () {
      service.startSafetyCheck(
        durationMinutes: 15,
        onEmergencyTriggered: () {},
      );

      expect(service.secondsRemaining, equals(900));

      service.extendDuration(additionalMinutes: 15);

      expect(service.secondsRemaining, equals(1800));
      expect(service.totalDurationSeconds, equals(1800));
      expect(service.status, equals(SafetyCheckStatus.active));
    });

    test('Confirm safe cancels timer and resets state to idle', () {
      service.startSafetyCheck(
        durationMinutes: 45,
        onEmergencyTriggered: () {},
      );

      expect(service.isActive, isTrue);

      service.confirmSafe();

      expect(service.status, equals(SafetyCheckStatus.idle));
      expect(service.isActive, isFalse);
      expect(service.secondsRemaining, equals(0));
    });

    test('Cancel safety check cleans up state cleanly', () {
      service.startSafetyCheck(
        durationMinutes: 60,
        onEmergencyTriggered: () {},
      );

      service.cancelSafetyCheck();

      expect(service.status, equals(SafetyCheckStatus.idle));
      expect(service.isActive, isFalse);
      expect(service.secondsRemaining, equals(0));
    });

    test('Format seconds to digital string MM:SS functions accurately', () {
      expect(SafetyCheckService.formatSecondsToMinutes(1800), equals('30:00'));
      expect(SafetyCheckService.formatSecondsToMinutes(905), equals('15:05'));
      expect(SafetyCheckService.formatSecondsToMinutes(65), equals('01:05'));
      expect(SafetyCheckService.formatSecondsToMinutes(9), equals('00:09'));
      expect(SafetyCheckService.formatSecondsToMinutes(0), equals('00:00'));
      expect(SafetyCheckService.formatSecondsToMinutes(-10), equals('00:00'));
    });
  });
}
