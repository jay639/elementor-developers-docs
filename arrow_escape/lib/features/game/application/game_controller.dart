import 'dart:async';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/game/data/resume_store.dart';
import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/core/services/haptics.dart';
import 'package:arrow_escape/core/services/sound.dart';
import 'package:arrow_escape/features/game/application/game_state.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/onboarding/tips.dart';
import 'package:arrow_escape/features/puzzles/puzzle_progress.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Game logic for one level. Requires [levelProvider] for the same ref to
/// have loaded.
final gameControllerProvider = NotifierProvider.autoDispose
    .family<GameController, GameViewState, LevelRef>(GameController.new);

class GameController extends Notifier<GameViewState> {
  GameController(this.levelRef);

  final LevelRef levelRef;

  final _clock = Stopwatch();

  /// Analytics context for the current attempt.
  late LevelInfo _info;
  HelpCounts _help = const HelpCounts();

  /// Whether the current attempt already ended in a win or a loss.
  bool _ended = false;
  late AnalyticsService _analytics;

  /// Latest session, kept outside [state] so onDispose can read it.
  PlaySession? _session;

  @override
  set state(GameViewState value) {
    _session = value.session;
    super.state = value;
  }

  String get _label => switch (levelRef) {
    CampaignLevelRef(:final number) => '$number',
    DailyLevelRef(:final dateKey) => 'daily_$dateKey',
    PuzzleLevelRef(:final shape, :final layer) => 'puzzle_${shape}_$layer',
  };

  @override
  GameViewState build() {
    final level = ref.watch(levelProvider(levelRef)).requireValue;
    // Captured now: `ref` can't be used inside onDispose.
    _analytics = ref.read(analyticsProvider);
    _startAttempt(level);
    ref.onDispose(_logQuitIfUnfinished);
    final tutorial = _tutorialStart(level);
    if (tutorial != TutorialStep.none) {
      _analytics.log('tutorial_begin');
    }
    // Pick up where the player left this level (app closed, Settings,
    // Home…), unless it is the guided tutorial.
    final saved = tutorial == TutorialStep.none
        ? ref.read(resumeStoreProvider).read(_label)
        : null;
    var session = PlaySession.start(level);
    _exits = [];
    if (saved != null) {
      session = PlaySession.resume(
        level,
        exits: saved.exits,
        hearts: saved.hearts,
        mistakes: saved.mistakes,
      );
      _exits = session.board.remainingCount < level.pieces.length
          ? [...saved.exits]
          : [];
      if (_exits.isNotEmpty || session.mistakes > 0) {
        _analytics.log('level_resume', {
          ..._info.params,
          'progress_pct': _progressPctOf(session),
        });
      }
    }
    _session = session;
    return GameViewState(
      levelRef: levelRef,
      session: session,
      tutorial: tutorial,
      stuck: _isDeadEnd(session),
    );
  }

  /// Arrows that left so far this attempt, in order (for resuming).
  List<int> _exits = [];

  void _saveProgress(PlaySession session) {
    final store = ref.read(resumeStoreProvider);
    if (session.isOver || state.tutorial != TutorialStep.none) {
      store.clear();
      return;
    }
    store.write(
      LevelProgress(
        level: _label,
        exits: _exits,
        hearts: session.hearts,
        mistakes: session.mistakes,
      ),
    );
  }

  void _startAttempt(Level level) {
    _clock
      ..reset()
      ..start();
    _help = const HelpCounts();
    _ended = false;
    final attempt = (ref.read(saveProvider).levelAttempts[_label] ?? 0) + 1;
    // Deferred: providers may not change other providers while building.
    scheduleMicrotask(
      () => ref.read(saveProvider.notifier).setAttempts(_label, attempt),
    );
    _info = LevelInfo(
      level: _label,
      mode: switch (levelRef) {
        CampaignLevelRef() => 'campaign',
        DailyLevelRef() => 'daily',
        PuzzleLevelRef() => 'puzzle',
      },
      tier: level.meta.tier.name,
      attempt: attempt,
      arrows: level.pieces.length,
      predictedDifficulty: level.meta.difficulty,
    );
    _analytics.levelStart(_info);
  }

