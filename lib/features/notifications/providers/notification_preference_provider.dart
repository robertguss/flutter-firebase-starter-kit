import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';

part 'notification_preference_provider.g.dart';

const _notificationsEnabledKey = 'notifications_enabled';

@Riverpod(keepAlive: true)
class NotificationPreference extends _$NotificationPreference {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_notificationsEnabledKey, enabled);
    state = enabled;
  }
}
