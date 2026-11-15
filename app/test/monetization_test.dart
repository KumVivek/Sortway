import 'package:flow_sort/features/monetization/ads_service.dart';
import 'package:flow_sort/features/monetization/purchases_service.dart';
import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flow_sort/services/remote_config_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('interstitial frequency caps', () {
    late DateTime now;
    late InterstitialPolicy policy;
    final config = RemoteConfigValues.defaults;

    setUp(() {
      now = DateTime(2026, 1, 1, 12);
      policy = InterstitialPolicy(clock: () => now);
    });

    void play(int levels) {
      for (var i = 0; i < levels; i++) {
        policy.onLevelFinished();
      }
    }

    bool show(int level, {bool removeAds = false}) => policy.shouldShow(
      levelNumber: level,
      config: config,
      removeAds: removeAds,
    );

    test('never before level 10', () {
      play(20);
      now = now.add(const Duration(hours: 1));
      expect(show(9), isFalse);
      expect(show(10), isTrue);
    });

    test('needs both the level gap and the time gap', () {
      play(3);
      expect(show(12), isFalse, reason: 'only seconds since app start');
      now = now.add(const Duration(seconds: 90));
      expect(show(12), isTrue);

      policy.onShown();
      now = now.add(const Duration(minutes: 5));
      play(2);
      expect(show(14), isFalse, reason: 'only two levels since the last one');
      play(1);
      expect(show(15), isTrue);

      policy.onShown();
      play(5);
      now = now.add(const Duration(seconds: 89));
      expect(show(20), isFalse, reason: '89 s since the last one');
    });

    test('Remove Ads turns them off', () {
      play(10);
      now = now.add(const Duration(hours: 1));
      expect(show(30, removeAds: true), isFalse);
    });
  });

  group('fakes', () {
    test('ads fake records policy and placements', () async {
      final ads = FakeAdsService();
      await ads.initialize(const AgePolicy(AgeBand.minor));
      expect(ads.profile!.nonPersonalizedOnly, isTrue);
      await ads.applyPolicy(const AgePolicy(AgeBand.adult));
      expect(ads.profile!.nonPersonalizedOnly, isFalse);
      expect(await ads.showRewarded(RewardedPlacement.undo), isTrue);
      expect(await ads.showInterstitial(), isTrue);
      ads.available = false;
      expect(await ads.showRewarded(RewardedPlacement.undo), isFalse);
      expect(await ads.showInterstitial(), isFalse);
      expect(ads.rewardedShown, [RewardedPlacement.undo]);
      expect(ads.interstitialsShown, 1);
    });

    test('no-ads and no-purchases services offer nothing', () async {
      final ads = NoAdsService();
      await ads.initialize(AgePolicy.unanswered);
      await ads.applyPolicy(AgePolicy.unanswered);
      expect(ads.available, isFalse);
      expect(await ads.showRewarded(RewardedPlacement.doubleCoins), isFalse);
      expect(await ads.showInterstitial(), isFalse);

      final shop = NoPurchasesService();
      await shop.initialize();
      expect(shop.available, isFalse);
      expect(await shop.products(), isEmpty);
      expect(await shop.purchase(ProductIds.removeAds), PurchaseOutcome.failed);
      expect(await shop.restore(), isFalse);
      expect(await shop.hasRemoveAds(), isFalse);
    });

    test('purchases fake', () async {
      final shop = FakePurchasesService();
      expect(await shop.products(), hasLength(catalog.length));
      expect(
        await shop.purchase(ProductIds.removeAds),
        PurchaseOutcome.success,
      );
      expect(await shop.hasRemoveAds(), isTrue);
      expect(await shop.restore(), isTrue);
      shop.outcome = PurchaseOutcome.cancelled;
      expect(
        await shop.purchase(ProductIds.coinsSmall),
        PurchaseOutcome.cancelled,
      );
      expect(shop.purchased, [ProductIds.removeAds]);
    });

    test('catalog has no random or duplicate products', () {
      expect({for (final c in catalog) c.id}, hasLength(catalog.length));
      expect(catalogItem(ProductIds.coinsLarge)!.coins, 8000);
      expect(catalogItem('loot_box'), isNull);
      expect(catalogItem(ProductIds.removeAds)!.oneTime, isTrue);
    });
  });
}
