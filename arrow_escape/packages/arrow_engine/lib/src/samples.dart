import 'ascii.dart';
import 'dir.dart';
import 'level.dart';

/// Level numbers at which each mechanic starts appearing.
abstract final class MechanicUnlocks {
  static const trucks = 20;
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
