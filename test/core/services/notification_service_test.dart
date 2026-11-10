import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Unit Tests', () {
    final notificationService = NotificationService.instance;

    test('Instance singleton is non-null and persistent', () {
      expect(notificationService, isNotNull);
      expect(identical(notificationService, NotificationService.instance), isTrue);
    });

    test('Channel constants are configured properly for Android', () {
      expect(NotificationService.emergencyChannelId, equals('sigap_emergency_channel'));
      expect(NotificationService.emergencyChannelName, contains('Panggilan Darurat'));
      expect(NotificationService.wellnessChannelId, equals('sigap_wellness_channel'));
      expect(NotificationService.taskChannelId, equals('sigap_task_channel'));
    });

    test('Notification tap handler can be set and invoked', () {
      String? capturedPayload;
      notificationService.setNotificationTapHandler((payload) {
        capturedPayload = payload;
      });

      expect(capturedPayload, isNull);
    });
  });
}
