import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/auth/screens/auth_screen.dart';
import 'package:flutter_starter_kit/features/home/screens/home_screen.dart';
import 'package:flutter_starter_kit/features/onboarding/screens/onboarding_screen.dart';
import 'package:flutter_starter_kit/features/paywall/screens/paywall_screen.dart';
import 'package:flutter_starter_kit/features/settings/screens/settings_screen.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:go_router/go_router.dart';

// Bridges Riverpod auth state to GoRouter's refreshListenable.
// GoRouter re-evaluates redirect when notifyListeners() fires.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }
}

/// Redirect logic extracted for testability.
/// Reads only cached provider values — never performs async/blocking calls.
String? routerRedirect(Ref ref, String location) {
  final user = ref.read(authStateProvider).valueOrNull;
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
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null && !profile.onboardingComplete) {
      return AppRoutes.onboarding;
    }
  }

  if (isLoggedIn && isOnOnboardingPage) {
    return null;
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = AuthChangeNotifier(ref);
  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      return routerRedirect(ref, state.matchedLocation);
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
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
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
});
