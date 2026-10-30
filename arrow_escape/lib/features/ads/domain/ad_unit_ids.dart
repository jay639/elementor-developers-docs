import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Ad unit IDs. Debug and dev builds use Google's public test units; real
/// units are injected at build time and never committed:
///
///   flutter build appbundle --flavor prod -t lib/main_prod.dart \
///     --dart-define=ADMOB_ANDROID_BANNER=ca-app-pub-xxx/yyy ...
class AdUnitIds {
  const AdUnitIds({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });

  final String banner;
  final String interstitial;
  final String rewarded;

  bool get isComplete =>
      banner.isNotEmpty && interstitial.isNotEmpty && rewarded.isNotEmpty;

  static const androidTest = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/9214589741',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const iosTest = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/2435281174',
    interstitial: 'ca-app-pub-3940256099942544/4411468910',
    rewarded: 'ca-app-pub-3940256099942544/1712485313',
  );

  static const androidRelease = AdUnitIds(
    banner: String.fromEnvironment('ADMOB_ANDROID_BANNER'),
    interstitial: String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL'),
    rewarded: String.fromEnvironment('ADMOB_ANDROID_REWARDED'),
  );

  static const iosRelease = AdUnitIds(
    banner: String.fromEnvironment('ADMOB_IOS_BANNER'),
    interstitial: String.fromEnvironment('ADMOB_IOS_INTERSTITIAL'),
    rewarded: String.fromEnvironment('ADMOB_IOS_REWARDED'),
  );

  /// Units for this build. [useTestAds] is true for debug and the dev
  /// flavor. Returns null when release units weren't provided, which
  /// turns ads off instead of shipping test ads.
  static AdUnitIds? forPlatform({required bool useTestAds}) {
    final ios = Platform.isIOS;
    if (useTestAds || kDebugMode) return ios ? iosTest : androidTest;
    final real = ios ? iosRelease : androidRelease;
    return real.isComplete ? real : null;
  }
}
