import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/notifications/providers/notification_provider.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('fcmServiceProvider', () {
    test('provides an FcmService instance', () {
      // Override with a mock since default constructor needs Firebase.initializeApp
      final mockMessaging = MockFirebaseMessaging();
      final container = ProviderContainer(
        overrides: [
          fcmServiceProvider.overrideWithValue(
            FcmService(messaging: mockMessaging),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(fcmServiceProvider);

      expect(service, isA<FcmService>());
      expect(service.messaging, mockMessaging);
    });

    test('returns same instance on subsequent reads', () {
      final mockMessaging = MockFirebaseMessaging();
      final container = ProviderContainer(
        overrides: [
          fcmServiceProvider.overrideWithValue(
            FcmService(messaging: mockMessaging),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service1 = container.read(fcmServiceProvider);
      final service2 = container.read(fcmServiceProvider);

      expect(identical(service1, service2), true);
    });
  });
}
