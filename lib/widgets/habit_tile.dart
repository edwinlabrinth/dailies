import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme.dart';

/// One habit row: icon chip, name, live streak and a today-or-not indicator.
///
/// Tap the tile to toggle today. Long-press to delete.
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.today,
    required this.onToggle,
    required this.onDelete,
  });

  final Habit habit;
  final DateTime today;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = habit.isDoneOn(today);
    final streak = habit.streakOn(today);
    final scheme = Theme.of(context).colorScheme;
    final color = habitColor(habit.colorIndex);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        key: ValueKey('habit-${habit.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: onToggle,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(habit.icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            decorationColor:
                                scheme.onSurface.withValues(alpha: 0.45),
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      streak > 0
                          ? '\u{1F525} $streak day${streak == 1 ? '' : 's'}'
                          : 'Tap to start a streak',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: streak > 0
                                ? const Color(0xFFFFB74D)
                                : scheme.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? const Color(0xFF66BB6A) : Colors.transparent,
                  border: done
                      ? null
                      : Border.all(
                          color: scheme.onSurface.withValues(alpha: 0.3),
                        ),
                ),
                child: Icon(
                  done ? Icons.check : Icons.add,
                  size: 22,
                  color: done ? Colors.white : scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
