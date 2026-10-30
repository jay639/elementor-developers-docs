import 'dart:async';

import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/purchases/data/purchase_service.dart';
import 'package:arrow_escape/features/purchases/domain/products.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live entitlements from the store backend.
final entitlementsProvider =
    NotifierProvider<EntitlementsController, Entitlements>(
      EntitlementsController.new,
    );

class EntitlementsController extends Notifier<Entitlements> {
  StreamSubscription<Entitlements>? _sub;

  @override
  Entitlements build() {
    final service = ref.watch(purchaseServiceProvider);
    _sub?.cancel();
    _sub = service.entitlementChanges.listen(_set);
    ref.onDispose(() => _sub?.cancel());
    _sync(service.entitlements);
    return service.entitlements;
  }

  void _set(Entitlements e) {
    state = e;
    _sync(e);
  }

  /// Keeps the ad layer and one-time bundle perks in step.
  void _sync(Entitlements e) {
    ref.read(adServiceProvider).adsRemoved = e.noAds;
    if (e.starter) {
      // Microtask: build() can't modify other providers synchronously.
      scheduleMicrotask(() {
        final p = Products.starterBundle;
        ref
            .read(saveProvider.notifier)
            .claimBundle(p.id, coins: p.coins, skin: p.skin);
      });
    }
  }
}

/// True when interstitials and the banner must not show.
final noAdsProvider = Provider<bool>(
  (ref) => ref.watch(entitlementsProvider).noAds,
);

final productsProvider = FutureProvider.autoDispose<List<ProductInfo>>(
  (ref) => ref.watch(purchaseServiceProvider).loadProducts(),
);

final purchaseControllerProvider = Provider<PurchaseController>(
  PurchaseController.new,
);

/// Runs purchases and grants what they pay for.
class PurchaseController {
  PurchaseController(this._ref);

  final Ref _ref;

  Future<PurchaseOutcome> buy(ProductDef product) async {
    final service = _ref.read(purchaseServiceProvider);
    final analytics = _ref.read(analyticsProvider);
    final outcome = await service.buy(product.id);
    await analytics.purchase(
      product.id,
      success: outcome.ok,
      error: outcome.ok ? null : outcome.status.name,
    );
    if (outcome.ok && product.kind == ProductKind.consumable) {
      _ref.read(saveProvider.notifier).addCoins(product.coins);
    }
    // Non-consumables (remove ads, starter) arrive through entitlements.
    return outcome;
  }

  Future<PurchaseOutcome> restore() =>
      _ref.read(purchaseServiceProvider).restore();
}
