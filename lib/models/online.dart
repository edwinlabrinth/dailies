import 'habit.dart';

int _asInt(Object? value) =>
    value is int ? value : int.tryParse('${value ?? ''}') ?? 0;

DateTime? _asDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, dynamic> _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

/// The public profile of somebody in the guild hall.
class PlayerProfile {
  const PlayerProfile({required this.id, required this.name, this.createdAt});

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Player',
        createdAt: _asDate(json['createdAt']),
      );

  final String id;
  final String name;
  final DateTime? createdAt;
}

/// The weekly community boss. Every completion in the guild deals damage.
class BossState {
  const BossState({
    required this.name,
    required this.emoji,
    required this.hpMax,
    required this.damage,
    required this.remaining,
    required this.percent,
    required this.defeated,
    required this.endsInDays,
  });

  factory BossState.fromJson(Map<String, dynamic> json) => BossState(
        name: json['name'] as String? ?? 'The Unknown Boss',
        emoji: json['emoji'] as String? ?? '🐉',
        hpMax: _asInt(json['hpMax']),
        damage: _asInt(json['damage']),
        remaining: _asInt(json['remaining']),
        percent: _asInt(json['percent']),
        defeated: json['defeated'] == true,
        endsInDays: _asInt(json['endsInDays']),
      );

  final String name;
  final String emoji;
  final int hpMax;
  final int damage;
  final int remaining;
  final int percent;
  final bool defeated;
  final int endsInDays;

  /// 0..1 bar value, clamped so a wild server can never break the UI.
  double get fraction =>
      hpMax <= 0 ? 0 : (damage / hpMax).clamp(0, 1).toDouble();
}

/// Numbers for the whole community this week.
class GuildStats {
  const GuildStats({
    required this.players,
    required this.weeklyCompletions,
    required this.weeklyXp,
    required this.todayCompletions,
    required this.todayXp,
    required this.streakDays,
    required this.totalCompletions,
  });

  factory GuildStats.fromJson(Map<String, dynamic> json) => GuildStats(
        players: _asInt(json['players']),
        weeklyCompletions: _asInt(json['weeklyCompletions']),
        weeklyXp: _asInt(json['weeklyXp']),
        todayCompletions: _asInt(json['todayCompletions']),
        todayXp: _asInt(json['todayXp']),
        streakDays: _asInt(json['streakDays']),
        totalCompletions: _asInt(json['totalCompletions']),
      );

  final int players;
  final int weeklyCompletions;
  final int weeklyXp;
  final int todayCompletions;
  final int todayXp;
  final int streakDays;
  final int totalCompletions;
}

class WorldState {
  const WorldState({
    required this.weekStart,
    required this.boss,
    required this.guild,
  });

  factory WorldState.fromJson(Map<String, dynamic> json) => WorldState(
        weekStart: json['weekStart'] as String? ?? '',
        boss: BossState.fromJson(_asMap(json['boss'])),
        guild: GuildStats.fromJson(_asMap(json['guild'])),
      );

  final String weekStart;
  final BossState boss;
  final GuildStats guild;
}

class LeaderEntry {
  const LeaderEntry({
    required this.id,
    required this.name,
    required this.weeklyXp,
    required this.totalXp,
    this.lastSeenAt,
  });

  factory LeaderEntry.fromJson(Map<String, dynamic> json) => LeaderEntry(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Player',
        weeklyXp: _asInt(json['weeklyXp']),
        totalXp: _asInt(json['totalXp']),
        lastSeenAt: _asDate(json['lastSeenAt']),
      );

  final String id;
  final String name;
  final int weeklyXp;
  final int totalXp;
  final DateTime? lastSeenAt;
}

/// Everything the guild hall screen needs in one payload.
class GuildSnapshot {
  const GuildSnapshot({required this.world, required this.leaders});

  factory GuildSnapshot.fromJson(Map<String, dynamic> json) {
    final worldJson =
        json['world'] is Map<String, dynamic> ? _asMap(json['world']) : json;
    final leaderJson = json['leaders'];
    return GuildSnapshot(
      world: WorldState.fromJson(worldJson),
      leaders: leaderJson is List
          ? [
              for (final item in leaderJson)
                if (item is Map<String, dynamic>) LeaderEntry.fromJson(item),
            ]
          : const <LeaderEntry>[],
    );
  }

  final WorldState world;
  final List<LeaderEntry> leaders;
}

class PlayerStats {
  const PlayerStats({this.totalXp = 0, this.weeklyXp = 0, this.streak = 0});

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        totalXp: _asInt(json['totalXp']),
        weeklyXp: _asInt(json['weeklyXp']),
        streak: _asInt(json['streak']),
      );

  final int totalXp;
  final int weeklyXp;
  final int streak;
}

/// A full pull from the cloud: profile, habits, stats and the world.
class SyncSnapshot {
  const SyncSnapshot({
    required this.player,
    required this.habits,
    required this.stats,
    required this.world,
  });

  factory SyncSnapshot.fromJson(Map<String, dynamic> json) {
    final habitJson = json['habits'];
    return SyncSnapshot(
      player: json['player'] is Map<String, dynamic>
          ? PlayerProfile.fromJson(_asMap(json['player']))
          : null,
      habits: habitJson is List
          ? [
              for (final item in habitJson)
                if (item is Map<String, dynamic>) Habit.fromJson(item),
            ]
          : const <Habit>[],
      stats: PlayerStats.fromJson(_asMap(json['stats'])),
      world: json['world'] is Map<String, dynamic>
          ? WorldState.fromJson(_asMap(json['world']))
          : null,
    );
  }

  final PlayerProfile? player;
  final List<Habit> habits;
  final PlayerStats stats;
  final WorldState? world;
}

/// The result of registering or claiming an account.
class AuthResult {
  const AuthResult({
    required this.player,
    required this.token,
    this.syncCode,
    this.habits = const <Habit>[],
    this.stats = const PlayerStats(),
    this.world,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final habitJson = json['habits'];
    final worldJson = json['world'];
    return AuthResult(
      player: PlayerProfile.fromJson(_asMap(json['player'])),
      token: json['token'] as String? ?? '',
      syncCode: json['syncCode'] as String?,
      habits: habitJson is List
          ? [
              for (final item in habitJson)
                if (item is Map<String, dynamic>) Habit.fromJson(item),
            ]
          : const <Habit>[],
      stats: PlayerStats.fromJson(_asMap(json['stats'])),
      world: worldJson is Map<String, dynamic>
          ? WorldState.fromJson(worldJson)
          : null,
    );
  }

  final PlayerProfile player;
  final String token;
  final String? syncCode;
  final List<Habit> habits;
  final PlayerStats stats;
  final WorldState? world;
}
