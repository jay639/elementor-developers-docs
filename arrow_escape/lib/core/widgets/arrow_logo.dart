import 'dart:math' as math;

import 'package:arrow_escape/core/theme/palette.dart';
import 'package:flutter/material.dart';

/// Brand mark: three rounded arrows escaping a tile. [progress] (0..1)
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
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(s * 0.28),
    );
    canvas.drawRRect(
      tile,
      Paint()..color = dark ? Palette.tileDark : Palette.tileLight,
    );
    canvas.save();
    canvas.clipRRect(tile);
    const arrows = [
      (Palette.secondary, 0.30, -math.pi / 2, 0.0),
      (Palette.primary, 0.50, 0.0, 0.15),
      (Palette.tertiary, 0.70, math.pi / 2, 0.3),
    ];
    for (final (color, at, angle, delay) in arrows) {
      final t = ((progress - delay) / 0.7).clamp(0.0, 1.0);
      final travel = Curves.easeInCubic.transform(t) * s;
      canvas.save();
      canvas.translate(s * at, s * 0.5);
      canvas.rotate(angle);
      canvas.translate(travel, 0);
      final paint = Paint()
        ..color = color
        ..strokeWidth = s * 0.11
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(-s * 0.12, 0), Offset(s * 0.04, 0), paint);
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.14, 0)
          ..lineTo(s * 0.03, -s * 0.09)
          ..lineTo(s * 0.03, s * 0.09)
          ..close(),
        Paint()..color = color,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.progress != progress || old.dark != dark;
}
