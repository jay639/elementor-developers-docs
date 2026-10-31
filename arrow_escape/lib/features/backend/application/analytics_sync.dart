import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/features/purchases/application/entitlements.dart';
import 'package:arrow_escape/features/purchases/data/purchase_service.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User properties for segments, funnels and A/B tests. Values are coarse
/// buckets so they stay within Firebase's 25-property / 36-char limits and
/// never identify anyone.
Map<String, String> userPropertiesFor(SaveData save, Entitlements e) {
  final s = save.settings;
  final a11y = [
    if (s.thickArrows) 'thick',
    if (s.highContrast) 'contrast',
    if (s.colorblind) 'colorblind',
    if (s.reduceMotion) 'motion',
  ];
  return {
    'max_level': _bucket(save.progress.unlocked - 1, const [
      0, 10, 25, 50, 100, 200, 300, 500, 750, 1000, 1500, //
    ]),
    'total_stars': _bucket(save.progress.totalStars, const [
      0, 30, 100, 300, 1000, 3000, //
    ]),
    'is_payer': '${e.active.isNotEmpty}',
    'no_ads': '${e.noAds}',
    'streak_days': _bucket(save.streak, const [0, 1, 3, 7, 14, 30, 100]),
    'skin': save.selectedSkin,
    'a11y_mode': a11y.isEmpty ? 'none' : a11y.join('+'),
  };
}

/// "50-99" style label for the bucket [value] falls in.
String _bucket(int value, List<int> edges) {
  for (var i = edges.length - 1; i >= 0; i--) {
    if (value >= edges[i]) {
      if (i == edges.length - 1) return '${edges[i]}+';
      final hi = edges[i + 1] - 1;
      return hi == edges[i] ? '${edges[i]}' : '${edges[i]}-$hi';
    }
  }
  return '<${edges.first}';
}

/// Keeps analytics in step with the save: user properties (sent only when
/// they change) and the player's "Share usage analytics" choice.
class AnalyticsSync {
  AnalyticsSync(this._container);

  final ProviderContainer _container;
  final _sent = <String, String>{};
  bool? _collection;

  void start() {
    _container
      ..listen(saveProvider, (_, _) => _sync(), fireImmediately: true)
      ..listen(entitlementsProvider, (_, _) => _sync());
  }

  void _sync() {
    final analytics = _container.read(analyticsProvider);
    final save = _container.read(saveProvider);
    final enabled = save.settings.shareAnalytics;
    if (enabled != _collection) {
      _collection = enabled;
      analytics.setCollectionEnabled(enabled);
    }
    final props = userPropertiesFor(
      save,
      _container.read(entitlementsProvider),
    );
    for (final MapEntry(:key, :value) in props.entries) {
      if (_sent[key] == value) continue;
      _sent[key] = value;
      analytics.setUserProperty(key, value);
    }
  }
}
