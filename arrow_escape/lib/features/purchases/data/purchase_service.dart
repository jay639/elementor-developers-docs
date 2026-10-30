import 'dart:async';

import 'package:arrow_escape/features/purchases/domain/products.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active entitlements, as reported by the store backend.
@immutable
class Entitlements {
  const Entitlements({this.active = const {}});

  final Set<String> active;

  bool get noAds =>
      active.contains(Products.noAdsEntitlement) ||
      active.contains(Products.starterEntitlement);
  bool get starter => active.contains(Products.starterEntitlement);

  @override
  bool operator ==(Object other) =>
      other is Entitlements && setEquals(other.active, active);

  @override
  int get hashCode => Object.hashAllUnordered(active);
}

/// A product with the store's localized price.
class ProductInfo {
  const ProductInfo(this.def, {this.price});

  final ProductDef def;
  final String? price;

  String get displayPrice => price ?? def.fallbackPrice;
}

enum PurchaseStatus { success, cancelled, failed, unavailable }

class PurchaseOutcome {
  const PurchaseOutcome(this.status, [this.message]);

  final PurchaseStatus status;
  final String? message;

  bool get ok => status == PurchaseStatus.success;
}

abstract interface class PurchaseService {
  Future<void> initialize();

  /// Ties purchases to the signed-in (anonymous) user.
  Future<void> identify(String userId);

  bool get available;
  Entitlements get entitlements;
  Stream<Entitlements> get entitlementChanges;

  Future<List<ProductInfo>> loadProducts();
  Future<PurchaseOutcome> buy(String productId);
  Future<PurchaseOutcome> restore();
}

/// No store configured (tests, missing API key).
class UnavailablePurchaseService implements PurchaseService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> identify(String userId) async {}

  @override
  bool get available => false;

  @override
  Entitlements get entitlements => const Entitlements();

  @override
  Stream<Entitlements> get entitlementChanges => const Stream.empty();

  @override
  Future<List<ProductInfo>> loadProducts() async => [
    for (final d in Products.all) ProductInfo(d),
  ];

  @override
  Future<PurchaseOutcome> buy(String productId) async => const PurchaseOutcome(
    PurchaseStatus.unavailable,
    'The store is not available right now.',
  );

  @override
  Future<PurchaseOutcome> restore() async => const PurchaseOutcome(
    PurchaseStatus.unavailable,
    'The store is not available right now.',
  );
}

/// Overridden in bootstrap.
final purchaseServiceProvider = Provider<PurchaseService>(
  (ref) => UnavailablePurchaseService(),
);
