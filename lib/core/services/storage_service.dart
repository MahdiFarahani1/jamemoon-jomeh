import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Local storage management via SharedPreferences
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyPurchasedPacks = 'purchased_packs';
  static const String _keySavedTeams = 'saved_teams';
  static const String _keySavedPlayers = 'saved_players';
  static const String _keyActiveTournament = 'active_tournament';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyCustomCards = 'custom_cards';

  // Sound settings
  bool get isSoundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) async => _prefs.setBool(_keySoundEnabled, value);

  // Vibration settings
  bool get isVibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  Future<void> setVibrationEnabled(bool value) async => _prefs.setBool(_keyVibrationEnabled, value);

  // Purchased packs (IDs of purchased items)
  List<String> get purchasedPacks => _prefs.getStringList(_keyPurchasedPacks) ?? [];
  Future<void> addPurchasedPack(String packId) async {
    final list = purchasedPacks.toSet();
    list.add(packId);
    await _prefs.setStringList(_keyPurchasedPacks, list.toList());
  }
  bool isPackPurchased(String packId) {
    if (purchasedPacks.contains('season_1_bundle')) return true;
    return purchasedPacks.contains(packId);
  }

  // Saved teams
  List<Map<String, dynamic>> getSavedTeams() {
    final raw = _prefs.getString(_keySavedTeams);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTeams(List<Map<String, dynamic>> teams) async {
    await _prefs.setString(_keySavedTeams, jsonEncode(teams));
  }

  // Saved players
  List<Map<String, dynamic>> getSavedPlayers() {
    final raw = _prefs.getString(_keySavedPlayers);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlayers(List<Map<String, dynamic>> players) async {
    await _prefs.setString(_keySavedPlayers, jsonEncode(players));
  }

  // Active tournament state
  Map<String, dynamic>? getActiveTournament() {
    final raw = _prefs.getString(_keyActiveTournament);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveTournament(Map<String, dynamic>? data) async {
    if (data == null) {
      await _prefs.remove(_keyActiveTournament);
    } else {
      await _prefs.setString(_keyActiveTournament, jsonEncode(data));
    }
  }

  // First launch check
  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;
  Future<void> setFirstLaunchCompleted() async => _prefs.setBool(_keyFirstLaunch, false);

  // Custom user cards
  List<Map<String, dynamic>> getCustomCards() {
    final raw = _prefs.getString(_keyCustomCards);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomCards(List<Map<String, dynamic>> cards) async {
    await _prefs.setString(_keyCustomCards, jsonEncode(cards));
  }

  // Reset all data
  Future<void> clearAll() async => _prefs.clear();
}
