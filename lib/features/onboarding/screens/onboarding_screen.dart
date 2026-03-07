import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
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

  final _pages = const [
    OnboardingPage(
      title: 'Welcome',
      description:
          'This is your app. Replace this with your value proposition.',
      icon: Icons.waving_hand,
    ),
    OnboardingPage(
      title: 'Personalize',
      description:
          'Customize your experience. Replace with app-specific preferences.',
      icon: Icons.tune,
    ),
    OnboardingPage(
      title: 'Stay Updated',
      description: 'Enable notifications to never miss important updates.',
      icon: Icons.notifications_active,
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
      await UserProfileService().markOnboardingComplete(user.uid);
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
