import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_starter_kit/config/environment.dart';

class FcmService {
  FcmService({FirebaseMessaging? messaging})
      : messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging messaging;

  Future<void> initialize() async {
    final settings = await messaging.requestPermission();
    if (EnvironmentConfig.current != Environment.prod) {
      debugPrint('FCM permission status: ${settings.authorizationStatus}');
    }

    await messaging.getToken();

    messaging.onTokenRefresh.listen((_) {});
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<String?> getToken() async {
    return messaging.getToken();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (EnvironmentConfig.current != Environment.prod) {
      debugPrint('Foreground message: ${message.notification?.title}');
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    if (EnvironmentConfig.current != Environment.prod) {
      debugPrint('Message tap: ${message.data}');
    }
  }
}
