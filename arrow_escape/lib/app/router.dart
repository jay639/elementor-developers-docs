import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/daily/daily_screen.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/game/presentation/game_screen.dart';
import 'package:arrow_escape/features/home/home_screen.dart';
import 'package:arrow_escape/features/settings/presentation/settings_screen.dart';
import 'package:arrow_escape/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/game/:level',
        pageBuilder: (context, state) {
          final level = int.tryParse(state.pathParameters['level'] ?? '');
          return MaterialPage(
            key: state.pageKey,
            child: level == null || level < 1
                ? const HomeScreen()
                : GameScreen(levelRef: LevelRef.campaign(level)),
          );
        },
      ),
      GoRoute(
        path: Routes.daily,
        builder: (context, state) => const DailyScreen(),
        routes: [
          GoRoute(
            path: ':date',
            pageBuilder: (context, state) {
              final key = state.pathParameters['date'] ?? '';
              final valid = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key);
              return MaterialPage(
                key: state.pageKey,
                child: valid
                    ? GameScreen(levelRef: LevelRef.daily(key))
                    : const DailyScreen(),
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );
  ref.onDispose(router.dispose);
  return router;
});
