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

    // Watch bootstrap in a Consumer lower in the tree so auth changes
    // don't rebuild the entire MaterialApp.
    return _BootstrapGate(
      child: MaterialApp.router(
        title: AppConfig.appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}

/// Watches auth + bootstrap state and shows a loading screen during bootstrap.
/// Separated from App so auth transitions don't rebuild MaterialApp.router.
class _BootstrapGate extends ConsumerWidget {
  const _BootstrapGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    if (user != null) {
      final bootstrap = ref.watch(postAuthBootstrapProvider);
      if (bootstrap.isLoading) {
        return MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }
    }

    return child;
  }
}
