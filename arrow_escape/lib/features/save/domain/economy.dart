import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';

/// Result of applying a win to the save.
typedef WinResult = ({SaveData save, int coins});

/// Pure game-economy rules. Every function takes the current save and
/// returns the next one, so they are trivial to test and replay.
abstract final class Economy {
  /// Daily login rewards, by consecutive claim day (cycles weekly).
  static const dailyRewards = [20, 30, 40, 50, 60, 80, 150];

  static String dayKey(DateTime now) => DailyChallenge.keyFor(now);

  static String _yesterday(DateTime now) =>
      dayKey(DateTime(now.year, now.month, now.day - 1));

  /// Coins for a campaign win: generous the first time, small on replays.
  static int levelCoins({required bool firstClear, required int stars}) =>
      firstClear ? 10 + 5 * stars : 2;

  /// Coins for the daily challenge: big the first time each day.
  static int dailyCoins({required bool firstClear, required int stars}) =>
      firstClear ? 50 + 10 * stars : 5;

  /// The streak as it stands today: it lapses after a missed day.
  static int currentStreak(SaveData s, DateTime now) {
    final last = s.lastWinDay;
    if (last == null) return 0;
    return last == dayKey(now) || last == _yesterday(now) ? s.streak : 0;
  }

  static SaveData _recordWinDay(SaveData s, DateTime now) {
    final today = dayKey(now);
    if (s.lastWinDay == today) return s;
    final streak = s.lastWinDay == _yesterday(now) ? s.streak + 1 : 1;
    return s.copyWith(streak: streak, lastWinDay: today);
  }

  /// [rewardMultiplier] is 2 for Hard and 3 for Super Hard levels; it
  /// applies to the first clear only.
  static WinResult winLevel(
    SaveData s,
    int level,
    int stars,
    DateTime now, {
    int rewardMultiplier = 1,
  }) {
    final p = s.progress;
    final first = p.starsFor(level) == 0;
    final coins =
        levelCoins(firstClear: first, stars: stars) *
        (first ? rewardMultiplier : 1);
    final best = stars > p.starsFor(level) ? stars : p.starsFor(level);
    final next = s.copyWith(
      coins: s.coins + coins,
      progress: p.copyWith(
        stars: {...p.stars, level: best},
        unlocked: level + 1 > p.unlocked ? level + 1 : p.unlocked,
      ),
    );
    return (save: _recordWinDay(next, now), coins: coins);
  }

  static WinResult winDaily(
    SaveData s,
    String dateKey,
    int stars,
    DateTime now,
  ) {
    final p = s.progress;
    final first = p.dailyStarsFor(dateKey) == 0;
    final coins = dailyCoins(firstClear: first, stars: stars);
    final best = stars > p.dailyStarsFor(dateKey)
        ? stars
        : p.dailyStarsFor(dateKey);
    final next = s.copyWith(
      coins: s.coins + coins,
      progress: p.copyWith(dailyStars: {...p.dailyStars, dateKey: best}),
    );
    return (save: _recordWinDay(next, now), coins: coins);
  }

  /// Coins to skip a campaign level.
  static const skipCost = 150;

  /// Skips campaign [level] for [skipCost] coins: the next level opens but
  /// no stars are given. Null when the player can't afford it.
  static SaveData? skipLevel(SaveData s, int level) {
    if (s.coins < skipCost) return null;
    final p = s.progress;
    return s.copyWith(
      coins: s.coins - skipCost,
      progress: p.copyWith(
        unlocked: level + 1 > p.unlocked ? level + 1 : p.unlocked,
      ),
    );
  }

  /// Coins for a picture-puzzle layer: more for deeper layers.
  static int puzzleCoins({
    required bool firstClear,
    required int layer,
    required int stars,
  }) => firstClear ? 20 + 20 * layer + 10 * stars : 3;

  static WinResult winPuzzle(
    SaveData s,
    String key,
    int layer,
    int stars,
    DateTime now,
  ) {
    final p = s.progress;
    final before = p.puzzleStarsFor(key);
    final coins = puzzleCoins(
      firstClear: before == 0,
      layer: layer,
      stars: stars,
    );
    final next = s.copyWith(
      coins: s.coins + coins,
      progress: p.copyWith(
        puzzleStars: {...p.puzzleStars, key: stars > before ? stars : before},
      ),
    );
    return (save: _recordWinDay(next, now), coins: coins);
  }

  static bool canClaimDailyReward(SaveData s, DateTime now) =>
      s.lastRewardDay != dayKey(now);

  /// Amount the next claim would pay.
  static int nextDailyReward(SaveData s, DateTime now) {
    final day = s.lastRewardDay == _yesterday(now) ? s.rewardStreak + 1 : 1;
    return dailyRewards[(day - 1) % dailyRewards.length];
  }

  /// Claims today's reward; [multiplier] is 2 after a rewarded ad.
  static WinResult claimDailyReward(
    SaveData s,
    DateTime now, {
    int multiplier = 1,
  }) {
    if (!canClaimDailyReward(s, now)) return (save: s, coins: 0);
    final amount = nextDailyReward(s, now) * multiplier;
    final day = s.lastRewardDay == _yesterday(now) ? s.rewardStreak + 1 : 1;
    return (
      save: s.copyWith(
        coins: s.coins + amount,
        rewardStreak: day,
        lastRewardDay: dayKey(now),
      ),
      coins: amount,
    );
  }

  /// Buys [skin] for [price] coins; null when unaffordable or owned.
  static SaveData? buySkin(SaveData s, String skin, int price) {
    if (s.owns(skin) || s.coins < price) return null;
    return s.copyWith(
      coins: s.coins - price,
      ownedSkins: [...s.ownedSkins, skin],
      selectedSkin: skin,
    );
  }

  /// Grants [skin] for free (rewarded ad or bundle).
  static SaveData grantSkin(SaveData s, String skin) =>
      s.owns(skin) ? s : s.copyWith(ownedSkins: [...s.ownedSkins, skin]);

  static SaveData selectSkin(SaveData s, String skin) =>
      s.owns(skin) ? s.copyWith(selectedSkin: skin) : s;

  /// Grants a bundle's one-time perks unless already claimed.
  static SaveData claimBundle(
    SaveData s,
    String bundle, {
    required int coins,
    String? skin,
  }) {
    if (s.claimedBundles.contains(bundle)) return s;
    final withSkin = skin == null ? s : grantSkin(s, skin);
    return withSkin.copyWith(
      coins: withSkin.coins + coins,
      claimedBundles: [...withSkin.claimedBundles, bundle],
    );
  }

  static SaveData addCoins(SaveData s, int amount) =>
      s.copyWith(coins: (s.coins + amount).clamp(0, 1 << 30));
}
