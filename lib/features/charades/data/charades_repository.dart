import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/services/content_service.dart';
import 'package:flutter_application_1/core/services/content_history_service.dart';

import 'charades_word_model.dart';

class CharadesRepository {
  List<CharadesWord> _allWords = [];
  final List<CharadesWord> _deck = [];

  bool get isLoaded => _allWords.isNotEmpty;
  bool hasCategory(String category) =>
      category == 'all' || _allWords.any((word) => word.category == category);

  CharadesWord? findById(String id) {
    for (final word in _allWords) {
      if (word.id == id) return word;
    }
    return null;
  }

  Future<void> loadWords() async {
    final List decoded;
    if (sl.isRegistered<ContentService>()) {
      decoded = await sl<ContentService>().load('charades');
    } else {
      final jsonString = await rootBundle.loadString(
        'assets/data/charades/pack_free.json',
      );
      decoded = jsonDecode(jsonString) as List;
    }
    if (decoded.isEmpty) throw const FormatException('بسته بازی خالی است.');
    final loaded = decoded
        .map((e) => CharadesWord.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((word) => CharadesWord.isValid(word.word))
        .toList();
    if (loaded.isEmpty) {
      throw const FormatException('واژهٔ مناسب پانتومیم پیدا نشد.');
    }
    _allWords = loaded;
    _resetDeck();
  }

  void _resetDeck() {
    _deck.clear();
    _deck.addAll(
      ContentHistoryService.freshDeck('charades', _allWords, (word) => word.id),
    );
  }

  CharadesWord getNextWord({int? filterPoints, String category = 'all'}) {
    bool matches(CharadesWord word) =>
        (category == 'all' || word.category == category) &&
        (filterPoints == null || word.points == filterPoints);
    if (!_allWords.any(matches)) {
      throw StateError('در این دسته واژه‌ای پیدا نشد.');
    }
    if (_deck.isEmpty) {
      _resetDeck();
    }
    var matchingIndex = _deck.indexWhere(matches);
    if (matchingIndex == -1) {
      ContentHistoryService.reset('charades');
      _deck
        ..clear()
        ..addAll(_allWords.where(matches))
        ..shuffle();
      matchingIndex = _deck.indexWhere(matches);
    }
    final word = _deck.removeAt(matchingIndex);
    ContentHistoryService.markSeen('charades', word.id);
    return word;
  }

  int get totalWords => _allWords.length;
}
