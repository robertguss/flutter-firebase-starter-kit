import 'dart:io';

import 'package:flutter_starter_kit/config/app_config.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesService {
  static Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);

    final apiKey =
        Platform.isIOS
            ? AppConfig.revenueCatAppleApiKey
            : AppConfig.revenueCatGoogleApiKey;

    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  static Future<void> login(String uid) async {
    await Purchases.logIn(uid);
  }

  static Future<void> logout() async {
    await Purchases.logOut();
  }

  static Future<CustomerInfo> getCustomerInfo() async {
    return Purchases.getCustomerInfo();
  }

  static Future<Offerings> getOfferings() async {
    return Purchases.getOfferings();
  }

  static Future<CustomerInfo> purchase(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo;
  }

  static Future<CustomerInfo> restorePurchases() async {
    return Purchases.restorePurchases();
  }
}
