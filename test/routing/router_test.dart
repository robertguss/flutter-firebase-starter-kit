import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoutes', () {
    test('auth route is /auth', () {
      expect(AppRoutes.auth, '/auth');
    });

    test('home route is /home', () {
      expect(AppRoutes.home, '/home');
    });

    test('onboarding route is /onboarding', () {
      expect(AppRoutes.onboarding, '/onboarding');
    });
  });
}
