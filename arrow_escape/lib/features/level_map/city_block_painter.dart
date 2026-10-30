import 'package:arrow_engine/arrow_engine.dart';
import 'package:flutter/material.dart';

/// Kinds of plots on a city block.
enum _Plot { house, tower, shop, park }

/// Draws one city block: ten plots, each a building once its level is
/// cleared and a faint outline before that.
class CityBlockPainter extends CustomPainter {
  CityBlockPainter({
    required this.block,
    required this.built,
    required this.ground,
    required this.ghost,
    required this.colors,
  });

  /// 0-based block index (levels block*10+1 … block*10+10).
  final int block;

  /// Which of the ten plots are built.
  final List<bool> built;
  final Color ground;
  final Color ghost;
  final List<Color> colors;

  static const plots = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - 10;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, groundY, size.width, 10),
        const Radius.circular(5),
      ),
      Paint()..color = ground,
    );
    final slot = size.width / plots;
    for (var i = 0; i < plots; i++) {
      final h = stableHash('block-$block-$i');
      final kind = _Plot.values[h % _Plot.values.length];
      final height = (0.35 + (h >> 4) % 60 / 100) * (groundY - 6);
      final color = colors[(h >> 10) % colors.length];
      final rect = Rect.fromLTWH(
        i * slot + slot * 0.12,
        groundY - height,
        slot * 0.76,
        height,
      );
      _drawPlot(canvas, kind, rect, built[i], color);
    }
  }

  void _drawPlot(Canvas canvas, _Plot kind, Rect r, bool done, Color color) {
    final fill = Paint()..color = done ? color : Colors.transparent;
    final line = Paint()
      ..color = done ? color : ghost
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final windows = Paint()..color = Colors.white.withValues(alpha: 0.75);
    switch (kind) {
      case _Plot.park:
        final trunk = Rect.fromLTWH(r.center.dx - 2, r.bottom - 14, 4, 14);
        final crown = Offset(r.center.dx, r.bottom - 20);
        if (done) {
          canvas
            ..drawRect(trunk, Paint()..color = const Color(0xFFA1887F))
            ..drawCircle(
              crown,
              r.width * 0.42,
              Paint()..color = const Color(0xFF8BC48A),
            );
        } else {
          canvas.drawCircle(crown, r.width * 0.42, line);
        }
      case _Plot.house:
        final body = Rect.fromLTRB(
          r.left,
          r.bottom - r.height * 0.6,
          r.right,
          r.bottom,
        );
        final roof = Path()
          ..moveTo(r.left - 2, body.top)
          ..lineTo(r.center.dx, r.top + r.height * 0.15)
          ..lineTo(r.right + 2, body.top)
          ..close();
        if (done) {
          canvas
            ..drawRRect(
              RRect.fromRectAndRadius(body, const Radius.circular(3)),
              fill,
            )
            ..drawPath(
              roof,
              Paint()..color = Color.lerp(color, Colors.black, 0.2)!,
            )
            ..drawRect(
              Rect.fromCenter(
                center: body.center,
                width: r.width * 0.3,
                height: body.height * 0.35,
              ),
              windows,
            );
        } else {
          canvas
            ..drawRRect(
              RRect.fromRectAndRadius(body, const Radius.circular(3)),
              line,
            )
            ..drawPath(roof, line);
        }
      case _Plot.tower:
      case _Plot.shop:
        final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
        canvas.drawRRect(rr, done ? fill : line);
        if (!done) return;
        if (kind == _Plot.shop) {
          canvas.drawRect(
            Rect.fromLTWH(r.left, r.top + 4, r.width, 5),
            Paint()..color = Colors.white.withValues(alpha: 0.6),
          );
        }
        for (var y = r.top + 12; y < r.bottom - 10; y += 10) {
          for (final fx in const [0.3, 0.7]) {
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(r.left + r.width * fx, y),
                width: 3.5,
                height: 4,
              ),
              windows,
            );
          }
        }
    }
  }

  @override
  bool shouldRepaint(CityBlockPainter old) =>
      old.block != block ||
      !_same(old.built, built) ||
      old.ground != ground ||
      old.ghost != ghost;

  static bool _same(List<bool> a, List<bool> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return a.length == b.length;
  }
}
