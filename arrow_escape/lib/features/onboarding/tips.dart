import 'package:arrow_engine/arrow_engine.dart';
import 'package:flutter/material.dart';

/// Ids of one-time tips stored in the save.
abstract final class Tips {
  static const tutorial = 'tutorial';
  static const pinch = 'pinch';
  static const homeTour = 'home_tour';
  static const fitBoard = 'fit_board';
  static String mechanic(Mechanic m) => 'mechanic_${m.name}';
}

/// Steps of the level-1 tutorial.
enum TutorialStep {
  none,

  /// Spotlight on the arrow in the way; only it can be tapped.
  tapBlocker,

  /// The blocked arrow is free now; only it can be tapped.
  tapFreed,

  /// Free play until the board is clear.
  finish;

  bool get guided => this == tapBlocker || this == tapFreed;

  /// Piece the step allows, or null when any piece may be tapped.
  int? get allowedPiece => switch (this) {
    tapBlocker => TutorialPieces.blocker,
    tapFreed => TutorialPieces.blocked,
    _ => null,
  };

  String get copy => switch (this) {
    tapBlocker =>
      'This arrow is blocked: another arrow is in its way. '
          'Tap the glowing arrow to clear the road.',
    tapFreed => 'Its road is clear now. Tap it!',
    finish =>
      'Clear every arrow to win. Tapping a blocked arrow costs a heart.',
    none => '',
  };
}

/// Special mechanics that get a one-time intro.
enum Mechanic {
  lights(
    Icons.traffic_rounded,
    'Traffic lights',
    'A red light blocks any arrow that would drive through it. All lights '
        'switch every time an arrow leaves, so pick your order with care.',
  ),
  gates(
    Icons.turn_right_rounded,
    'One-way gates',
    'An arrow that drives into a gate turns and continues the way the gate '
        'points. It can never enter a gate from the front.',
  ),
  ambulance(
    Icons.local_hospital_rounded,
    'Ambulance first',
    'While the ambulance is on the board, only arrows standing in its lane '
        'may move. Clear its way, let it out, then the rest can go.',
  );

  const Mechanic(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;

  static List<Mechanic> inLevel(Level level) => [
    if (level.lights.isNotEmpty) lights,
    if (level.gates.isNotEmpty) gates,
    if (level.hasAmbulance) ambulance,
  ];
}
