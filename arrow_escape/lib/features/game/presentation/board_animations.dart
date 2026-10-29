import 'dart:math' as math;

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/game/presentation/track.dart';
import 'package:flutter/animation.dart';

/// A vehicle moving along its [Track]. [offsetAt] gives the distance
/// travelled (in cells) at time `t` since [start].
sealed class PieceAnimation {
  PieceAnimation(this.piece, this.track, this.start, this.duration);

  final int piece;
  final Track track;
  final Duration start;
  final Duration duration;

  double progress(Duration now) {
    if (duration == Duration.zero) return 1;
    final t = (now - start).inMicroseconds / duration.inMicroseconds;
    return t.clamp(0.0, 1.0);
  }

  bool isDone(Duration now) => now - start >= duration;

  double offsetAt(Duration now);

  /// Whether the vehicle should still be drawn once the animation ends.
  bool get remainsOnBoard;
}

/// Drives off the board, accelerating.
class ExitAnimation extends PieceAnimation {
  ExitAnimation(int piece, Track track, Duration start, {bool fast = false})
    : super(piece, track, start, _duration(track.exitTravel, fast));

  static Duration _duration(double travel, bool fast) {
    final ms = (travel * (fast ? 22 : 34)).clamp(fast ? 160 : 260, 720);
    return Duration(milliseconds: ms.round());
  }

  @override
  double offsetAt(Duration now) =>
      track.exitTravel * Curves.easeInCubic.transform(progress(now));

  @override
  bool get remainsOnBoard => false;
}

/// Rolls towards the obstacle, taps it, and springs back.
class BumpAnimation extends PieceAnimation {
  BumpAnimation(
    int piece,
    Track track,
    Duration start, {
    required this.distance,
    bool fast = false,
  }) : super(piece, track, start, _duration(distance, fast));

  /// Furthest point reached, in cells.
  final double distance;

  /// Share of the animation spent moving forward.
  static const _forward = 0.45;

  static Duration _duration(double distance, bool fast) {
    final ms = (140 + distance * (fast ? 40 : 70)).clamp(180, 520);
    return Duration(milliseconds: ms.round());
  }

  /// Moment the vehicle touches the obstacle.
  Duration get impact =>
      start +
      Duration(microseconds: (duration.inMicroseconds * _forward).round());

  @override
  double offsetAt(Duration now) {
    final p = progress(now);
    if (p < _forward) {
      return distance * Curves.easeOutCubic.transform(p / _forward);
    }
    final back = (p - _forward) / (1 - _forward);
    // Small overshoot on the way back reads as a springy recoil.
    return distance * (1 - Curves.easeOutBack.transform(back));
  }

  @override
  bool get remainsOnBoard => true;

  /// How far a blocked vehicle rolls before it touches the obstacle.
  static double distanceFor(BlockedMove move) => switch (move.reason) {
    BlockReason.ambulanceFirst => 0.18,
    BlockReason.vehicle => move.freeSteps + 0.28,
    _ => move.freeSteps + 0.2,
  };
}

/// Reverses an exit when the player undoes it.
class ReturnAnimation extends PieceAnimation {
  ReturnAnimation(int piece, Track track, Duration start)
    : super(
        piece,
        track,
        start,
        Duration(milliseconds: (track.exitTravel * 30).clamp(240, 560).round()),
      );

  @override
  double offsetAt(Duration now) =>
      track.exitTravel * (1 - Curves.easeOutCubic.transform(progress(now)));

  @override
  bool get remainsOnBoard => true;
}

/// Red pulse on whatever stopped a vehicle.
class FlashAnimation {
  FlashAnimation({this.piece, this.cell, required this.start})
    : assert(piece != null || cell != null);

  static const duration = Duration(milliseconds: 420);

  final int? piece;
  final int? cell;
  final Duration start;

  bool isDone(Duration now) => now - start >= duration;

  /// 0 → 1 → 0 intensity; 0 before [start].
  double intensity(Duration now) {
    if (now < start) return 0;
    final t = (now - start).inMicroseconds / duration.inMicroseconds;
    if (t >= 1) return 0;
    return math.sin(t * math.pi);
  }
}
