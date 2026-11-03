import 'dart:async';
import 'dart:math' as math;

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/theme/board_style.dart';
import 'package:arrow_escape/features/game/application/game_controller.dart';
import 'package:arrow_escape/features/game/application/game_state.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/game/presentation/board_animations.dart';
import 'package:arrow_escape/features/game/presentation/board_geometry.dart';
import 'package:arrow_escape/features/game/presentation/board_painter.dart';
import 'package:arrow_escape/features/game/presentation/track.dart';
import 'package:arrow_escape/features/onboarding/tips.dart';
import 'package:arrow_escape/features/onboarding/tutorial_overlay.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:arrow_escape/features/skins/skins.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The interactive board: pinch-zoom, pan, tap-to-move and all vehicle
/// animations, painted with two [CustomPaint] layers.
class BoardView extends ConsumerStatefulWidget {
  const BoardView({super.key, required this.levelRef});

  final LevelRef levelRef;

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView>
    with TickerProviderStateMixin {
  /// Taps on the same vehicle closer together than this are treated as one.
  static const _debounce = Duration(milliseconds: 280);

  late final Ticker _ticker = createTicker(_onTick);
  final _frame = ValueNotifier<int>(0);
  final _zoom = TransformationController();
  final _zoomed = ValueNotifier<bool>(false);

  /// Monotonic animation clock driven by the ticker.
  Duration _now = Duration.zero;
  Duration _base = Duration.zero;

  Map<int, PieceAnimation> _animations = const {};
  List<FlashAnimation> _flashes = const [];
  final _lastTap = <int, Duration>{};

  /// Big boards open zoomed out (the whole puzzle at a glance), then
  /// zoom in to a comfortable tap size; pinch out to see everything.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..addListener(_onIntro);
  Matrix4Tween? _introTween;
  Level? _introFor;
  Timer? _introDelay;

  /// Cells smaller than this on screen get the zoom-in.
  static const _zoomBelowCell = 17.0;

  /// Cell size the zoom-in aims for.
  static const _comfortCell = 25.0;

  void _onIntro() {
    final t = Curves.easeInOutCubic.transform(_intro.value);
    final tween = _introTween;
    if (tween != null) _zoom.value = tween.transform(t);
  }

  void _scheduleIntro(Level level, BoardLayout layout, Size size) {
    if (identical(_introFor, level)) return;
    _introFor = level;
    _intro.stop();
    _introDelay?.cancel();
    _introTween = null;
    if (_zoom.value.getMaxScaleOnAxis() != 1) _zoom.value = Matrix4.identity();
    final tutorial =
        ref.read(gameControllerProvider(widget.levelRef)).tutorial !=
        TutorialStep.none;
    if (tutorial || layout.cell >= _zoomBelowCell) return;
    final scale = (_comfortCell / layout.cell).clamp(1.0, 2.4);
    // Zoom about the board's centre.
    final c = size.center(Offset.zero);
    final end = Matrix4.identity()
      ..translateByDouble(c.dx * (1 - scale), c.dy * (1 - scale), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    _introTween = Matrix4Tween(begin: Matrix4.identity(), end: end);
    if (_fast) {
      _zoom.value = end;
      return;
    }
    _introDelay = Timer(const Duration(milliseconds: 1100), () {
      if (mounted && _introTween != null) _intro.forward(from: 0);
    });
  }

  Level? _tracksFor;
  List<Track> _restTracks = const [];

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      _zoomed.value = _zoom.value.getMaxScaleOnAxis() > 1.01;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _introDelay?.cancel();
    _intro.dispose();
    _frame.dispose();
    _zoom.dispose();
    _zoomed.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _now = _base + elapsed;
    final finished = _animations.values.where((a) => a.isDone(_now)).toList();
    if (finished.isNotEmpty) {
      _animations = {
        for (final e in _animations.entries)
          if (!e.value.isDone(_now)) e.key: e.value,
      };
    }
    if (_flashes.any((f) => f.isDone(_now))) {
      _flashes = [
        for (final f in _flashes)
          if (!f.isDone(_now)) f,
      ];
    }
    if (_animations.isEmpty && _flashes.isEmpty) {
      _ticker.stop();
      _base = _now;
      // Rebuild once so the painter gets the final, settled maps.
      if (mounted) setState(() {});
    }
    _frame.value++;
  }

  void _ensureTicking() {
    if (!_ticker.isActive) {
      _base = _now;
      _ticker.start();
    }
  }

  bool get _fast => ref.read(settingsProvider).reduceMotion;

  bool _pinchDismissed = false;

  void _dismissPinch() {
    if (_pinchDismissed) return;
    setState(() => _pinchDismissed = true);
    ref.read(saveProvider.notifier).markSeen(Tips.pinch);
  }

  void _handleTap(Offset position, Size size) {
    final state = ref.read(gameControllerProvider(widget.levelRef));
    if (state.session.isOver) return;
    final layout = BoardLayout(state.level, size);
    final board = state.session.board;

    // A quick second tap on a car that just drove off lands on its now
    // empty cell; don't let the tap tolerance hand it to a neighbour.
    final cell = layout.cellAt(position);
    if (cell != null &&
        _animations.values.any(
          (a) =>
              a is ExitAnimation &&
              state.level.pieces[a.piece].cells.contains(cell),
        )) {
      return;
    }

    final piece = layout.pieceAt(position, board.isOnBoard);
    if (piece == null) return;
    _tapPiece(piece);
  }

  /// Moves [piece] (from a touch, or a screen reader's activate action).
  void _tapPiece(int piece) {
    final state = ref.read(gameControllerProvider(widget.levelRef));
    if (state.session.isOver || !state.session.board.isOnBoard(piece)) return;

    // Double-tap protection: a vehicle mid-bump or mid-return ignores taps,
    // and rapid repeat taps on one vehicle count once.
    if (_animations.containsKey(piece)) return;
    final at = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final last = _lastTap[piece];
    if (last != null && at - last < _debounce) return;
    _lastTap[piece] = at;

    final outcome = ref
        .read(gameControllerProvider(widget.levelRef).notifier)
        .tap(piece);
    if (outcome == null) return;
    _animate(state.level, outcome);
  }

  void _animate(Level level, MoveOutcome outcome) {
    final piece = outcome.piece;
    switch (outcome) {
      case ExitMove(:final path):
        final track = Track.forPiece(level, piece, path);
        _animations = {
          ..._animations,
          piece: ExitAnimation(piece, track, _now, fast: _fast),
        };
      case BlockedMove():
        final steps = outcome.freeSteps.clamp(0, outcome.path.length);
        final track = Track.forPiece(
          level,
          piece,
          outcome.path.sublist(0, steps),
        );
        final bump = BumpAnimation(
          piece,
          track,
          _now,
          distance: BumpAnimation.distanceFor(outcome),
          fast: _fast,
        );
        _animations = {..._animations, piece: bump};
        // The tapped arrow itself turns red: "wrong move".
        _flashes = [
          ..._flashes,
          FlashAnimation(piece: piece, start: _now, alert: true),
        ];
        final blockerPiece = outcome.blockerPiece;
        final blockerCell = outcome.blockerCell;
        if (outcome.reason == BlockReason.ambulanceFirst) {
          _flashes = [
            ..._flashes,
            for (var i = 0; i < level.pieces.length; i++)
              if (level.pieces[i].kind == PieceKind.ambulance)
                FlashAnimation(piece: i, start: bump.impact),
          ];
        } else if (blockerPiece != null || blockerCell != null) {
          _flashes = [
            ..._flashes,
            FlashAnimation(
              piece: blockerPiece,
              cell: blockerCell,
              start: bump.impact,
            ),
          ];
        }
    }
    _ensureTicking();
    setState(() {});
  }

  /// Clears running animations when the board is reset (restart).
  void _onStateChanged(GameViewState? prev, GameViewState next) {
    if (prev == null || !mounted) return;
    final before = prev.session.board;
    final after = next.session.board;
    // Exits are animated by the tap handler; bumps keep the same board.
    if (identical(before, after) || after.exits == before.exits + 1) return;
    setState(() {
      _animations = const {};
      _flashes = const [];
    });
  }

  List<Track> _tracks(Level level) {
    if (!identical(level, _tracksFor)) {
      _tracksFor = level;
      _restTracks = [
        for (var i = 0; i < level.pieces.length; i++)
          Track.forPiece(level, i, const []),
      ];
    }
    return _restTracks;
  }

  @override
  Widget build(BuildContext context) {
    final provider = gameControllerProvider(widget.levelRef);
    ref.listen(provider, _onStateChanged);
    final state = ref.watch(provider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final skin = Skins.byId(
      ref.watch(saveProvider.select((s) => s.selectedSkin)),
    );
    final style = BoardStyle.of(
      theme,
      settings,
      skinColors: skin.colors(theme.brightness),
      skinEffect: skin.effect,
    );
    final level = state.level;
    final remaining = state.session.board.remainingCount;
    final step = state.tutorial;
    final seenPinch = ref.watch(
      saveProvider.select((s) => s.hasSeen(Tips.pinch)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final layout = BoardLayout(level, size);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scheduleIntro(level, layout, size);
        });
        final allowed = step.allowedPiece;
        // Small cells mean a dense board worth zooming into.
        final showPinch =
            !seenPinch &&
            step == TutorialStep.none &&
            layout.cell < 30 &&
            !_pinchDismissed;
        return Stack(
          children: [
            Semantics(
              label:
                  'Puzzle board. $remaining vehicles left. '
                  'Tap a vehicle to drive it out.',
              child: InteractiveViewer(
                transformationController: _zoom,
                minScale: 1,
                maxScale: 3.5,
                boundaryMargin: const EdgeInsets.all(48),
                onInteractionStart: (_) {
                  // The player took over: don't fight their zoom.
                  _intro.stop();
                  _introDelay?.cancel();
                  _introTween = null;
                  if (showPinch) _dismissPinch();
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _handleTap(d.localPosition, size),
                  child: SizedBox.fromSize(
                    size: size,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              isComplex: true,
                              willChange: false,
                              painter: BoardBackgroundPainter(
                                level: level,
                                style: style,
                              ),
                              foregroundPainter: BoardPiecesPainter(
                                rules: state.session.rules,
                                restTracks: _tracks(level),
                                board: state.session.board,
                                style: style,
                                showPaths: state.showPaths,
                                hintPiece: state.hintPiece,
                                animations: _animations,
                                flashes: _flashes,
                                now: () => _now,
                                onActivate: _tapPiece,
                                repaint: _frame,
                              ),
                            ),
                          ),
                        ),
                        if (allowed != null) ...[
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: TutorialSpotlightPainter(
                                  rules: state.session.rules,
                                  board: state.session.board,
                                  step: step,
                                  scrim: theme.colorScheme.scrim.withValues(
                                    alpha: 0.45,
                                  ),
                                  danger: style.danger,
                                ),
                              ),
                            ),
                          ),
                          if (state.session.board.isOnBoard(allowed) &&
                              !_animations.containsKey(allowed))
                            TapHand(
                              key: ValueKey('hand-$allowed'),
                              at: layout.centerOf(level.pieces[allowed].head),
                              size: math.max(44, layout.cell * 0.9),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (showPinch)
              Positioned.fill(child: PinchHint(onDismiss: _dismissPinch)),
            Positioned(
              right: 8,
              top: 8,
              child: ValueListenableBuilder<bool>(
                valueListenable: _zoomed,
                builder: (context, zoomed, _) => AnimatedOpacity(
                  opacity: zoomed ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !zoomed,
                    child: IconButton.filledTonal(
                      tooltip: 'Fit board',
                      onPressed: () => _zoom.value = Matrix4.identity(),
                      icon: const Icon(Icons.fit_screen_rounded),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
