import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/features/profile/providers/profile_providers.dart';
import 'package:flutter_starter_kit/features/profile/screens/profile_screen.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_starter_kit/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockUserProfileService mockProfileService;
  late MockProfileStorageService mockStorageService;
  late SharedPreferences prefs;

  setUp(() async {
    mockProfileService = MockUserProfileService();
    mockStorageService = MockProfileStorageService();
    SharedPreferences.setMockInitialValues({'analytics_consent': true});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject() {
    final profile = createTestProfile(
      photoUrl: 'https://example.com/photo.jpg',
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userProfileProvider.overrideWith((_) => Stream.value(profile)),
        userProfileServiceProvider.overrideWithValue(mockProfileService),
        profileStorageServiceProvider.overrideWithValue(mockStorageService),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen', () {
    testWidgets('renders profile info and account actions', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('shows edit display name dialog on tap', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.text('Edit display name'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('saves display name via dialog', (tester) async {
      when(() => mockProfileService.updateDisplayName(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New Name');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockProfileService.updateDisplayName('test-uid', 'New Name'))
          .called(1);
    });

    testWidgets('shows delete account confirmation dialog', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.scrollUntilVisible(find.text('Delete Account'), 100);
      await tester.pump();
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
    });

    testWidgets('shows settings icon in app bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
