import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/utils/clock.dart';
import 'package:arrow_escape/core/widgets/arrow_logo.dart';
import 'package:arrow_escape/core/widgets/coin_chip.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/ads/presentation/rewarded.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/domain/economy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final save = ref.watch(saveProvider);
    final now = ref.watch(clockProvider)();
    final count = ref.watch(levelRepositoryProvider).count;
    final next = save.progress.unlocked.clamp(1, count);
    final dailyDone =
        save.progress.dailyStarsFor(DailyChallenge.keyFor(now)) > 0;
    final streak = Economy.currentStreak(save, now);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              label: '$streak day streak',
              excludeSemantics: true,
              child: Chip(
                key: const Key('streak'),
                avatar: Icon(
                  Icons.local_fire_department_rounded,
                  color: streak > 0 ? Palette.secondary : theme.disabledColor,
                ),
                label: Text('$streak'),
              ),
            ),
          ),
        ),
        actions: [
          const CoinChip(),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(Routes.settings),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    const ArrowLogo(size: 112),
                    const SizedBox(height: 16),
                    Text('Arrow Escape', style: theme.textTheme.displaySmall),
                    Text(
                      'Traffic Puzzle',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: '${save.progress.totalStars} stars collected',
                      excludeSemantics: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Palette.star),
                          const SizedBox(width: 4),
                          Text(
                            '${save.progress.totalStars}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (Economy.canClaimDailyReward(save, now)) ...[
                      const _DailyRewardCard(),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('play'),
                        onPressed: () => context.push(Routes.game(next)),
                        icon: const Icon(Icons.play_arrow_rounded, size: 30),
                        label: Text('Play  ·  Level $next'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeTile(
                            key: const Key('map'),
                            icon: Icons.location_city_rounded,
                            label: 'City map',
                            onTap: () => context.push(Routes.map),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HomeTile(
                            key: const Key('daily'),
                            icon: dailyDone
                                ? Icons.check_circle_rounded
                                : Icons.calendar_today_rounded,
                            iconColor: dailyDone ? Palette.success : null,
                            label: dailyDone ? 'Daily done' : 'Daily',
                            onTap: () => context.push(Routes.daily),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeTile(
                            key: const Key('skins'),
                            icon: Icons.palette_rounded,
                            label: 'Skins',
                            onTap: () => context.push(Routes.skins),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HomeTile(
                            key: const Key('shop'),
                            icon: Icons.storefront_rounded,
                            label: 'Shop',
                            onTap: () => context.push(Routes.shop),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
      icon: Icon(icon, color: iconColor),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

class _DailyRewardCard extends ConsumerWidget {
  const _DailyRewardCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final save = ref.watch(saveProvider);
    final now = ref.watch(clockProvider)();
    final amount = Economy.nextDailyReward(save, now);
    final controller = ref.read(saveProvider.notifier);

    void claimed(int coins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$coins coins! Come back tomorrow for more.')),
      );
    }

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.redeem_rounded, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daily reward: $amount coins',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const Key('claim-reward'),
                    onPressed: () => claimed(controller.claimDailyReward()),
                    child: const Text('Claim'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('claim-reward-x2'),
                    onPressed: () async {
                      if (await watchRewarded(
                        context,
                        ref,
                        RewardKind.doubleDailyReward,
                      )) {
                        claimed(controller.claimDailyReward(multiplier: 2));
                      }
                    },
                    icon: const Icon(Icons.smart_display_rounded),
                    label: const Text('x2'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
