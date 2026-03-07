import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});
