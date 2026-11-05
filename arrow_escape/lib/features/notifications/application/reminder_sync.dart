import 'dart:async';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/core/utils/clock.dart';
import 'package:arrow_escape/features/notifications/data/notification_service.dart';
import 'package:arrow_escape/features/notifications/domain/reminder_planner.dart';
import 'package:arrow_escape/features/onboarding/tips.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:arrow_escape/features/splash/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps the 7:30 PM reminders in step with the save, asks for the
/// notification permission once (after level 3), honours the Settings
/// switch and opens the right screen when a notification is tapped.
class ReminderSync {
  ReminderSync(this._container);

  final ProviderContainer _container;

  /// The permission is asked once the player has cleared this many levels
  /// (they've seen the game is worth coming back to).
  static const askAfterLevel = 3;

  NotificationService get _service =>
      _container.read(notificationServiceProvider);

  Future<void> start() async {
    _service.opened.listen(_open);
    final launch = await _service.launchRoute();
    if (launch != null) {
      // Let the splash finish and land on home first.
      Timer(SplashScreen.duration + const Duration(milliseconds: 400), () {
        _open(launch);
      });
    }

    _container.listen<bool>(
      settingsProvider.select((s) => s.reminders),
      (prev, on) => unawaited(on ? _enable() : _service.disable()),
    );
    _container.listen<int>(
      saveProvider.select((s) => s.progress.unlocked),
      (prev, unlocked) => _maybeAskPermission(unlocked),
    );
    _maybeAskPermission(_container.read(saveProvider).progress.unlocked);
    await reschedule();
  }

  Future<void> _enable() async {
    await _service.enable();
    await reschedule();
  }

  void _maybeAskPermission(int unlocked) {
    final save = _container.read(saveProvider);
    if (unlocked <= askAfterLevel || save.hasSeen(Tips.notifications)) return;
    if (!save.settings.reminders) return;
    _container.read(saveProvider.notifier).markSeen(Tips.notifications);
    unawaited(() async {
      final ok = await _service.requestPermission();
      unawaited(
        _container.read(analyticsProvider).log('notification_permission', {
          'granted': ok ? 1 : 0,
        }),
      );
      if (ok) await reschedule();
    }());
  }

  /// Plans and schedules the reminders from the current save. Called at
  /// start and whenever the app goes to the background.
  Future<void> reschedule() async {
    final save = _container.read(saveProvider);
    if (!save.settings.reminders) return;
    final now = _container.read(clockProvider)();
    final today = DailyChallenge.keyFor(now);
    final yesterday = DailyChallenge.keyFor(
      now.subtract(const Duration(days: 1)),
    );
    // A streak only counts while it's alive (a win today or yesterday).
    final alive = save.lastWinDay == today || save.lastWinDay == yesterday;
    try {
      await _service.schedule(
        ReminderPlanner.plan(
          ReminderState(
            now: now,
            streak: alive ? save.streak : 0,
            playedToday: save.lastWinDay == today,
            dailyDoneToday: save.progress.dailyStarsFor(today) > 0,
            nextLevel: save.progress.unlocked,
          ),
        ),
      );
    } on Object catch (e) {
      debugPrint('Reminders not scheduled: $e');
    }
  }

  void _open(String route) {
    unawaited(
      _container.read(analyticsProvider).log('notification_open', {
        'route': route,
      }),
    );
    final router = _container.read(routerProvider);
    router.go(Routes.home);
    if (route != Routes.home) router.push(route);
  }
}
