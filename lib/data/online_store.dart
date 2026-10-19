import 'package:shared_preferences/shared_preferences.dart';

/// The local half of an online identity: a device token plus the sync code
/// used to claim the same account on another device.
class OnlineSession {
  const OnlineSession({
    required this.token,
    required this.playerId,
    required this.name,
    this.syncCode,
  });

  final String token;
  final String playerId;
  final String name;
  final String? syncCode;

  OnlineSession copyWith({String? syncCode}) => OnlineSession(
        token: token,
        playerId: playerId,
        name: name,
        syncCode: syncCode ?? this.syncCode,
      );
}

class OnlineStore {
  static const String _tokenKey = 'dailies.online.token';
  static const String _playerIdKey = 'dailies.online.playerId';
  static const String _nameKey = 'dailies.online.name';
  static const String _codeKey = 'dailies.online.syncCode';

  Future<OnlineSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final playerId = prefs.getString(_playerIdKey);
    final name = prefs.getString(_nameKey);
    if (token == null || playerId == null || name == null) return null;
    return OnlineSession(
      token: token,
      playerId: playerId,
      name: name,
      syncCode: prefs.getString(_codeKey),
    );
  }

  Future<void> save(OnlineSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_playerIdKey, session.playerId);
    await prefs.setString(_nameKey, session.name);
    final code = session.syncCode;
    if (code == null) {
      await prefs.remove(_codeKey);
    } else {
      await prefs.setString(_codeKey, code);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_playerIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_codeKey);
  }
}
