import 'ascii.dart';
import 'dir.dart';
import 'level.dart';

/// Level numbers at which each mechanic starts appearing.
abstract final class MechanicUnlocks {
  static const trafficLights = 40;
  static const gates = 70;
  static const ambulance = 100;
}

/// Hand-made starter levels. Each one introduces a single idea; the
/// generated campaign (phase 2) takes over after these.
final List<Level> sampleLevels = [
  parseAsciiLevel(id: 1, meta: const LevelMeta(shape: 'intro'), '''
.^.
>>.
.^.
'''),
  parseAsciiLevel(id: 2, meta: const LevelMeta(shape: 'square'), '''
<^^>
<v>>
<<v>
v<vv
'''),
  parseAsciiLevel(id: 3, meta: const LevelMeta(shape: 'heart'), '''
#^^#^^#
<.v.v.>
<^...<>
#<.^.>#
##<v>##
###v###
'''),
  parseAsciiLevel(
    id: 4,
    meta: const LevelMeta(shape: 'truck'),
    vehicles: [
      (
        kind: PieceKind.truck,
        dir: Dir.right,
        cells: [(3, 1), (2, 1), (1, 1), (1, 2)],
      ),
      (kind: PieceKind.truck, dir: Dir.down, cells: [(2, 3), (2, 2)]),
    ],
    '''
<.^.>
....^
^...v
<...<
.>v..
''',
  ),
  parseAsciiLevel(id: 5, meta: const LevelMeta(shape: 'lights'), '''
^.^.^
..>..
>.r.v
..^..
^.<.v
'''),
  parseAsciiLevel(id: 6, meta: const LevelMeta(shape: 'gates'), '''
..v..
.>6..
..^.<
v.8..
>....
'''),
  parseAsciiLevel(
    id: 7,
    meta: const LevelMeta(shape: 'ambulance'),
    vehicles: [
      (kind: PieceKind.ambulance, dir: Dir.right, cells: [(1, 2), (0, 2)]),
    ],
    '''
.^...
.v..<
..^^.
.<.>.
<.v.^
''',
  ),
];

/// Campaign level 1: teaches tapping and blocking with long arrows.
///
/// ```
/// . . . . C      A is free and blocks B and D.
/// . . . . C      C is free.
/// A A A . .      B and D can go once A has left.
/// D B . . .
/// D B B B .
/// ```
final Level tutorialLevel = parseAsciiLevel(
  id: 1,
  meta: const LevelMeta(shape: 'tutorial'),
  vehicles: [
    (kind: PieceKind.car, dir: Dir.right, cells: [(2, 2), (1, 2), (0, 2)]),
    (kind: PieceKind.car, dir: Dir.up, cells: [(1, 3), (1, 4), (2, 4), (3, 4)]),
    (kind: PieceKind.car, dir: Dir.up, cells: [(4, 0), (4, 1)]),
    (kind: PieceKind.car, dir: Dir.up, cells: [(0, 3), (0, 4)]),
  ],
  '''
.....
.....
.....
.....
.....
''',
);

/// Indexes into [tutorialLevel].pieces used by the onboarding script.
abstract final class TutorialPieces {
  static const blocker = 0;
  static const blocked = 1;
}
