import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';

const _notificationsEnabledKey = 'notifications_enabled';

class NotificationPreferenceNotifier extends Notifier<bool> {
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

final notificationPreferenceProvider =
    NotifierProvider<NotificationPreferenceNotifier, bool>(
  NotificationPreferenceNotifier.new,
);
