import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product analytics. Firebase in production, recorded in tests.
///
/// One typed method per event keeps names and parameters consistent (see
/// docs/growth_plan.html for the event plan). Firebase limits: event names
/// up to 40 chars, 25 parameters, values up to 100 chars; never send
/// personal data.
abstract class AnalyticsService {
  Future<void> log(String name, [Map<String, Object> params = const {}]);

  /// Persistent attribute of the player, used for segments and A/B tests.
  Future<void> setUserProperty(String name, String? value) async {}

  /// The player's "Share usage analytics" choice.
  Future<void> setCollectionEnabled(bool enabled) async {}

  /// Ad consent from the UMP form (consent mode v2).
  Future<void> setAdConsent({required bool granted}) async {}

  Future<void> setUserId(String? id) async {}

  // ---- Levels -------------------------------------------------------------

  Future<void> levelStart(LevelInfo info) => log('level_start', info.params);

  Future<void> levelComplete(
    LevelInfo info, {
    required int stars,
    required int mistakes,
    required int seconds,
    required HelpCounts help,
  }) => log('level_complete', {
    ...info.params,
    'stars': stars,
    'mistakes': mistakes,
    'seconds': seconds,
    'first_try': info.attempt == 1 && mistakes == 0 ? 1 : 0,
    ...help.params,
  });

  Future<void> levelFail(
    LevelInfo info, {
    required int seconds,
    required int progressPct,
    required HelpCounts help,
  }) => log('level_fail', {
    ...info.params,
    'seconds': seconds,
    'progress_pct': progressPct,
    ...help.params,
  });

  /// Left a level unfinished: the strongest "too hard or boring" signal.
  Future<void> levelQuit(
    LevelInfo info, {
    required int seconds,
    required int progressPct,
  }) => log('level_quit', {
    ...info.params,
    'seconds': seconds,
    'progress_pct': progressPct,
  });

  Future<void> levelContinue(LevelInfo info, {required String source}) =>
      log('level_continue', {...info.params, 'source': source});

  /// Hint, show paths or a booster.
  Future<void> helpUsed(
    String type, {
    required String level,
    required String source,
  }) => log('help_used', {'type': type, 'level': level, 'source': source});

  // ---- Economy and meta ---------------------------------------------------

  Future<void> earnCoins(int value, String reason) => log(
    'earn_virtual_currency',
    {'virtual_currency_name': 'coins', 'value': value, 'reason': reason},
  );

  Future<void> spendCoins(int value, String reason) => log(
    'spend_virtual_currency',
    {'virtual_currency_name': 'coins', 'value': value, 'item_name': reason},
  );

  // ---- Ads and purchases ---------------------------------------------------

  Future<void> adShown(String format, String placement) =>
      log('ad_show', {'format': format, 'placement': placement});

  Future<void> adReward(String placement) =>
      log('ad_reward', {'placement': placement});

  Future<void> adFailed(String format, String reason) =>
      log('ad_fail', {'format': format, 'reason': reason});

  /// Impression-level ad revenue (AdMob paid event), for ARPDAU and LTV.
  Future<void> adRevenue({
    required String format,
    required double value,
    required String currency,
    String? source,
    String? precision,
  }) => log('ad_impression', {
    'ad_platform': 'AdMob',
    'ad_format': format,
    'value': value,
    'currency': currency,
    'ad_source': ?source,
    'precision': ?precision,
  });

  Future<void> purchase(
    String productId, {
    required bool success,
    String? error,
  }) => log(success ? 'purchase_success' : 'purchase_fail', {
    'product': productId,
    'error': ?error,
  });
}

/// Who/what a level event is about. `attempt` counts plays of this level
/// until it is first won.
@immutable
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.mode,
    required this.tier,
    required this.attempt,
    required this.arrows,
    required this.predictedDifficulty,
  });

  final String level;

  /// campaign or daily.
  final String mode;
  final String tier;
  final int attempt;
  final int arrows;
  final double predictedDifficulty;

  Map<String, Object> get params => {
    'level': level,
    'mode': mode,
    'tier': tier,
    'attempt': attempt,
    'arrows': arrows,
    'predicted_difficulty': predictedDifficulty,
  };
}

/// Help used during one attempt.
@immutable
class HelpCounts {
  const HelpCounts({this.hints = 0, this.paths = false});

  final int hints;
  final bool paths;

  HelpCounts copyWith({int? hints, bool? paths}) =>
      HelpCounts(hints: hints ?? this.hints, paths: paths ?? this.paths);

  Map<String, Object> get params => {
    'hints': hints,
    'paths_used': paths ? 1 : 0,
  };
}

class DebugAnalytics extends AnalyticsService {
  bool _enabled = true;

  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) async {
    if (_enabled && kDebugMode) debugPrint('[analytics] $name $params');
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    if (_enabled && kDebugMode) debugPrint('[analytics] user $name=$value');
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async => _enabled = enabled;
}

/// Overridden in bootstrap.
final analyticsProvider = Provider<AnalyticsService>((ref) => DebugAnalytics());
