import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';

part 'notification_provider.g.dart';

@Riverpod(keepAlive: true)
FcmService fcmService(Ref ref) {
  return FcmService();
}
