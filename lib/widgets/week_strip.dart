import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme.dart';

/// A row of seven dots showing the last week of completions — oldest on the
/// left, today on the right inside a ring.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.habit, required this.today});

  final Habit habit;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = habit.lastSevenDays(today);
    final done = days.where((day) => day).length;
    final color = habitColor(habit.colorIndex);
    final outline = Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: 'Last 7 days: $done done',
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
              key: ValueKey('week-dot-$i'),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: days[i] ? color : outline.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: i == days.length - 1
                    ? Border.all(color: outline.withValues(alpha: 0.4))
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
