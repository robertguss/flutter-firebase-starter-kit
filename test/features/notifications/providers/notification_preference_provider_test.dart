import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/notifications/providers/notification_preference_provider.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationPreferenceNotifier', () {
    test('defaults to true when no preference stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(notificationPreferenceProvider), true);
    });

    test('reads stored preference', () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': false});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(notificationPreferenceProvider), false);
    });

    test('setEnabled persists and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(notificationPreferenceProvider), true);

      await container
          .read(notificationPreferenceProvider.notifier)
          .setEnabled(false);

      expect(container.read(notificationPreferenceProvider), false);
      expect(prefs.getBool('notifications_enabled'), false);
    });

    test('toggle on then off persists correctly', () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(notificationPreferenceProvider.notifier)
          .setEnabled(false);
      expect(container.read(notificationPreferenceProvider), false);

      await container
          .read(notificationPreferenceProvider.notifier)
          .setEnabled(true);
      expect(container.read(notificationPreferenceProvider), true);
      expect(prefs.getBool('notifications_enabled'), true);
    });
  });
}
