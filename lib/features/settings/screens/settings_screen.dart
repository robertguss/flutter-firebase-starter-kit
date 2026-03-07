import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/shared/providers/delete_account_provider.dart';
import 'package:flutter_starter_kit/shared/providers/sign_out_provider.dart';
import 'package:flutter_starter_kit/features/settings/providers/theme_provider.dart';
import 'package:flutter_starter_kit/features/settings/widgets/settings_section.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SettingsSection(
            title: 'Appearance',
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeMode == ThemeMode.dark,
                onChanged: (_) {
                  ref.read(themeModeProvider.notifier).toggle();
                },
              ),
            ],
          ),
          if (AppConfig.enablePaywall)
            SettingsSection(
              title: 'Subscription',
              children: [
                ListTile(
                  title: const Text('Current Plan'),
                  subtitle: Text(isPremium ? 'Premium' : 'Free'),
                  trailing: isPremium ? null : const Icon(Icons.chevron_right),
                  onTap:
                      isPremium ? null : () => context.push(AppRoutes.paywall),
                ),
                ListTile(
                  title: const Text('Restore Purchases'),
                  onTap: () async {
                    try {
                      final service = ref.read(purchasesServiceProvider);
                      final info = await service.restorePurchases();
                      ref.invalidate(customerInfoProvider);
                      final restored = info.entitlements.active.containsKey(
                        'premium',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              restored
                                  ? 'Purchases restored!'
                                  : 'No purchases found',
                            ),
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Something went wrong. Please try again.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          SettingsSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(Uri.parse(AppConfig.privacyPolicyUrl)),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(Uri.parse(AppConfig.termsOfServiceUrl)),
              ),
            ],
          ),
          SettingsSection(
            title: 'Account',
            children: [
              ListTile(
                title: const Text('Sign Out'),
                onTap: () async {
                  await ref.read(signOutProvider.future);
                },
              ),
              ListTile(
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                trailing: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _isDeleting ? null : () => _showDeleteConfirmation(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'This will permanently delete your account and all data. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAccount();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    try {
      await ref.read(deleteAccountProvider.future);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = switch (e.code) {
          'requires-recent-login' => 'Please sign in again to continue.',
          _ => 'Authentication error. Please try again.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}
