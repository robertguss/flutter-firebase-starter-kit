import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/screens/auth_screen.dart';
import 'package:flutter_starter_kit/features/home/screens/home_screen.dart';
import 'package:flutter_starter_kit/features/onboarding/screens/onboarding_screen.dart';
import 'package:flutter_starter_kit/features/paywall/screens/paywall_screen.dart';
import 'package:flutter_starter_kit/features/profile/screens/profile_screen.dart';
import 'package:flutter_starter_kit/features/settings/screens/settings_screen.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:go_router/go_router.dart';

part 'router.g.dart';

// Bridges Riverpod auth state to GoRouter's refreshListenable.
// GoRouter re-evaluates redirect when notifyListeners() fires.
class AuthChangeNotifier extends ChangeNotifier {
  bool? _wasLoggedIn;
  bool? _wasOnboardingComplete;

  AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, next) {
      final isLoggedIn = next.value != null;
      if (isLoggedIn != _wasLoggedIn) {
        _wasLoggedIn = isLoggedIn;
        notifyListeners();
      }
    });
    ref.listen(userProfileProvider, (_, next) {
      final isComplete = next.value?.onboardingComplete;
      if (isComplete != _wasOnboardingComplete) {
        _wasOnboardingComplete = isComplete;
        notifyListeners();
      }
    });
  }
}

/// Redirect logic extracted for testability.
/// Takes resolved values — no Ref dependency, easy to unit test.
String? routerRedirect({
  required User? user,
  required UserProfile? profile,
  required String location,
}) {
  final isLoggedIn = user != null;
  final isOnAuthPage = location == AppRoutes.auth;
  final isOnOnboardingPage = location == AppRoutes.onboarding;

  if (!isLoggedIn && !isOnAuthPage) {
    return AppRoutes.auth;
  }

  if (isLoggedIn && isOnAuthPage) {
    return AppRoutes.home;
  }

  // Check cached profile for onboarding status
  if (isLoggedIn && !isOnOnboardingPage) {
    if (profile != null && !profile.onboardingComplete) {
      return AppRoutes.onboarding;
    }
  }

  return null;
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final authNotifier = AuthChangeNotifier(ref);
  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authNotifier,
    observers: [
      if (AppConfig.enableAnalytics && Firebase.apps.isNotEmpty)
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    redirect: (context, state) {
      return routerRedirect(
        user: ref.read(authStateProvider).value,
        profile: ref.read(userProfileProvider).value,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
    ],
  );
}
