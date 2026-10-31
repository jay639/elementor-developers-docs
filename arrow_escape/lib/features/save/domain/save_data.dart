import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:arrow_escape/features/settings/domain/app_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_data.freezed.dart';
part 'save_data.g.dart';

/// Everything the player owns, in one document. Stored locally (encrypted,
/// HMAC-signed) and synced to Firestore.
@freezed
abstract class SaveData with _$SaveData {
  const SaveData._();

  const factory SaveData({
    @Default(Progress()) Progress progress,
    @Default(0) int coins,
    @Default(<String>['classic']) List<String> ownedSkins,
    @Default('classic') String selectedSkin,

    /// Consecutive days with at least one win.
    @Default(0) int streak,

    /// `yyyy-mm-dd` of the last day with a win.
    String? lastWinDay,

    /// Consecutive days the daily reward was claimed (drives the amount).
    @Default(0) int rewardStreak,

    /// `yyyy-mm-dd` of the last daily-reward claim.
    String? lastRewardDay,
    @Default(AppSettings()) AppSettings settings,

    /// Non-consumable bundles whose one-time perks (coins, skin) were
    /// granted, so restores on a new device don't grant them twice.
    @Default(<String>[]) List<String> claimedBundles,

    /// One-time tips already shown (tutorial, pinch hint, mechanic intros).
    @Default(<String>[]) List<String> seenTips,

    /// Set once this install's save has been merged with the cloud copy.
    @Default(false) bool cloudSynced,

    /// Bumped on every change; used when merging with the cloud copy.
    @Default(0) int revision,

    /// Milliseconds since epoch of the last change.
    @Default(0) int updatedAt,
  }) = _SaveData;

  factory SaveData.fromJson(Map<String, Object?> json) =>
      _$SaveDataFromJson(json);

  bool owns(String skin) => ownedSkins.contains(skin);

  bool hasSeen(String tip) => seenTips.contains(tip);
}
