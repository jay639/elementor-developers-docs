import 'campaign.dart';
import 'level.dart';
import 'rng.dart';
import 'shapes.dart';

/// The daily challenge: one level per calendar day, generated on-device
/// from the date, identical for every player.
abstract final class DailyChallenge {
  /// Part of the seed. Bump when generator changes would alter past dailies
  /// anyway, so the change is deliberate.
  static const version = 5;

  /// First day of the current daily series.
  static final launch = DateTime.utc(2026, 11, 1);

  /// Always harder than campaign level 20, and harder every day: +0.1 a
  /// day (about +3 a month) up to an expert ceiling, plus a small weekend
  /// bump.
  static double targetFor(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final days = day.difference(launch).inDays.clamp(0, 100000);
    final weekend = date.weekday >= DateTime.saturday ? 2.0 : 0.0;
    return (66 + days * 0.1 + weekend).clamp(66.0, 90.0);
  }

  /// Board size grows with the difficulty: always a crowded board.
  static int minCellsFor(DateTime date) =>
      (190 + (targetFor(date) - 66) * 4).round().clamp(190, 290);

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

  static Level levelFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final rng = Rng(stableHash('daily-v$version-${keyFor(day)}'));
    // Always a full rectangle: the most crowded board, every cell in play.
    final shape = ShapeMask.rect(13 + rng.nextInt(3), 15 + rng.nextInt(4));
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
        // Bigger boards as the daily gets harder.
        minCells: minCellsFor(day),
      );
      if (level != null) return level;
    }
    throw StateError('Could not generate the daily for ${keyFor(day)}');
  }
}
