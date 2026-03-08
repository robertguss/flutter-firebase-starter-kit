import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_starter_kit/shared/providers/premium_provider.dart';
import 'package:flutter_starter_kit/features/settings/screens/settings_screen.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject({bool isPremium = false}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isPremiumProvider.overrideWithValue(isPremium),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('renders appearance and about sections', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('does not show account section (moved to profile)',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Sign Out'), findsNothing);
      expect(find.text('Delete Account'), findsNothing);
    });

    testWidgets('theme selector shows segmented button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final segmentedButton = find.byType(SegmentedButton<ThemeMode>);
      expect(segmentedButton, findsOneWidget);

      // System is selected by default
      expect(find.text('System'), findsWidgets);
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
  });
}
