import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_kit/features/auth/widgets/social_login_buttons.dart';

void main() {
  group('SocialLoginButtons', () {
    Widget buildSubject() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SocialLoginButtons(
            onGooglePressed: () {},
            onApplePressed: () {},
          ),
        ),
      );
    }

    testWidgets('shows Apple button on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(buildSubject());

      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('hides Apple button on Android', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await tester.pumpWidget(buildSubject());

      expect(find.text('Continue with Apple'), findsNothing);
      expect(find.text('Continue with Google'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
