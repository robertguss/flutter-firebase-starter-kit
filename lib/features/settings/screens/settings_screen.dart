import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/auth/providers/delete_account_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/sign_out_provider.dart';
import 'package:flutter_starter_kit/shared/providers/feature_hooks.dart';
import 'package:flutter_starter_kit/shared/providers/premium_provider.dart';
import 'package:flutter_starter_kit/features/settings/providers/package_info_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          SettingsSection(
            title: l10n.appearance,
            children: [
              ListTile(
                title: Text(l10n.theme),
                subtitle: Text(switch (themeMode) {
                  ThemeMode.system => l10n.themeSystem,
                  ThemeMode.light => l10n.themeLight,
                  ThemeMode.dark => l10n.themeDark,
                }),
                trailing: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selected) {
                    ref.read(themeModeProvider.notifier).setMode(selected.first);
                  },
                ),
              ),
            ],
          ),
          if (AppConfig.enablePaywall)
            SettingsSection(
              title: l10n.subscription,
              children: [
                ListTile(
                  title: Text(l10n.currentPlan),
                  subtitle: Text(isPremium ? l10n.premium : l10n.free),
                  trailing: isPremium ? null : Icon(Icons.chevron_right, semanticLabel: l10n.viewPlans),
                  onTap:
                      isPremium ? null : () => context.push(AppRoutes.paywall),
                ),
                ListTile(
                  title: Text(l10n.restorePurchases),
                  onTap: () async {
                    final restoreAction = ref.read(restorePurchasesActionProvider);
                    if (restoreAction == null) return;
                    try {
                      final message = await restoreAction();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.genericError),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          SettingsSection(
            title: l10n.about,
            children: [
              ListTile(
                title: Text(l10n.privacyPolicy),
                trailing: Icon(Icons.open_in_new, semanticLabel: l10n.opensInBrowser),
                onTap: () => launchUrl(Uri.parse(AppConfig.privacyPolicyUrl)),
              ),
              ListTile(
                title: Text(l10n.termsOfService),
                trailing: Icon(Icons.open_in_new, semanticLabel: l10n.opensInBrowser),
                onTap: () => launchUrl(Uri.parse(AppConfig.termsOfServiceUrl)),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.account,
            children: [
              ListTile(
                title: Text(l10n.signOut),
                onTap: () async {
                  await ref.read(signOutProvider.future);
                },
              ),
              ListTile(
                title: Text(
                  l10n.deleteAccount,
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
          const SizedBox(height: 24),
          ref.watch(packageInfoProvider).when(
                data: (info) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.versionInfo(info.version, info.buildNumber),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.deleteAccount),
            content: Text(l10n.deleteAccountConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAccount();
                },
                child: Text(l10n.delete),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isDeleting = true);
    // Invalidate to clear any cached error from a previous attempt
    ref.invalidate(deleteAccountProvider);
    try {
      await ref.read(deleteAccountProvider.future);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = switch (e.code) {
          'requires-recent-login' => l10n.requiresRecentLogin,
          _ => l10n.authenticationError,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.genericError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}
