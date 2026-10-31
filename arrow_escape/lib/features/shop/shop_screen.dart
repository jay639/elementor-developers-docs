import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/coin_chip.dart';
import 'package:arrow_escape/features/purchases/application/entitlements.dart';
import 'package:arrow_escape/features/purchases/data/purchase_service.dart';
import 'package:arrow_escape/features/purchases/domain/products.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _busy;

  Future<void> _run(
    String id,
    Future<PurchaseOutcome> Function() action,
  ) async {
    if (_busy != null) return;
    setState(() => _busy = id);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await action();
    if (!mounted) return;
    setState(() => _busy = null);
    final text = switch (outcome.status) {
      PurchaseStatus.success =>
        id == 'restore'
            ? 'Purchases restored.'
            : 'Thank you! Your purchase is ready.',
      PurchaseStatus.cancelled => null,
      PurchaseStatus.failed => outcome.message ?? 'Purchase failed.',
      PurchaseStatus.unavailable =>
        outcome.message ?? 'The store is not available right now.',
    };
    if (text != null) {
      // Replace rather than queue behind the previous message.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final entitlements = ref.watch(entitlementsProvider);
    final controller = ref.read(purchaseControllerProvider);
    final theme = Theme.of(context);

    ProductInfo info(ProductDef d) =>
        products.value?.firstWhere(
          (p) => p.def.id == d.id,
          orElse: () => ProductInfo(d),
        ) ??
        ProductInfo(d);

    Widget tile(ProductDef d, {required IconData icon, bool owned = false}) {
      final p = info(d);
      return Card(
        child: ListTile(
          key: Key('product-${d.id}'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          ),
          title: Text(d.title, style: theme.textTheme.titleMedium),
          subtitle: Text(d.description),
          trailing: owned
              ? const Chip(
                  avatar: Icon(Icons.check_rounded, color: Palette.success),
                  label: Text('Owned'),
                )
              : FilledButton(
                  key: Key('buy-${d.id}'),
                  onPressed: _busy == null
                      ? () => _run(d.id, () => controller.buy(d))
                      : null,
                  child: _busy == d.id
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(p.displayPrice),
                ),
        ),
      );
    }

    return Backdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Shop'),
          actions: const [CoinChip(openShop: false), SizedBox(width: 12)],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            tile(
              Products.starterBundle,
              icon: Icons.card_giftcard_rounded,
              owned: entitlements.starter,
            ),
            const SizedBox(height: 8),
            tile(
              Products.removeAds,
              icon: Icons.block_rounded,
              owned: entitlements.noAds,
            ),
            const SizedBox(height: 20),
            Text('Coins', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            tile(Products.coinsSmall, icon: Icons.monetization_on_outlined),
            const SizedBox(height: 8),
            tile(Products.coinsMedium, icon: Icons.monetization_on_rounded),
            const SizedBox(height: 8),
            tile(Products.coinsLarge, icon: Icons.savings_rounded),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                key: const Key('restore'),
                onPressed: _busy == null
                    ? () => _run('restore', controller.restore)
                    : null,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Restore purchases'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment is charged to your App Store or Google Play account. '
              'Coin packs are consumable; Remove ads and the Starter bundle '
              'are one-time purchases you can restore on any device.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
