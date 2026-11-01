import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local storage management via SharedPreferences with memory fallback
class StorageService {
  final SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};

  StorageService([this._prefs]);

  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyPurchasedPacks = 'purchased_packs';
  static const String _keySavedTeams = 'saved_teams';
  static const String _keySavedPlayers = 'saved_players';
  static const String _keyActiveTournament = 'active_tournament';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyCustomCards = 'custom_cards';

  // Sound settings
  bool get isSoundEnabled {
    try {
      return _prefs?.getBool(_keySoundEnabled) ?? (_memoryCache[_keySoundEnabled] as bool? ?? true);
    } catch (_) {
      return _memoryCache[_keySoundEnabled] as bool? ?? true;
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    _memoryCache[_keySoundEnabled] = value;
    try {
      await _prefs?.setBool(_keySoundEnabled, value);
    } catch (e) {
      debugPrint('StorageService write error: $e');
    }
  }

  // Vibration settings
  bool get isVibrationEnabled {
    try {
      return _prefs?.getBool(_keyVibrationEnabled) ?? (_memoryCache[_keyVibrationEnabled] as bool? ?? true);
    } catch (_) {
      return _memoryCache[_keyVibrationEnabled] as bool? ?? true;
    }
  }

  Future<void> setVibrationEnabled(bool value) async {
    _memoryCache[_keyVibrationEnabled] = value;
    try {
      await _prefs?.setBool(_keyVibrationEnabled, value);
    } catch (e) {
      debugPrint('StorageService write error: $e');
    }
  }

  // Purchased packs (IDs of purchased items)
  List<String> get purchasedPacks {
    try {
      return _prefs?.getStringList(_keyPurchasedPacks) ??
          List<String>.from(_memoryCache[_keyPurchasedPacks] ?? []);
    } catch (_) {
      return List<String>.from(_memoryCache[_keyPurchasedPacks] ?? []);
    }
  }

  Future<void> addPurchasedPack(String packId) async {
    final list = purchasedPacks.toSet();
    list.add(packId);
    _memoryCache[_keyPurchasedPacks] = list.toList();
    try {
      await _prefs?.setStringList(_keyPurchasedPacks, list.toList());
    } catch (e) {
      debugPrint('StorageService write error: $e');
    }
  }

  bool isPackPurchased(String packId) {
    if (purchasedPacks.contains('season_1_bundle')) return true;
    return purchasedPacks.contains(packId);
  }

  // Saved teams
  List<Map<String, dynamic>> getSavedTeams() {
    try {
      final raw = _prefs?.getString(_keySavedTeams) ?? _memoryCache[_keySavedTeams];
      if (raw == null || raw.toString().isEmpty) return [];
      final decoded = jsonDecode(raw.toString()) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTeams(List<Map<String, dynamic>> teams) async {
    final encoded = jsonEncode(teams);
    _memoryCache[_keySavedTeams] = encoded;
    try {
      await _prefs?.setString(_keySavedTeams, encoded);
    } catch (e) {
      debugPrint('StorageService write error: $e');
    }
  }

  // Saved players
  List<Map<String, dynamic>> getSavedPlayers() {
    try {
      final raw = _prefs?.getString(_keySavedPlayers) ?? _memoryCache[_keySavedPlayers];
      if (raw == null || raw.toString().isEmpty) return [];
      final decoded = jsonDecode(raw.toString()) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlayers(List<Map<String, dynamic>> players) async {
    final encoded = jsonEncode(players);
    _memoryCache[_keySavedPlayers] = encoded;
    try {
      await _prefs?.setString(_keySavedPlayers, encoded);
    } catch (e) {
      debugPrint('StorageService write error: $e');
    }
  }

  // Active tournament state
  Map<String, dynamic>? getActiveTournament() {
    try {
      final raw = _prefs?.getString(_keyActiveTournament) ?? _memoryCache[_keyActiveTournament];
      if (raw == null || raw.toString().isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(raw.toString()));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveTournament(Map<String, dynamic>? data) async {
    if (data == null) {
      _memoryCache.remove(_keyActiveTournament);
      try {
        await _prefs?.remove(_keyActiveTournament);
      } catch (_) {}
    } else {
      final encoded = jsonEncode(data);
      _memoryCache[_keyActiveTournament] = encoded;
      try {
        await _prefs?.setString(_keyActiveTournament, encoded);
      } catch (e) {
        debugPrint('StorageService write error: $e');
      }
    }
  }

  // First launch check
  bool get isFirstLaunch {
    try {
      return _prefs?.getBool(_keyFirstLaunch) ?? (_memoryCache[_keyFirstLaunch] as bool? ?? true);
    } catch (_) {
      return _memoryCache[_keyFirstLaunch] as bool? ?? true;
    }
  }

  Future<void> setFirstLaunchCompleted() async {
    _memoryCache[_keyFirstLaunch] = false;
    try {
      await _prefs?.setBool(_keyFirstLaunch, false);
    } catch (_) {}
  }

  // Custom user cards
  List<Map<String, dynamic>> getCustomCards() {
    try {
      final raw = _prefs?.getString(_keyCustomCards) ?? _memoryCache[_keyCustomCards];
      if (raw == null || raw.toString().isEmpty) return [];
      final decoded = jsonDecode(raw.toString()) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomCards(List<Map<String, dynamic>> cards) async {
    final encoded = jsonEncode(cards);
    _memoryCache[_keyCustomCards] = encoded;
    try {
      await _prefs?.setString(_keyCustomCards, encoded);
    } catch (e) {
      debugPrint('StorageService write error: $e');
    }
  }

  // Reset all data
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      await _prefs?.clear();
    } catch (_) {}
  }
}
