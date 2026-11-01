import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/game/presentation/widgets/progress_cheer.dart';
import 'package:arrow_escape/features/review/domain/review_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 1);
  bool ask({
    int level = 20,
    int stars = 3,
    bool interstitial = false,
    List<int> asks = const [],
    int lastLevel = 0,
    DateTime? at,
  }) => ReviewPolicy.shouldAsk(
    level: level,
    stars: stars,
    showedInterstitial: interstitial,
    asks: asks,
    lastAskLevel: lastLevel,
    now: at ?? now,
  );

  test('asks after a great win from level 12, never mid-ad or early', () {
    expect(ask(), isTrue);
    expect(ask(level: 11), isFalse);
    expect(ask(stars: 2), isFalse);
    expect(ask(interstitial: true), isFalse);
  });

  test('spaces asks out and stops after three', () {
    final first = now.millisecondsSinceEpoch;
    // Too soon by levels, then by days.
    expect(
      ask(
        asks: [first],
        lastLevel: 20,
        level: 40,
        at: now.add(const Duration(days: 60)),
      ),
      isFalse,
    );
    expect(
      ask(
        asks: [first],
        lastLevel: 20,
        level: 80,
        at: now.add(const Duration(days: 10)),
      ),
      isFalse,
    );
    expect(
      ask(
        asks: [first],
        lastLevel: 20,
        level: 80,
        at: now.add(const Duration(days: 40)),
      ),
      isTrue,
    );
    expect(
      ask(
        asks: [first, first, first],
        lastLevel: 20,
        level: 500,
        at: now.add(const Duration(days: 900)),
      ),
      isFalse,
    );
  });

  test('cheers at halfway, and near the end of hard levels only', () {
    Cheer? due(int total, int remaining, LevelTier tier, [Set<Cheer>? s]) =>
        ProgressCheer.due(
          total: total,
          remaining: remaining,
          tier: tier,
          shown: s ?? {},
        );
    expect(due(40, 21, LevelTier.normal), isNull);
    expect(due(40, 20, LevelTier.normal), Cheer.halfway);
    expect(due(40, 20, LevelTier.normal, {Cheer.halfway}), isNull);
    expect(due(40, 3, LevelTier.normal, {Cheer.halfway}), isNull);
    expect(due(40, 4, LevelTier.hard, {Cheer.halfway}), Cheer.almost);
    // Small boards are over too fast for a cheer.
    expect(due(12, 6, LevelTier.normal), isNull);
  });
}
