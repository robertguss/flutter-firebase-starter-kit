import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/auth_provider.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_starter_kit/features/settings/providers/theme_provider.dart';
import 'package:flutter_starter_kit/features/settings/widgets/settings_section.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      final info = await PurchasesService.restorePurchases();
                      final restored = info.entitlements.active.containsKey(
                        'premium',
                      );
                      ref.read(isPremiumProvider.notifier).state = restored;
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
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
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
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.auth);
                  }
                },
              ),
              ListTile(
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => _showDeleteConfirmation(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
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
                onPressed: () async {
                  Navigator.pop(context);
                  final user = ref.read(authStateProvider).valueOrNull;
                  if (user != null) {
                    await UserProfileService().deleteProfile(user.uid);
                    await PurchasesService.logout();
                    await ref.read(authServiceProvider).deleteAccount();
                  }
                  if (context.mounted) {
                    context.go(AppRoutes.auth);
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
