import 'package:flutter/material.dart';

/// Seed color for the app's Material 3 color scheme.
const Color kSeedColor = Color(0xFF7C6CFF);

/// Deep background used behind everything.
const Color kBackgroundColor = Color(0xFF121118);

/// Surface color for cards.
const Color kCardColor = Color(0xFF1C1B26);

/// Palette habits rotate through for their icon chips.
const List<Color> kHabitColors = <Color>[
  Color(0xFFFFB74D), // amber
  Color(0xFF4FC3F7), // light blue
  Color(0xFF81C784), // green
  Color(0xFFFF8A65), // deep orange
  Color(0xFFBA68C8), // purple
  Color(0xFFE57373), // red
  Color(0xFF4DD0E1), // cyan
  Color(0xFFAED581), // light green
];

Color habitColor(int index) => kHabitColors[index % kHabitColors.length];

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackgroundColor,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: kCardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF262433),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}
