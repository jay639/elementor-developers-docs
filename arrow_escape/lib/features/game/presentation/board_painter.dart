import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/theme/board_style.dart';
import 'package:arrow_escape/features/game/presentation/board_animations.dart';
import 'package:arrow_escape/features/game/presentation/board_geometry.dart';
import 'package:arrow_escape/features/game/presentation/track.dart';
import 'package:flutter/material.dart';

/// Static layer: board tiles and one-way gates. Repaints only when the level,
/// size or style changes.
class BoardBackgroundPainter extends CustomPainter {
  BoardBackgroundPainter({required this.level, required this.style});

  final Level level;
  final BoardStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = BoardLayout(level, size);
    final cell = layout.cell;
    final inset = cell * 0.06;
    final radius = Radius.circular(cell * 0.22);
    final tile = Paint()..color = style.tile;
    final edge = Paint()
      ..color = style.tileEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, cell * 0.03);

    for (var i = 0; i < level.cellCount; i++) {
      if (!level.mask[i]) continue;
      final r = RRect.fromRectAndRadius(
        layout.cellRect(i).deflate(inset),
        radius,
      );
      canvas.drawRRect(r, tile);
      canvas.drawRRect(r, edge);
    }

    final gatePaint = Paint()
      ..color = style.gate
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, cell * 0.08)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final g in level.gates) {
      final c = layout.centerOf(g.cell);
      final fwd = dirOffset(g.dir) * cell;
      final side = Offset(-fwd.dy, fwd.dx);
      for (final shift in const [-0.14, 0.14]) {
        final tip = c + fwd * (0.12 + shift);
        canvas.drawPath(
          Path()
            ..moveTo(
              tip.dx - fwd.dx * 0.18 + side.dx * 0.22,
              tip.dy - fwd.dy * 0.18 + side.dy * 0.22,
            )
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(
              tip.dx - fwd.dx * 0.18 - side.dx * 0.22,
              tip.dy - fwd.dy * 0.18 - side.dy * 0.22,
            ),
          gatePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoardBackgroundPainter old) =>
      old.level != level || old.style != style;
}

/// Everything that moves or changes: vehicles, lights, path previews and
/// feedback flashes. Driven by [repaint] every animation frame.
class BoardPiecesPainter extends CustomPainter {
  BoardPiecesPainter({
    required this.rules,
    required this.restTracks,
    required this.board,
    required this.style,
    required this.showPaths,
    required this.animations,
    required this.flashes,
    required this.now,
    super.repaint,
  });

  final Rules rules;

  /// Tracks of every vehicle at rest, built once per level.
  final List<Track> restTracks;
  final BoardState board;
  final BoardStyle style;
  final bool showPaths;
  final Map<int, PieceAnimation> animations;
  final List<FlashAnimation> flashes;
  final Duration Function() now;

  Level get level => rules.level;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = BoardLayout(level, size);
    final t = now();

    if (showPaths) _paintPaths(canvas, layout);
    _paintLights(canvas, layout);

    // Resting vehicles first, then moving ones on top.
    for (var i = 0; i < level.pieces.length; i++) {
      if (!board.isOnBoard(i) || animations.containsKey(i)) continue;
      _paintVehicle(canvas, layout, i, restTracks[i], 0, _flashFor(i, t));
    }
    for (final a in animations.values) {
      _paintVehicle(
        canvas,
        layout,
        a.piece,
        a.track,
        a.offsetAt(t),
        _flashFor(a.piece, t),
      );
    }
    _paintCellFlashes(canvas, layout, t);
  }

  double _flashFor(int piece, Duration t) {
    var v = 0.0;
    for (final f in flashes) {
      if (f.piece == piece) v = math.max(v, f.intensity(t));
    }
    return v;
  }

  void _paintVehicle(
    Canvas canvas,
    BoardLayout layout,
    int piece,
    Track track,
    double offset,
    double flash,
  ) {
    final def = level.pieces[piece];
    final cell = layout.cell;
    final stroke = cell * style.strokeFactor;
    final from = track.tailArc - 0.34 + offset;
    final to = track.headArc + 0.02 + offset;
    final pts = [for (final p in track.slice(from, to)) layout.toPixels(p)];

    final body = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      body.lineTo(p.dx, p.dy);
    }
    final tangent = track.tangentAt(to);
    final base = layout.toPixels(track.pointAt(to));
    final halfWidth = math.min(stroke * 0.95, cell * 0.36);
    final tip = base + tangent * (cell * 0.34);
    final normal = Offset(-tangent.dy, tangent.dx) * halfWidth;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + normal.dx, base.dy + normal.dy)
      ..lineTo(base.dx - normal.dx, base.dy - normal.dy)
      ..close();

    final isAmbulance = def.kind == PieceKind.ambulance;
    final color = isAmbulance ? style.ambulance : style.vehicleColor(piece);
    final rim = isAmbulance ? style.ambulanceCross : style.outline;

    Paint line(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint fill(Color c) => Paint()..color = c;
    Paint rimLine(Color c, double w) =>
        line(c, w)..strokeJoin = StrokeJoin.round;

    if (flash > 0) {
      final glow = style.danger.withValues(alpha: 0.55 * flash);
      canvas.drawPath(body, line(glow, stroke + cell * 0.28 * flash));
      canvas.drawPath(head, rimLine(glow, cell * 0.28 * flash));
    }
    if (rim != null) {
      final w = math.max(2.5, cell * 0.05);
      canvas.drawPath(body, line(rim, stroke + w * 2));
      canvas.drawPath(head, rimLine(rim, w * 2));
      canvas.drawPath(head, fill(rim));
    }
    canvas.drawPath(body, line(color, stroke));
    canvas.drawPath(head, fill(color));

    if (isAmbulance) {
      // Red cross on the roof, between tail and head.
      final mid = layout.toPixels(track.pointAt((from + to) / 2));
      final arm = stroke * 0.32;
      final cross = line(style.ambulanceCross, stroke * 0.18)
        ..strokeCap = StrokeCap.butt;
      canvas
        ..drawLine(mid - Offset(arm, 0), mid + Offset(arm, 0), cross)
        ..drawLine(mid - Offset(0, arm), mid + Offset(0, arm), cross);
    } else if (def.kind == PieceKind.truck) {
      // Cab window just behind the arrow head.
      final cab = layout.toPixels(track.pointAt(to - 0.28));
      canvas.drawCircle(
        cab,
        stroke * 0.16,
        fill(Colors.white.withValues(alpha: 0.85)),
      );
    }
  }

  void _paintLights(Canvas canvas, BoardLayout layout) {
    final cell = layout.cell;
    for (var i = 0; i < level.lights.length; i++) {
      final light = level.lights[i];
      final green = rules.isGreen(i, board);
      final c = layout.centerOf(light.cell);
      final housing = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: cell * 0.56, height: cell * 0.56),
        Radius.circular(cell * 0.16),
      );
      canvas.drawRRect(housing, Paint()..color = const Color(0xFF3B3847));
      final bulb = green ? style.lightGreen : style.lightRed;
      canvas.drawCircle(
        c,
        cell * 0.3,
        Paint()..color = bulb.withValues(alpha: 0.22),
      );
      canvas.drawCircle(c, cell * 0.19, Paint()..color = bulb);
      if (style.symbols) {
        final mark = Paint()
          ..color = Colors.white
          ..strokeWidth = cell * 0.06
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        if (green) {
          canvas.drawCircle(c, cell * 0.08, mark);
        } else {
          canvas.drawLine(
            c - Offset(cell * 0.1, 0),
            c + Offset(cell * 0.1, 0),
            mark,
          );
        }
      }
    }
  }

  void _paintPaths(Canvas canvas, BoardLayout layout) {
    final cell = layout.cell;
    for (var i = 0; i < level.pieces.length; i++) {
      if (!board.isOnBoard(i) || animations.containsKey(i)) continue;
      final def = level.pieces[i];
      final path = rules.pathOf(i);
      final clear = rules.canExit(board, i);
      final pts = <Offset>[layout.centerOf(def.head)];
      for (final c in path) {
        pts.add(layout.centerOf(c));
      }
      if (rules.pathCanExit(i)) {
        final last = pts.length > 1 ? pts.last - pts[pts.length - 2] : null;
        final dir = last == null || last.distance == 0
            ? dirOffset(def.dir)
            : last / last.distance;
        pts.add(pts.last + dir * (cell * 0.5));
      }
      final paint = Paint()
        ..color = (clear ? style.pathClear : style.pathBlocked).withValues(
          alpha: clear ? 0.75 : 0.6,
        )
        ..strokeWidth = math.max(2, cell * 0.07)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (clear) {
        canvas.drawPoints(ui.PointMode.polygon, pts, paint);
      } else {
        _dashed(canvas, pts, paint, cell * 0.14, cell * 0.12);
        final blocker = rules.evaluate(board, i);
        if (style.symbols &&
            blocker is BlockedMove &&
            blocker.blockerCell != null) {
          _cross(
            canvas,
            layout.centerOf(blocker.blockerCell!),
            cell * 0.12,
            paint,
          );
        }
      }
    }
  }

  void _paintCellFlashes(Canvas canvas, BoardLayout layout, Duration t) {
    for (final f in flashes) {
      final cell = f.cell;
      if (cell == null || f.piece != null) continue;
      final v = f.intensity(t);
      if (v <= 0) continue;
      canvas.drawCircle(
        layout.centerOf(cell),
        layout.cell * (0.32 + 0.1 * v),
        Paint()
          ..color = style.danger.withValues(alpha: 0.8 * v)
          ..style = PaintingStyle.stroke
          ..strokeWidth = layout.cell * 0.08,
      );
    }
  }

  static void _cross(Canvas canvas, Offset c, double r, Paint paint) {
    canvas
      ..drawLine(c + Offset(-r, -r), c + Offset(r, r), paint)
      ..drawLine(c + Offset(-r, r), c + Offset(r, -r), paint);
  }

  static void _dashed(
    Canvas canvas,
    List<Offset> pts,
    Paint paint,
    double dash,
    double gap,
  ) {
    var drawing = true;
    var remaining = dash;
    for (var i = 0; i < pts.length - 1; i++) {
      var a = pts[i];
      final b = pts[i + 1];
      var segLeft = (b - a).distance;
      if (segLeft == 0) continue;
      final dir = (b - a) / segLeft;
      while (segLeft > 0) {
        final step = math.min(remaining, segLeft);
        final next = a + dir * step;
        if (drawing) canvas.drawLine(a, next, paint);
        a = next;
        segLeft -= step;
        remaining -= step;
        if (remaining <= 0) {
          drawing = !drawing;
          remaining = drawing ? dash : gap;
        }
      }
    }
  }

  @override
  bool shouldRepaint(BoardPiecesPainter old) =>
      old.board != board ||
      old.style != style ||
      old.showPaths != showPaths ||
      old.rules != rules ||
      old.animations != animations ||
      old.flashes != flashes;
}
