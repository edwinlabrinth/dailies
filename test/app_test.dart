import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailies/main.dart';
import 'package:dailies/widgets/habit_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the "new habit" dialog end to end.
Future<void> addHabit(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('add_habit_fab')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('habit-name-field')), name);
  await tester.tap(find.byKey(const Key('add-habit-confirm')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the empty state on a fresh install', (tester) async {
    await tester.pumpWidget(const DailiesApp());
    await tester.pumpAndSettle();

    expect(find.text('No habits yet'), findsOneWidget);
    expect(find.text('0 XP'), findsOneWidget);
    expect(find.byType(HabitTile), findsNothing);
  });

  testWidgets('creates a habit from the dialog', (tester) async {
    await tester.pumpWidget(const DailiesApp());
    await tester.pumpAndSettle();

    await addHabit(tester, 'Read 20 pages');

    expect(find.text('Read 20 pages'), findsOneWidget);
    expect(find.byType(HabitTile), findsOneWidget);
    expect(find.text('No habits yet'), findsNothing);
  });

  testWidgets('completing a habit earns XP and starts the streak',
      (tester) async {
    await tester.pumpWidget(const DailiesApp());
    await tester.pumpAndSettle();
    await addHabit(tester, 'Meditate');

    await tester.tap(find.byType(HabitTile).first);
    await tester.pumpAndSettle();

    expect(find.text('10 XP'), findsOneWidget);
    expect(find.text('1 completion'), findsOneWidget);
    expect(find.textContaining('1 day'), findsOneWidget);

    // Ticking again takes the XP back.
    await tester.tap(find.byType(HabitTile).first);
    await tester.pumpAndSettle();

    expect(find.text('0 XP'), findsOneWidget);
    expect(find.textContaining('1 day'), findsNothing);
  });

  testWidgets('habits survive a restart', (tester) async {
    await tester.pumpWidget(const DailiesApp());
    await tester.pumpAndSettle();
    await addHabit(tester, 'Meditate');
    await tester.tap(find.byType(HabitTile).first);
    await tester.pumpAndSettle();

    // Tear the app down and boot it again from persistence.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const DailiesApp());
    await tester.pumpAndSettle();

    expect(find.text('Meditate'), findsOneWidget);
    expect(find.text('10 XP'), findsOneWidget);
  });

  testWidgets('deletes a habit after long-press confirmation', (tester) async {
    await tester.pumpWidget(const DailiesApp());
    await tester.pumpAndSettle();
    await addHabit(tester, 'Junk food');

    await tester.longPress(find.byType(HabitTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Delete "Junk food"?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(find.byType(HabitTile), findsNothing);
    expect(find.text('No habits yet'), findsOneWidget);
  });

  testWidgets('loads previously saved habits on boot', (tester) async {
    SharedPreferences.setMockInitialValues({
      'dailies.habits.v1': jsonEncode([
        {
          'id': 'seeded',
          'name': 'Drink water',
          'icon': 4, // Icons.water_drop
          'color': 2,
          'done': <String>[],
        },
      ]),
    });

    await tester.pumpWidget(const DailiesApp());
    await tester.pumpAndSettle();

    expect(find.text('Drink water'), findsOneWidget);
  });
}
