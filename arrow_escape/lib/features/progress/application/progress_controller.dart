import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final progressProvider = NotifierProvider<ProgressController, Progress>(
  ProgressController.new,
);

class ProgressController extends Notifier<Progress> {
  @override
  Progress build() => const Progress();

  /// Records a win: keeps the best star rating and unlocks the next level.
  void completeLevel(int level, int stars) {
    final best = stars > state.starsFor(level) ? stars : state.starsFor(level);
    state = state.copyWith(
      stars: {...state.stars, level: best},
      unlocked: level + 1 > state.unlocked ? level + 1 : state.unlocked,
    );
  }
}
