import 'package:dailies/models/online.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/online_fixtures.dart';

void main() {
  test('the boss bar is clamped between 0 and 1', () {
    const half = BossState(
      name: 'Boss',
      emoji: '🐉',
      hpMax: 2000,
      damage: 500,
      remaining: 1500,
      percent: 25,
      defeated: false,
      endsInDays: 3,
    );
    expect(half.fraction, 0.25);

    const overshot = BossState(
      name: 'Boss',
      emoji: '🐉',
      hpMax: 2000,
      damage: 5000,
      remaining: 0,
      percent: 100,
      defeated: true,
      endsInDays: 3,
    );
    expect(overshot.fraction, 1.0);

    const empty = BossState(
      name: 'Boss',
      emoji: '🐉',
      hpMax: 0,
      damage: 0,
      remaining: 0,
      percent: 0,
      defeated: false,
      endsInDays: 0,
    );
    expect(empty.fraction, 0);
  });

  test('a leaderboard payload parses into world and leaders', () {
    final snapshot = GuildSnapshot.fromJson(leaderboardJson());

    expect(snapshot.world.boss.name, 'The Procrastination Hydra');
    expect(snapshot.world.boss.emoji, '🐉');
    expect(snapshot.world.boss.percent, 43);
    expect(snapshot.world.guild.players, 4);
    expect(snapshot.world.guild.streakDays, 6);
    expect(snapshot.leaders, hasLength(2));
    expect(snapshot.leaders.first.name, 'Night Owl');
    expect(snapshot.leaders.first.weeklyXp, 120);
    expect(snapshot.leaders.first.lastSeenAt, isNotNull);
  });

  test('a sync snapshot tolerates a minimal payload', () {
    final snapshot = SyncSnapshot.fromJson(<String, dynamic>{
      'stats': <String, dynamic>{'totalXp': 20, 'weeklyXp': 10, 'streak': 2},
    });

    expect(snapshot.player, isNull);
    expect(snapshot.habits, isEmpty);
    expect(snapshot.stats.totalXp, 20);
    expect(snapshot.stats.streak, 2);
    expect(snapshot.world, isNull);
  });

  test('habits come back from the server with their completion days', () {
    final snapshot = SyncSnapshot.fromJson(<String, dynamic>{
      'player': <String, dynamic>{'id': 'p1', 'name': 'Night Owl'},
      'stats': <String, dynamic>{'totalXp': 30, 'weeklyXp': 20, 'streak': 3},
      'habits': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'habit-1',
          'name': 'Morning run',
          'icon': 3,
          'color': 4,
          'done': <String>['2026-10-18', '2026-10-19'],
        },
      ],
      'world': worldJson,
    });

    expect(snapshot.player?.name, 'Night Owl');
    expect(snapshot.habits, hasLength(1));
    expect(snapshot.habits.first.name, 'Morning run');
    expect(snapshot.habits.first.iconIndex, 3);
    expect(snapshot.habits.first.doneDates, {'2026-10-18', '2026-10-19'});
    expect(snapshot.world?.boss.hpMax, 2800);
  });

  test('register responses carry the token, code and identity', () {
    final result = AuthResult.fromJson(authJson());

    expect(result.player.name, 'Night Owl');
    expect(result.token, 'tok_acceptance_1234567890');
    expect(result.syncCode, 'ABCD-EFGH-JKLM');
    expect(result.world?.guild.players, 4);
  });
}
