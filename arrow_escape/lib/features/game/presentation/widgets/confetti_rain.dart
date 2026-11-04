import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A one-shot shower of confetti falling from the top of the screen to
/// the bottom, for wins. Purely decorative: it never takes taps.
class ConfettiRain extends StatefulWidget {
  const ConfettiRain({super.key, this.pieces = 90, this.seed = 7});

  final int pieces;
  final int seed;

  static const duration = Duration(milliseconds: 2800);

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ConfettiRain.duration,
  )..forward();

  late final List<_Piece> _pieces = _makePieces();

  List<_Piece> _makePieces() {
    final rng = math.Random(widget.seed);
    const colors = [
      Color(0xFFFFC233), // gold
      Color(0xFFFF5FA2), // pink
      Color(0xFF6C4CF5), // violet
      Color(0xFF14C3A2), // teal
      Color(0xFF3FA9FF), // sky
      Color(0xFFFF7A45), // orange
    ];
    return [
      for (var i = 0; i < widget.pieces; i++)
        _Piece(
          x: rng.nextDouble(),
          // Start above the top edge, staggered so they arrive in waves.
          delay: rng.nextDouble() * 0.45,
          speed: 0.75 + rng.nextDouble() * 0.5,
          drift: (rng.nextDouble() - 0.5) * 0.18,
          sway: rng.nextDouble() * math.pi * 2,
          spin: (rng.nextDouble() - 0.5) * 14,
          size: 6 + rng.nextDouble() * 6,
          color: colors[rng.nextInt(colors.length)],
          round: rng.nextDouble() < 0.3,
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.sway,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  final double x, delay, speed, drift, sway, spin, size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.progress) : super(repaint: progress);

  final List<_Piece> pieces;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final paint = Paint();
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      // Fall from just above the top to past the bottom, swaying.
      final y = -0.08 + local * p.speed * 1.2;
      if (y > 1.08) continue;
      final x = p.x + p.drift * local + math.sin(p.sway + local * 9) * 0.02;
      // Fade out in the last stretch.
      final fade = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      paint.color = p.color.withValues(alpha: fade);
      canvas
        ..save()
        ..translate(x * size.width, y * size.height)
        ..rotate(p.spin * local);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      } else {
        // Paper strip that flips as it falls.
        final flip = math.cos(p.sway + local * 12).abs() * 0.8 + 0.2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.5 * flip,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
