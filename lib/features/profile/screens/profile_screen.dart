import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/delete_account_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/sign_out_provider.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/notifications/providers/notification_preference_provider.dart';
import 'package:flutter_starter_kit/features/profile/providers/profile_providers.dart';
import 'package:flutter_starter_kit/features/profile/widgets/avatar_picker.dart';
import 'package:flutter_starter_kit/features/settings/widgets/settings_section.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingAvatar = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(l10n.noProfileData));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar
              Center(
                child: AvatarPicker(
                  photoUrl: profile.photoUrl,
                  displayName: profile.displayName,
                  isUploading: _isUploadingAvatar,
                  onSourceSelected: (source) => _uploadAvatar(source, profile.uid),
                ),
              ),
              const SizedBox(height: 16),

              // Display name (tappable to edit)
              Center(
                child: GestureDetector(
                  onTap: () => _editDisplayName(context, profile.uid, profile.displayName),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.displayName ?? '',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              // Email (read-only)
              if (profile.email != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    profile.email!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],

              // Profile completion
              if (profile.completionPercentage < 1.0) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileCompletion(
                          (profile.completionPercentage * 100).round().toString(),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: profile.completionPercentage,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Preferences section
              if (AppConfig.enableNotifications)
                SettingsSection(
                  title: l10n.preferences,
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: Text(l10n.notifications),
                      subtitle: Text(l10n.notificationsDescription),
                      value: ref.watch(notificationPreferenceProvider),
                      onChanged: (value) {
                        ref
                            .read(notificationPreferenceProvider.notifier)
                            .setEnabled(value);
                      },
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Account section
              SettingsSection(
                title: l10n.account,
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l10n.signOut),
                    onTap: () async {
                      await ref.read(signOutProvider.future);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever,
                        color: Theme.of(context).colorScheme.error),
                    title: Text(
                      l10n.deleteAccount,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    trailing: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap:
                        _isDeleting ? null : () => _showDeleteConfirmation(context),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
      ),
    );
  }

  Future<void> _uploadAvatar(ImageSource source, String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final storageService = ref.read(profileStorageServiceProvider);
    final profileService = ref.read(userProfileServiceProvider);

    final file = await storageService.pickImage(source);
    if (file == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await storageService.uploadAvatar(uid, bytes);
      await profileService.updateAvatarUrl(uid, url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.avatarUpdated)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.avatarUpdateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _editDisplayName(
      BuildContext context, String uid, String? currentName) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(text: currentName);
        return AlertDialog(
          title: Text(l10n.editDisplayName),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.displayName),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty || result == currentName) return;

    try {
      await ref.read(userProfileServiceProvider).updateDisplayName(uid, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.displayNameUpdated)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.displayNameUpdateFailed)),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
          SnackBar(content: Text(l10n.genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}
