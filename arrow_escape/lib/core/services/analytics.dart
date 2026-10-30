import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product analytics. Firebase in production, recorded in tests.
abstract class AnalyticsService {
  Future<void> log(String name, [Map<String, Object> params = const {}]);

  Future<void> levelStart(String level, {required bool daily}) =>
      log('level_start', {'level': level, 'daily': daily ? 1 : 0});

  Future<void> levelComplete(
    String level, {
    required bool daily,
    required int stars,
    required int mistakes,
    required int seconds,
  }) => log('level_complete', {
    'level': level,
    'daily': daily ? 1 : 0,
    'stars': stars,
    'mistakes': mistakes,
    'seconds': seconds,
  });

  Future<void> levelFail(
    String level, {
    required bool daily,
    required int seconds,
  }) => log('level_fail', {
    'level': level,
    'daily': daily ? 1 : 0,
    'seconds': seconds,
  });

  Future<void> adShown(String format, String placement) =>
      log('ad_show', {'format': format, 'placement': placement});

  Future<void> adReward(String placement) =>
      log('ad_reward', {'placement': placement});

  Future<void> adFailed(String format, String reason) =>
      log('ad_fail', {'format': format, 'reason': reason});

  Future<void> purchase(
    String productId, {
    required bool success,
    String? error,
  }) => log(success ? 'purchase_success' : 'purchase_fail', {
    'product': productId,
    'error': ?error,
  });

  Future<void> setUserId(String? id) async {}
}

class DebugAnalytics extends AnalyticsService {
  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) async {
    if (kDebugMode) debugPrint('[analytics] $name $params');
  }
}

/// Overridden in bootstrap.
final analyticsProvider = Provider<AnalyticsService>((ref) => DebugAnalytics());
