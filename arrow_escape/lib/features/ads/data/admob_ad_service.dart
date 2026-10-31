import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/ads/domain/ad_unit_ids.dart';
import 'package:arrow_escape/features/ads/domain/interstitial_policy.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google Mobile Ads with AdMob mediation (AppLovin, Unity, Meta,
/// ironSource/LevelPlay adapters are linked as plugins and configured in
/// the AdMob console; consent reaches them through Google's certified CMP).
class AdMobAdService implements AdService {
  AdMobAdService({
    required this.ids,
    required this.policy,
    required this.analytics,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AdUnitIds ids;
  final InterstitialPolicy policy;
  final AnalyticsService analytics;
  final DateTime Function() _clock;

  bool _ready = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _retry = 0;

  @override
  bool adsRemoved = false;

  @override
  bool get rewardedReady => _rewarded != null;

  @override
  Future<void> initialize() async {
    await _gatherConsent();
    if (Platform.isIOS) {
      // ATT after the GDPR form, as Google recommends.
      try {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (e) {
        debugPrint('ATT unavailable: $e');
      }
    }
    final canRequest = await ConsentInformation.instance.canRequestAds();
    await analytics.setAdConsent(granted: canRequest && await _personalized());
    if (!canRequest) return;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        // Not a children's app.
        // ignore: deprecated_member_use
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        // ignore: deprecated_member_use
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        maxAdContentRating: MaxAdContentRating.pg,
      ),
    );
    await MobileAds.instance.initialize();
    _ready = true;
    _loadInterstitial();
    _loadRewarded();
  }

  /// Whether UMP consent covers personalised ads: "obtained" from the form,
  /// or "not required" outside regulated regions.
  Future<bool> _personalized() async {
    final status = await ConsentInformation.instance.getConsentStatus();
    return status == ConsentStatus.obtained ||
        status == ConsentStatus.notRequired;
  }

  /// Impression-level revenue for ARPDAU / LTV (micros to currency units).
  void _paid(String format, Ad ad, double micros, PrecisionType p, String cc) {
    analytics.adRevenue(
      format: format,
      value: micros / 1e6,
      currency: cc,
      source: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
      precision: p.name,
    );
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('Consent form: ${error.message}');
        });
        if (!done.isCompleted) done.complete();
      },
      (error) {
        debugPrint('Consent info: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() => ConsentForm.showPrivacyOptionsForm((e) {
    if (e != null) debugPrint('Privacy options: ${e.message}');
  });

  Duration get _backoff =>
      Duration(seconds: (2 << _retry.clamp(0, 5)).clamp(2, 64));

  void _loadInterstitial() {
    if (!_ready || adsRemoved || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: ids.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _retry = 0;
          ad.onPaidEvent = (ad, micros, precision, currency) =>
              _paid('interstitial', ad, micros, precision, currency);
          _interstitial = ad;
        },
        onAdFailedToLoad: (e) {
          analytics.adFailed('interstitial', e.message);
          Future.delayed(_backoff, _loadInterstitial);
          _retry++;
        },
      ),
    );
  }

  void _loadRewarded() {
    if (!_ready || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: ids.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _retry = 0;
          ad.onPaidEvent = (ad, micros, precision, currency) =>
              _paid('rewarded', ad, micros, precision, currency);
          _rewarded = ad;
        },
        onAdFailedToLoad: (e) {
          analytics.adFailed('rewarded', e.message);
          Future.delayed(_backoff, _loadRewarded);
          _retry++;
        },
      ),
    );
  }

  @override
  Future<void> onLevelCompleted(int level) async {
    if (!policy.onLevelCompleted(level, _clock())) return;
    final ad = _interstitial;
    if (adsRemoved || ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        policy.markShown(_clock());
        analytics.adShown('interstitial', 'level_complete');
      },
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        closed.complete();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        analytics.adFailed('interstitial', e.message);
        closed.complete();
        _loadInterstitial();
      },
    );
    await ad.show();
    return closed.future;
  }

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) =>
          analytics.adShown('rewarded', kind.name),
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!result.isCompleted) result.complete(earned);
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        analytics.adFailed('rewarded', e.message);
        if (!result.isCompleted) result.complete(false);
        _loadRewarded();
      },
    );
    await ad.show(
      onUserEarnedReward: (_, _) {
        earned = true;
        analytics.adReward(kind.name);
      },
    );
    return result.future;
  }

  @override
  Widget buildBanner() => _ready && !adsRemoved
      ? _AdaptiveBanner(
          unitId: ids.banner,
          onPaid: (ad, micros, precision, currency) =>
              _paid('banner', ad, micros, precision, currency),
        )
      : const SizedBox.shrink();
}

class _AdaptiveBanner extends StatefulWidget {
  const _AdaptiveBanner({required this.unitId, required this.onPaid});

  final String unitId;
  final OnPaidEventCallback onPaid;

  @override
  State<_AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<_AdaptiveBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _load(MediaQuery.sizeOf(context).width.truncate());
  }

  Future<void> _load(int width) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    final ad = BannerAd(
      adUnitId: widget.unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
        onPaidEvent: widget.onPaid,
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
