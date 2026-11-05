import 'package:arrow_escape/features/notifications/domain/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReminderState at(
    DateTime now, {
    int streak = 0,
    bool played = false,
    bool daily = false,
  }) => ReminderState(
    now: now,
    streak: streak,
    playedToday: played,
    dailyDoneToday: daily,
    nextLevel: 12,
  );

  test('everything fires at 7:30 PM local time', () {
    final plan = ReminderPlanner.plan(at(DateTime(2026, 11, 5, 10)));
    for (final r in plan) {
      expect((r.at.hour, r.at.minute), (19, 30));
    }
    expect(plan.map((r) => r.id), [1, 3, 7]);
  });

  test('streak at risk: tonight\'s reminder saves it', () {
    final r = ReminderPlanner.plan(
      at(DateTime(2026, 11, 5, 10), streak: 4),
    ).first;
    expect(r.at, DateTime(2026, 11, 5, 19, 30));
    expect(r.title, contains('4-day streak ends tonight'));
  });

  test('daily not done yet: tonight it is the daily challenge', () {
    final r = ReminderPlanner.plan(at(DateTime(2026, 11, 5, 10))).first;
    expect(r.at, DateTime(2026, 11, 5, 19, 30));
    expect(r.route, '/daily');
  });

  test('played and daily done: nothing tonight, next one tomorrow', () {
    final r = ReminderPlanner.plan(
      at(DateTime(2026, 11, 5, 10), streak: 2, played: true, daily: true),
    ).first;
    expect(r.at, DateTime(2026, 11, 6, 19, 30));
    expect(r.title, contains('2-day streak'));
  });

  test('after 7:30 PM the next reminder is tomorrow', () {
    final r = ReminderPlanner.plan(at(DateTime(2026, 11, 5, 21))).first;
    expect(r.at, DateTime(2026, 11, 6, 19, 30));
  });

  test('comeback reminders 3 and 7 days out', () {
    final plan = ReminderPlanner.plan(at(DateTime(2026, 11, 5, 10)));
    expect(plan[1].at, DateTime(2026, 11, 8, 19, 30));
    expect(plan[1].body, contains('Level 12'));
    expect(plan[2].at, DateTime(2026, 11, 12, 19, 30));
  });
}
