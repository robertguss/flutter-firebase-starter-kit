import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission();
    if (kDebugMode) {
      print('FCM permission status: ${settings.authorizationStatus}');
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    _messaging.onTokenRefresh.listen(_saveToken);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<void> _saveToken(String token) async {
    if (kDebugMode) {
      print('FCM Token: $token');
    }
  }

  Future<void> saveTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message: ${message.notification?.title}');
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Message tap: ${message.data}');
    }
  }
}
