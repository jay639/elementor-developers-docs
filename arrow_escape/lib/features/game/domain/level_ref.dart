import 'package:freezed_annotation/freezed_annotation.dart';

part 'level_ref.freezed.dart';

/// Identifies what is being played. Used as the family key for the level
/// and game providers.
@freezed
sealed class LevelRef with _$LevelRef {
  const LevelRef._();

  /// Campaign level, numbered from 1.
  const factory LevelRef.campaign(int number) = CampaignLevelRef;

  /// Daily challenge for a `yyyy-mm-dd` local date.
  const factory LevelRef.daily(String dateKey) = DailyLevelRef;

  /// One layer (1-based) of a picture puzzle from the collection.
  const factory LevelRef.puzzle(String shape, int layer) = PuzzleLevelRef;

  bool get isDaily => this is DailyLevelRef;
}
