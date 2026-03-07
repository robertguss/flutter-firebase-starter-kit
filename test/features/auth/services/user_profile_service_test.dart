import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserProfileService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = UserProfileService(firestore: fakeFirestore);
  });

  group('UserProfileService', () {
    group('createOrUpdateProfile', () {
      test('creates a new profile with set merge', () async {
        await service.createOrUpdateProfile('uid-1', {
          'email': 'test@example.com',
          'displayName': 'Test User',
          'onboardingComplete': false,
        });

        final doc =
            await fakeFirestore.collection('users').doc('uid-1').get();
        expect(doc.exists, true);
        expect(doc.data()?['email'], 'test@example.com');
        expect(doc.data()?['displayName'], 'Test User');
      });

      test('merges data on existing profile without overwriting', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'email': 'test@example.com',
          'displayName': 'Test User',
          'onboardingComplete': false,
        });

        await service.createOrUpdateProfile('uid-1', {
          'displayName': 'Updated Name',
        });

        final doc =
            await fakeFirestore.collection('users').doc('uid-1').get();
        expect(doc.data()?['email'], 'test@example.com');
        expect(doc.data()?['displayName'], 'Updated Name');
        expect(doc.data()?['onboardingComplete'], false);
      });
    });

    group('getProfile', () {
      test('returns UserProfile when document exists', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'email': 'test@example.com',
          'displayName': 'Test User',
          'onboardingComplete': true,
        });

        final profile = await service.getProfile('uid-1');

        expect(profile, isNotNull);
        expect(profile, isA<UserProfile>());
        expect(profile!.uid, 'uid-1');
        expect(profile.email, 'test@example.com');
        expect(profile.displayName, 'Test User');
        expect(profile.onboardingComplete, true);
      });

      test('returns null when document does not exist', () async {
        final profile = await service.getProfile('nonexistent');

        expect(profile, isNull);
      });
    });

    group('profileStream', () {
      test('emits UserProfile on document changes', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'email': 'test@example.com',
          'onboardingComplete': false,
        });

        final stream = service.profileStream('uid-1');

        await expectLater(
          stream,
          emits(isA<UserProfile>()
              .having((p) => p.uid, 'uid', 'uid-1')
              .having((p) => p.email, 'email', 'test@example.com')
              .having(
                  (p) => p.onboardingComplete, 'onboardingComplete', false)),
        );
      });

      test('emits null when document does not exist', () async {
        final stream = service.profileStream('nonexistent');

        await expectLater(stream, emits(isNull));
      });
    });

    group('markOnboardingComplete', () {
      test('updates onboardingComplete to true', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'displayName': 'Test User',
          'onboardingComplete': false,
        });

        await service.markOnboardingComplete('uid-1');

        final doc =
            await fakeFirestore.collection('users').doc('uid-1').get();
        expect(doc.data()?['onboardingComplete'], true);
      });
    });

    group('updateFcmToken', () {
      test('sets fcmToken on user document', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'displayName': 'Test User',
        });

        await service.updateFcmToken('uid-1', 'new-token');

        final doc =
            await fakeFirestore.collection('users').doc('uid-1').get();
        expect(doc.data()?['fcmToken'], 'new-token');
      });
    });

    group('clearFcmToken', () {
      test('removes fcmToken from user document', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'displayName': 'Test User',
          'fcmToken': 'old-token',
        });

        await service.clearFcmToken('uid-1');

        final doc =
            await fakeFirestore.collection('users').doc('uid-1').get();
        expect(doc.data()?.containsKey('fcmToken'), false);
      });
    });

    group('deleteProfile', () {
      test('removes user document', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'displayName': 'Test User',
        });

        await service.deleteProfile('uid-1');

        final doc =
            await fakeFirestore.collection('users').doc('uid-1').get();
        expect(doc.exists, false);
      });
    });
  });
}
