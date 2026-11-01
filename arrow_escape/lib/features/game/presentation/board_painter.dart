import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/theme/board_style.dart';
import 'package:arrow_escape/features/game/presentation/board_animations.dart';
import 'package:arrow_escape/features/game/presentation/board_geometry.dart';
import 'package:arrow_escape/features/game/presentation/track.dart';
import 'package:arrow_escape/features/skins/skin_paint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    // The shape reads as one soft silhouette; a dot marks each cell so
    // paths can be followed by eye, like graph paper.
    final silhouette = Path();
    for (var i = 0; i < level.cellCount; i++) {
      if (level.mask[i]) silhouette.addRect(layout.cellRect(i).inflate(0.5));
    }
    canvas.drawPath(silhouette, Paint()..color = style.tile);
    final dot = Paint()..color = style.tileEdge;
    final dotRadius = (cell * 0.06).clamp(1.0, 2.2);
    for (var i = 0; i < level.cellCount; i++) {
      if (level.mask[i]) canvas.drawCircle(layout.centerOf(i), dotRadius, dot);
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
/// Where an arrow's head sits and which way it points. The direction is
/// taken just *past* the head, along the road it drives out on: an arrow
/// whose body turns at the head cell must still point its own way, not
/// along its last body segment.
({Offset base, Offset tangent}) headPose(
  Track track,
  double offset,
  BoardLayout layout,
) => (
  base: layout.toPixels(track.pointAt(track.headArc + offset)),
  tangent: track.tangentAt(track.headArc + offset + 0.05),
);

class BoardPiecesPainter extends CustomPainter {
  BoardPiecesPainter({
    required this.rules,
    required this.restTracks,
    required this.board,
    required this.style,
    required this.showPaths,
    this.hintPiece,
    required this.animations,
    required this.flashes,
    required this.now,
    this.onActivate,
    super.repaint,
  });

  /// Screen-reader activation of a vehicle.
  final void Function(int piece)? onActivate;

  final Rules rules;

  /// Tracks of every vehicle at rest, built once per level.
  final List<Track> restTracks;
  final BoardState board;
  final BoardStyle style;
  final bool showPaths;

  /// Vehicle to highlight (rewarded hint).
  final int? hintPiece;
  final Map<int, PieceAnimation> animations;
  final List<FlashAnimation> flashes;
  final Duration Function() now;

  Level get level => rules.level;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = BoardLayout(level, size);
    final t = now();

    if (showPaths) _paintPaths(canvas, layout);
    final hint = hintPiece;
    if (hint != null &&
        board.isOnBoard(hint) &&
        !animations.containsKey(hint)) {
      _paintHint(canvas, layout, hint);
    }
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
    // The white ambulance needs a little more body to stand out.
    // Thin lines whatever the cell size: big cells (small boards) would
    // otherwise get bulky arrows.
    final stroke =
        (cell * style.strokeFactor).clamp(2.6, style.maxStroke) *
        (def.kind == PieceKind.ambulance ? 1.7 : 1);
    // Thin line from just behind the tail to the head; the arrowhead sits
    // past the head centre so a 1-cell arrow still reads as an arrow.
    final from = track.tailArc - 0.18 + offset;
    // The line ends at the head cell's centre, where the head starts.
    final to = track.headArc + offset;
    final pts = [for (final p in track.slice(from, to)) layout.toPixels(p)];

    final body = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      body.lineTo(p.dx, p.dy);
    }
    final (:base, :tangent) = headPose(track, offset, layout);
    // A sharp, clearly pointed head: longer than it is wide.
    // A crisp head, centred on the line (the last body segment always runs
    // straight into it), starting a little behind the head cell's centre
    // so the point reads clearly without crowding the next cell.
    // Thick mode (bigger stroke) gets a proportionally bigger head.
    final double headLength = math
        .max(stroke * 3.4, cell * 0.46)
        .clamp(9.0, math.max(17.0, stroke * 3.0));
    final halfWidth = headLength * 0.48;
    final headBase = base - tangent * (headLength * 0.3);
    final tip = headBase + tangent * headLength;
    final normal = Offset(-tangent.dy, tangent.dx) * halfWidth;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(headBase.dx + normal.dx, headBase.dy + normal.dy)
      ..lineTo(headBase.dx - normal.dx, headBase.dy - normal.dy)
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

    if (offset > 0.3 && !isAmbulance) {
      // Fading trail behind a moving arrow.
      final trail = [
        for (final p in track.slice(math.max(0, from - 1.4), from))
          layout.toPixels(p),
      ];
      if (trail.length > 1) {
        canvas.drawPoints(
          ui.PointMode.polygon,
          trail,
          line(color.withValues(alpha: 0.28), stroke * 0.8),
        );
      }
    }
    if (flash > 0) {
      final glow = style.danger.withValues(alpha: 0.55 * flash);
      canvas.drawPath(body, line(glow, stroke + cell * 0.22 * flash));
      canvas.drawPath(head, rimLine(glow, cell * 0.22 * flash));
    }
    if (rim != null) {
      final w = math.max(1.5, cell * 0.035);
      canvas.drawPath(body, line(rim, stroke + w * 2));
      canvas.drawPath(head, rimLine(rim, w * 2));
      canvas.drawPath(head, fill(rim));
    }
    if (isAmbulance) {
      canvas.drawPath(body, line(color, stroke));
      canvas.drawPath(head, fill(color));
    } else {
      paintArrow(
        canvas,
        body: body,
        head: head,
        tail: pts.first,
        tip: tip,
        color: color,
        stroke: stroke,
        effect: style.effect,
      );
    }

    if (isAmbulance) {
      // Red cross on the roof, between tail and head.
      final mid = layout.toPixels(track.pointAt((from + to) / 2));
      final arm = cell * 0.13;
      final cross = line(style.ambulanceCross, cell * 0.06)
        ..strokeCap = StrokeCap.butt;
      canvas
        ..drawLine(mid - Offset(arm, 0), mid + Offset(arm, 0), cross)
        ..drawLine(mid - Offset(0, arm), mid + Offset(0, arm), cross);
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
      // Every road looks the same: it shows where an arrow would drive,
      // never whether it is free (that would solve the puzzle).
      final paint = Paint()
        ..color = style.pathBlocked.withValues(alpha: 0.6)
        ..strokeWidth = math.max(2, cell * 0.07)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _dashed(canvas, pts, paint, cell * 0.14, cell * 0.12);
    }
  }

  void _paintHint(Canvas canvas, BoardLayout layout, int piece) {
    final cell = layout.cell;
    final glow = Paint()
      ..color = style.pathClear.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.16
      ..strokeCap = StrokeCap.round;
    for (final c in level.pieces[piece].cells) {
      canvas.drawCircle(layout.centerOf(c), cell * 0.46, glow);
    }
    final pts = [
      layout.centerOf(level.pieces[piece].head),
      for (final c in rules.pathOf(piece)) layout.centerOf(c),
    ];
    canvas.drawPoints(
      ui.PointMode.polygon,
      pts,
      Paint()
        ..color = style.pathClear
        ..strokeWidth = math.max(3, cell * 0.09)
        ..strokeCap = StrokeCap.round,
    );
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

  /// One accessible node per vehicle, so TalkBack / VoiceOver users can
  /// explore the board and move vehicles with a double tap. Whether a road
  /// is clear is only announced with "show paths" on, like for everyone.
  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final layout = BoardLayout(level, size);
    final nodes = <CustomPainterSemantics>[];
    for (var i = 0; i < level.pieces.length; i++) {
      if (!board.isOnBoard(i)) continue;
      final def = level.pieces[i];
      var rect = layout.cellRect(def.cells.first);
      for (final c in def.cells.skip(1)) {
        rect = rect.expandToInclude(layout.cellRect(c));
      }
      final kind = switch (def.kind) {
        PieceKind.car || PieceKind.truck => 'Arrow',
        PieceKind.ambulance => 'Ambulance',
      };
      final x = level.xOf(def.head) + 1;
      final y = level.yOf(def.head) + 1;
      final road = showPaths
          ? (rules.canExit(board, i) ? ', road clear' : ', blocked')
          : '';
      final activate = onActivate;
      nodes.add(
        CustomPainterSemantics(
          key: ValueKey('piece-$i'),
          rect: rect,
          properties: SemanticsProperties(
            button: true,
            label: '$kind facing ${def.dir.name}, row $y, column $x$road',
            hint: 'Drive out',
            onTap: activate == null ? null : () => activate(i),
            textDirection: TextDirection.ltr,
          ),
        ),
      );
    }
    for (var i = 0; i < level.lights.length; i++) {
      final cell = level.lights[i].cell;
      nodes.add(
        CustomPainterSemantics(
          key: ValueKey('light-$i'),
          rect: layout.cellRect(cell),
          properties: SemanticsProperties(
            label:
                'Traffic light, ${rules.isGreen(i, board) ? 'green' : 'red'}',
            textDirection: TextDirection.ltr,
          ),
        ),
      );
    }
    return nodes;
  };

  @override
  bool shouldRebuildSemantics(BoardPiecesPainter oldDelegate) =>
      oldDelegate.board != board ||
      oldDelegate.showPaths != showPaths ||
      oldDelegate.rules != rules;

  @override
  bool shouldRepaint(BoardPiecesPainter old) =>
      old.board != board ||
      old.style != style ||
      old.showPaths != showPaths ||
      old.hintPiece != hintPiece ||
      old.rules != rules ||
      old.animations != animations ||
      old.flashes != flashes;
}
