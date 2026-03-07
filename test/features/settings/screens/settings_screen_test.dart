import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/shared/providers/premium_provider.dart';
import 'package:flutter_starter_kit/features/settings/screens/settings_screen.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'theme_mode': false});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject({bool isPremium = false}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isPremiumProvider.overrideWithValue(isPremium),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  group('SettingsScreen', () {
    testWidgets('renders all required sections', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('dark mode toggle switches theme', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);

      // Initially light mode (false)
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, false);

      // Tap to toggle
      await tester.tap(switchFinder);
      await tester.pump();

      final updatedSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(updatedSwitch.value, true);
    });

    testWidgets('shows subscription section with current plan', (tester) async {
      await tester.pumpWidget(buildSubject(isPremium: false));
      await tester.pump();

      expect(find.text('Current Plan'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('shows Premium label when user is premium', (tester) async {
      await tester.pumpWidget(buildSubject(isPremium: true));
      await tester.pump();

      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('delete account shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Scroll to make Delete Account visible, then tap
      await tester.scrollUntilVisible(find.text('Delete Account'), 100);
      await tester.pump();
      await tester.tap(find.text('Delete Account'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
    });
  });
}
