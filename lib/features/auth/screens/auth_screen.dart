import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/widgets/social_login_buttons.dart';

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await method();
      if (AppConfig.enableAnalytics) {
        FirebaseAnalytics.instance.logEvent(
          name: 'app_sign_in',
          parameters: {'method': providerName},
        );
      }
    } on FirebaseAuthException {
      _setError('Authentication error. Please try again.');
    } on PlatformException {
      _setError('Something went wrong. Please try again.');
    } catch (e) {
      debugPrint('Sign-in error ($providerName): $e');
      _setError('Something went wrong. Please try again.');
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
              Text('Sign in to get started', style: theme.textTheme.bodyLarge),
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
