/// Product ids. Create matching products in Play Console / App Store Connect
/// and attach them to the current RevenueCat offering.
abstract final class ProductIds {
  static const removeAds = 'remove_ads';
  static const starterPack = 'starter_pack';
  static const coinsSmall = 'coins_small';
  static const coinsMedium = 'coins_medium';
  static const coinsLarge = 'coins_large';
}

/// RevenueCat entitlement granted by [ProductIds.removeAds].
const String removeAdsEntitlement = 'remove_ads';

enum ProductKind { removeAds, coins }

/// What each product grants. Prices come from the store, never from here.
class CatalogItem {
  const CatalogItem(this.id, this.kind, {this.coins = 0, this.oneTime = false});

  final String id;
  final ProductKind kind;
  final int coins;

  /// Can be bought only once (Remove Ads, starter pack).
  final bool oneTime;
}

const List<CatalogItem> catalog = [
  CatalogItem(ProductIds.removeAds, ProductKind.removeAds, oneTime: true),
  CatalogItem(
    ProductIds.starterPack,
    ProductKind.coins,
    coins: 1500,
    oneTime: true,
  ),
  CatalogItem(ProductIds.coinsSmall, ProductKind.coins, coins: 1000),
  CatalogItem(ProductIds.coinsMedium, ProductKind.coins, coins: 3000),
  CatalogItem(ProductIds.coinsLarge, ProductKind.coins, coins: 8000),
];

CatalogItem? catalogItem(String id) {
  for (final c in catalog) {
    if (c.id == id) return c;
  }
  return null;
}

/// A product as the store describes it.
class StoreProductInfo {
  const StoreProductInfo({required this.id, required this.price});

  final String id;

  /// Localized real-money price string from the store, e.g. "₹99.00".
  final String price;
}

enum PurchaseOutcome { success, cancelled, failed }

abstract class PurchasesService {
  /// Whether real purchases can be made in this build.
  bool get available;

  Future<void> initialize();

  /// Products currently on sale, with store prices.
  Future<List<StoreProductInfo>> products();

  Future<PurchaseOutcome> purchase(String productId);

  /// Restores past purchases; returns whether Remove Ads is owned.
  Future<bool> restore();

  Future<bool> hasRemoveAds();
}

/// Scripted fake for tests and local mode.
class FakePurchasesService implements PurchasesService {
  FakePurchasesService({
    this.available = true,
    this.outcome = PurchaseOutcome.success,
    this.ownsRemoveAds = false,
  });

  @override
  bool available;
  PurchaseOutcome outcome;
  bool ownsRemoveAds;
  final List<String> purchased = [];

  static const _prices = {
    ProductIds.removeAds: '₹249.00',
    ProductIds.starterPack: '₹49.00',
    ProductIds.coinsSmall: '₹89.00',
    ProductIds.coinsMedium: '₹229.00',
    ProductIds.coinsLarge: '₹449.00',
  };

  @override
  Future<void> initialize() async {}

  @override
  Future<List<StoreProductInfo>> products() async => [
    if (available)
      for (final c in catalog)
        StoreProductInfo(id: c.id, price: _prices[c.id]!),
  ];

  @override
  Future<PurchaseOutcome> purchase(String productId) async {
    if (!available) return PurchaseOutcome.failed;
    if (outcome == PurchaseOutcome.success) {
      purchased.add(productId);
      if (productId == ProductIds.removeAds) ownsRemoveAds = true;
    }
    return outcome;
  }

  @override
  Future<bool> restore() async => ownsRemoveAds;

  @override
  Future<bool> hasRemoveAds() async => ownsRemoveAds;
}

/// Used when a build has no store configuration: the shop shows that
/// purchases are unavailable instead of pretending.
class NoPurchasesService implements PurchasesService {
  @override
  bool get available => false;
  @override
  Future<void> initialize() async {}
  @override
  Future<List<StoreProductInfo>> products() async => const [];
  @override
  Future<PurchaseOutcome> purchase(String productId) async =>
      PurchaseOutcome.failed;
  @override
  Future<bool> restore() async => false;
  @override
  Future<bool> hasRemoveAds() async => false;
}
