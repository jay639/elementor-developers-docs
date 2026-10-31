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
      final bounds = body.getBounds().expandToInclude(head.getBounds());
      final shader = ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        const [
          Color(0xFF8A5A00),
          Color(0xFFFFE9A6),
          Color(0xFFC8901E),
          Color(0xFFFFF4C8),
          Color(0xFF9C6A08),
        ],
        const [0, 0.3, 0.5, 0.7, 1],
      );
      canvas
        ..drawPath(body, line()..shader = shader)
        ..drawPath(head, Paint()..shader = shader)
        ..drawPath(
          body,
          line()
            ..color = Colors.white.withValues(alpha: 0.45)
            ..strokeWidth = stroke * 0.3,
        );
  }
}
