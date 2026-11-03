import 'campaign.dart';
import 'level.dart';
import 'rng.dart';
import 'shapes.dart';

/// The daily challenge: one level per calendar day, generated on-device
/// from the date, identical for every player.
abstract final class DailyChallenge {
  /// Part of the seed. Bump when generator changes would alter past dailies
  /// anyway, so the change is deliberate.
  static const version = 8;

  /// First day of the current daily series.
  static final launch = DateTime.utc(2026, 11, 1);

  /// Arrow count: a huge board from day one (85 arrows, about campaign
  /// level 900), growing by one arrow every 10 days, with 6 extra at
  /// weekends, up to 110 (about what the biggest board holds).
  /// Solve effort ([LevelStats.effort], roughly solve time): 750 at
  /// launch (about campaign level 350), +1.5 every day, +90 at weekends,
  /// up to 1250. So each weekday's daily takes a little longer than the one
  /// before. Plain arithmetic: identical on every device.
  static double effortFor(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final days = day.difference(launch).inDays.clamp(0, 100000);
    final weekend = date.weekday >= DateTime.saturday ? 90.0 : 0.0;
    return (750.0 + days * 1.5 + weekend).clamp(750.0, 1250.0);
  }

  /// Starting guess for the arrow count (the effort target decides).
  static int arrowsFor(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final days = day.difference(launch).inDays.clamp(0, 100000);
    final weekend = date.weekday >= DateTime.saturday ? 6 : 0;
    return (85 + days ~/ 10 + weekend).clamp(85, 110);
  }

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
    // The biggest board (24x32) every day.
    final shape = ShapeMask.rect(3, 4);
    final mechanics = MechanicSet(
      lights: rng.nextBool(0.4) ? 1 + rng.nextInt(2) : 0,
      gates: rng.nextBool(0.35) ? 1 + rng.nextInt(2) : 0,
      ambulance: rng.nextBool(0.25),
    );
    final seed = rng.nextUint32();
    for (var attempt = 0; attempt < 6; attempt++) {
      final level = generateForEffort(
        id: idFor(day),
        effort: effortFor(day),
        arrows: arrowsFor(day),
        seed: seed + attempt * 7919,
        // Fall back to fewer constraints if a combination is too tight.
        shape: attempt < 3 ? shape : ShapeMask.rect(3, 4),
        mechanics: attempt < 4 ? mechanics : const MechanicSet(),
        greed: 12,
        maxLength: 22,
        longShare: 0.07,
        midShare: 0.2,
        candidates: 10,
      );
      if (level != null) return level;
    }
    throw StateError('Could not generate the daily for ${keyFor(day)}');
  }
}
