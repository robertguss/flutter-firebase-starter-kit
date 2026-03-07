import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final purchasesServiceProvider = Provider<PurchasesService>((ref) {
  return PurchasesService();
});

final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  ref.keepAlive();
  final service = ref.read(purchasesServiceProvider);
  return service.getCustomerInfo();
});

final offeringsProvider = FutureProvider<Offerings>((ref) async {
  ref.keepAlive();
  final service = ref.read(purchasesServiceProvider);
  return service.getOfferings();
});
