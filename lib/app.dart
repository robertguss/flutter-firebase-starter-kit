import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/config/theme.dart';
import 'package:flutter_starter_kit/features/settings/providers/theme_provider.dart';
import 'package:flutter_starter_kit/routing/router.dart';
import 'package:flutter_starter_kit/shared/providers/post_auth_bootstrap_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    if (AppConfig.enableAnalytics && Firebase.apps.isNotEmpty) {
      FirebaseAnalytics.instance
          .setAnalyticsCollectionEnabled(AppConfig.enableAnalytics);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);

    // Watch bootstrap provider when user is signed in to trigger
    // profile creation, RevenueCat login, and FCM token save.
    final user = authState.valueOrNull;
    final bootstrap = user != null
        ? ref.watch(postAuthBootstrapProvider)
        : null;

    // Show loading while bootstrap runs after sign-in
    if (bootstrap != null && bootstrap.isLoading) {
      return MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
