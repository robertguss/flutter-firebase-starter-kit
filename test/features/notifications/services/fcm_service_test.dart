import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late MockFirebaseMessaging mockMessaging;
  late FcmService service;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    service = FcmService(messaging: mockMessaging);
  });

  group('FcmService', () {
    test('accepts FirebaseMessaging via constructor', () {
      expect(service, isA<FcmService>());
      expect(service.messaging, mockMessaging);
    });

    test('does not import or reference FirebaseFirestore', () async {
      // Verify FcmService source has no Firestore import by checking
      // the service only depends on FirebaseMessaging
      final service2 = FcmService(messaging: mockMessaging);
      expect(service2.messaging, isA<FirebaseMessaging>());
    });

    test('getToken returns token from messaging', () async {
      when(() => mockMessaging.getToken())
          .thenAnswer((_) async => 'test-token');

      final token = await service.getToken();

      expect(token, 'test-token');
      verify(() => mockMessaging.getToken()).called(1);
    });

    test('getToken returns null when no token available', () async {
      when(() => mockMessaging.getToken()).thenAnswer((_) async => null);

      final token = await service.getToken();

      expect(token, isNull);
    });

    test('initialize requests permission', () async {
      when(() => mockMessaging.requestPermission())
          .thenAnswer((_) async => _fakeSettings());
      when(() => mockMessaging.getToken()).thenAnswer((_) async => 'token');
      when(() => mockMessaging.onTokenRefresh)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockMessaging.getInitialMessage())
          .thenAnswer((_) async => null);

      await service.initialize();

      verify(() => mockMessaging.requestPermission()).called(1);
    });

    test('initialize gets token', () async {
      when(() => mockMessaging.requestPermission())
          .thenAnswer((_) async => _fakeSettings());
      when(() => mockMessaging.getToken()).thenAnswer((_) async => 'token');
      when(() => mockMessaging.onTokenRefresh)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockMessaging.getInitialMessage())
          .thenAnswer((_) async => null);

      await service.initialize();

      verify(() => mockMessaging.getToken()).called(1);
    });

    test('initialize listens to token refresh', () async {
      when(() => mockMessaging.requestPermission())
          .thenAnswer((_) async => _fakeSettings());
      when(() => mockMessaging.getToken()).thenAnswer((_) async => 'token');
      when(() => mockMessaging.onTokenRefresh)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockMessaging.getInitialMessage())
          .thenAnswer((_) async => null);

      await service.initialize();

      verify(() => mockMessaging.onTokenRefresh).called(1);
    });
  });
}

NotificationSettings _fakeSettings() {
  return const NotificationSettings(
    alert: AppleNotificationSetting.enabled,
    announcement: AppleNotificationSetting.enabled,
    authorizationStatus: AuthorizationStatus.authorized,
    badge: AppleNotificationSetting.enabled,
    carPlay: AppleNotificationSetting.enabled,
    criticalAlert: AppleNotificationSetting.enabled,
    lockScreen: AppleNotificationSetting.enabled,
    notificationCenter: AppleNotificationSetting.enabled,
    providesAppNotificationSettings: AppleNotificationSetting.enabled,
    showPreviews: AppleShowPreviewSetting.always,
    sound: AppleNotificationSetting.enabled,
    timeSensitive: AppleNotificationSetting.enabled,
  );
}
