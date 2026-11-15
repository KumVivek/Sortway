import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../services/audio_service.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'parental_gate.dart';
import 'purchases_service.dart';

final shopProductsProvider = FutureProvider.autoDispose<List<StoreProductInfo>>(
  (ref) => ref.watch(purchasesServiceProvider).products(),
);

const _starterBoughtKey = 'starter_bought';

/// Shop: Remove Ads and coin packs. No random rewards, no countdown
/// pressure; every price is the store's real-money price, shown up front.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _buying;
  final _viewed = <String>{};

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _buy(StoreProductInfo product) async {
    final item = catalogItem(product.id);
    if (item == null || _buying != null) return;
    final l = context.l10n;
    final policy = ref.read(agePolicyProvider);
    if (policy.purchasesNeedGate) {
      final passed = await showParentalGate(
        context,
        price: product.price,
        random: ref.read(randomProvider),
      );
      if (!passed || !mounted) return;
    }
    setState(() => _buying = product.id);
    final outcome = await ref
        .read(purchasesServiceProvider)
        .purchase(product.id);
    if (outcome == PurchaseOutcome.success) {
      switch (item.kind) {
        case ProductKind.removeAds:
          await ref.read(removeAdsProvider.notifier).set(owned: true);
        case ProductKind.coins:
          await ref.read(gameStoreProvider).addCoins(item.coins);
          ref.read(audioServiceProvider).play(Sfx.coin);
      }
      if (item.id == ProductIds.starterPack) {
        await ref
            .read(settingsStoreProvider)
            .setBool(_starterBoughtKey, value: true);
      }
      ref
          .read(analyticsProvider)
          .iapPurchase(product: product.id, price: product.price);
    }
    if (!mounted) return;
    setState(() => _buying = null);
    switch (outcome) {
      case PurchaseOutcome.success:
        _toast(l.purchaseDone);
      case PurchaseOutcome.failed:
        _toast(l.purchaseFailed);
      case PurchaseOutcome.cancelled:
        break;
    }
  }

  Future<void> _restore() async {
    final l = context.l10n;
    final owned = await ref.read(purchasesServiceProvider).restore();
    if (owned) await ref.read(removeAdsProvider.notifier).set(owned: true);
    if (mounted) _toast(owned ? l.restored : l.nothingToRestore);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final products = ref.watch(shopProductsProvider);
    final removeAds = ref.watch(removeAdsProvider);
    final starterBought =
        ref.watch(settingsStoreProvider).getBool(_starterBoughtKey) ?? false;
    return AppScaffold(
      title: l.shopTitle,
      actions: const [CoinChip()],
      body: products.when(
        loading: () => const LoadingView(),
        error:
            (_, __) =>
                ErrorView(onRetry: () => ref.invalidate(shopProductsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.storeUnavailable,
                  key: const Key('store-unavailable'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          for (final p in list) {
            if (_viewed.add(p.id)) {
              ref
                  .read(analyticsProvider)
                  .iapView(product: p.id, price: p.price);
            }
          }
          return ContentWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.textDim,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.realMoney,
                      style: const TextStyle(color: AppColors.textDim),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final p in list)
                  if (catalogItem(p.id) case final item?)
                    if (!(item.id == ProductIds.starterPack && starterBought))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProductCard(
                          product: p,
                          item: item,
                          owned:
                              item.kind == ProductKind.removeAds && removeAds,
                          busy: _buying == p.id,
                          onBuy: _buying == null ? () => _buy(p) : null,
                        ),
                      ),
                const SizedBox(height: 4),
                TextButton(
                  key: const Key('restore'),
                  onPressed: _restore,
                  child: Text(l.restorePurchases),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.item,
    required this.owned,
    required this.busy,
    required this.onBuy,
  });

  final StoreProductInfo product;
  final CatalogItem item;
  final bool owned;
  final bool busy;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (title, subtitle, icon) = switch (item.id) {
      ProductIds.removeAds => (
        l.removeAds,
        l.removeAdsDesc,
        Icons.block_rounded,
      ),
      ProductIds.starterPack => (
        l.starterPack,
        l.starterDesc(item.coins),
        Icons.card_giftcard_rounded,
      ),
      _ => (l.coinPack(item.coins), null, Icons.savings_rounded),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (owned)
              Text(
                l.owned,
                style: const TextStyle(
                  color: AppColors.good,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              FilledButton(
                key: Key('buy-${item.id}'),
                style: FilledButton.styleFrom(minimumSize: const Size(88, 46)),
                onPressed: onBuy,
                child:
                    busy
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(product.price),
              ),
          ],
        ),
      ),
    );
  }
}
