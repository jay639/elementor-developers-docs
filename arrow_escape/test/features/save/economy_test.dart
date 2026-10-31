import 'package:arrow_escape/features/save/domain/economy.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day1 = DateTime(2026, 10, 29, 10);
  final day2 = DateTime(2026, 10, 30, 9);
  final day4 = DateTime(2026, 11, 1, 9);
  const empty = SaveData();

  group('level wins', () {
    test('first clear pays by stars, replays pay a little', () {
      var r = Economy.winLevel(empty, 1, 3, day1);
      expect(r.coins, 25);
      expect(r.save.progress.unlocked, 2);
      r = Economy.winLevel(r.save, 1, 1, day1);
      expect(r.coins, 2);
      expect(r.save.progress.starsFor(1), 3, reason: 'best stars kept');
      expect(r.save.coins, 27);
    });

    test('hard tiers multiply the first clear only', () {
      var r = Economy.winLevel(empty, 19, 3, day1, rewardMultiplier: 2);
      expect(r.coins, 50);
      r = Economy.winLevel(r.save, 19, 3, day1, rewardMultiplier: 2);
      expect(r.coins, 2);
    });

    test('replaying an old level does not move the unlock back', () {
      final s = empty.copyWith.progress(unlocked: 50);
      expect(Economy.winLevel(s, 3, 2, day1).save.progress.unlocked, 50);
    });

    test('daily wins pay more and only once per day', () {
      var r = Economy.winDaily(empty, '2026-10-29', 2, day1);
      expect(r.coins, 70);
      r = Economy.winDaily(r.save, '2026-10-29', 3, day1);
      expect(r.coins, 5);
      expect(r.save.progress.dailyStarsFor('2026-10-29'), 3);
    });
  });

  group('streak', () {
    test('grows on consecutive days, once per day', () {
      var s = Economy.winLevel(empty, 1, 3, day1).save;
      s = Economy.winLevel(s, 2, 3, day1).save;
      expect(s.streak, 1);
      s = Economy.winLevel(s, 3, 3, day2).save;
      expect(s.streak, 2);
      expect(Economy.currentStreak(s, day2), 2);
    });

    test('lapses after a missed day and restarts at 1', () {
      final s = Economy.winLevel(empty, 1, 3, day1).save;
      expect(Economy.currentStreak(s, day2), 1, reason: 'still alive');
      expect(Economy.currentStreak(s, day4), 0);
      expect(Economy.winLevel(s, 2, 3, day4).save.streak, 1);
    });
  });

  group('daily reward', () {
    test('once per day, amount climbs with consecutive claims', () {
      expect(Economy.canClaimDailyReward(empty, day1), isTrue);
      var r = Economy.claimDailyReward(empty, day1);
      expect(r.coins, 20);
      expect(Economy.canClaimDailyReward(r.save, day1), isFalse);
      expect(Economy.claimDailyReward(r.save, day1).coins, 0);
      r = Economy.claimDailyReward(r.save, day2);
      expect(r.coins, 30);
    });

    test('a missed day resets the ladder; x2 doubles', () {
      var r = Economy.claimDailyReward(empty, day1);
      r = Economy.claimDailyReward(r.save, day4, multiplier: 2);
      expect(r.coins, 40);
      expect(r.save.rewardStreak, 1);
    });

    test('the ladder cycles weekly', () {
      var s = empty;
      final paid = <int>[];
      for (var d = 0; d < 9; d++) {
        final r = Economy.claimDailyReward(s, DateTime(2026, 11, 1 + d));
        paid.add(r.coins);
        s = r.save;
      }
      expect(paid, [20, 30, 40, 50, 60, 80, 150, 20, 30]);
    });
  });

  group('skins and bundles', () {
    test('buying needs coins, selects the skin and is not repeatable', () {
      expect(Economy.buySkin(empty, 'ocean', 500), isNull);
      final rich = empty.copyWith(coins: 600);
      final s = Economy.buySkin(rich, 'ocean', 500)!;
      expect(s.coins, 100);
      expect(s.owns('ocean'), isTrue);
      expect(s.selectedSkin, 'ocean');
      expect(Economy.buySkin(s.copyWith(coins: 900), 'ocean', 500), isNull);
    });

    test('cannot select a skin you do not own', () {
      expect(Economy.selectSkin(empty, 'gold').selectedSkin, 'classic');
    });

    test('bundle perks are granted once', () {
      var s = Economy.claimBundle(
        empty,
        'starter_bundle',
        coins: 1500,
        skin: 'neon',
      );
      s = Economy.claimBundle(s, 'starter_bundle', coins: 1500, skin: 'neon');
      expect(s.coins, 1500);
      expect(s.owns('neon'), isTrue);
    });

    test('coins never go negative', () {
      expect(Economy.addCoins(empty.copyWith(coins: 5), -50).coins, 0);
    });
  });
}
