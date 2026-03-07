import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingProvider = NotifierProvider<OnboardingNotifier, int>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void nextPage() {
    state = state + 1;
  }

  void previousPage() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void goToPage(int page) {
    state = page;
  }
}
