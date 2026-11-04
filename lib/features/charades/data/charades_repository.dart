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
        .toList();
    _allWords = loaded;
    _resetDeck();
  }

  void _resetDeck() {
    _deck.clear();
    _deck.addAll(
      ContentHistoryService.freshDeck('charades', _allWords, (word) => word.id),
    );
  }

  CharadesWord getNextWord({int? filterPoints}) {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    if (filterPoints != null) {
      final matchingIndex = _deck.indexWhere((w) => w.points == filterPoints);
      if (matchingIndex != -1) {
        final word = _deck.removeAt(matchingIndex);
        ContentHistoryService.markSeen('charades', word.id);
        return word;
      }
      ContentHistoryService.reset('charades');
      _deck
        ..clear()
        ..addAll(_allWords.where((word) => word.points == filterPoints))
        ..shuffle();
    }
    if (_deck.isEmpty) throw StateError('بسته بازی آماده نیست.');
    final word = _deck.removeLast();
    ContentHistoryService.markSeen('charades', word.id);
    return word;
  }

  int get totalWords => _allWords.length;
}
