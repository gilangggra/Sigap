import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/core/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService Standby Tracking Unit Tests', () {
    final locationService = LocationService.instance;

    test('Instance singleton is persistent', () {
      expect(locationService, isNotNull);
      expect(identical(locationService, LocationService.instance), isTrue);
    });

    test('Format distance converts meters and kilometers correctly', () {
      expect(locationService.formatDistance(250), equals('250 m'));
      expect(locationService.formatDistance(999), equals('999 m'));
      expect(locationService.formatDistance(1000), equals('1.0 km'));
      expect(locationService.formatDistance(1450), equals('1.5 km'));
      expect(locationService.formatDistance(2500), equals('2.5 km'));
    });

    test('Calculate distance between coordinates works via Haversine', () {
      // Monas to Bundaran HI (approx 2 km)
      final distance = locationService.calculateDistanceMeters(
        startLatitude: -6.1754,
        startLongitude: 106.8272,
        endLatitude: -6.1950,
        endLongitude: 106.8230,
      );

      expect(distance, greaterThan(2000));
      expect(distance, lessThan(2500));
    });

    test('Standby tracking status toggle changes state correctly', () async {
      expect(locationService.isStandbyTrackingActive, isFalse);

      await locationService.stopStandbyTracking(
        responderId: 'mock-resp-001',
        clearCloudLocation: false,
      );

      expect(locationService.isStandbyTrackingActive, isFalse);
      expect(locationService.standbyPositionNotifier.value, isNull);
    });
  });
}

