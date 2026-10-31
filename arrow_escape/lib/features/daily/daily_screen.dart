import 'dart:async';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/utils/clock.dart';
import 'package:arrow_escape/features/progress/application/progress_controller.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Today's challenge, how hard it is, this week at a glance and the time
/// until the next one.
class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  /// Label for a day's target difficulty (the daily only gets harder).
  static String difficultyLabel(DateTime day) =>
      switch (DailyChallenge.targetFor(day)) {
        < 78 => 'Hard',
        < 88 => 'Expert',
        _ => 'Master',
      };

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Refresh the countdown (and roll over at midnight).
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  static String _countdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final key = DailyChallenge.keyFor(today);
    final progress = ref.watch(progressProvider);
    final stars = progress.dailyStarsFor(key);
    final done = stars > 0;
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final weekdayNames = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Backdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Daily challenge')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      done ? Icons.emoji_events_rounded : Icons.today_rounded,
                      size: 56,
                      color: done ? Palette.star : scheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      MaterialLocalizations.of(context).formatFullDate(today),
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      avatar: const Icon(Icons.speed_rounded, size: 18),
                      label: Text(DailyScreen.difficultyLabel(today)),
                    ),
                    if (done) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        label: 'Completed with $stars of 3 stars',
                        excludeSemantics: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Icon(
                                i < stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: i < stars
                                    ? Palette.star
                                    : scheme.outlineVariant,
                                size: 32,
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    CandyButton(
                      key: const Key('play-daily'),
                      onPressed: () => context.push(Routes.dailyGame(key)),
                      icon: done
                          ? Icons.replay_rounded
                          : Icons.play_arrow_rounded,
                      label: done ? 'Play again' : 'Play today',
                      colors: const [Color(0xFFFFC94D), Color(0xFFFF8A3D)],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Next challenge in ${_countdown(tomorrow.difference(now))}',
                      key: const Key('daily-countdown'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('This week', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 6; i >= 0; i--)
                  _DayDot(
                    day: today.subtract(Duration(days: i)),
                    label:
                        weekdayNames[today.subtract(Duration(days: i)).weekday -
                            1],
                    isToday: i == 0,
                    stars: progress.dailyStarsFor(
                      DailyChallenge.keyFor(today.subtract(Duration(days: i))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Everyone gets the same puzzle each day. It is always tougher '
              'than the early campaign and gets a little harder every day, '
              'with an extra push at weekends.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.day,
    required this.label,
    required this.isToday,
    required this.stars,
  });

  final DateTime day;
  final String label;
  final bool isToday;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = stars > 0;
    return Semantics(
      label:
          '${MaterialLocalizations.of(context).formatMediumDate(day)}: '
          '${done ? 'completed' : 'not completed'}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isToday ? scheme.primary : null,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? Palette.success : scheme.surfaceContainerHighest,
              border: isToday
                  ? Border.all(color: scheme.primary, width: 2.5)
                  : null,
            ),
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}
