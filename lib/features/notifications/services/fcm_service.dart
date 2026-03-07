import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';

class FcmService {
  FcmService({FirebaseMessaging? messaging})
      : messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize() async {
    final settings = await messaging.requestPermission();
    if (EnvironmentConfig.current != Environment.prod) {
      debugPrint('FCM permission status: ${settings.authorizationStatus}');
    }

    await messaging.getToken();

    // TODO: Show in-app notification UI for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // TODO: Navigate to relevant screen based on message data
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  /// Start listening for token refreshes and persist to Firestore via service layer.
  /// Call after sign-in with the authenticated user's UID.
  void startTokenRefreshListener(String uid, UserProfileService profileService) {
    stopTokenRefreshListener();
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
      (newToken) async {
        await profileService.updateFcmToken(uid, newToken);
      },
    );
  }

  /// Stop listening for token refreshes. Call during sign-out to prevent
  /// writing tokens to the wrong user's document.
  void stopTokenRefreshListener() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
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
      debugPrint('Message tap: ${message.data.keys}');
    }
  }
}
