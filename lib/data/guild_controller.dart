import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../models/online.dart';
import 'api_client.dart';
import 'online_store.dart';

/// Owns the online half of Dailies: the session, the guild data and syncing.
///
/// The tracker keeps working with no network and no account. Every failure in
/// here is turned into a friendly [error] string instead of an exception, so
/// the offline-first screens never have to think about connectivity.
class GuildController extends ChangeNotifier {
  GuildController({ApiClient? api, OnlineStore? store})
      : api = api ?? ApiClient(),
        store = store ?? OnlineStore();

  final ApiClient api;
  final OnlineStore store;

  OnlineSession? session;
  WorldState? world;
  List<LeaderEntry> leaders = const <LeaderEntry>[];
  PlayerStats? stats;
  String? error;
  DateTime? lastSync;
  bool busy = false;

  bool _syncing = false;

  bool get isOnline => session != null;

  /// Loads the saved device token (if any) and refreshes the guild.
  Future<void> restore() async {
    session = await store.load();
    if (session == null) return;
    api.token = session!.token;
    await refresh();
  }

  void _setBusy(bool value) {
    busy = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!isOnline) return;
    _setBusy(true);
    error = null;
    try {
      final snapshot = await api.guild();
      world = snapshot.world;
      leaders = snapshot.leaders;
      lastSync = DateTime.now();
    } on ApiException catch (failure) {
      error = failure.message;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> register(String name) async {
    _setBusy(true);
    error = null;
    try {
      final result = await api.register(name);
      api.token = result.token;
      session = OnlineSession(
        token: result.token,
        playerId: result.player.id,
        name: result.player.name,
        syncCode: result.syncCode,
      );
      await store.save(session!);
      world = result.world ?? world;
      stats = result.stats;
      await refresh();
      return true;
    } on ApiException catch (failure) {
      error = failure.message;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Returns the habits stored in the cloud, or null when the code is wrong.
  Future<List<Habit>?> claim(String code) async {
    _setBusy(true);
    error = null;
    try {
      final result = await api.claim(code);
      api.token = result.token;
      session = OnlineSession(
        token: result.token,
        playerId: result.player.id,
        name: result.player.name,
        syncCode: code.trim().toUpperCase(),
      );
      await store.save(session!);
      world = result.world ?? world;
      stats = result.stats;
      await refresh();
      return result.habits;
    } on ApiException catch (failure) {
      error = failure.message;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  /// Pushes a full snapshot. Returns false when the server could not be
  /// reached — callers can stay quiet, the local data is still safe.
  Future<bool> sync(List<Habit> habits) async {
    if (!isOnline || _syncing) return false;
    _syncing = true;
    error = null;
    try {
      final snapshot = await api.push(habits);
      world = snapshot.world ?? world;
      stats = snapshot.stats;
      lastSync = DateTime.now();
      if (leaders.isEmpty) {
        final guild = await api.guild();
        leaders = guild.leaders;
        world = guild.world;
      }
      return true;
    } on ApiException catch (failure) {
      error = failure.message;
      return false;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Pulls the cloud snapshot — used to restore progress on a new device.
  Future<List<Habit>?> pull() async {
    if (!isOnline) return null;
    try {
      final snapshot = await api.pull();
      world = snapshot.world ?? world;
      stats = snapshot.stats;
      lastSync = DateTime.now();
      notifyListeners();
      return snapshot.habits;
    } on ApiException catch (failure) {
      error = failure.message;
      notifyListeners();
      return null;
    }
  }

  Future<String?> rotateSyncCode() async {
    if (!isOnline) return null;
    try {
      final code = await api.rotateSyncCode();
      session = session!.copyWith(syncCode: code);
      await store.save(session!);
      notifyListeners();
      return code;
    } on ApiException catch (failure) {
      error = failure.message;
      notifyListeners();
      return null;
    }
  }

  /// Signs this device out. The dailies themselves stay right where they are.
  Future<void> signOut() async {
    api.token = null;
    session = null;
    world = null;
    leaders = const <LeaderEntry>[];
    stats = null;
    error = null;
    lastSync = null;
    await store.clear();
    notifyListeners();
  }
}
