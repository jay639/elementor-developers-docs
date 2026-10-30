import 'package:arrow_escape/features/ads/domain/interstitial_policy.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signed-in player identity (Firebase anonymous auth).
abstract interface class AuthService {
  /// Signs in anonymously if needed; returns the uid, or null offline.
  Future<String?> signIn();
}

/// The player's save in the cloud (one Firestore document per user).
abstract interface class CloudSaveService {
  Future<SaveData?> fetch(String uid);
  Future<void> push(String uid, SaveData save);
}

/// Server-tunable values.
abstract interface class RemoteConfigService {
  InterstitialConfig get interstitial;

  /// Fetches new values in the background.
  Future<void> refresh();
}

class OfflineAuth implements AuthService {
  @override
  Future<String?> signIn() async => null;
}

class OfflineCloudSave implements CloudSaveService {
  @override
  Future<SaveData?> fetch(String uid) async => null;

  @override
  Future<void> push(String uid, SaveData save) async {}
}

class DefaultRemoteConfig implements RemoteConfigService {
  const DefaultRemoteConfig([this.interstitial = const InterstitialConfig()]);

  @override
  final InterstitialConfig interstitial;

  @override
  Future<void> refresh() async {}
}

/// Overridden in bootstrap when Firebase is configured.
final authServiceProvider = Provider<AuthService>((ref) => OfflineAuth());
final cloudSaveProvider = Provider<CloudSaveService>(
  (ref) => OfflineCloudSave(),
);
final remoteConfigProvider = Provider<RemoteConfigService>(
  (ref) => const DefaultRemoteConfig(),
);
