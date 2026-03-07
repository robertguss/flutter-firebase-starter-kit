import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the current user has premium access.
/// Defaults to false. Paywall feature overrides this via ProviderScope.
final isPremiumProvider = Provider<bool>((ref) => false);
