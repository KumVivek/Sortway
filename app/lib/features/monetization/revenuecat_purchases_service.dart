import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'purchases_service.dart';

/// RevenueCat implementation: receipt validation without our own backend.
/// The SDK runs with an anonymous app user id; nothing personal is attached.
class RevenueCatPurchasesService implements PurchasesService {
  RevenueCatPurchasesService(this._apiKey);

  final String _apiKey;
  bool _configured = false;
  final Map<String, Package> _packages = {};

  @override
  bool get available => _configured;

  @override
  Future<void> initialize() async {
    try {
      if (kDebugMode) await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
    } on Object catch (e) {
      debugPrint('RevenueCat configure failed: $e');
    }
  }

  @override
  Future<List<StoreProductInfo>> products() async {
    if (!_configured) return const [];
    try {
      final offerings = await Purchases.getOfferings();
      _packages.clear();
      for (final p
          in offerings.current?.availablePackages ?? const <Package>[]) {
        if (catalogItem(p.storeProduct.identifier) != null) {
          _packages[p.storeProduct.identifier] = p;
        }
      }
      return [
        for (final c in catalog)
          if (_packages[c.id] case final p?)
            StoreProductInfo(id: c.id, price: p.storeProduct.priceString),
      ];
    } on Object catch (e) {
      debugPrint('RevenueCat offerings failed: $e');
      return const [];
    }
  }

  @override
  Future<PurchaseOutcome> purchase(String productId) async {
    if (!_configured) return PurchaseOutcome.failed;
    if (_packages[productId] == null) await products();
    final package = _packages[productId];
    if (package == null) return PurchaseOutcome.failed;
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      return PurchaseOutcome.success;
    } on PlatformException catch (e) {
      return PurchasesErrorHelper.getErrorCode(e) ==
              PurchasesErrorCode.purchaseCancelledError
          ? PurchaseOutcome.cancelled
          : PurchaseOutcome.failed;
    } on Object {
      return PurchaseOutcome.failed;
    }
  }

  bool _owns(CustomerInfo info) =>
      info.entitlements.active.containsKey(removeAdsEntitlement);

  @override
  Future<bool> restore() async {
    if (!_configured) return false;
    try {
      return _owns(await Purchases.restorePurchases());
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> hasRemoveAds() async {
    if (!_configured) return false;
    try {
      return _owns(await Purchases.getCustomerInfo());
    } on Object {
      return false;
    }
  }
}
