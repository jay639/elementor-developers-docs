import 'dart:async';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/ads/presentation/rewarded.dart';
import 'package:arrow_escape/core/services/sound.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:arrow_escape/features/game/application/game_controller.dart';
import 'package:arrow_escape/features/game/application/game_state.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/features/game/presentation/board_view.dart';
import 'package:arrow_escape/features/onboarding/tips.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/game/presentation/widgets/game_toolbar.dart';
import 'package:arrow_escape/features/game/presentation/widgets/hearts_bar.dart';
import 'package:arrow_escape/features/game/presentation/widgets/result_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Loads the level (campaign pack or generated daily), then shows the board.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key, required this.levelRef});

  final LevelRef levelRef;

  /// App bar title for [ref].
  static String titleFor(LevelRef ref) => switch (ref) {
    CampaignLevelRef(:final number) => 'Level $number',
    DailyLevelRef(:final dateKey) => 'Daily · ${_shortDate(dateKey)}',
    PuzzleLevelRef(:final shape, :final layer) =>
      '${ShapePuzzles.byId(shape).name} · Layer $layer',
  };

  static String _shortDate(String key) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = DailyChallenge.parseKey(key);
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(levelProvider(levelRef));
    return level.when(
      data: (_) => _GameView(key: ValueKey(levelRef), levelRef: levelRef),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(titleFor(levelRef))),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(titleFor(levelRef))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load this level.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(levelProvider(levelRef)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameView extends ConsumerStatefulWidget {
  const _GameView({super.key, required this.levelRef});

  final LevelRef levelRef;

  @override
  ConsumerState<_GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<_GameView> {
  /// Lets the final exit (or bump) animation play before the result card.
  static const _resultDelay = Duration(milliseconds: 550);

  Timer? _resultTimer;
  bool _showResult = false;

  /// Hard / Super Hard announcement, shown for a moment at start.
  Timer? _introTimer;
  bool _introChecked = false;

  /// A mechanic seen here for the first time, explained before play.
  Mechanic? _mechanicIntro;

  void _closeMechanicIntro() {
    final m = _mechanicIntro;
    if (m == null) return;
    ref.read(saveProvider.notifier).markSeen(Tips.mechanic(m));
    ref.read(analyticsProvider).log('tip_shown', {'tip': Tips.mechanic(m)});
    setState(() => _mechanicIntro = null);
  }

  bool _showTierIntro = false;

  @override
  void initState() {
    super.initState();
    ref.read(soundProvider).warmUp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_introChecked) return;
    _introChecked = true;
    final level = ref.read(gameControllerProvider(widget.levelRef)).level;
    final save = ref.read(saveProvider);
    for (final m in Mechanic.inLevel(level)) {
      if (!save.hasSeen(Tips.mechanic(m))) {
        _mechanicIntro = m;
        // One card at a time: the tier banner still shows in the strip.
        return;
      }
    }
    if (level.meta.tier == LevelTier.normal || widget.levelRef.isDaily) return;
    _showTierIntro = true;
    _introTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showTierIntro = false);
    });
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _resultTimer?.cancel();
    super.dispose();
  }

  void _onStatus(SessionStatus? prev, SessionStatus next) {
    _resultTimer?.cancel();
    if (next == SessionStatus.playing) {
      if (_showResult) setState(() => _showResult = false);
      return;
    }
    _resultTimer = Timer(_resultDelay, () async {
      final levelRef = widget.levelRef;
      // Interstitials only ever follow a finished campaign level (the
      // frequency policy decides), never precede one.
      if (next == SessionStatus.won && levelRef is CampaignLevelRef) {
        await ref.read(adServiceProvider).onLevelCompleted(levelRef.number);
      }
      if (mounted) setState(() => _showResult = true);
    });
  }

  Future<void> _hint() async {
    final controller = ref.read(
      gameControllerProvider(widget.levelRef).notifier,
    );
    if (await watchRewarded(context, ref, RewardKind.hint)) {
      controller.showHint();
    }
  }

  Future<void> _extraHeart() async {
    final controller = ref.read(
      gameControllerProvider(widget.levelRef).notifier,
    );
    if (await watchRewarded(context, ref, RewardKind.extraHeart)) {
      controller.addHeart();
    }
  }

  Future<void> _doubleCoins() async {
    final controller = ref.read(
      gameControllerProvider(widget.levelRef).notifier,
    );
    if (await watchRewarded(context, ref, RewardKind.doubleCoins)) {
      controller.doubleCoins();
    }
  }

  void _goTo(String route) => context.pushReplacement(route);

  @override
  Widget build(BuildContext context) {
    final levelRef = widget.levelRef;
    final provider = gameControllerProvider(levelRef);
    ref.listen(provider.select((s) => s.status), _onStatus);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final levelCount = ref.watch(levelRepositoryProvider).count;
    final String? next = switch (levelRef) {
      CampaignLevelRef(:final number) when number < levelCount => Routes.game(
        number + 1,
      ),
      PuzzleLevelRef(:final shape, :final layer)
          when layer < PuzzleShape.layerCount =>
        Routes.puzzleGame(shape, layer + 1),
      _ => null,
    };
    final doneRoute = switch (levelRef) {
      DailyLevelRef() => Routes.daily,
      PuzzleLevelRef() => Routes.collection,
      CampaignLevelRef() => Routes.home,
    };

    return Backdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          title: Text(GameScreen.titleFor(levelRef)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: HeartsBar(
                hearts: state.session.hearts,
                max: state.session.maxHearts,
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                children: [
                  if (state.tutorial != TutorialStep.none)
                    _TutorialCallout(
                      step: state.tutorial,
                      onSkip: controller.skipTutorial,
                    )
                  else
                    _MechanicBanner(state: state),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SoftCard(
                        padding: const EdgeInsets.all(6),
                        radius: 28,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BoardView(levelRef: levelRef),
                        ),
                      ),
                    ),
                  ),
                  GameToolbar(
                    showPaths: state.showPaths,
                    onTogglePaths: controller.togglePaths,
                    onRestart: controller.restart,
                    onHint: state.session.isOver ? null : _hint,
                  ),
                ],
              ),
              if (_showTierIntro) _TierIntro(tier: state.level.meta.tier),
              if (_mechanicIntro case final m?)
                Positioned.fill(
                  child: _MechanicIntroCard(
                    mechanic: m,
                    onClose: _closeMechanicIntro,
                  ),
                ),
              if (_showResult && state.status == SessionStatus.won)
                Positioned.fill(
                  child: ResultOverlay.win(
                    title: switch (levelRef) {
                      DailyLevelRef() => 'Daily challenge done!',
                      PuzzleLevelRef(:final layer) => 'Layer $layer cleared!',
                      CampaignLevelRef() =>
                        '${GameScreen.titleFor(levelRef)} cleared!',
                    },
                    stars: state.session.stars,
                    coins: state.coinsEarned,
                    onDoubleCoins: state.coinsDoubled || state.coinsEarned == 0
                        ? null
                        : _doubleCoins,
                    hasNext: next != null,
                    nextLabel: levelRef is PuzzleLevelRef
                        ? 'Next layer'
                        : 'Next level',
                    unlocked: [
                      for (final id in state.unlockedPuzzles)
                        ShapePuzzles.byId(id).name,
                    ],
                    onPrimary: () =>
                        next != null ? _goTo(next) : context.go(doneRoute),
                    onHome: () => context.go(Routes.home),
                  ),
                ),
              if (_showResult && state.status == SessionStatus.lost)
                Positioned.fill(
                  child: ResultOverlay.lose(
                    onExtraHeart: _extraHeart,
                    onPrimary: controller.restart,
                    onHome: () => context.go(Routes.home),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tier strip for Hard / Super Hard levels, else a one-line reminder of
/// the level's special mechanic.
class _MechanicBanner extends StatelessWidget {
  const _MechanicBanner({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final level = state.level;
    final scheme = Theme.of(context).colorScheme;
    final tier = level.meta.tier;
    if (tier != LevelTier.normal && !state.levelRef.isDaily) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _Strip(
          key: const Key('tier-banner'),
          icon: Icons.local_fire_department_rounded,
          text: '${TierLabel.of(tier)} level · ${tier.rewardMultiplier}× coins',
          background: TierLabel.color(tier, scheme),
          foreground: Colors.white,
        ),
      );
    }
    final String? text;
    if (level.hasAmbulance) {
      text = 'Ambulance first! Only arrows in its lane may move before it.';
    } else if (level.gates.isNotEmpty) {
      text = 'One-way gates turn arrows in the gate\'s direction.';
    } else if (level.lights.isNotEmpty) {
      text = 'Lights switch every time an arrow leaves. Red means wait.';
    } else {
      text = null;
    }
    if (text == null) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: _Strip(
        icon: Icons.lightbulb_rounded,
        text: text,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({
    super.key,
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Names and colours for difficulty tiers.
abstract final class TierLabel {
  static String of(LevelTier tier) => switch (tier) {
    LevelTier.normal => 'Normal',
    LevelTier.hard => 'Hard',
    LevelTier.superHard => 'Super hard',
  };

  static Color color(LevelTier tier, ColorScheme scheme) => switch (tier) {
    LevelTier.normal => scheme.primary,
    LevelTier.hard => const Color(0xFFE0663A),
    LevelTier.superHard => const Color(0xFFB2316B),
  };
}

/// Card that announces a Hard / Super Hard level for a moment at start.
class _TierIntro extends StatelessWidget {
  const _TierIntro({required this.tier});

  final LevelTier tier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          builder: (context, v, child) =>
              Transform.scale(scale: v, child: child),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TierLabel.color(tier, theme.colorScheme),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${TierLabel.of(tier)} level',
                    key: const Key('tier-intro'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${tier.rewardMultiplier}× coins for the first clear',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tutorial instructions above the board, with a way out.
class _TutorialCallout extends StatelessWidget {
  const _TutorialCallout({required this.step, required this.onSkip});

  final TutorialStep step;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                Icon(Icons.school_rounded, color: scheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      step.copy,
                      key: ValueKey(step),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('skip-tutorial'),
                  onPressed: onSkip,
                  style: TextButton.styleFrom(minimumSize: const Size(56, 48)),
                  child: const Text('Skip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One-time explanation of a mechanic, shown before the level starts.
class _MechanicIntroCard extends StatelessWidget {
  const _MechanicIntroCard({required this.mechanic, required this.onClose});

  final Mechanic mechanic;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.scrim.withValues(alpha: 0.4),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    mechanic.icon,
                    size: 38,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'New: ${mechanic.title}',
                  key: const Key('mechanic-intro'),
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  mechanic.body,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('mechanic-intro-ok'),
                    onPressed: onClose,
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
