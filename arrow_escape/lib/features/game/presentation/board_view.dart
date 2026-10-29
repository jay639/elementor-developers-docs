import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/theme/board_style.dart';
import 'package:arrow_escape/features/game/application/game_controller.dart';
import 'package:arrow_escape/features/game/application/game_state.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/game/presentation/board_animations.dart';
import 'package:arrow_escape/features/game/presentation/board_geometry.dart';
import 'package:arrow_escape/features/game/presentation/board_painter.dart';
import 'package:arrow_escape/features/game/presentation/track.dart';
import 'package:arrow_escape/features/settings/application/settings_controller.dart';
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
    with SingleTickerProviderStateMixin {
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

  /// Animates vehicles that came back through undo, and clears everything
  /// on restart.
  void _onStateChanged(GameViewState? prev, GameViewState next) {
    if (prev == null || !mounted) return;
    final before = prev.session.board;
    final after = next.session.board;
    // Exits are animated by the tap handler; bumps keep the same board.
    if (identical(before, after) || after.exits == before.exits + 1) return;
    if (after.exits != before.exits - 1) {
      // Restart: snap everything back into place.
      setState(() {
        _animations = const {};
        _flashes = const [];
      });
      return;
    }
    final returned = [
      for (final p in after.remaining)
        if (!before.isOnBoard(p)) p,
    ];
    if (returned.isEmpty) return;
    final level = next.level;
    _animations = {
      ..._animations,
      for (final p in returned)
        p: ReturnAnimation(
          p,
          Track.forPiece(level, p, next.session.rules.pathOf(p)),
          _now,
        ),
    };
    _ensureTicking();
    setState(() {});
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
    final style = BoardStyle.of(Theme.of(context), settings);
    final level = state.level;
    final remaining = state.session.board.remainingCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _handleTap(d.localPosition, size),
                  child: SizedBox.fromSize(
                    size: size,
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
                          animations: _animations,
                          flashes: _flashes,
                          now: () => _now,
                          repaint: _frame,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
