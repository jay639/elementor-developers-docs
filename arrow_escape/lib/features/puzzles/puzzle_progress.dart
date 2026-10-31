import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/progress/domain/progress.dart';

/// Unlock rules for the picture-puzzle collection. Pictures open with
/// stars ("points") earned anywhere; layers open one after another.
extension PuzzleProgress on Progress {
  bool puzzleUnlocked(PuzzleShape shape) => points >= shape.starsToUnlock;

  bool layerOpen(PuzzleShape shape, int layer) =>
      puzzleUnlocked(shape) &&
      (layer == 1 || puzzleStarsFor(ShapePuzzles.key(shape.id, layer - 1)) > 0);

  /// Layers cleared, 0..[PuzzleShape.layerCount].
  int layersDone(PuzzleShape shape) => [
    for (var l = 1; l <= PuzzleShape.layerCount; l++)
      if (puzzleStarsFor(ShapePuzzles.key(shape.id, l)) > 0) l,
  ].length;

  int puzzleStarsOf(PuzzleShape shape) => [
    for (var l = 1; l <= PuzzleShape.layerCount; l++)
      puzzleStarsFor(ShapePuzzles.key(shape.id, l)),
  ].fold(0, (a, b) => a + b);
}

/// The next picture still locked, if any.
PuzzleShape? nextLockedPuzzle(Progress p) {
  for (final s in ShapePuzzles.all) {
    if (!p.puzzleUnlocked(s)) return s;
  }
  return null;
}

/// Pictures that a change from [before] to [after] points opens.
List<PuzzleShape> puzzlesOpenedBetween(int before, int after) => [
  for (final s in ShapePuzzles.all)
    if (before < s.starsToUnlock && after >= s.starsToUnlock) s,
];
