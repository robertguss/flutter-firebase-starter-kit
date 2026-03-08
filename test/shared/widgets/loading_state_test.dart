import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_starter_kit/shared/widgets/loading_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadingState', () {
    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: LoadingState(
              isLoading: true,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Content'), findsNothing);
    });

    testWidgets('shows child when not loading and no error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: LoadingState(
              isLoading: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error message when error is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: LoadingState(
              isLoading: false,
              errorMessage: 'Something went wrong',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Content'), findsNothing);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: LoadingState(
              isLoading: false,
              errorMessage: 'Error occurred',
              onRetry: () => retried = true,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, true);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: LoadingState(
              isLoading: false,
              errorMessage: 'Error occurred',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
