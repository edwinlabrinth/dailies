import 'dart:convert';

import 'package:dailies/data/api_client.dart';
import 'package:dailies/data/guild_controller.dart';
import 'package:dailies/screens/guild_screen.dart';
import 'package:dailies/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/online_fixtures.dart';

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

GuildController _controller(MockClient client) => GuildController(
      api: ApiClient(baseUrl: 'https://example.test/api', client: client),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the guild hall invites players who are not online yet',
      (tester) async {
    final controller = _controller(
      MockClient((_) async => _json(const <String, dynamic>{}, 200)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: GuildScreen(controller: controller),
      ),
    );

    expect(find.text('Join the guild hall'), findsOneWidget);
    expect(find.byKey(const Key('guild-name-field')), findsOneWidget);
    expect(find.byKey(const Key('guild-register')), findsOneWidget);
    expect(find.byKey(const Key('guild-code-field')), findsOneWidget);
    expect(find.byKey(const Key('guild-claim')), findsOneWidget);
  });

  testWidgets('short names are rejected before any request is made',
      (tester) async {
    var requests = 0;
    final controller = _controller(
      MockClient((_) async {
        requests += 1;
        return _json(const <String, dynamic>{}, 200);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: GuildScreen(controller: controller),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('guild-name-field')),
      'A',
    );
    await tester.tap(find.byKey(const Key('guild-register')));
    await tester.pump();

    expect(find.text('Names need at least 2 characters.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('registering reveals the sync code and the leaderboard',
      (tester) async {
    final controller = _controller(
      MockClient((request) async {
        if (request.url.path.endsWith('/register')) {
          return _json(authJson(), 201);
        }
        return _json(leaderboardJson(), 200);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: GuildScreen(controller: controller),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('guild-name-field')),
      'Night Owl',
    );
    await tester.tap(find.byKey(const Key('guild-register')));
    await tester.pumpAndSettle();

    expect(controller.isOnline, isTrue);
    expect(find.text('ABCD-EFGH-JKLM'), findsOneWidget);
    expect(find.byKey(const Key('guild-sync')), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Early Bird'), 250);
    expect(find.text('Early Bird'), findsOneWidget);
    expect(find.text('🥇'), findsOneWidget);
    expect(find.textContaining('(you)'), findsOneWidget);
  });
}
