import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';

UserProfile createTestProfile({
  String uid = 'test-uid',
  String? email = 'test@example.com',
  String? displayName = 'Test User',
  String? photoUrl,
  bool onboardingComplete = true,
  String? fcmToken,
}) {
  return UserProfile(
    uid: uid,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    onboardingComplete: onboardingComplete,
    fcmToken: fcmToken,
    createdAt: DateTime(2026, 1, 1),
  );
}