  int get _progressPct {
    final session = _session;
    if (session == null) return 0;
    return _progressPctOf(session);
  }

  static int _progressPctOf(PlaySession session) {
    final total = session.rules.pieceCount;
    if (total == 0) return 0;
    return ((total - session.board.remainingCount) * 100 / total).round();
  }

  void _logQuitIfUnfinished() {
    if (_ended) return;
    _ended = true;
    _analytics.levelQuit(
      _info,
      seconds: _clock.elapsed.inSeconds,
      progressPct: _progressPct,
    );
  }

  TutorialStep _tutorialStart(Level level) =>
      level.meta.shape == 'tutorial' &&
          !ref.read(saveProvider).hasSeen(Tips.tutorial)
      ? TutorialStep.tapBlocker
      : TutorialStep.none;

  /// Ends the tutorial early; it won't be shown again.
  void skipTutorial() {
    if (state.tutorial == TutorialStep.none) return;
    ref.read(analyticsProvider).log('tutorial_skip', {
      'step': state.tutorial.name,
    });
    ref.read(saveProvider.notifier).markSeen(Tips.tutorial);
    state = state.copyWith(tutorial: TutorialStep.none);
  }

  void _advanceTutorial(MoveOutcome outcome, SessionStatus status) {
    final step = state.tutorial;
    if (step == TutorialStep.none) return;
    final analytics = ref.read(analyticsProvider);
    if (status == SessionStatus.won) {
      analytics.log('tutorial_complete', {'seconds': _clock.elapsed.inSeconds});
      ref.read(saveProvider.notifier).markSeen(Tips.tutorial);
      state = state.copyWith(tutorial: TutorialStep.none);
      return;
    }
    if (outcome is! ExitMove || !step.guided) return;
    final next = step == TutorialStep.tapBlocker
        ? TutorialStep.tapFreed
        : TutorialStep.finish;
    analytics.log('tutorial_step', {'step': next.name});
    state = state.copyWith(tutorial: next);
  }

  /// Applies a tap and plays feedback. Returns the outcome so the view can
  /// animate it, or null if the tap was ignored.
  MoveOutcome? tap(int piece) {
    // Guided tutorial steps only accept the highlighted arrow, so new
    // players can't lose hearts while learning.
    final allowed = state.tutorial.allowedPiece;
    if (allowed != null && piece != allowed) {
      ref.read(hapticsProvider).play(HapticKind.tap);
      return null;
    }
    final result = state.session.tap(piece);
    final outcome = result.outcome;
    if (outcome == null) return null;
    state = state.copyWith(session: result.session, hintPiece: null);
    if (outcome is ExitMove) _exits = [..._exits, piece];
    _saveProgress(result.session);

    final haptics = ref.read(hapticsProvider);
    final sound = ref.read(soundProvider);
    switch (outcome) {
      case ExitMove():
        haptics.play(HapticKind.exit);
        sound.play(Sfx.swoosh);
      case BlockedMove():
        haptics.play(HapticKind.bump);
        sound.play(Sfx.bump);
        sound.play(Sfx.error);
    }

    switch (result.session.status) {
      case SessionStatus.won:
        final save = ref.read(saveProvider.notifier);
        final stars = result.session.stars;
        final pointsBefore = save.current.progress.points;
        final coins = switch (levelRef) {
          CampaignLevelRef(:final number) => save.winLevel(
            number,
            stars,
            rewardMultiplier: state.level.meta.tier.rewardMultiplier,
          ),
          DailyLevelRef(:final dateKey) => save.winDaily(dateKey, stars),
          PuzzleLevelRef(:final shape, :final layer) => save.winPuzzle(
            shape,
            layer,
            stars,
          ),
        };
        final opened = puzzlesOpenedBetween(
          pointsBefore,
          save.current.progress.points,
        );
        state = state.copyWith(
          coinsEarned: coins,
          unlockedPuzzles: [for (final p in opened) p.id],
        );
        for (final p in opened) {
          ref.read(analyticsProvider).log('puzzle_unlock', {'puzzle': p.id});
        }
        _ended = true;
        ref
            .read(analyticsProvider)
            .levelComplete(
              _info,
              stars: stars,
              mistakes: result.session.mistakes,
              seconds: _clock.elapsed.inSeconds,
              help: _help,
            );
        // Queued after the attempt count this build may have scheduled.
        scheduleMicrotask(() => save.clearAttempts(_label));
        haptics.play(HapticKind.win);
        sound.play(Sfx.win);
      case SessionStatus.lost:
        _ended = true;
        ref
            .read(analyticsProvider)
            .levelFail(
              _info,
              seconds: _clock.elapsed.inSeconds,
              progressPct: _progressPct,
              help: _help,
            );
        haptics.play(HapticKind.lose);
        sound.play(Sfx.lose);
      case SessionStatus.playing:
        if (_isDeadEnd(result.session)) {
          state = state.copyWith(stuck: true);
          ref.read(analyticsProvider).log('level_stuck', {
            ..._info.params,
            'progress_pct': _progressPct,
          });
        }
    }
    _advanceTutorial(outcome, result.session.status);
    return outcome;
  }

