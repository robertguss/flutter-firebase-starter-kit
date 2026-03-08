import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';

part 'user_profile_provider.g.dart';

@Riverpod(keepAlive: true)
UserProfileService userProfileService(Ref ref) {
  return UserProfileService();
}

@Riverpod(keepAlive: true)
Stream<UserProfile?> userProfile(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);

  final profileService = ref.read(userProfileServiceProvider);
  return profileService.profileStream(user.uid);
}
