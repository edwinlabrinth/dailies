import 'dart:convert';

import 'package:dailies/data/api_client.dart';
import 'package:dailies/models/habit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../fixtures/online_fixtures.dart';

/// Mirrors the real server: JSON is always UTF-8 (the boss emoji needs it).
http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('register posts the name and parses the new identity', () async {
    late http.Request captured;
    final api = ApiClient(
      baseUrl: 'https://example.test/api/',
      client: MockClient((request) async {
        captured = request;
        return _json(authJson(), 201);
      }),
    );

    final result = await api.register('Night Owl');

    expect(captured.method, 'POST');
    expect(captured.url.toString(), 'https://example.test/api/register');
    expect(jsonDecode(captured.body), {'name': 'Night Owl'});
    expect(result.player.name, 'Night Owl');
    expect(result.token, 'tok_acceptance_1234567890');
    expect(result.syncCode, 'ABCD-EFGH-JKLM');
    expect(result.world, isNotNull);
  });

  test('API errors keep their status, code and friendly message', () async {
    final api = ApiClient(
      baseUrl: 'https://example.test/api',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': 'name_taken',
            'message': 'Someone already claimed that name in the guild hall.',
          }),
          409,
        ),
      ),
    );

    await expectLater(
      api.register('Night Owl'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'name_taken')
            .having((error) => error.statusCode, 'status', 409)
            .having((error) => error.isOffline, 'isOffline', false)
            .having((error) => error.message, 'message',
                contains('already claimed')),
      ),
    );
  });

  test('push sends the snapshot with a bearer token', () async {
    late http.Request captured;
    final api = ApiClient(
      baseUrl: 'https://example.test/api',
      client: MockClient((request) async {
        captured = request;
        return _json({
          'player': {'id': 'player-1', 'name': 'Night Owl'},
          'stats': {'totalXp': 10, 'weeklyXp': 10, 'streak': 1},
          'world': worldJson,
        }, 200);
      }),
    )..token = 'device-secret';

    final habit = Habit(
      id: 'habit-1',
      name: 'Morning run',
      iconIndex: 3,
      colorIndex: 4,
      doneDates: {'2026-10-19'},
    );
    final result = await api.push([habit]);

    expect(captured.url.toString(), 'https://example.test/api/sync');
    expect(captured.headers['authorization'], 'Bearer device-secret');
    final payload = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(payload['habits'], [
      {
        'id': 'habit-1',
        'name': 'Morning run',
        'icon': 3,
        'color': 4,
        'done': ['2026-10-19'],
      },
    ]);
    expect(result.stats.totalXp, 10);
  });

  test('pulling parses the full snapshot', () async {
    final api = ApiClient(
      baseUrl: 'https://example.test/api',
      client: MockClient(
        (_) async => _json({
          'player': {'id': 'player-1', 'name': 'Night Owl'},
          'habits': [
            {
              'id': 'habit-1',
              'name': 'Read',
              'icon': 2,
              'color': 1,
              'done': ['2026-10-19'],
            },
          ],
          'stats': {'totalXp': 10, 'weeklyXp': 10, 'streak': 1},
          'world': worldJson,
        }, 200),
      ),
    );

    final snapshot = await api.pull();
    expect(snapshot.habits.single.name, 'Read');
    expect(snapshot.habits.single.doneDates, {'2026-10-19'});
    expect(snapshot.world?.boss.percent, 43);
  });

  test('the leaderboard request parses the guild', () async {
    final api = ApiClient(
      baseUrl: 'https://example.test/api',
      client: MockClient(
        (_) async => _json(leaderboardJson(), 200),
      ),
    );

    final snapshot = await api.guild();
    expect(snapshot.leaders, hasLength(2));
    expect(snapshot.leaders.last.name, 'Early Bird');
    expect(snapshot.world.guild.todayXp, 70);
  });

  test('network failures become friendly offline errors', () async {
    final api = ApiClient(
      baseUrl: 'https://example.test/api',
      client: MockClient(
        (_) async => throw http.ClientException('connection refused'),
      ),
    );

    await expectLater(
      api.guild(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.isOffline, 'isOffline', true)
            .having((error) => error.code, 'code', 'offline'),
      ),
    );
  });
}
