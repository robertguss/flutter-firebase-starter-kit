import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/notifications/providers/notification_provider.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';

/// Orchestrates all post-sign-in side effects in a defined order.
/// Watched by the App widget to show loading state during bootstrap.
final postAuthBootstrapProvider = FutureProvider<void>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return;

  final profileService = ref.read(userProfileServiceProvider);

  // 1. Create or update profile (set merge avoids race conditions on concurrent sign-ins)
  await profileService.createOrUpdateProfile(user.uid, {
    'email': user.email,
    'displayName': user.displayName,
    'photoUrl': user.photoURL,
    'createdAt': FieldValue.serverTimestamp(),
    'onboardingComplete': false,
  });

  // 2. RevenueCat login
  final purchasesService = ref.read(purchasesServiceProvider);
  await purchasesService.login(user.uid);

  // 3. FCM token save
  final fcmService = ref.read(fcmServiceProvider);
  final token = await fcmService.getToken();
  if (token != null) {
    await profileService.updateFcmToken(user.uid, token);
  }
});
