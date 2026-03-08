import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_starter_kit/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/widgets/feature_comparison_row.dart';
import 'package:go_router/go_router.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;

  Future<void> _restorePurchases() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(purchasesServiceProvider);
      final customerInfo = await service.restorePurchases();
      // Invalidate to refresh derived isPremiumProvider
      ref.invalidate(customerInfoProvider);
      final isPremium = customerInfo.entitlements.active.containsKey('premium');
      if (isPremium && mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.purchasesRestored)),
        );
        router.pop();
      }
    } on PlatformException {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.genericError),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.genericError),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerings = ref.watch(offeringsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.upgrade),
        leading: IconButton(
          icon: Icon(Icons.close, semanticLabel: l10n.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                l10n.unlockPremium,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.getAccessToAllFeatures,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              const FeatureComparisonRow(
                feature: 'Feature',
                freeIncluded: true,
                premiumIncluded: true,
              ),
              const FeatureComparisonRow(
                feature: 'Basic Access',
                freeIncluded: true,
                premiumIncluded: true,
              ),
              const FeatureComparisonRow(
                feature: 'Premium Feature 1',
                freeIncluded: false,
                premiumIncluded: true,
              ),
              const FeatureComparisonRow(
                feature: 'Premium Feature 2',
                freeIncluded: false,
                premiumIncluded: true,
              ),
              const Spacer(),
              offerings.when(
                data: (offerings) {
                  final current = offerings.current;
                  if (current == null) {
                    return Text(l10n.noOfferingsAvailable);
                  }

                  final packages = current.availablePackages;
                  if (packages.isEmpty) {
                    return Text(l10n.noPackagesAvailable);
                  }

                  final package = packages.first;
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final router = GoRouter.of(context);

                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  if (AppConfig.enableAnalytics) {
                                    FirebaseAnalytics.instance.logEvent(
                                      name: 'purchase_started',
                                      parameters: {
                                        'product_id': package.storeProduct.identifier,
                                      },
                                    );
                                  }
                                  final service =
                                      ref.read(purchasesServiceProvider);
                                  final info = await service.purchase(package);
                                  // Invalidate to refresh derived isPremiumProvider
                                  ref.invalidate(customerInfoProvider);
                                  final isPremium = info.entitlements.active
                                      .containsKey('premium');
                                  if (isPremium && mounted) {
                                    router.pop();
                                  }
                                } on PlatformException {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.genericError),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.genericError),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                      child: Text(
                        _isLoading
                            ? l10n.loading
                            : l10n.subscribePrice(package.storeProduct.priceString),
                      ),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => Text(l10n.unableToLoadOfferings),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _restorePurchases,
                child: Text(l10n.restorePurchases),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
