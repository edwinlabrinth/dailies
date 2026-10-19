import 'package:flutter_test/flutter_test.dart';
import 'package:pro/models/habit.dart';
import 'package:pro/models/level.dart';

void main() {
  group('xpToEnterLevel', () {
    test('level 1 is free, steps grow by 50', () {
      expect(xpToEnterLevel(1), 0);
      expect(xpToEnterLevel(2), 100);
      expect(xpToEnterLevel(3), 250); // 100 + 150
      expect(xpToEnterLevel(4), 450); // 100 + 150 + 200
    });
  });

  group('levelForXp', () {
    test('boundaries', () {
      expect(levelForXp(0), 1);
      expect(levelForXp(99), 1);
      expect(levelForXp(100), 2);
      expect(levelForXp(249), 2);
      expect(levelForXp(250), 3);
      expect(levelForXp(450), 4);
    });
  });

  group('level progress', () {
    test('xpIntoLevel and xpToNextLevel around a boundary', () {
      expect(xpIntoLevel(0), 0);
      expect(xpToNextLevel(0), 100);

      expect(xpIntoLevel(100), 0); // just crossed into level 2
      expect(xpToNextLevel(100), 150);

      expect(xpIntoLevel(150), 50);
      expect(xpToNextLevel(150), 150);
    });

    test('levelProgress spans 0..1 within a level', () {
      expect(levelProgress(0), 0.0);
      expect(levelProgress(50), 0.5);
      expect(levelProgress(99), closeTo(0.99, 0.001));
      // Crossing the boundary starts the new level fresh.
      expect(levelProgress(100), 0.0);
    });
  });

  group('totalXp', () {
    test('sums 10 XP per completion across habits', () {
      final habits = [
        Habit(
          id: 'a',
          name: 'Read',
          iconIndex: 2,
          doneDates: {
            '2026-10-17',
            '2026-10-18',
            '2026-10-19',
          },
        ),
        Habit(
          id: 'b',
          name: 'Run',
          iconIndex: 3,
          doneDates: {'2026-10-19'},
        ),
        Habit(id: 'c', name: 'New', iconIndex: 4),
      ];
      expect(totalXp(habits), 40);
    });

    test('no habits means no XP', () {
      expect(totalXp(const []), 0);
    });
  });
}
