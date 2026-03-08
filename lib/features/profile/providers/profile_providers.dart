import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/profile/services/profile_storage_service.dart';

final profileStorageServiceProvider = Provider<ProfileStorageService>((ref) {
  return ProfileStorageService();
});
