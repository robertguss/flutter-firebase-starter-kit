import 'package:flutter/foundation.dart';
import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesService {
  Future<void> initialize() async {
    final logLevel = EnvironmentConfig.current == Environment.prod
        ? LogLevel.warn
        : LogLevel.debug;
    await Purchases.setLogLevel(logLevel);

    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? AppConfig.revenueCatAppleApiKey
        : AppConfig.revenueCatGoogleApiKey;

    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  Future<void> login(String uid) async {
    await Purchases.logIn(uid);
  }

  Future<void> logout() async {
    await Purchases.logOut();
  }

  Future<CustomerInfo> getCustomerInfo() async {
    return Purchases.getCustomerInfo();
  }

  Future<Offerings> getOfferings() async {
    return Purchases.getOfferings();
  }

  Future<CustomerInfo> purchase(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo;
  }

  Future<CustomerInfo> restorePurchases() async {
    return Purchases.restorePurchases();
  }
}
