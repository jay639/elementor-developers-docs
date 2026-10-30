/// Store products. IDs must match App Store Connect / Play Console and the
/// RevenueCat dashboard (see README).
enum ProductKind { nonConsumable, consumable }

class ProductDef {
  const ProductDef({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    this.coins = 0,
    this.skin,
    this.entitlement,
    this.fallbackPrice = '',
  });

  final String id;
  final ProductKind kind;
  final String title;
  final String description;

  /// Coins granted (consumables each time; bundles once).
  final int coins;

  /// Skin granted once.
  final String? skin;

  /// RevenueCat entitlement this product unlocks.
  final String? entitlement;

  /// Shown only if the store hasn't returned a localized price yet.
  final String fallbackPrice;
}

abstract final class Products {
  static const noAdsEntitlement = 'no_ads';
  static const starterEntitlement = 'starter';

  static const removeAds = ProductDef(
    id: 'remove_ads',
    kind: ProductKind.nonConsumable,
    title: 'Remove ads',
    description:
        'No more interstitials or banners. Rewarded videos stay optional.',
    entitlement: noAdsEntitlement,
    fallbackPrice: r'$3.99',
  );

  static const starterBundle = ProductDef(
    id: 'starter_bundle',
    kind: ProductKind.nonConsumable,
    title: 'Starter bundle',
    description: 'Remove ads + 1,500 coins + the Neon skin.',
    coins: 1500,
    skin: 'neon',
    entitlement: starterEntitlement,
    fallbackPrice: r'$4.99',
  );

  static const coinsSmall = ProductDef(
    id: 'coins_500',
    kind: ProductKind.consumable,
    title: '500 coins',
    description: 'A handful of coins.',
    coins: 500,
    fallbackPrice: r'$0.99',
  );

  static const coinsMedium = ProductDef(
    id: 'coins_1500',
    kind: ProductKind.consumable,
    title: '1,500 coins',
    description: 'A bag of coins. Best for skins.',
    coins: 1500,
    fallbackPrice: r'$2.99',
  );

  static const coinsLarge = ProductDef(
    id: 'coins_5000',
    kind: ProductKind.consumable,
    title: '5,000 coins',
    description: 'A chest of coins. Best value.',
    coins: 5000,
    fallbackPrice: r'$7.99',
  );

  static const all = [
    removeAds,
    starterBundle,
    coinsSmall,
    coinsMedium,
    coinsLarge,
  ];

  static ProductDef? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
