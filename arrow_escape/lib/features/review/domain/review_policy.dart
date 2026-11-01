/// When to ask for a store rating.
///
/// The stores never tell an app whether (or how) the player rated, so a
/// 5-star rater can't be skipped and a low rater can't be re-asked
/// specifically. Both stores also forbid asking "do you like it?" first
/// and only sending happy players to the store (review gating). What we
/// can do is ask at the best moments and rarely:
///
/// - only after a 3-star campaign win from level [firstLevel] on, never on
///   a win that just showed an interstitial;
/// - at least [gapLevels] levels and [gapDays] days after the last ask;
/// - at most [maxAsks] times ever (iOS itself allows 3 per 365 days and
///   Google Play quietly rate-limits too).
abstract final class ReviewPolicy {
  static const firstLevel = 12;
  static const gapLevels = 40;
  static const gapDays = 30;
  static const maxAsks = 3;

  static bool shouldAsk({
    required int level,
    required int stars,
    required bool showedInterstitial,
    required List<int> asks,
    required int lastAskLevel,
    required DateTime now,
  }) {
    if (level < firstLevel || stars < 3 || showedInterstitial) return false;
    if (asks.length >= maxAsks) return false;
    if (asks.isEmpty) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(asks.last);
    return level - lastAskLevel >= gapLevels &&
        now.difference(last).inDays >= gapDays;
  }
}
