import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/shared/providers/premium_provider.dart';
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

    final l10n = AppLocalizations.of(context)!;
    return lockedWidget ??
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 48, semanticLabel: l10n.premiumFeatureLocked),
              const SizedBox(height: 16),
              Text(l10n.premiumFeature),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.push(AppRoutes.paywall),
                child: Text(l10n.upgrade),
              ),
            ],
          ),
        );
  }
}
