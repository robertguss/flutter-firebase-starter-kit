import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/providers/purchases_provider.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
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
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final customerInfo = await PurchasesService.restorePurchases();
      final isPremium = customerInfo.entitlements.active.containsKey('premium');
      ref.read(isPremiumProvider.notifier).state = isPremium;
      if (isPremium && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Purchases restored!')),
        );
        router.pop();
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Restore failed: $error')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Unlock Premium',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Get access to all features',
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
                    return const Text('No offerings available');
                  }

                  final packages = current.availablePackages;
                  if (packages.isEmpty) {
                    return const Text('No packages available');
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
                                  final info = await PurchasesService.purchase(
                                    package,
                                  );
                                  final isPremium = info.entitlements.active
                                      .containsKey('premium');
                                  ref.read(isPremiumProvider.notifier).state =
                                      isPremium;
                                  if (isPremium && mounted) {
                                    router.pop();
                                  }
                                } catch (error) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Purchase failed: $error',
                                        ),
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
                            ? 'Loading...'
                            : 'Subscribe - ${package.storeProduct.priceString}',
                      ),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _restorePurchases,
                child: const Text('Restore Purchases'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
