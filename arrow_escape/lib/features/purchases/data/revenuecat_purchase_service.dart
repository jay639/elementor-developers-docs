import 'dart:async';
import 'dart:io' show Platform;

import 'package:arrow_escape/features/purchases/data/purchase_service.dart';
import 'package:arrow_escape/features/purchases/domain/products.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat-backed store. Entitlements always come from RevenueCat's
/// CustomerInfo (cached by the SDK for offline starts), never from a local
/// flag the player could flip.
class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService(this.apiKey);

  /// Public SDK key, injected with --dart-define (see README).
  final String apiKey;

  static String keyForPlatform() => Platform.isIOS
      ? const String.fromEnvironment('REVENUECAT_IOS_KEY')
      : const String.fromEnvironment('REVENUECAT_ANDROID_KEY');

  final _changes = StreamController<Entitlements>.broadcast();
  Entitlements _entitlements = const Entitlements();
  bool _configured = false;

  @override
  bool get available => _configured;

  @override
  Entitlements get entitlements => _entitlements;

  @override
  Stream<Entitlements> get entitlementChanges => _changes.stream;

  void _apply(CustomerInfo info) {
    final next = Entitlements(active: info.entitlements.active.keys.toSet());
    if (next == _entitlements) return;
    _entitlements = next;
    _changes.add(next);
  }

  @override
  Future<void> initialize() async {
    if (apiKey.isEmpty) return;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
    Purchases.addCustomerInfoUpdateListener(_apply);
    try {
      _apply(await Purchases.getCustomerInfo());
    } on PlatformException catch (e) {
      debugPrint('RevenueCat customer info: ${e.message}');
    }
    // Auto-restore: after a reinstall or on a new phone, Remove Ads comes
    // back without the player tapping anything. On Android this sync is
    // silent; on iOS it could ask for the Apple ID password, so iOS keeps
    // the explicit "Restore purchases" button (which Apple requires).
    if (Platform.isAndroid && _entitlements.active.isEmpty) {
      unawaited(
        Purchases.syncPurchasesForResult()
            .then((r) => _apply(r.customerInfo))
            .catchError((Object e) {
              debugPrint('RevenueCat sync: $e');
            }),
      );
    }
  }

  @override
  Future<void> identify(String userId) async {
    if (!_configured) return;
    try {
      final result = await Purchases.logIn(userId);
      _apply(result.customerInfo);
    } on PlatformException catch (e) {
      debugPrint('RevenueCat logIn: ${e.message}');
    }
  }

  Future<Map<String, Package>> _packages() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    return {
      for (final p in current?.availablePackages ?? const <Package>[])
        p.storeProduct.identifier: p,
    };
  }

  @override
  Future<List<ProductInfo>> loadProducts() async {
    if (!_configured) return [for (final d in Products.all) ProductInfo(d)];
    try {
      final packages = await _packages();
      return [
        for (final d in Products.all)
          ProductInfo(
            d,
            price: _match(packages, d.id)?.storeProduct.priceString,
          ),
      ];
    } on PlatformException catch (e) {
      debugPrint('RevenueCat offerings: ${e.message}');
      return [for (final d in Products.all) ProductInfo(d)];
    }
  }

  /// Play product ids may carry a base-plan suffix (`id:plan`).
  static Package? _match(Map<String, Package> packages, String id) {
    for (final e in packages.entries) {
      if (e.key == id || e.key.startsWith('$id:')) return e.value;
    }
    return null;
  }

  @override
  Future<PurchaseOutcome> buy(String productId) async {
    if (!_configured) {
      return const PurchaseOutcome(PurchaseStatus.unavailable);
    }
    try {
      final package = _match(await _packages(), productId);
      if (package == null) {
        return const PurchaseOutcome(
          PurchaseStatus.failed,
          'This item is not available.',
        );
      }
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _apply(result.customerInfo);
      return const PurchaseOutcome(PurchaseStatus.success);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseOutcome(PurchaseStatus.cancelled);
      }
      return PurchaseOutcome(PurchaseStatus.failed, e.message);
    }
  }

  @override
  Future<PurchaseOutcome> restore() async {
    if (!_configured) {
      return const PurchaseOutcome(PurchaseStatus.unavailable);
    }
    try {
      _apply(await Purchases.restorePurchases());
      return const PurchaseOutcome(PurchaseStatus.success);
    } on PlatformException catch (e) {
      return PurchaseOutcome(PurchaseStatus.failed, e.message);
    }
  }
}