  /// Skips this campaign level for coins. Returns false (and changes
  /// nothing) for other modes or when the player can't afford it.
  bool skip() {
    final ref0 = levelRef;
    if (ref0 is! CampaignLevelRef || state.session.isOver) return false;
    if (!ref.read(saveProvider.notifier).skipLevel(ref0.number)) return false;
    ref.read(resumeStoreProvider).clear();
    // A skip ends the attempt; it is logged as level_skip, not a quit.
    _ended = true;
    return true;
  }

  void togglePaths() {
    state = state.copyWith(showPaths: !state.showPaths);
    ref.read(hapticsProvider).play(HapticKind.tap);
    if (state.showPaths && !_help.paths) {
      _help = _help.copyWith(paths: true);
      ref
          .read(analyticsProvider)
          .helpUsed('paths', level: _label, source: 'free');
    }
  }

  /// Highlights a vehicle that keeps the board solvable. Returns false when
  /// there is none (game over or the solver gave up).
  /// Only lights and the ambulance can trap the player: without them an
  /// exit never blocks anyone, so some order always clears the board.
  bool _isDeadEnd(PlaySession session) {
    final level = session.level;
    if (level.lights.isEmpty && !level.hasAmbulance) return false;
    return Solver.fromRules(
          session.rules,
          maxStates: 80000,
        ).solve(session.board) ==
        null;
  }

  bool showHint() {
    final session = state.session;
    if (session.isOver) return false;
    final piece = Solver.fromRules(
      session.rules,
      maxStates: 50000,
    ).hint(session.board);
    if (piece == null) return false;
    state = state.copyWith(hintPiece: piece);
    ref.read(hapticsProvider).play(HapticKind.tap);
    _help = _help.copyWith(hints: _help.hints + 1);
    ref
        .read(analyticsProvider)
        .helpUsed('hint', level: _label, source: 'video');
    return true;
  }

  /// Rewarded "extra heart": continue after running out.
  void addHeart() {
    state = state.copyWith(session: state.session.addHeart());
    _saveProgress(state.session);
    // The attempt goes on: a later win or quit is logged for it.
    _ended = false;
    _clock.start();
    ref.read(analyticsProvider).levelContinue(_info, source: 'video');
  }

  /// Rewarded "double coins" on the win card; once per win.
  void doubleCoins() {
    if (state.coinsDoubled || state.coinsEarned == 0) return;
    ref
        .read(saveProvider.notifier)
        .addCoins(state.coinsEarned, reason: 'double_coins');
    state = state.copyWith(
      coinsEarned: state.coinsEarned * 2,
      coinsDoubled: true,
    );
  }

  void restart() {
    // Restarting mid-level abandons that attempt.
    _logQuitIfUnfinished();
    ref.read(resumeStoreProvider).clear();
    _exits = [];
    _startAttempt(state.level);
    state = GameViewState(
      levelRef: levelRef,
      session: PlaySession.start(state.level, rules: state.session.rules),
      showPaths: state.showPaths,
      tutorial: _tutorialStart(state.level),
    );
  }
}
