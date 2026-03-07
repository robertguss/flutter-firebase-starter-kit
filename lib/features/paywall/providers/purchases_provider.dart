import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final purchasesServiceProvider = Provider<PurchasesService>((ref) {
  return PurchasesService();
});

final isPremiumProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoProvider);
  return customerInfo.whenOrNull(
        data: (info) => info.entitlements.active.containsKey('premium'),
      ) ??
      false;
});

final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  final service = ref.read(purchasesServiceProvider);
  return service.getCustomerInfo();
});

final offeringsProvider = FutureProvider<Offerings>((ref) async {
  final service = ref.read(purchasesServiceProvider);
  return service.getOfferings();
});
