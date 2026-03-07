import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/onboarding/providers/onboarding_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('OnboardingNotifier', () {
    test('starts at page 0', () {
      final page = container.read(onboardingProvider);
      expect(page, 0);
    });

    test('nextPage increments', () {
      container.read(onboardingProvider.notifier).nextPage();
      expect(container.read(onboardingProvider), 1);
    });

    test('previousPage decrements', () {
      container.read(onboardingProvider.notifier).nextPage();
      container.read(onboardingProvider.notifier).previousPage();
      expect(container.read(onboardingProvider), 0);
    });

    test('previousPage does not go below 0', () {
      container.read(onboardingProvider.notifier).previousPage();
      expect(container.read(onboardingProvider), 0);
    });
  });
}
