import 'package:flutter/material.dart';

/// Catalog of icons a habit can use.
///
/// Habits store the *index* into this list rather than a raw codepoint so
/// every [IconData] stays a compile-time constant — that keeps Flutter's
/// icon font tree-shaking (and therefore release builds) working.
const List<IconData> kHabitIcons = <IconData>[
  Icons.self_improvement,
  Icons.fitness_center,
  Icons.menu_book,
  Icons.directions_run,
  Icons.water_drop,
  Icons.bedtime,
  Icons.code,
  Icons.brush,
  Icons.savings,
  Icons.psychology,
  Icons.local_cafe,
  Icons.health_and_safety,
];

/// Resolves an icon index to its [IconData], wrapping out-of-range values.
IconData habitIconFor(int index) => kHabitIcons[index % kHabitIcons.length];
