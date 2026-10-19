import 'package:flutter_test/flutter_test.dart';
import 'package:dailies/models/habit.dart';

void main() {
  final today = DateTime(2026, 10, 19);
  final yesterday = DateTime(2026, 10, 18);
  final twoDaysAgo = DateTime(2026, 10, 17);

  Habit build({Set<String> done = const {}}) => Habit(
        id: 'h1',
        name: 'Read',
        iconIndex: 2, // Icons.menu_book
        doneDates: done,
      );

  group('dateKey', () {
    test('formats yyyy-MM-dd with zero padding', () {
      expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dateKey(DateTime(2026, 10, 19)), '2026-10-19');
    });
  });

  group('streakOn', () {
    test('is 0 with no completions', () {
      expect(build().streakOn(today), 0);
    });

    test('counts consecutive days ending today', () {
      final habit = build(done: {
        dateKey(today),
        dateKey(yesterday),
        dateKey(twoDaysAgo),
      });
      expect(habit.streakOn(today), 3);
    });

    test('survives until midnight when today is still pending', () {
      final habit = build(done: {dateKey(yesterday)});
      expect(habit.streakOn(today), 1);
    });

    test('breaks when there is a gap', () {
      final habit = build(done: {dateKey(twoDaysAgo)});
      expect(habit.streakOn(today), 0);
    });

    test('reset after today is un-ticked but yesterday still counts', () {
      final habit = build(done: {
        dateKey(today),
        dateKey(yesterday),
      }).markUndone(today);
      expect(habit.isDoneOn(today), isFalse);
      expect(habit.streakOn(today), 1);
    });
  });

  group('markDone / markUndone', () {
    test('markDone adds today exactly once', () {
      final habit = build().markDone(today).markDone(today);
      expect(habit.doneDates, {dateKey(today)});
    });

    test('markUndone removes the day', () {
      final habit = build(done: {dateKey(today)}).markUndone(today);
      expect(habit.doneDates, isEmpty);
    });
  });

  group('JSON', () {
    test('roundtrips through toJson/fromJson', () {
      final original = Habit(
        id: 'abc',
        name: 'Drink water',
        iconIndex: 4, // Icons.water_drop
        colorIndex: 5,
        doneDates: {dateKey(today), dateKey(yesterday)},
      );

      final restored = Habit.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.iconIndex, original.iconIndex);
      expect(restored.colorIndex, original.colorIndex);
      expect(restored.doneDates, original.doneDates);
    });

    test('tolerates missing optional fields', () {
      final habit = Habit.fromJson(const {
        'id': 'x',
        'name': 'Run',
      });
      expect(habit.iconIndex, 0);
      expect(habit.colorIndex, 0);
      expect(habit.doneDates, isEmpty);
    });
  });
}
