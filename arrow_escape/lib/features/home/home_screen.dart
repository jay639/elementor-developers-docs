import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/utils/clock.dart';
import 'package:arrow_escape/core/widgets/arrow_logo.dart';
import 'package:arrow_escape/core/widgets/coin_chip.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/ads/presentation/rewarded.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/puzzles/puzzle_progress.dart';
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
    final points = save.progress.points;
    final opened = [
      for (final s in ShapePuzzles.all)
        if (save.progress.puzzleUnlocked(s)) s,
    ].length;
    final nextPuzzle = nextLockedPuzzle(save.progress);

    return Scaffold(
      body: Backdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Semantics(
                            label: '$streak day streak',
                            excludeSemantics: true,
                            child: StatPill(
                              key: const Key('streak'),
                              icon: Icons.local_fire_department_rounded,
                              iconColor: streak > 0
                                  ? Palette.secondary
                                  : theme.disabledColor,
                              value: Text('$streak'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            label: '$points stars collected',
                            excludeSemantics: true,
                            child: StatPill(
                              icon: Icons.star_rounded,
                              iconColor: Palette.star,
                              value: Text('$points'),
                            ),
                          ),
                          const Spacer(),
                          const CoinChip(),
                          IconButton(
                            tooltip: 'Settings',
                            icon: const Icon(Icons.settings_rounded),
                            onPressed: () => context.push(Routes.settings),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 12),
                      const ArrowLogo(size: 120),
                      const SizedBox(height: 10),
                      Text(
                        'Arrow Escape',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Palette.primaryDeep,
                        ),
                      ),
                      Text(
                        'TRAFFIC PUZZLE',
                        style: theme.textTheme.titleMedium?.copyWith(
                          letterSpacing: 4,
                          color: theme.brightness == Brightness.dark
                              ? Palette.secondary
                              : const Color(0xFFC0391B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      if (Economy.canClaimDailyReward(save, now)) ...[
                        const _DailyRewardCard(),
                        const SizedBox(height: 16),
                      ],
                      CandyButton(
                        key: const Key('play'),
                        icon: Icons.play_arrow_rounded,
                        label: 'Play  ·  Level $next',
                        onPressed: () => context.push(Routes.game(next)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _HomeTile(
                              key: const Key('daily'),
                              icon: dailyDone
                                  ? Icons.check_rounded
                                  : Icons.calendar_today_rounded,
                              colors: dailyDone
                                  ? const [Color(0xFF3FE0B0), Palette.tertiary]
                                  : const [Color(0xFFFFD25E), Palette.sun],
                              label: 'Daily',
                              detail: dailyDone ? 'Done today' : 'New puzzle',
                              onTap: () => context.push(Routes.daily),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HomeTile(
                              key: const Key('collection'),
                              icon: Icons.auto_awesome_rounded,
                              colors: const [Palette.pink, Palette.primary],
                              label: 'Collection',
                              detail: nextPuzzle == null
                                  ? 'All $opened open'
                                  : '$opened / ${ShapePuzzles.all.length} '
                                        'open',
                              onTap: () => context.push(Routes.collection),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _HomeTile(
                              key: const Key('map'),
                              icon: Icons.location_city_rounded,
                              colors: const [Color(0xFF7CC8FF), Palette.sky],
                              label: 'City',
                              detail: 'Your map',
                              onTap: () => context.push(Routes.map),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HomeTile(
                              key: const Key('shop'),
                              icon: Icons.storefront_rounded,
                              colors: const [
                                Color(0xFFFF9A7A),
                                Palette.secondary,
                              ],
                              label: 'Shop',
                              detail: 'Coins & more',
                              onTap: () => context.push(Routes.shop),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
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
    required this.colors,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> colors;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '$label, $detail',
      excludeSemantics: true,
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        child: Column(
          children: [
            IconBubble(icon: icon, colors: colors, size: 50),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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

    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.redeem_rounded,
                colors: [Color(0xFFFFD25E), Palette.sun],
                size: 44,
              ),
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
    );
  }
}
