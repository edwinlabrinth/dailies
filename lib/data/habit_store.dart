import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

/// Persists habits locally with `shared_preferences` so progress survives
/// restarts — fully offline, no accounts, no servers.
class HabitStore {
  static const String _key = 'pro.habits.v1';

  Future<List<Habit>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => Habit.fromJson(entry as Map<String, dynamic>))
          .toList();
    } on FormatException {
      // Corrupt payload — start fresh rather than crash.
      return const [];
    }
  }

  Future<void> save(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(habits.map((habit) => habit.toJson()).toList());
    await prefs.setString(_key, payload);
  }
}
