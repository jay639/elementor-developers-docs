import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/core/services/meta_events.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

class _FakeMeta implements MetaEvents {
  bool enabled = false;
  final logged = <(String, Map<String, Object>, double?)>[];

  @override
  Future<void> setEnabled(bool e) async => enabled = e;

  @override
  Future<void> log(
    String name, {
    Map<String, Object> params = const {},
    double? valueToSum,
  }) async {
    if (enabled) logged.add((name, params, valueToSum));
  }
}

void main() {
  late _FakeMeta meta;
  late RecordingAnalytics inner;
  late MetaForwardingAnalytics analytics;

  setUp(() {
    meta = _FakeMeta();
    inner = RecordingAnalytics();
    analytics = MetaForwardingAnalytics(inner, meta);
  });

  const info = LevelInfo(
    level: '8',
    mode: 'campaign',
    tier: 'normal',
    attempt: 1,
    arrows: 80,
    predictedDifficulty: 90,
  );

  test('nothing reaches Meta before ad consent', () async {
    await analytics.levelComplete(
      info,
      stars: 3,
      mistakes: 0,
      seconds: 60,
      help: const HelpCounts(),
    );
    expect(meta.enabled, isFalse);
    expect(meta.logged, isEmpty);
    // Our own analytics still gets it.
    expect(inner.events.map((e) => e.name), contains('level_complete'));
  });

  test(
    'with consent: level, tutorial, rewarded and ad revenue events',
    () async {
      await analytics.setAdConsent(granted: true);
      expect(meta.enabled, isTrue);
      await analytics.levelComplete(
        info,
        stars: 2,
        mistakes: 1,
        seconds: 60,
        help: const HelpCounts(),
      );
      await analytics.log('tutorial_complete', {'seconds': 30});
      await analytics.adReward('hint');
      await analytics.adRevenue(
        format: 'rewarded',
        value: 0.012,
        currency: 'USD',
      );
      final names = [for (final e in meta.logged) e.$1];
      expect(names, [
        'fb_mobile_level_achieved',
        'fb_mobile_tutorial_completion',
        'rewarded_ad_completed',
        'AdImpression',
      ]);
      expect(meta.logged.first.$2['fb_level'], '8');
      expect(meta.logged.last.$3, closeTo(0.012, 1e-9));
      expect(meta.logged.last.$2['fb_currency'], 'USD');
    },
  );

  test('analytics opt-out turns Meta off again', () async {
    await analytics.setAdConsent(granted: true);
    await analytics.setCollectionEnabled(false);
    expect(meta.enabled, isFalse);
    await analytics.log('tutorial_complete');
    expect(meta.logged, isEmpty);
  });

  test('purchases are left to the SDK (no double counting)', () async {
    await analytics.setAdConsent(granted: true);
    await analytics.purchase('remove_ads', success: true);
    expect(meta.logged, isEmpty);
  });
}
