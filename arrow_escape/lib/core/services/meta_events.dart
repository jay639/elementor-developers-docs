import 'package:arrow_escape/core/services/analytics.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Meta (Facebook) app events for install campaigns: install / app open,
/// in-app purchases (logged by the SDK itself, as set in the Meta
/// dashboard), level progress and ad revenue.
///
/// Nothing is sent until the player's choices allow it: "Share usage
/// analytics" on AND ad consent granted (UMP in the EEA/UK, always granted
/// elsewhere). On iOS the SDK also follows App Tracking Transparency.
abstract interface class MetaEvents {
  /// Turns automatic logging (install, app open, purchases) and the
  /// advertising ID on or off.
  Future<void> setEnabled(bool enabled);

  Future<void> log(
    String name, {
    Map<String, Object> params = const {},
    double? valueToSum,
  });
}

class NoMetaEvents implements MetaEvents {
  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> log(
    String name, {
    Map<String, Object> params = const {},
    double? valueToSum,
  }) async {}
}

class FacebookMetaEvents implements MetaEvents {
  final _fb = FacebookAppEvents();
  bool _enabled = false;

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled == _enabled) return;
    _enabled = enabled;
    try {
      await _fb.setAutoLogAppEventsEnabled(enabled);
      await _fb.setAdvertiserIdCollectionEnabled(enabled);
      // Counts the install and this app open as soon as it is allowed.
      if (enabled) await _fb.activateApp();
    } on Object catch (e) {
      debugPrint('Meta events: $e');
    }
  }

  @override
  Future<void> log(
    String name, {
    Map<String, Object> params = const {},
    double? valueToSum,
  }) async {
    if (!_enabled) return;
    try {
      await _fb.logEvent(
        name: name,
        parameters: params,
        valueToSum: valueToSum,
      );
    } on Object catch (e) {
      debugPrint('Meta events: $e');
    }
  }
}

/// Wraps the app's analytics and forwards the events Meta campaigns can
/// optimise for, using Meta's standard event names. Consent follows the
/// same switches as analytics and ads.
class MetaForwardingAnalytics extends AnalyticsService {
  MetaForwardingAnalytics(this.inner, this.meta);

  final AnalyticsService inner;
  final MetaEvents meta;

  bool _collection = true;
  bool _adConsent = false;

  void _sync() => meta.setEnabled(_collection && _adConsent);

  /// Meta event for one of our events, or null when it isn't forwarded.
  /// Purchases aren't forwarded: the Meta SDK logs them automatically
  /// ("Log in-app purchases automatically" in the Meta app settings), and
  /// logging them twice would double-count revenue.
  @visibleForTesting
  static ({String name, Map<String, Object> params, double? value})? mapEvent(
    String name,
    Map<String, Object> params,
  ) => switch (name) {
    'level_complete' => (
      name: 'fb_mobile_level_achieved',
      params: {
        'fb_level': '${params['level'] ?? ''}',
        'mode': '${params['mode'] ?? ''}',
        'stars': params['stars'] ?? 0,
      },
      value: null,
    ),
    'level_start' => (
      name: 'level_start',
      params: {'fb_level': '${params['level'] ?? ''}'},
      value: null,
    ),
    'tutorial_complete' => (
      name: 'fb_mobile_tutorial_completion',
      params: {'fb_success': 1},
      value: null,
    ),
    'ad_reward' => (
      name: 'rewarded_ad_completed',
      params: {'placement': '${params['placement'] ?? ''}'},
      value: null,
    ),
    'ad_impression' => (
      name: 'AdImpression',
      params: {
        'fb_currency': '${params['currency'] ?? 'USD'}',
        'ad_type': '${params['ad_format'] ?? ''}',
      },
      value: (params['value'] as num?)?.toDouble(),
    ),
    'review_prompt' => (name: 'fb_mobile_rate', params: {}, value: null),
    _ => null,
  };

  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) {
    final m = mapEvent(name, params);
    if (m != null) {
      meta.log(m.name, params: m.params, valueToSum: m.value);
    }
    return inner.log(name, params);
  }

  @override
  Future<void> setUserProperty(String name, String? value) =>
      inner.setUserProperty(name, value);

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    _collection = enabled;
    _sync();
    return inner.setCollectionEnabled(enabled);
  }

  @override
  Future<void> setAdConsent({required bool granted}) {
    _adConsent = granted;
    _sync();
    return inner.setAdConsent(granted: granted);
  }

  @override
  Future<void> setUserId(String? id) => inner.setUserId(id);
}
