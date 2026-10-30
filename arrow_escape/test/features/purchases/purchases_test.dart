import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/purchases/application/entitlements.dart';
import 'package:arrow_escape/features/purchases/data/purchase_service.dart';
import 'package:arrow_escape/features/purchases/domain/products.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late ProviderContainer c;
  late FakePurchaseService store;
  late FakeAdService ads;
  late RecordingAnalytics analytics;

  setUp(() {
    store = FakePurchaseService();
    ads = FakeAdService();
    analytics = RecordingAnalytics();
    c = ProviderContainer(
      overrides: testOverrides(
        purchases: store,
        ads: ads,
        analytics: analytics,
      ),
    );
    addTearDown(c.dispose);
    c.listen(entitlementsProvider, (_, _) {});
  });

  test('coin packs grant coins each time', () async {
    final controller = c.read(purchaseControllerProvider);
    await controller.buy(Products.coinsMedium);
    await controller.buy(Products.coinsMedium);
    expect(c.read(saveProvider).coins, 3000);
    expect(analytics.events.last.name, 'purchase_success');
  });

  test('failed or cancelled purchases grant nothing', () async {
    store.next = PurchaseStatus.cancelled;
    await c.read(purchaseControllerProvider).buy(Products.coinsLarge);
    expect(c.read(saveProvider).coins, 0);
    expect(analytics.events.last.name, 'purchase_fail');
  });

  test('remove_ads comes from the entitlement and turns ads off', () async {
    expect(c.read(noAdsProvider), isFalse);
    await c.read(purchaseControllerProvider).buy(Products.removeAds);
    await pumpEventQueue();
    expect(c.read(noAdsProvider), isTrue);
    expect(ads.adsRemoved, isTrue);
    expect(c.read(saveProvider).coins, 0);
  });

  test('starter bundle removes ads and grants its perks once', () async {
    await c.read(purchaseControllerProvider).buy(Products.starterBundle);
    await pumpEventQueue();
    expect(c.read(noAdsProvider), isTrue);
    expect(c.read(saveProvider).coins, 1500);
    expect(c.read(saveProvider).owns('neon'), isTrue);
    // A restore re-announces the entitlement: no double grant.
    store.grant(Products.starterEntitlement);
    store.grant('something_else');
    await pumpEventQueue();
    expect(c.read(saveProvider).coins, 1500);
  });

  test('without a store everything is politely unavailable', () async {
    final none = UnavailablePurchaseService();
    expect((await none.buy('remove_ads')).status, PurchaseStatus.unavailable);
    expect(await none.loadProducts(), hasLength(Products.all.length));
    expect(none.entitlements.noAds, isFalse);
  });

  test('NoAdService never shows anything', () async {
    final none = NoAdService();
    expect(await none.showRewarded(RewardKind.hint), isFalse);
    expect(none.rewardedReady, isFalse);
  });
}
