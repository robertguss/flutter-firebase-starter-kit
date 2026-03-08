import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    group('fromMap', () {
      test('creates profile with all fields', () {
        final now = DateTime(2026, 1, 1);
        final profile = UserProfile.fromMap('uid-1', {
          'email': 'test@example.com',
          'displayName': 'Test User',
          'photoUrl': 'https://example.com/photo.jpg',
          'onboardingComplete': true,
          'fcmToken': 'token-123',
          'createdAt': Timestamp.fromDate(now),
        });

        expect(profile.uid, 'uid-1');
        expect(profile.email, 'test@example.com');
        expect(profile.displayName, 'Test User');
        expect(profile.photoUrl, 'https://example.com/photo.jpg');
        expect(profile.onboardingComplete, true);
        expect(profile.fcmToken, 'token-123');
        expect(profile.createdAt, now);
      });

      test('handles nullable email for Apple Sign-In', () {
        final profile = UserProfile.fromMap('uid-1', {
          'email': null,
          'onboardingComplete': false,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        });

        expect(profile.email, isNull);
      });

      test('defaults onboardingComplete to false when missing', () {
        final profile = UserProfile.fromMap('uid-1', {});

        expect(profile.onboardingComplete, false);
      });

      test('defaults createdAt to now when null', () {
        final before = DateTime.now();
        final profile = UserProfile.fromMap('uid-1', {
          'createdAt': null,
        });
        final after = DateTime.now();

        expect(profile.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(profile.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        final now = DateTime(2026, 1, 1);
        final profile = UserProfile(
          uid: 'uid-1',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          onboardingComplete: true,
          fcmToken: 'token-123',
          createdAt: now,
        );

        final map = profile.toMap();

        expect(map['email'], 'test@example.com');
        expect(map['displayName'], 'Test User');
        expect(map['photoUrl'], 'https://example.com/photo.jpg');
        expect(map['onboardingComplete'], true);
        expect(map['fcmToken'], 'token-123');
        expect(map['createdAt'], Timestamp.fromDate(now));
      });

      test('does not include uid in map', () {
        final profile = UserProfile(
          uid: 'uid-1',
          createdAt: DateTime(2026, 1, 1),
        );

        expect(profile.toMap().containsKey('uid'), false);
      });
    });

    group('copyWith', () {
      test('copies with updated fields', () {
        final profile = UserProfile(
          uid: 'uid-1',
          email: 'old@example.com',
          onboardingComplete: false,
          createdAt: DateTime(2026, 1, 1),
        );

        final updated = profile.copyWith(
          email: 'new@example.com',
          onboardingComplete: true,
        );

        expect(updated.uid, 'uid-1');
        expect(updated.email, 'new@example.com');
        expect(updated.onboardingComplete, true);
        expect(updated.createdAt, profile.createdAt);
      });

      test('preserves uid and createdAt', () {
        final profile = UserProfile(
          uid: 'uid-1',
          createdAt: DateTime(2026, 1, 1),
        );

        final updated = profile.copyWith(displayName: 'New Name');

        expect(updated.uid, 'uid-1');
        expect(updated.createdAt, DateTime(2026, 1, 1));
      });
    });

    group('completionPercentage', () {
      test('returns 1.0 when all fields filled', () {
        final profile = UserProfile(
          uid: 'uid-1',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          onboardingComplete: true,
          createdAt: DateTime(2026, 1, 1),
        );
        expect(profile.completionPercentage, 1.0);
      });

      test('returns 0.0 when no optional fields filled', () {
        final profile = UserProfile(
          uid: 'uid-1',
          onboardingComplete: false,
          createdAt: DateTime(2026, 1, 1),
        );
        expect(profile.completionPercentage, 0.0);
      });

      test('returns 0.5 when half the fields filled', () {
        final profile = UserProfile(
          uid: 'uid-1',
          email: 'test@example.com',
          onboardingComplete: true,
          createdAt: DateTime(2026, 1, 1),
        );
        expect(profile.completionPercentage, 0.5);
      });

      test('empty strings count as unfilled', () {
        final profile = UserProfile(
          uid: 'uid-1',
          displayName: '',
          photoUrl: '',
          email: '',
          onboardingComplete: false,
          createdAt: DateTime(2026, 1, 1),
        );
        expect(profile.completionPercentage, 0.0);
      });
    });

    group('equality', () {
      test('equal profiles are equal', () {
        final now = DateTime(2026, 1, 1);
        final a = UserProfile(uid: 'uid-1', email: 'a@b.com', createdAt: now);
        final b = UserProfile(uid: 'uid-1', email: 'a@b.com', createdAt: now);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different profiles are not equal', () {
        final now = DateTime(2026, 1, 1);
        final a = UserProfile(uid: 'uid-1', email: 'a@b.com', createdAt: now);
        final b = UserProfile(uid: 'uid-2', email: 'a@b.com', createdAt: now);

        expect(a, isNot(equals(b)));
      });

      test('different onboardingComplete are not equal', () {
        final now = DateTime(2026, 1, 1);
        final a = UserProfile(uid: 'uid-1', onboardingComplete: false, createdAt: now);
        final b = UserProfile(uid: 'uid-1', onboardingComplete: true, createdAt: now);

        expect(a, isNot(equals(b)));
      });
    });
  });
}
