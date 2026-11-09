import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/features/emergency/presentation/state/emergency_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('vibration'),
      (MethodCall methodCall) async => false,
    );
  });

  group('EmergencyProvider SOS Countdown Tests', () {
    late EmergencyProvider provider;

    setUp(() {
      provider = EmergencyProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Inisialisasi awal provider tidak dalam keadaan darurat atau hitung mundur', () {
      expect(provider.isCountingDown, isFalse);
      expect(provider.isDispatched, isFalse);
      expect(provider.countdownRemaining, equals(8));
      expect(provider.activeIncident, isNull);
    });

    test('Memulai countdown SOS menyetel isCountingDown true dan hitungan 8 detik', () {
      provider.startSosCountdown(
        careReceiverId: 'test-user-01',
        senderName: 'Lansia Uji Coba',
      );

      expect(provider.isCountingDown, isTrue);
      expect(provider.countdownRemaining, equals(8));
    });

    test('Membatalkan countdown SOS menghentikan timer dan mereset status', () {
      provider.startSosCountdown(
        careReceiverId: 'test-user-01',
        senderName: 'Lansia Uji Coba',
      );
      expect(provider.isCountingDown, isTrue);

      provider.cancelSosCountdown();
      expect(provider.isCountingDown, isFalse);
      expect(provider.countdownRemaining, equals(8));
    });
  });
}
