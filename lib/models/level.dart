import 'habit.dart';

/// XP awarded every time any habit is ticked off.
const int xpPerCompletion = 10;

/// Total XP earned across every habit completion, ever.
int totalXp(Iterable<Habit> habits) =>
    habits.fold(0, (sum, habit) => sum + habit.doneDates.length * xpPerCompletion);

/// Cumulative XP required to *enter* [level].
///
/// Level 1 is free; reaching level 2 costs 100 XP, and every level after
/// that costs 50 XP more than the previous step (100, 150, 200, ...).
int xpToEnterLevel(int level) {
  var total = 0;
  for (var l = 2; l <= level; l++) {
    total += 100 + (l - 2) * 50;
  }
  return total;
}

/// The level a player currently holds for [xp].
int levelForXp(int xp) {
  var level = 1;
  while (xp >= xpToEnterLevel(level + 1)) {
    level++;
  }
  return level;
}

/// XP earned toward the current level (0 at level start).
int xpIntoLevel(int xp) => xp - xpToEnterLevel(levelForXp(xp));

/// XP still needed to reach the next level.
int xpToNextLevel(int xp) =>
    xpToEnterLevel(levelForXp(xp) + 1) - xpToEnterLevel(levelForXp(xp));

/// Progress through the current level, from 0.0 to 1.0.
double levelProgress(int xp) {
  final needed = xpToNextLevel(xp);
  if (needed == 0) return 1.0;
  return (xpIntoLevel(xp) / needed).clamp(0.0, 1.0);
}
