import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/widgets/social_login_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _signIn({
    required Future<UserCredential> Function() method,
    required String providerName,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await method();
      if (AppConfig.enableAnalytics) {
        final prefs = await SharedPreferences.getInstance();
        final hasConsent = prefs.getBool('analytics_consent') ?? false;
        if (hasConsent) {
          FirebaseAnalytics.instance.logEvent(
            name: 'app_sign_in',
            parameters: {'method': providerName},
          );
        }
      }
    } on FirebaseAuthException {
      _setError(l10n.authenticationError);
    } on PlatformException {
      _setError(l10n.genericError);
    } catch (e) {
      debugPrint('Sign-in error ($providerName): $e');
      _setError(l10n.genericError);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(AppConfig.appName, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(l10n.signInPrompt, style: theme.textTheme.bodyLarge),
              const Spacer(),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 16),
              ],
              SocialLoginButtons(
                onGooglePressed: () => _signIn(
                  method: ref.read(authServiceProvider).signInWithGoogle,
                  providerName: 'google',
                ),
                onApplePressed: () => _signIn(
                  method: ref.read(authServiceProvider).signInWithApple,
                  providerName: 'apple',
                ),
                isLoading: _isLoading,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
