import 'dart:math' as math;
import 'dart:ui';

import 'package:arrow_engine/arrow_engine.dart';

/// A polyline in cell units that a vehicle slides along, snake-style.
///
/// Points run tail → head → path → off-board. A vehicle drawn at offset
/// `d` covers arc lengths `[tailArc + d, headArc + d]`, so the body follows
/// the head around corners.
class Track {
  Track._(this.points, this._cumulative, this.tailArc, this.headArc);

  /// Builds the track for [piece] driving along [path] (cells in front of
  /// its head). The track always ends well outside the board.
  factory Track.forPiece(Level level, int piece, List<int> path) {
    final def = level.pieces[piece];
    Offset center(int c) => Offset(level.xOf(c) + 0.5, level.yOf(c) + 0.5);
    final body = [for (final c in def.cells.reversed) center(c)];
    final headDir = Offset(def.dir.dx.toDouble(), def.dir.dy.toDouble());
    final behindTail = body.length > 1 ? _unit(body[0] - body[1]) : -headDir;

    final points = <Offset>[body.first + behindTail, ...body];
    for (final c in path) {
      points.add(center(c));
    }
    final last = points.last;
    final prev = points[points.length - 2];
    final outDir = path.isEmpty ? headDir : _unit(last - prev);
    points.add(last + outDir * (def.length + 3.0));

    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(cumulative.last + (points[i] - points[i - 1]).distance);
    }
    return Track._(points, cumulative, 1, 1.0 + def.length - 1);
  }

  final List<Offset> points;
  final List<double> _cumulative;

  /// Arc length of the tail and head cell centres at rest.
  final double tailArc;
  final double headArc;

  double get length => _cumulative.last;

  /// Distance the vehicle must travel for its tail to leave the board.
  double get exitTravel => length - headArc - 1.5;

  int _segmentAt(double s) {
    if (s <= 0) return 0;
    var lo = 0;
    var hi = _cumulative.length - 2;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_cumulative[mid] <= s) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// Point at arc length [s]; extrapolates beyond both ends.
  Offset pointAt(double s) {
    final i = _segmentAt(s);
    final a = points[i];
    final b = points[i + 1];
    final segLen = _cumulative[i + 1] - _cumulative[i];
    if (segLen == 0) return a;
    return a + (b - a) * ((s - _cumulative[i]) / segLen);
  }

  /// Unit direction of travel at arc length [s].
  Offset tangentAt(double s) {
    final i = _segmentAt(s);
    return _unit(points[i + 1] - points[i]);
  }

  /// Points of the polyline between arc lengths [from] and [to], including
  /// every corner in between.
  List<Offset> slice(double from, double to) {
    final out = <Offset>[pointAt(from)];
    for (var i = 1; i < points.length - 1; i++) {
      final s = _cumulative[i];
      if (s > from && s < to) out.add(points[i]);
    }
    out.add(pointAt(to));
    return out;
  }

  static Offset _unit(Offset v) {
    final d = v.distance;
    return d == 0 ? Offset.zero : v / d;
  }
}

/// Unit vector for a direction.
Offset dirOffset(Dir d) => Offset(d.dx.toDouble(), d.dy.toDouble());

/// Angle in radians for a direction (0 = right, clockwise, screen coords).
double dirAngle(Dir d) => math.atan2(d.dy.toDouble(), d.dx.toDouble());
