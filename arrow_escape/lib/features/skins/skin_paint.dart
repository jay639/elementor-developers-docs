import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// How a skin draws its arrows, beyond colour.
enum SkinEffect {
  /// Solid lines.
  plain,

  /// Each arrow fades from a light tail to a strong head.
  gradient,

  /// Neon tubes with a soft glow.
  glow,

  /// Polished gold.
  metallic,
}

/// Paints one arrow (body path + head triangle) in a skin's effect. Shared
/// by the board and the skin previews so the shop shows what you get.
void paintArrow(
  Canvas canvas, {
  required Path body,
  required Path head,
  required Offset tail,
  required Offset tip,
  required Color color,
  required double stroke,
  required SkinEffect effect,
}) {
  Paint line() => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  switch (effect) {
    case SkinEffect.plain:
      canvas
        ..drawPath(body, line()..color = color)
        ..drawPath(head, Paint()..color = color);
    case SkinEffect.gradient:
      final shader = ui.Gradient.linear(tail, tip, [
        Color.lerp(color, Colors.white, 0.55)!,
        color,
      ]);
      canvas
        ..drawPath(body, line()..shader = shader)
        ..drawPath(head, Paint()..color = color);
    case SkinEffect.glow:
      final glow = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 1.4);
      canvas
        ..drawPath(
          body,
          line()
            ..color = glow.color
            ..maskFilter = glow.maskFilter
            ..strokeWidth = stroke * 2.6,
        )
        ..drawPath(head, glow)
        ..drawPath(body, line()..color = color)
        ..drawPath(head, Paint()..color = color)
        // White-hot core.
        ..drawPath(
          body,
          line()
            ..color = Colors.white.withValues(alpha: 0.75)
            ..strokeWidth = stroke * 0.35,
        );
    case SkinEffect.metallic:
      // The top skin: a warm golden halo, a dark bronze rim, a polished
      // gradient with repeating highlights, a bright specular core and a
      // sparkle at the tip.
      final bounds = body.getBounds().expandToInclude(head.getBounds());
      final span = Offset(stroke * 9, stroke * 9);
      final shader = ui.Gradient.linear(
        bounds.topLeft,
        bounds.topLeft + span,
        const [
          Color(0xFF7A4A00),
          Color(0xFFFFD86B),
          Color(0xFFB8780A),
          Color(0xFFFFF3C4),
          Color(0xFFE0A21E),
          Color(0xFF8A5600),
        ],
        const [0, 0.22, 0.42, 0.6, 0.8, 1],
        TileMode.mirror,
      );
      final halo = Paint()
        ..color = const Color(0xFFFFC233).withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 1.3);
      final rim = const Color(0xFF4A2C00);
      canvas
        ..drawPath(
          body,
          line()
            ..color = halo.color
            ..maskFilter = halo.maskFilter
            ..strokeWidth = stroke * 2.4,
        )
        ..drawPath(head, halo)
        ..drawPath(
          body,
          line()
            ..color = rim
            ..strokeWidth = stroke + 2,
        )
        ..drawPath(
          head,
          Paint()
            ..color = rim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round,
        )
        ..drawPath(body, line()..shader = shader)
        ..drawPath(head, Paint()..shader = shader)
        ..drawPath(
          body,
          line()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..strokeWidth = stroke * 0.28,
        );
      _sparkle(canvas, tip, stroke * 1.6);
  }
}

/// A small four-pointed glint.
void _sparkle(Canvas canvas, Offset c, double r) {
  final p = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
    ..close();
  canvas
    ..drawPath(
      p,
      Paint()
        ..color = const Color(0xFFFFF6D5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.15),
    )
    ..drawCircle(c, r * 0.18, Paint()..color = Colors.white);
}
