import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/utils/clock.dart';
import 'package:arrow_escape/core/widgets/arrow_logo.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/progress/application/progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(progressProvider);
    final count = ref.watch(levelRepositoryProvider).count;
    final next = progress.unlocked.clamp(1, count);
    final today = DailyChallenge.keyFor(ref.watch(clockProvider)());
    final dailyDone = progress.dailyStarsFor(today) > 0;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(Routes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              const ArrowLogo(size: 136),
              const SizedBox(height: 24),
              Text('Arrow Escape', style: theme.textTheme.displaySmall),
              Text(
                'Traffic Puzzle',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: '${progress.totalStars} stars collected',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Palette.star),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.totalStars}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('play'),
                  onPressed: () => context.push(Routes.game(next)),
                  icon: const Icon(Icons.play_arrow_rounded, size: 30),
                  label: Text('Play  ·  Level $next'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('daily'),
                  onPressed: () => context.push(Routes.daily),
                  icon: Icon(
                    dailyDone
                        ? Icons.check_circle_rounded
                        : Icons.calendar_today_rounded,
                    color: dailyDone ? Palette.success : null,
                  ),
                  label: Text(
                    dailyDone ? 'Daily challenge done' : 'Daily challenge',
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
