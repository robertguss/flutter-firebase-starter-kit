import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_starter_kit/features/profile/services/profile_storage_service.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileStorageService profileStorageService(Ref ref) {
  return ProfileStorageService();
}
