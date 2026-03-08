import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'premium_provider.g.dart';

/// Whether the current user has premium access.
/// Defaults to false. Paywall feature overrides this via ProviderScope.
@Riverpod(keepAlive: true)
bool isPremium(Ref ref) => false;
