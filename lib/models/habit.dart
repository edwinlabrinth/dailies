import 'package:flutter/material.dart';

import 'habit_icons.dart';

/// Canonical `yyyy-MM-dd` key for a local calendar date.
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// A single habit the user is leveling up with.
class Habit {
  const Habit({
    required this.id,
    required this.name,
    this.iconIndex = 0,
    this.colorIndex = 0,
    this.doneDates = const {},
  });

  final String id;
  final String name;

  /// Index into [kHabitIcons] — see that list for why we don't store a
  /// raw codepoint.
  final int iconIndex;
  final int colorIndex;

  /// Days (as `yyyy-MM-dd` keys) on which the habit was completed.
  final Set<String> doneDates;

  IconData get icon => habitIconFor(iconIndex);

  bool isDoneOn(DateTime date) => doneDates.contains(dateKey(date));

  /// Number of consecutive days ending [today] (or yesterday, if today is
  /// still pending) on which the habit was completed. Returns 0 when the
  /// chain is broken.
  int streakOn(DateTime today) {
    if (doneDates.isEmpty) return 0;
    var day = today;
    if (!isDoneOn(day)) {
      // Today is still in progress — the streak survives until midnight.
      day = day.subtract(const Duration(days: 1));
      if (!isDoneOn(day)) return 0;
    }
    var streak = 0;
    while (isDoneOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Habit markDone(DateTime date) => copyWith(doneDates: {...doneDates, dateKey(date)});

  Habit markUndone(DateTime date) => copyWith(
      doneDates: {...doneDates}..remove(dateKey(date)));

  Habit copyWith({
    String? name,
    int? colorIndex,
    Set<String>? doneDates,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      iconIndex: iconIndex,
      colorIndex: colorIndex ?? this.colorIndex,
      doneDates: doneDates ?? this.doneDates,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': iconIndex,
        'color': colorIndex,
        'done': doneDates.toList()..sort(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final done = <String>{
      for (final day in (json['done'] as List<dynamic>? ?? const []))
        day as String,
    };
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      iconIndex: json['icon'] as int? ?? 0,
      colorIndex: json['color'] as int? ?? 0,
      doneDates: done,
    );
  }
}
