import 'package:dailies/data/demo_habits.dart';
import 'package:dailies/models/habit.dart';
import 'package:dailies/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 19);

  test('seeds a showcase-ready set of habits', () {
    final habits = demoHabits(today: today);

    expect(habits, hasLength(5));
    expect(habits.where((h) => h.isDoneOn(today)), hasLength(3));
    expect(habits.first.streakOn(today), 5);
    // 110 XP puts the demo player just inside level 2.
    expect(totalXp(habits), 110);
    expect(levelForXp(totalXp(habits)), 2);
  });

  test('never contains future completions', () {
    final todayKey = dateKey(today);
    for (final habit in demoHabits(today: today)) {
      for (final day in habit.doneDates) {
        expect(day.compareTo(todayKey) <= 0, isTrue,
            reason: '$day is in the future');
      }
    }
  });
}
