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

  testWidgets('demo mode seeds sample habits', (tester) async {
    await tester.pumpWidget(const DailiesApp(demoMode: true));
    await tester.pumpAndSettle();

    expect(find.text('Morning run'), findsOneWidget);
    expect(find.text('110 XP'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);

    // The last demo habit sits below the fold in the test viewport.
    await tester.scrollUntilVisible(find.text('Ship something'), 200);
    expect(find.text('Ship something'), findsOneWidget);
  });

  testWidgets('demo mode never writes to storage', (tester) async {
    await tester.pumpWidget(const DailiesApp(demoMode: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HabitTile).last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dailies.habits.v1'), isNull);
  });

  testWidgets('the week strip tracks the last seven days', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const DailiesApp());
    await tester.pumpAndSettle();
    await addHabit(tester, 'Meditate');

    expect(find.byKey(const ValueKey('week-dot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('week-dot-6')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Last 7 days: 0 done')),
      findsOneWidget,
    );

    await tester.tap(find.byType(HabitTile).first);
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('Last 7 days: 1 done')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
