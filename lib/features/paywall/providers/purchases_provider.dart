import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part 'purchases_provider.g.dart';

@Riverpod(keepAlive: true)
PurchasesService purchasesService(Ref ref) {
  return PurchasesService();
}

@Riverpod(keepAlive: true)
Future<CustomerInfo> customerInfo(Ref ref) async {
  final service = ref.read(purchasesServiceProvider);
  return service.getCustomerInfo();
}

@Riverpod(keepAlive: true)
Future<Offerings> offerings(Ref ref) async {
  final service = ref.read(purchasesServiceProvider);
  return service.getOfferings();
}
