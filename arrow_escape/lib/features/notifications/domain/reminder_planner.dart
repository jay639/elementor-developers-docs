import 'package:flutter/foundation.dart';

/// One local notification to schedule.
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
  });

  final int id;

  /// Local wall-clock time.
  final DateTime at;
  final String title;
  final String body;

  /// Screen to open when tapped.
  final String route;

  @override
  String toString() => '#$id $at "$title"';
}

/// What the planner needs to know about the player.
@immutable
class ReminderState {
  const ReminderState({
    required this.now,
    required this.streak,
    required this.playedToday,
    required this.dailyDoneToday,
    required this.nextLevel,
  });

  final DateTime now;
  final int streak;
  final bool playedToday;
  final bool dailyDoneToday;
  final int nextLevel;
}

/// Decides the automatic reminders. All of them fire at 7:30 PM local time,
/// at most one a day:
///
/// - **Next evening slot** (today if it's before 7:30 PM and there's a
///   reason, else tomorrow): streak at risk → "your streak ends tonight";
///   otherwise "today's daily challenge is ready".
/// - **Comeback** 3 and 7 days from now, only reached if the player hasn't
///   opened the game since (every launch reschedules everything).
abstract final class ReminderPlanner {
  static const hour = 19;
  static const minute = 30;

  static const idEvening = 1;
  static const idComeback3 = 3;
  static const idComeback7 = 7;

  static DateTime _slot(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  static List<PlannedReminder> plan(ReminderState s) {
    final today = _slot(s.now);
    final beforeSlot = s.now.isBefore(today);
    final reasonToday = (s.streak > 0 && !s.playedToday) || !s.dailyDoneToday;
    final isToday = beforeSlot && reasonToday;
    final evening = isToday ? today : _slot(s.now.add(const Duration(days: 1)));

    final PlannedReminder eveningReminder;
    if (isToday && s.streak > 0 && !s.playedToday) {
      eveningReminder = PlannedReminder(
        id: idEvening,
        at: evening,
        title: '🔥 Your ${s.streak}-day streak ends tonight!',
        body: 'Play one level to keep it going.',
        route: '/home',
      );
    } else if (!isToday && s.streak > 0) {
      eveningReminder = PlannedReminder(
        id: idEvening,
        at: evening,
        title: '🔥 Keep your ${s.streak}-day streak alive',
        body: "Today's puzzles are waiting. One level is all it takes.",
        route: '/home',
      );
    } else {
      eveningReminder = PlannedReminder(
        id: idEvening,
        at: evening,
        title: "📅 Today's daily challenge is ready",
        body: 'A fresh puzzle for everyone. Can you clear it?',
        route: '/daily',
      );
    }

    return [
      eveningReminder,
      PlannedReminder(
        id: idComeback3,
        at: _slot(s.now.add(const Duration(days: 3))),
        title: '🧩 We miss you!',
        body: 'Level ${s.nextLevel} is waiting. Can you clear it?',
        route: '/home',
      ),
      PlannedReminder(
        id: idComeback7,
        at: _slot(s.now.add(const Duration(days: 7))),
        title: '🚗 The arrows are still stuck!',
        body: 'Come back for a quick puzzle and free them.',
        route: '/home',
      ),
    ];
  }
}
