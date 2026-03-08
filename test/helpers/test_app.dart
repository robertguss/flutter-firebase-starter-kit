import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';

/// Wraps a widget in a MaterialApp with localization support for testing.
Widget testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}
