import '../models/habit.dart';
import '../models/online.dart';

/// Sample habits used by demo mode — `?demo` in the URL on the web build —
/// so the app can be shown off (or screenshotted) without typing anything in.
///
/// The numbers are tuned to look good on screen: 5 habits, 3 of them already
/// ticked today, a 5-day best streak and 110 XP, which lands you mid-level 2.
List<Habit> demoHabits({DateTime? today}) {
  final now = today ?? DateTime.now();
  DateTime daysAgo(int days) => now.subtract(Duration(days: days));

  Set<String> everyDaySince(int days) => {
        for (var i = 0; i <= days; i++) dateKey(daysAgo(i)),
      };

  return [
    Habit(
      id: 'demo-run',
      name: 'Morning run',
      iconIndex: 3, // directions_run
      colorIndex: 4,
      doneDates: everyDaySince(4),
    ),
    Habit(
      id: 'demo-read',
      name: 'Read 20 pages',
      iconIndex: 2, // menu_book
      colorIndex: 1,
      doneDates: everyDaySince(2),
    ),
    Habit(
      id: 'demo-water',
      name: 'Drink 2L of water',
      iconIndex: 4, // water_drop
      colorIndex: 6,
      doneDates: everyDaySince(1),
    ),
    Habit(
      id: 'demo-meditate',
      name: 'Meditate 10 min',
      iconIndex: 0, // self_improvement
      colorIndex: 5,
      doneDates: {dateKey(daysAgo(1))},
    ),
    Habit(
      id: 'demo-ship',
      name: 'Ship something',
      iconIndex: 6, // code
      colorIndex: 3,
    ),
  ];
}

/// A sample world state so the demo build shows off the guild features too.
WorldState demoWorld({DateTime? today}) {
  final now = today ?? DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return WorldState(
    weekStart: dateKey(monday),
    boss: const BossState(
      name: 'The Procrastination Hydra',
      emoji: '🐉',
      hpMax: 2800,
      damage: 1190,
      remaining: 1610,
      percent: 43,
      defeated: false,
      endsInDays: 4,
    ),
    guild: const GuildStats(
      players: 4,
      weeklyCompletions: 119,
      weeklyXp: 1190,
      todayCompletions: 7,
      todayXp: 70,
      streakDays: 6,
      totalCompletions: 842,
    ),
  );
}
