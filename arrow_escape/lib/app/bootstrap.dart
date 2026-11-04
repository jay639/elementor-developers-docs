import 'dart:async';

import 'package:arrow_escape/core/services/meta_events.dart';
import 'package:arrow_escape/features/game/data/resume_store.dart';
import 'package:arrow_escape/app/app.dart';
import 'package:arrow_escape/app/flavor.dart';
import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/ads/data/admob_ad_service.dart';
import 'package:arrow_escape/features/ads/domain/ad_unit_ids.dart';
import 'package:arrow_escape/features/ads/domain/interstitial_policy.dart';
import 'package:arrow_escape/features/backend/application/analytics_sync.dart';
import 'package:arrow_escape/features/backend/application/cloud_sync.dart';
import 'package:arrow_escape/features/backend/data/backend.dart';
import 'package:arrow_escape/features/backend/data/firebase_backend.dart';
import 'package:arrow_escape/features/purchases/application/entitlements.dart';
import 'package:arrow_escape/features/purchases/data/purchase_service.dart';
import 'package:arrow_escape/features/purchases/data/revenuecat_purchase_service.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/data/save_repository.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared start-up for every flavor. Everything optional (Firebase, ads,
/// store) degrades to an offline implementation when it isn't configured,
/// so a fresh checkout runs without any keys.
Future<void> bootstrap(FlavorConfig flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  final firebase = await initFirebase();
  final AnalyticsService analytics = MetaForwardingAnalytics(
    firebase ? FirebaseAnalyticsService() : DebugAnalytics(),
    FacebookMetaEvents(),
  );
  RemoteConfigService remoteConfig = const DefaultRemoteConfig();
  if (firebase) {
    try {
      remoteConfig = await FirebaseRemoteConfigService.create();
    } catch (e) {
      debugPrint('Remote Config unavailable, using defaults: $e');
    }
  }
  unawaited(remoteConfig.refresh());

  SaveRepository repository;
  LoadedSave loaded;
  try {
    repository = await HiveSaveRepository.open();
    loaded = await repository.load();
  } catch (e) {
    debugPrint('Local save unavailable, using memory: $e');
    repository = InMemorySaveRepository();
    loaded = const LoadedSave(SaveData());
  }
  ResumeStore resume;
  try {
    resume = await HiveResumeStore.open();
  } catch (e) {
    debugPrint('Resume store unavailable, using memory: $e');
    resume = InMemoryResumeStore();
  }
  if (loaded.tampered) unawaited(analytics.log('save_tamper'));

  final adIds = AdUnitIds.forPlatform(useTestAds: flavor.isDev);
  final AdService ads = adIds == null
      ? NoAdService()
      : AdMobAdService(
          ids: adIds,
          policy: InterstitialPolicy(() => remoteConfig.interstitial),
          analytics: analytics,
        );
  final rcKey = RevenueCatPurchaseService.keyForPlatform();
  final PurchaseService purchases = rcKey.isEmpty
      ? UnavailablePurchaseService()
      : RevenueCatPurchaseService(rcKey);

  final container = ProviderContainer(
    overrides: [
      flavorProvider.overrideWithValue(flavor),
      analyticsProvider.overrideWithValue(analytics),
      remoteConfigProvider.overrideWithValue(remoteConfig),
      saveRepositoryProvider.overrideWithValue(repository),
      initialSaveProvider.overrideWithValue(loaded),
      resumeStoreProvider.overrideWithValue(resume),
      adServiceProvider.overrideWithValue(ads),
      purchaseServiceProvider.overrideWithValue(purchases),
      if (firebase) ...[
        authServiceProvider.overrideWithValue(FirebaseAuthService()),
        cloudSaveProvider.overrideWithValue(FirestoreCloudSave()),
      ],
    ],
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ArrowEscapeApp(),
    ),
  );
  // Before anything else is logged, so an opt-out applies from the start.
  AnalyticsSync(container).start();
  unawaited(_startServices(container));
}

/// Network-bound start-up that must not delay the first frame.
Future<void> _startServices(ProviderContainer container) async {
  final purchases = container.read(purchaseServiceProvider);
  try {
    await purchases.initialize();
  } catch (e) {
    debugPrint('Store init failed: $e');
  }
  // Starts listening for entitlement changes (and syncs ads).
  container.read(entitlementsProvider);

  try {
    // Shows the GDPR form / ATT prompt when needed, then loads ads.
    await container.read(adServiceProvider).initialize();
  } catch (e) {
    debugPrint('Ads init failed: $e');
  }

  final uid = await container.read(authServiceProvider).signIn();
  CloudSync? sync;
  if (uid != null) {
    await container.read(analyticsProvider).setUserId(uid);
    await purchases.identify(uid);
    sync = CloudSync(
      uid: uid,
      cloud: container.read(cloudSaveProvider),
      controller: container.read(saveProvider.notifier),
    );
    await sync.start();
  }

  AppLifecycleListener(
    onPause: () {
      unawaited(sync?.flush());
      unawaited(container.read(saveProvider.notifier).flush());
    },
  );
}
