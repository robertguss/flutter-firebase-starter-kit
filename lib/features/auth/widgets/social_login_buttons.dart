import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({
    super.key,
    required this.onGooglePressed,
    required this.onApplePressed,
    this.isLoading = false,
  });

  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (defaultTargetPlatform == TargetPlatform.iOS) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onApplePressed,
              icon: const Icon(Icons.apple),
              label: const Text('Continue with Apple'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onGooglePressed,
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Continue with Google'),
          ),
        ),
      ],
    );
  }
}
