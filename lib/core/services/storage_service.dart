import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Memory is authoritative during this process; ordered writes prevent an
/// older snapshot from overwriting a newer one. Existing storage keys survive.
class StorageService {
  final SharedPreferences? _prefs;
  final Map<String, Object?> _cache = {};
  Future<void> _writes = Future.value();
  bool _writeFailed = false;
  StorageService([this._prefs]);

  bool get isPersistent => _prefs != null && !_writeFailed;
  static const seasonOnePackIds = {
    'pack_taboo_full',
    'pack_bomb_full',
    'pack_charades_full',
    'pack_five_full',
    'pack_drawing_full',
  };

  Object? _read(String key) {
    if (_cache.containsKey(key)) return _cache[key];
    try {
      return _cache[key] = _prefs?.get(key);
    } catch (_) {
      _writeFailed = true;
      return null;
    }
  }

  Future<void> _write(String key, Object? value) {
    _cache[key] = value;
    _writes = _writes.then((_) async {
      if (_prefs == null) return;
      try {
        final bool saved;
        if (value == null) {
          saved = await _prefs.remove(key);
        } else if (value is bool) {
          saved = await _prefs.setBool(key, value);
        } else if (value is List<String>) {
          saved = await _prefs.setStringList(key, value);
        } else {
          saved = await _prefs.setString(key, value as String);
        }
        if (!saved) _writeFailed = true;
      } catch (error) {
        _writeFailed = true;
        debugPrint('Local storage unavailable: $error');
      }
    });
    return _writes;
  }

  bool get isSoundEnabled =>
      _read('sound_enabled') is bool ? _read('sound_enabled') as bool : true;
  bool get isVibrationEnabled => _read('vibration_enabled') is bool
      ? _read('vibration_enabled') as bool
      : true;
  Future<void> setSoundEnabled(bool value) => _write('sound_enabled', value);
  Future<void> setVibrationEnabled(bool value) =>
      _write('vibration_enabled', value);

  List<String> get purchasedPacks {
    final value = _read('purchased_packs');
    return value is List
        ? List<String>.unmodifiable(value.whereType<String>())
        : const [];
  }

  Future<void> addPurchasedPack(String id) =>
      _write('purchased_packs', {...purchasedPacks, id}.toList());
  bool isPackPurchased(String id) =>
      purchasedPacks.contains(id) ||
      (seasonOnePackIds.contains(id) &&
          purchasedPacks.contains('season_1_bundle'));

  List<Map<String, dynamic>> _readList(String key) {
    try {
      final raw = _read(key);
      if (raw is! String) return [];
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic>? _readMap(String key) {
    try {
      final raw = _read(key);
      if (raw is! String) return null;
      final data = jsonDecode(raw);
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeJson(String key, Object? data) =>
      _write(key, data == null ? null : jsonEncode(data));

  List<Map<String, dynamic>> getSavedTeams() => _readList('saved_teams');
  List<Map<String, dynamic>> getSavedPlayers() => _readList('saved_players');
  Future<void> saveTeams(List<Map<String, dynamic>> teams) =>
      _writeJson('saved_teams', teams);
  Future<void> savePlayers(List<Map<String, dynamic>> players) =>
      _writeJson('saved_players', players);
  Map<String, dynamic>? getActiveTournament() => _readMap('active_tournament');
  Future<void> saveActiveTournament(Map<String, dynamic>? data) =>
      _writeJson('active_tournament', data);
  bool get isFirstLaunch => _read('first_launch') != false;
  Future<void> setFirstLaunchCompleted() => _write('first_launch', false);
  List<Map<String, dynamic>> getCustomCards() => _readList('custom_cards');
  Future<void> saveCustomCards(List<Map<String, dynamic>> cards) =>
      _writeJson('custom_cards', cards);

  Map<String, dynamic>? getGameSession(String key) =>
      _readMap('game_session_$key');
  Future<void> saveGameSession(String key, Map<String, dynamic>? data) =>
      _writeJson('game_session_$key', data);
  Map<String, dynamic>? getActiveDecoder() => getGameSession('decoder');
  Future<void> saveActiveDecoder(Map<String, dynamic>? data) =>
      saveGameSession('decoder', data);

  List<Map<String, dynamic>> getGameHistory() => _readList('game_history');
  Future<void> recordGameResult({
    required String sessionId,
    required String gameKey,
    required Map<String, int> scores,
    String? winnerName,
  }) {
    final history = getGameHistory();
    if (history.any((entry) => entry['sessionId'] == sessionId)) {
      return Future.value();
    }
    history.insert(0, {
      'sessionId': sessionId,
      'gameKey': gameKey,
      'finishedAt': DateTime.now().toUtc().toIso8601String(),
      'scores': scores,
      'winnerName': winnerName,
    });
    return _writeJson('game_history', history.take(200).toList());
  }

  /// Reset game data, never lifetime purchase entitlements or unrelated keys.
  Future<void> clearAll() async {
    final keys = <String>{
      'sound_enabled',
      'vibration_enabled',
      'saved_teams',
      'saved_players',
      'active_tournament',
      'first_launch',
      'custom_cards',
      'game_history',
      ..._cache.keys.where((key) => key.startsWith('game_session_')),
      ...?_prefs?.getKeys().where((key) => key.startsWith('game_session_')),
    };
    for (final key in keys) {
      await _write(key, null);
    }
  }
}
