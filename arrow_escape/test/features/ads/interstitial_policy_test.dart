import 'package:arrow_escape/features/ads/domain/ad_unit_ids.dart';
import 'package:arrow_escape/features/ads/domain/interstitial_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 10, 29, 12);
  InterstitialPolicy policy([
    InterstitialConfig c = const InterstitialConfig(),
  ]) => InterstitialPolicy(() => c);

  test('never before level 10', () {
    final p = policy();
    for (var level = 1; level < 10; level++) {
      expect(p.onLevelCompleted(level, t0), isFalse, reason: 'L$level');
    }
  });

  test('at most one per 3 levels AND 3 minutes', () {
    final p = policy();
    for (var level = 1; level < 10; level++) {
      p.onLevelCompleted(level, t0);
    }
    expect(p.onLevelCompleted(10, t0), isTrue);
    p.markShown(t0);
    // Two more levels: gap not reached.
    expect(p.onLevelCompleted(11, t0.add(const Duration(minutes: 5))), isFalse);
    expect(p.onLevelCompleted(12, t0.add(const Duration(minutes: 6))), isFalse);
    // Gap reached but within 3 minutes of the last ad.
    final p2 = policy();
    for (var level = 1; level <= 10; level++) {
      p2.onLevelCompleted(level, t0);
    }
    p2.markShown(t0);
    for (var level = 11; level <= 13; level++) {
      final ok = p2.onLevelCompleted(level, t0.add(const Duration(minutes: 1)));
      expect(ok, isFalse, reason: 'L$level too soon');
    }
    expect(p2.onLevelCompleted(14, t0.add(const Duration(minutes: 3))), isTrue);
  });

  test('values come from remote config at call time', () {
    var config = const InterstitialConfig();
    final p = InterstitialPolicy(() => config);
    config = const InterstitialConfig(
      minLevel: 1,
      levelGap: 1,
      minInterval: Duration.zero,
    );
    expect(p.onLevelCompleted(1, t0), isTrue);
  });

  test('test ad units are Google\'s public ones', () {
    expect(
      AdUnitIds.androidTest.rewarded,
      startsWith('ca-app-pub-3940256099942544/'),
    );
    expect(AdUnitIds.iosTest.isComplete, isTrue);
    // No real IDs are compiled in without --dart-define.
    expect(AdUnitIds.androidRelease.isComplete, isFalse);
  });
}
