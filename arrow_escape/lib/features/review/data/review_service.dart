import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

/// Store rating: the native in-app review sheet (Google Play In-App
/// Review / iOS SKStoreReviewController) and the store listing page.
abstract interface class ReviewService {
  /// Shows the native rating sheet if the platform allows it right now
  /// (the OS may silently decide not to).
  Future<void> requestReview();

  /// Opens the store page (the "Rate us" row in Settings).
  Future<void> openStoreListing();
}

class StoreReviewService implements ReviewService {
  StoreReviewService({this.appStoreId});

  /// iOS App Store id, only needed to open the listing on iOS.
  final String? appStoreId;

  final _review = InAppReview.instance;

  @override
  Future<void> requestReview() async {
    try {
      if (await _review.isAvailable()) await _review.requestReview();
    } on Object {
      // Never let a rating prompt break the game.
    }
  }

  @override
  Future<void> openStoreListing() async {
    try {
      await _review.openStoreListing(appStoreId: appStoreId);
    } on Object {
      // No store on this device (emulator, sideload).
    }
  }
}

/// iOS App Store id from `--dart-define=APP_STORE_ID=...` (not a secret,
/// but it only exists once the app is created in App Store Connect).
const _appStoreId = String.fromEnvironment('APP_STORE_ID');

final reviewServiceProvider = Provider<ReviewService>(
  (ref) =>
      StoreReviewService(appStoreId: _appStoreId.isEmpty ? null : _appStoreId),
);
