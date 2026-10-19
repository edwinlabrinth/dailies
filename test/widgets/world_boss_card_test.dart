import 'package:dailies/data/demo_habits.dart';
import 'package:dailies/models/online.dart';
import 'package:dailies/widgets/world_boss_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the boss card shows damage, percentage and time left',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: WorldBossCard(world: demoWorld())),
      ),
    );

    expect(find.text('The Procrastination Hydra'), findsOneWidget);
    expect(find.text('WORLD BOSS · 4d LEFT'), findsOneWidget);
    expect(find.text('43%'), findsOneWidget);
    expect(find.text('1.2k / 2.8k damage'), findsOneWidget);
    expect(find.text('1.6k HP left'), findsOneWidget);
    expect(find.textContaining('6-day guild streak'), findsOneWidget);
    expect(find.textContaining('4 in the guild'), findsOneWidget);
  });

  testWidgets('a defeated boss celebrates', (tester) async {
    const world = WorldState(
      weekStart: '2026-10-19',
      boss: BossState(
        name: 'The Snooze Golem',
        emoji: '🗿',
        hpMax: 1400,
        damage: 1600,
        remaining: 0,
        percent: 100,
        defeated: true,
        endsInDays: 2,
      ),
      guild: GuildStats(
        players: 2,
        weeklyCompletions: 160,
        weeklyXp: 1600,
        todayCompletions: 12,
        todayXp: 120,
        streakDays: 9,
        totalCompletions: 900,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: WorldBossCard(world: world, compact: true)),
      ),
    );

    expect(find.text('WORLD BOSS · DEFEATED'), findsOneWidget);
    expect(find.text('the guild wins this week'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });
}
