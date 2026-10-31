import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/game/presentation/board_geometry.dart';
import 'package:arrow_escape/features/onboarding/tips.dart';
import 'package:flutter/material.dart';

/// Dims the board except the arrows the tutorial is about, and draws the
/// blocked arrow's road in red up to the arrow in its way.
class TutorialSpotlightPainter extends CustomPainter {
  TutorialSpotlightPainter({
    required this.rules,
    required this.board,
    required this.step,
    required this.scrim,
    required this.danger,
  });

  final Rules rules;
  final BoardState board;
  final TutorialStep step;
  final Color scrim;
  final Color danger;

  Level get level => rules.level;

  @override
  void paint(Canvas canvas, Size size) {
    final allowed = step.allowedPiece;
    if (allowed == null) return;
    final layout = BoardLayout(level, size);
    final cell = layout.cell;
    final holes = Path();
    final focus = {allowed, TutorialPieces.blocked};
    for (final p in focus) {
      if (!board.isOnBoard(p)) continue;
      for (final c in level.pieces[p].cells) {
        holes.addRRect(
          RRect.fromRectAndRadius(
            layout.cellRect(c).inflate(cell * 0.08),
            Radius.circular(cell * 0.3),
          ),
        );
      }
    }
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        holes,
      ),
      Paint()..color = scrim,
    );

    if (step == TutorialStep.tapBlocker) {
      // The blocked arrow's road, ending in a cross where it is stopped.
      final out = rules.evaluate(board, TutorialPieces.blocked);
      if (out is BlockedMove && out.blockerCell != null) {
        final pts = [
          layout.centerOf(level.pieces[TutorialPieces.blocked].head),
          for (final c in out.path.take(out.freeSteps + 1)) layout.centerOf(c),
        ];
        final paint = Paint()
          ..color = danger
          ..strokeWidth = math.max(3, cell * 0.06)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawPoints(ui.PointMode.polygon, pts, paint);
        final c = layout.centerOf(out.blockerCell!);
        final r = cell * 0.16;
        canvas
          ..drawCircle(c, cell * 0.28, paint..strokeWidth = cell * 0.05)
          ..drawLine(c + Offset(-r, -r), c + Offset(r, r), paint)
          ..drawLine(c + Offset(-r, r), c + Offset(r, -r), paint);
      }
    }
  }

  @override
  bool shouldRepaint(TutorialSpotlightPainter old) =>
      old.board != board || old.step != step || old.scrim != scrim;
}

/// A hand that keeps tapping a point on the board.
class TapHand extends StatefulWidget {
  const TapHand({super.key, required this.at, this.size = 56});

  /// Where the fingertip touches.
  final Offset at;
  final double size;

  @override
  State<TapHand> createState() => _TapHandState();
}

class _TapHandState extends State<TapHand> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Positioned(
      // touch_app's fingertip sits near the top centre of the glyph.
      left: widget.at.dx - widget.size * 0.42,
      top: widget.at.dy - widget.size * 0.08,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = reduce ? 0.0 : _c.value;
            // Press down quickly, release slowly, with a ripple.
            final double press = t < 0.25
                ? t / 0.25
                : math.max(0.0, 1 - (t - 0.25) / 0.5);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (!reduce && t < 0.6)
                  Positioned(
                    left: widget.size * 0.42 - 18 * (1 + t * 2),
                    top: widget.size * 0.08 - 18 * (1 + t * 2),
                    child: Container(
                      width: 36 * (1 + t * 2),
                      height: 36 * (1 + t * 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.8 * (1 - t / 0.6),
                          ),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(0, 8 * (1 - press)),
                  child: Transform.scale(scale: 1 - 0.12 * press, child: child),
                ),
              ],
            );
          },
          child: Icon(
            Icons.touch_app_rounded,
            size: widget.size,
            color: Colors.white,
            shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
          ),
        ),
      ),
    );
  }
}

/// "Pinch to zoom" hint: two fingertips spreading apart.
class PinchHint extends StatefulWidget {
  const PinchHint({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<PinchHint> createState() => _PinchHintState();
}

class _PinchHintState extends State<PinchHint>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      key: const Key('pinch-hint'),
      behavior: HitTestBehavior.translucent,
      onTap: widget.onDismiss,
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.inverseSurface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 90,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final t = reduce
                        ? 0.6
                        : Curves.easeInOut.transform(
                            _c.value < 0.7 ? _c.value / 0.7 : 1,
                          );
                    final spread = 10 + 30 * t;
                    Widget finger(double sign) => Positioned(
                      left: 60 + sign * spread - 11,
                      top: 45 - sign * spread * 0.7 - 11,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      ),
                    );
                    return Stack(children: [finger(-1), finger(1)]);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pinch to zoom in',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
              ),
              Text(
                'Spread two fingers on the board. Tap to close.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
