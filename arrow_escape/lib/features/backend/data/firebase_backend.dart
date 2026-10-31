import 'dart:async';

import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/features/ads/domain/interstitial_policy.dart';
import 'package:arrow_escape/features/backend/data/backend.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Starts Firebase from the native config files
/// (`android/app/src/<flavor>/google-services.json`,
/// `ios/Runner/GoogleService-Info.plist`). Returns false when they are
/// missing, and the app runs fully offline instead.
Future<bool> initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured, running offline: $e');
    return false;
  }
  // App Check: Play Integrity / App Attest in release, debug providers
  // (token registered in the console) in debug builds.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    crashlytics.recordFlutterFatalError(details);
    previous?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
  return true;
}

class FirebaseAuthService implements AuthService {
  @override
  Future<String?> signIn() async {
    final auth = FirebaseAuth.instance;
    try {
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
      final uid = user?.uid;
      if (uid != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(uid);
      }
      return uid;
    } on FirebaseAuthException catch (e) {
      debugPrint('Anonymous sign-in failed: ${e.code}');
      return null;
    }
  }
}

/// `users/{uid}` holds `{save: {...}, updatedAt}`. Security rules (see
/// firestore.rules) only let a user read and write their own document.
class FirestoreCloudSave implements CloudSaveService {
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  @override
  Future<SaveData?> fetch(String uid) async {
    try {
      final snap = await _doc(uid).get();
      final data = snap.data()?['save'];
      if (data is! Map) return null;
      return SaveData.fromJson(Map<String, Object?>.from(data));
    } catch (e) {
      debugPrint('Cloud save fetch failed: $e');
      return null;
    }
  }

  @override
  Future<void> push(String uid, SaveData save) async {
    try {
      await _doc(
        uid,
      ).set({'save': save.toJson(), 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Cloud save push failed: $e');
    }
  }
}

class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService._(this._rc);

  static const defaults = <String, Object>{
    'interstitial_min_level': 10,
    'interstitial_level_gap': 3,
    'interstitial_min_seconds': 180,
  };

  final FirebaseRemoteConfig _rc;

  static Future<FirebaseRemoteConfigService> create() async {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 5)
            : const Duration(hours: 6),
      ),
    );
    await rc.setDefaults(defaults);
    return FirebaseRemoteConfigService._(rc);
  }

  @override
  InterstitialConfig get interstitial => InterstitialConfig(
    minLevel: _rc.getInt('interstitial_min_level'),
    levelGap: _rc.getInt('interstitial_level_gap').clamp(1, 100),
    minInterval: Duration(
      seconds: _rc.getInt('interstitial_min_seconds').clamp(0, 3600),
    ),
  );

  @override
  Future<void> refresh() async {
    try {
      await _rc.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote config fetch failed: $e');
    }
  }
}

class FirebaseAnalyticsService extends AnalyticsService {
  final _fa = FirebaseAnalytics.instance;

  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) =>
      _fa.logEvent(name: name, parameters: params);

  @override
  Future<void> setUserId(String? id) => _fa.setUserId(id: id);

  @override
  Future<void> setUserProperty(String name, String? value) =>
      _fa.setUserProperty(name: name, value: value);

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _fa.setAnalyticsCollectionEnabled(enabled);

  /// Consent mode v2. Analytics storage stays granted (it is first-party
  /// and covered by the in-app toggle); the ad signals follow UMP.
  @override
  Future<void> setAdConsent({required bool granted}) => _fa.setConsent(
    analyticsStorageConsentGranted: true,
    adStorageConsentGranted: granted,
    adUserDataConsentGranted: granted,
    adPersonalizationSignalsConsentGranted: granted,
  );
}
