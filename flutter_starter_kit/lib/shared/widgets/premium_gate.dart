import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/routing/routes.dart';
import 'package:go_router/go_router.dart';

class PremiumGate extends ConsumerWidget {
  const PremiumGate({super.key, required this.child, this.lockedWidget});

  final Widget child;
  final Widget? lockedWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) {
      return child;
    }

    return lockedWidget ??
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 16),
              const Text('Premium Feature'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.push(AppRoutes.paywall),
                child: const Text('Upgrade'),
              ),
            ],
          ),
        );
  }
}
