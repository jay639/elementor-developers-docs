import 'package:arrow_engine/arrow_engine.dart';
import 'package:test/test.dart';

void main() {
  test('pictures have unique ids, rising thresholds and real outlines', () {
    final ids = ShapePuzzles.all.map((s) => s.id).toSet();
    expect(ids.length, ShapePuzzles.all.length);
    var last = 0;
    for (final s in ShapePuzzles.all) {
      expect(s.starsToUnlock, greaterThan(last), reason: s.id);
      last = s.starsToUnlock;
      final m = s.mask;
      expect(m.area, greaterThan(m.width * m.height * 0.25), reason: s.id);
      expect(m.name, 'puzzle_${s.id}');
    }
  });

  test('layers get more arrows and stay solvable', () {
    final layers = ShapePuzzles.buildLayers(ShapePuzzles.byId('mountain'));
    expect(layers, hasLength(PuzzleShape.layerCount));
    for (var i = 0; i < layers.length; i++) {
      expect(analyzeLevel(layers[i]), isNotNull);
      if (i > 0) {
        expect(
          layers[i].pieces.length,
          greaterThan(layers[i - 1].pieces.length),
        );
      }
    }
  });

  test('codec round trip', () {
    final level = Campaign.build(2);
    final decoded = ShapePuzzles.decode(ShapePuzzles.encode({'a/1': level}));
    expect(decoded['a/1']!.pieces, level.pieces);
  });
}
