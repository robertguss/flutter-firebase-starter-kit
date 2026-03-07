import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/onboarding/providers/onboarding_provider.dart';
import 'package:flutter_starter_kit/features/onboarding/widgets/onboarding_page.dart';
import 'package:flutter_starter_kit/features/onboarding/widgets/progress_dots.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  static const _totalPages = 3;

  // Replace these pages with your app-specific onboarding content.
  // Keep three pages: overview, key feature, and call to action.
  final _pages = const [
    OnboardingPage(
      title: 'Welcome to AppName',
      description:
          'Your all-in-one solution for staying organized and productive. '
          'We help you focus on what matters most.',
      icon: Icons.rocket_launch,
    ),
    OnboardingPage(
      title: 'Stay on Track',
      description:
          'Set goals, track your progress, and celebrate your wins. '
          'Smart reminders keep you moving forward every day.',
      icon: Icons.trending_up,
    ),
    OnboardingPage(
      title: 'Get Started',
      description:
          'You\'re all set! Dive in and explore everything the app has '
          'to offer. Your journey starts now.',
      icon: Icons.check_circle_outline,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await ref.read(userProfileServiceProvider).markOnboardingComplete(user.uid);
    }
    if (AppConfig.enableAnalytics) {
      FirebaseAnalytics.instance.logEvent(name: 'onboarding_complete');
    }
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingProvider);
    final isLastPage = currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  ref.read(onboardingProvider.notifier).goToPage(page);
                },
                children: _pages,
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
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
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
