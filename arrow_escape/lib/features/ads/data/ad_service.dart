import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a rewarded ad pays out. Also the analytics placement name.
enum RewardKind { hint, extraHeart, doubleCoins, unlockSkin, doubleDailyReward }

/// Everything the game needs from an ad network.
abstract interface class AdService {
  /// Consent (UMP), tracking prompt (iOS ATT), SDK start, first loads.
  Future<void> initialize();

  /// Set from the `no_ads` entitlement: hides interstitials and banners.
  /// Rewarded ads stay available; they're the player's choice.
  set adsRemoved(bool value);
  bool get adsRemoved;

  bool get rewardedReady;

  /// Shows a rewarded ad; true when the reward was earned.
  Future<bool> showRewarded(RewardKind kind);

  /// Call after a completed campaign level; the frequency policy decides.
  /// True when an interstitial was shown.
  Future<bool> onLevelCompleted(int level);

  /// Banner for the map screen, or an empty box.
  Widget buildBanner();

  /// GDPR: whether settings must offer "Privacy options".
  Future<bool> privacyOptionsRequired();
  Future<void> showPrivacyOptions();
}

/// No network (tests, missing release IDs): never shows anything.
class NoAdService implements AdService {
  @override
  bool adsRemoved = false;

  @override
  Future<void> initialize() async {}

  @override
  bool get rewardedReady => false;

  @override
  Future<bool> showRewarded(RewardKind kind) async => false;

  @override
  Future<bool> onLevelCompleted(int level) async => false;

  @override
  Widget buildBanner() => const SizedBox.shrink();

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}

/// Overridden in bootstrap.
final adServiceProvider = Provider<AdService>((ref) => NoAdService());
