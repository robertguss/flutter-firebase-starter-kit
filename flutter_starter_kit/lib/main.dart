import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/app.dart';
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_starter_kit/shared/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvironmentConfig.init();
  await FirebaseService.initialize();

  runApp(const ProviderScope(child: App()));
}
