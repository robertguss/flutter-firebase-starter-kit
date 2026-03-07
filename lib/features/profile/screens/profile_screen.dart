import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/auth/providers/user_profile_provider.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
            return const Center(child: Text('No profile data'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (profile.photoUrl != null)
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(profile.photoUrl!),
                  ),
                ),
              const SizedBox(height: 16),
              if (profile.displayName != null)
                Center(
                  child: Text(
                    profile.displayName!,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              if (profile.email != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    profile.email!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Something went wrong. Please try again.'),
        ),
      ),
    );
  }
}
