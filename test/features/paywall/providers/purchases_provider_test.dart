import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/shared/providers/premium_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isPremiumProvider', () {
    test('defaults to false', () {
      final container = ProviderContainer();

      expect(container.read(isPremiumProvider), false);
      container.dispose();
    });

    test('returns true when overridden', () {
      final container = ProviderContainer(
        overrides: [isPremiumProvider.overrideWith((ref) => true)],
      );

      expect(container.read(isPremiumProvider), true);
      container.dispose();
    });
  });
}
