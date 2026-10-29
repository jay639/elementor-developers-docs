import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress.freezed.dart';
part 'progress.g.dart';

/// Campaign progress. Persisted (and HMAC-signed) from phase 3 on.
@freezed
abstract class Progress with _$Progress {
  const Progress._();

  const factory Progress({
    /// Highest level the player may open (1-based).
    @Default(1) int unlocked,

    /// Best star rating per completed level, keyed by level number.
    @Default(<int, int>{}) Map<int, int> stars,

    /// Best stars per completed daily challenge, keyed by `yyyy-mm-dd`.
    @Default(<String, int>{}) Map<String, int> dailyStars,
  }) = _Progress;

  factory Progress.fromJson(Map<String, Object?> json) =>
      _$ProgressFromJson(json);

  int starsFor(int level) => stars[level] ?? 0;

  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  int dailyStarsFor(String dateKey) => dailyStars[dateKey] ?? 0;
}
