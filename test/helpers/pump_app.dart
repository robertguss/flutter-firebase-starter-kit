import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ProviderContainer? container,
  }) async {
    final app = MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: widget,
    );

    if (container != null) {
      await pumpWidget(
        UncontrolledProviderScope(container: container, child: app),
      );
    } else {
      await pumpWidget(ProviderScope(child: app));
    }
  }
}
