import 'package:flutter/material.dart';

import '../models/level.dart';

/// Big card at the top of the screen showing the player's level, XP bar and
/// progress toward the next level.
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    final level = levelForXp(xp);
    final progress = levelProgress(xp);
    final into = xpIntoLevel(xp);
    final needed = xpToNextLevel(xp);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                  ),
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEVEL $level',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: const Color(0xFF2C2A3A),
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$into / $needed XP to level ${level + 1}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatChip(icon: Icons.bolt, label: '$xp XP'),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.trending_up,
                  label: totalCompletions(xp) == 1
                      ? '1 completion'
                      : '${totalCompletions(xp)} completions',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

int totalCompletions(int xp) => xp ~/ xpPerCompletion;

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2A3A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: style?.color),
          const SizedBox(width: 6),
          Text(label, style: style),
        ],
      ),
    );
  }
}
