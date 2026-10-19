import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/habit.dart';
import '../models/online.dart';

/// A friendly wrapper around every way the API can say no.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);

  final int statusCode;
  final String code;
  final String message;

  /// Status 0 means the request never reached the server at all.
  bool get isOffline => statusCode == 0;

  @override
  String toString() => message;
}

/// Thin client for the Dailies serverless API.
///
/// The app is offline-first, so every caller is expected to cope with an
/// [ApiException] — nothing here is required for the tracker to work.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = _normalise(baseUrl ?? defaultBaseUrl()),
        _client = client ?? http.Client();

  /// Compile-time override: `--dart-define=DAILIES_API=https://…/api`.
  static const String _configured = String.fromEnvironment('DAILIES_API');

  /// Where the desktop build talks to by default.
  static const String productionBaseUrl =
      'https://dailies-guild.netlify.app/api';

  /// `/api` on the same origin in the browser, the deployed API otherwise.
  /// GitHub Pages has no functions, so the Pages demo talks to Netlify.
  static String defaultBaseUrl() {
    if (_configured.isNotEmpty) return _configured;
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.contains('github.io')) return productionBaseUrl;
      return '$origin/api';
    }
    return productionBaseUrl;
  }

  static String _normalise(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  final String baseUrl;
  final http.Client _client;

  /// Set after registering or claiming; sent as a bearer token.
  String? token;

  Map<String, String> get _headers => <String, String>{
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };

  Future<AuthResult> register(String name) async {
    final data = await _send('POST', '/register', body: {'name': name});
    return AuthResult.fromJson(data);
  }

  Future<AuthResult> claim(String syncCode) async {
    final data = await _send('POST', '/claim', body: {'syncCode': syncCode});
    return AuthResult.fromJson(data);
  }

  Future<SyncSnapshot> pull() async =>
      SyncSnapshot.fromJson(await _send('GET', '/sync'));

  Future<SyncSnapshot> push(List<Habit> habits) async {
    final data = await _send('POST', '/sync', body: {
      'habits': [for (final habit in habits) habit.toJson()],
    });
    return SyncSnapshot.fromJson(data);
  }

  Future<GuildSnapshot> guild() async =>
      GuildSnapshot.fromJson(await _send('GET', '/leaderboard'));

  Future<WorldState> world() async {
    final data = await _send('GET', '/world');
    return WorldState.fromJson(
      data['world'] is Map<String, dynamic>
          ? data['world'] as Map<String, dynamic>
          : const <String, dynamic>{},
    );
  }

  Future<String> rotateSyncCode() async {
    final data = await _send('POST', '/sync-code');
    return data['syncCode'] as String? ?? '';
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final http.Response response;
      if (method == 'GET') {
        response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));
      } else {
        response = await _client
            .post(uri, headers: _headers, body: jsonEncode(body ?? const {}))
            .timeout(const Duration(seconds: 20));
      }

      final decoded =
          response.body.isEmpty ? null : jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (response.statusCode >= 400) {
        throw ApiException(
          response.statusCode,
          data['error'] as String? ?? 'http_${response.statusCode}',
          data['message'] as String? ?? 'The guild hall said no.',
        );
      }
      return data;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        0,
        'timeout',
        'The guild hall is taking too long to answer. Try again.',
      );
    } catch (_) {
      throw const ApiException(
        0,
        'offline',
        'Could not reach the guild hall. Your dailies are safe on this device.',
      );
    }
  }
}
