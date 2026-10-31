import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Brand mark: a white arrow escaping a royal-violet board past a gold one. [progress] (0..1)
/// slides the arrows out for the splash animation.
class ArrowLogo extends StatelessWidget {
  const ArrowLogo({super.key, this.size = 120, this.progress = 0});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Arrow Escape logo',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(
          progress,
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.progress, this.dark);

  final double progress;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) =>
      paintLogo(canvas, size.width, progress);

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.progress != progress || old.dark != dark;
}

/// Draws the brand mark into a [s]-sized square: a royal-violet tile with
/// a gold rim, a faint board grid, and a white arrow winding its way out
/// past an interlocking gold one. Shared with the launcher-icon renderer.
/// [progress] (0..1) slides the arrows out for the splash animation.
void paintLogo(
  Canvas canvas,
  double s, [
  double progress = 0,
  bool square = false,
]) {
  // Full-bleed square for store icons (the platform rounds the corners).
  final rim = !square;
  final tile = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, s, s),
    Radius.circular(square ? 0 : s * 0.23),
  );
  canvas.drawRRect(
    tile,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(s, s),
        const [Color(0xFF7448FF), Color(0xFF4B23D6), Color(0xFF240C78)],
        const [0, 0.5, 1],
      ),
  );
  canvas.save();
  canvas.clipRRect(tile);
  // Soft light from the top left.
  canvas.drawCircle(
    Offset(s * 0.2, s * 0.1),
    s * 0.75,
    Paint()
      ..shader = ui.Gradient.radial(Offset(s * 0.2, s * 0.1), s * 0.75, [
        Colors.white.withValues(alpha: 0.22),
        Colors.transparent,
      ]),
  );
  // Board dots.
  final dot = Paint()..color = Colors.white.withValues(alpha: 0.16);
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      canvas.drawCircle(
        Offset(s * (0.18 + x * 0.16), s * (0.18 + y * 0.16)),
        s * 0.012,
        dot,
      );
    }
  }

  Offset p(double x, double y) => Offset(x * s, y * s);
  final out = Curves.easeInCubic.transform(progress.clamp(0.0, 1.0)) * s;

  void arrow(List<Offset> pts, Offset dir, Paint Function() paint) {
    final shift = dir * out;
    final body = Path()
      ..moveTo(pts.first.dx + shift.dx, pts.first.dy + shift.dy);
    for (final q in pts.skip(1)) {
      body.lineTo(q.dx + shift.dx, q.dy + shift.dy);
    }
    final end = pts.last + shift;
    final n = Offset(-dir.dy, dir.dx);
    final len = s * 0.16;
    final head = Path()
      ..moveTo(end.dx + dir.dx * len, end.dy + dir.dy * len)
      ..lineTo(end.dx + n.dx * len * 0.62, end.dy + n.dy * len * 0.62)
      ..lineTo(end.dx - n.dx * len * 0.62, end.dy - n.dy * len * 0.62)
      ..close();
    // Soft drop shadow from two offset, translucent copies; no blur
    // filter, which some software GPUs (emulators) can't handle.
    canvas.save();
    for (final (dy, alpha, grow) in const [
      (0.028, 0.12, 0.03),
      (0.016, 0.2, 0.0),
    ]) {
      final shadow = Colors.black.withValues(alpha: alpha);
      canvas
        ..save()
        ..translate(0, s * dy)
        ..drawPath(
          body,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * (0.085 + grow)
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = shadow,
        )
        ..drawPath(head, Paint()..color = shadow)
        ..restore();
    }
    canvas
      ..restore()
      ..drawPath(
        body,
        paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.085
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(head, paint());
  }

  // Gold arrow first, so the white one reads on top.
  final gold = ui.Gradient.linear(
    p(0.3, 0.9),
    p(0.9, 0.3),
    const [
      Color(0xFFB8780A),
      Color(0xFFFFE08A),
      Color(0xFFE0A21E),
      Color(0xFFFFF3C4),
      Color(0xFFC88A12),
    ],
    const [0, 0.3, 0.55, 0.75, 1],
  );
  arrow(
    [p(0.34, 0.82), p(0.76, 0.82), p(0.76, 0.58)],
    const Offset(0, -1),
    () => Paint()..shader = gold,
  );
  arrow(
    [p(0.22, 0.7), p(0.22, 0.5), p(0.5, 0.5), p(0.5, 0.26), p(0.66, 0.26)],
    const Offset(1, 0),
    () => Paint()..color = Colors.white,
  );
  canvas.restore();

  if (rim) {
    canvas.drawRRect(
      tile.deflate(s * 0.008),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(s, s),
          [
            const Color(0xFFFFE9A6),
            const Color(0xFFC88A12).withValues(alpha: 0.8),
            const Color(0xFFFFF3C4),
          ],
          const [0, 0.5, 1],
        ),
    );
  }
}
