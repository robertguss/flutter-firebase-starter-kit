import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/app.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_starter_kit/features/notifications/services/fcm_service.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_starter_kit/shared/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvironmentConfig.init();
  await FirebaseService.initialize();

  if (AppConfig.enablePaywall) {
    await PurchasesService.initialize();
  }

  if (AppConfig.enableNotifications) {
    await FcmService().initialize();
  }

  runApp(const ProviderScope(child: App()));
}
