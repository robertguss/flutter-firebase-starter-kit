import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/onboarding/providers/onboarding_provider.dart';
import 'package:flutter_starter_kit/features/onboarding/widgets/onboarding_page.dart';
import 'package:flutter_starter_kit/features/onboarding/widgets/progress_dots.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  static const _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<OnboardingPage> _buildPages(AppLocalizations l10n) {
    return [
      OnboardingPage(
        title: l10n.onboardingWelcomeTitle,
        description: l10n.onboardingWelcomeDescription,
        icon: Icons.rocket_launch,
      ),
      OnboardingPage(
        title: l10n.onboardingTrackTitle,
        description: l10n.onboardingTrackDescription,
        icon: Icons.trending_up,
      ),
      OnboardingPage(
        title: l10n.onboardingGetStartedTitle,
        description: l10n.onboardingGetStartedDescription,
        icon: Icons.check_circle_outline,
      ),
    ];
  }

  Future<void> _completeOnboarding() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref.read(userProfileServiceProvider).markOnboardingComplete(user.uid);
    }
    if (AppConfig.enableAnalytics) {
      final prefs = await SharedPreferences.getInstance();
      final hasConsent = prefs.getBool('analytics_consent') ?? false;
      if (hasConsent) {
        FirebaseAnalytics.instance.logEvent(name: 'onboarding_complete');
      }
    }
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingProvider);
    final isLastPage = currentPage == _totalPages - 1;
    final l10n = AppLocalizations.of(context)!;
    final pages = _buildPages(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(l10n.skip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  ref.read(onboardingProvider.notifier).goToPage(page);
                },
                children: pages,
              ),
            ),
            ProgressDots(total: _totalPages, current: currentPage),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      isLastPage
                          ? _completeOnboarding
                          : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                  child: Text(isLastPage ? l10n.getStarted : l10n.next),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
