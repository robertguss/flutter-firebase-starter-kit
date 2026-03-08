import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows a consent dialog for analytics/crash reporting if the user
/// hasn't responded yet. Call once after first authentication.
///
/// Stores the response in SharedPreferences under 'analytics_consent'.
/// Enables/disables Crashlytics collection based on the response.
///
/// TODO: Customize consent flow for your jurisdiction (GDPR, CCPA, etc.)
Future<void> showAnalyticsConsentIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('analytics_consent')) return;

  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l10n.analyticsConsent),
      content: Text(l10n.analyticsConsentDescription),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.decline),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.accept),
        ),
      ],
    ),
  );

  final consent = accepted ?? false;
  await prefs.setBool('analytics_consent', consent);

  if (AppConfig.enableCrashlytics &&
      EnvironmentConfig.current.enableCrashlytics) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(consent);
  }
}
