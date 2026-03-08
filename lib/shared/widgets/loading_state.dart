import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    required this.child,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ],
        ),
      );
    }

    return child;
  }
}
