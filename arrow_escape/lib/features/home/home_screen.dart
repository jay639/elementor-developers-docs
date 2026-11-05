import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/services/sound.dart';
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
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:arrow_escape/features/onboarding/product_tour.dart';
import 'package:arrow_escape/features/onboarding/tips.dart';
import 'package:arrow_escape/core/services/analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _streakKey = GlobalKey();
  final _starsKey = GlobalKey();
  final _coinsKey = GlobalKey();
  final _collectionKey = GlobalKey();
  final _dailyKey = GlobalKey();
  final _cityKey = GlobalKey();
  final _shopKey = GlobalKey();

  void _endTour(bool finished) {
    ref.read(saveProvider.notifier).markSeen(Tips.homeTour);
    ref.read(analyticsProvider).log(finished ? 'tour_complete' : 'tour_skip');
  }

  List<TourStep> get _tour => [
    TourStep(
      target: _streakKey,
      icon: Icons.local_fire_department_rounded,
      color: Palette.secondary,
      title: 'Daily streak',
      body:
          'Win at least one puzzle every day to grow your streak. '
          'Miss a day and it starts again.',
    ),
    TourStep(
      target: _starsKey,
      icon: Icons.star_rounded,
      color: Palette.sun,
      title: 'Stars',
      body:
          'Earn up to 3 stars per level by losing fewer hearts. '
          'Stars unlock new Wonders in your Collection.',
    ),
    TourStep(
      target: _coinsKey,
      icon: Icons.monetization_on_rounded,
      color: Palette.sun,
      title: 'Coins',
      body:
          'Spend coins on arrow skins, or to skip a level that has you '
          'stuck. Tap here to get more.',
    ),
    TourStep(
      target: _collectionKey,
      icon: Icons.auto_awesome_rounded,
      color: Palette.pink,
      title: 'Collection',
      body:
          'Your Wonders (from a ladybug to a galaxy) and arrow skins live '
          'here.',
    ),
    TourStep(
      target: _dailyKey,
      icon: Icons.calendar_today_rounded,
      color: Palette.sun,
      title: 'Daily puzzle',
      body:
          'A new puzzle every day, the same for everyone. It gets harder '
          'through the week and pays big coins.',
    ),
    TourStep(
      target: _cityKey,
      icon: Icons.location_city_rounded,
      color: Palette.sky,
      title: 'City',
      body:
          'Every 10 levels you clear builds a new block of your city. '
          'Jump back to any level from the map.',
    ),
    TourStep(
      target: _shopKey,
      icon: Icons.storefront_rounded,
      color: Palette.secondary,
      title: 'Shop',
      body: 'Coin packs, the starter bundle and No Ads live here.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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

    final showTour =
        save.hasSeen(Tips.tutorial) && !save.hasSeen(Tips.homeTour);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _homeBody(
              context,
              save,
              now,
              next,
              dailyDone,
              streak,
              points,
              opened,
              nextPuzzle,
              theme,
            ),
          ),
          if (showTour)
            Positioned.fill(
              child: ProductTour(steps: _tour, onDone: _endTour),
            ),
        ],
      ),
    );
  }

  Widget _homeBody(
    BuildContext context,
    SaveData save,
    DateTime now,
    int next,
    bool dailyDone,
    int streak,
    int points,
    int opened,
    PuzzleShape? nextPuzzle,
    ThemeData theme,
  ) {
    return Backdrop(
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
                          key: _streakKey,
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
                          key: _starsKey,
                          label: '$points stars collected',
                          excludeSemantics: true,
                          child: StatPill(
                            icon: Icons.star_rounded,
                            iconColor: Palette.star,
                            value: Text('$points'),
                          ),
                        ),
                        const Spacer(),
                        CoinChip(key: _coinsKey),
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
                      onPressed: () {
                        ref.read(soundProvider).play(Sfx.nextLevel);
                        context.push(Routes.game(next));
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          key: _dailyKey,
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
                          key: _collectionKey,
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
                          key: _cityKey,
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
                          key: _shopKey,
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
