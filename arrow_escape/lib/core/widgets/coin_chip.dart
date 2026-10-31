import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Coin balance; tapping opens the shop.
class CoinChip extends ConsumerWidget {
  const CoinChip({super.key, this.openShop = true});

  final bool openShop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(saveProvider.select((s) => s.coins));
    return Semantics(
      button: openShop,
      label: '$coins coins${openShop ? ', open shop' : ''}',
      excludeSemantics: true,
      child: StatPill(
        key: const Key('coin-chip'),
        icon: Icons.monetization_on_rounded,
        iconColor: Palette.sun,
        value: TweenAnimationBuilder<int>(
          tween: IntTween(end: coins),
          duration: const Duration(milliseconds: 500),
          builder: (context, v, _) => Text('$v'),
        ),
        onTap: openShop ? () => context.push(Routes.shop) : null,
      ),
    );
  }
}
