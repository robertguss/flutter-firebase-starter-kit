import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final isPremiumProvider = StateProvider<bool>((ref) => false);

final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  return PurchasesService.getCustomerInfo();
});

final offeringsProvider = FutureProvider<Offerings>((ref) async {
  return PurchasesService.getOfferings();
});
