import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/core/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return ['wifi'];
        }
        return null;
      },
    );
  });

  group('SyncService Autonomous Network Sync Unit Tests', () {
    final syncService = SyncService.instance;

    test('Instance singleton is persistent', () {
      expect(syncService, isNotNull);
      expect(identical(syncService, SyncService.instance), isTrue);
    });

    test('Initial states have valid default notifiers', () {
      expect(syncService.isOnlineNotifier.value, isNotNull);
      expect(syncService.isSyncingNotifier.value, isFalse);
    });

    test('Manual sync triggers and terminates with syncing flag false', () async {
      await syncService.triggerManualSync();
      expect(syncService.isSyncing, isFalse);
    });
  });
}

