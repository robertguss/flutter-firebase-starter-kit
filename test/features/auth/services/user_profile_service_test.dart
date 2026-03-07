import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
    test('createProfile writes user data to Firestore', () async {
      await service.createProfile(
        uid: 'test-uid',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: null,
      );

      final doc = await fakeFirestore.collection('users').doc('test-uid').get();
      expect(doc.exists, true);
      expect(doc.data()?['displayName'], 'Test User');
      expect(doc.data()?['email'], 'test@example.com');
      expect(doc.data()?['onboardingComplete'], false);
    });

    test('getProfile returns user data', () async {
      await fakeFirestore.collection('users').doc('test-uid').set({
        'displayName': 'Test User',
        'email': 'test@example.com',
        'onboardingComplete': true,
      });

      final profile = await service.getProfile('test-uid');
      expect(profile?['displayName'], 'Test User');
      expect(profile?['onboardingComplete'], true);
    });

    test('markOnboardingComplete updates flag', () async {
      await fakeFirestore.collection('users').doc('test-uid').set({
        'displayName': 'Test User',
        'onboardingComplete': false,
      });

      await service.markOnboardingComplete('test-uid');

      final doc = await fakeFirestore.collection('users').doc('test-uid').get();
      expect(doc.data()?['onboardingComplete'], true);
    });

    test('deleteProfile removes user document', () async {
      await fakeFirestore.collection('users').doc('test-uid').set({
        'displayName': 'Test User',
      });

      await service.deleteProfile('test-uid');

      final doc = await fakeFirestore.collection('users').doc('test-uid').get();
      expect(doc.exists, false);
    });
  });
}
