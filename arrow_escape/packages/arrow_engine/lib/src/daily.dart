import 'campaign.dart';
import 'level.dart';
import 'rng.dart';
import 'shapes.dart';

/// The daily challenge: one level per calendar day, generated on-device
/// from the date, identical for every player.
abstract final class DailyChallenge {
  /// Part of the seed. Bump when generator changes would alter past dailies
  /// anyway, so the change is deliberate.
  static const version = 4;

  /// Easier early in the week, hardest on Sunday.
  static const weekdayTargets = {
    DateTime.monday: 58.0,
    DateTime.tuesday: 61.0,
    DateTime.wednesday: 64.0,
    DateTime.thursday: 67.0,
    DateTime.friday: 70.0,
    DateTime.saturday: 74.0,
    DateTime.sunday: 78.0,
  };

  /// `yyyy-mm-dd` of the player's local calendar day.
  static String keyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Level id: yyyymmdd.
  static int idFor(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static DateTime parseKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) throw FormatException('Bad daily key "$key"');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static double targetFor(DateTime date) => weekdayTargets[date.weekday]!;

  static Level levelFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final rng = Rng(stableHash('daily-v$version-${keyFor(day)}'));
    final shapes = [
      for (final s in Shapes.all)
        if (!Shapes.isLetter(s)) s,
    ];
    final shape = rng.pick(shapes);
    final mechanics = MechanicSet(
      lights: rng.nextBool(0.4) ? 1 + rng.nextInt(2) : 0,
      gates: rng.nextBool(0.35) ? 1 + rng.nextInt(2) : 0,
      ambulance: rng.nextBool(0.25),
    );
    final seed = rng.nextUint32();
    for (var attempt = 0; attempt < 6; attempt++) {
      final level = generateForTarget(
        id: idFor(day),
        target: targetFor(day),
        seed: seed + attempt * 7919,
        // Fall back to fewer constraints if a combination is too tight.
        shape: attempt < 3 ? shape : ShapeMask.rect(14, 18),
        mechanics: attempt < 4 ? mechanics : const MechanicSet(),
        candidates: 14,
        // Bigger boards later in the week.
        minCells: 100 + day.weekday * 12,
      );
      if (level != null) return level;
    }
    throw StateError('Could not generate the daily for ${keyFor(day)}');
  }
}
