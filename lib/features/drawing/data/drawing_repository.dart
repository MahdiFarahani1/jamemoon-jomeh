import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/services/content_service.dart';
import 'package:flutter_application_1/core/services/content_history_service.dart';

import 'drawing_word_model.dart';

class DrawingRepository {
  List<DrawingWord> _allWords = [];
  final List<DrawingWord> _deck = [];

  bool get isLoaded => _allWords.isNotEmpty;

  Future<void> loadWords() async {
    final List decoded;
    if (sl.isRegistered<ContentService>()) {
      decoded = await sl<ContentService>().load('drawing');
    } else {
      final jsonString = await rootBundle.loadString(
        'assets/data/drawing/pack_free.json',
      );
      decoded = jsonDecode(jsonString) as List;
    }
    if (decoded.isEmpty) throw const FormatException('بسته بازی خالی است.');
    final loaded = decoded
        .map((e) => DrawingWord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _allWords = loaded;
    _resetDeck();
  }

  void _resetDeck() {
    _deck.clear();
    _deck.addAll(
      ContentHistoryService.freshDeck('drawing', _allWords, (word) => word.id),
    );
  }

  DrawingWord getNextWord({int? difficulty}) {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    if (_deck.isEmpty) throw StateError('بسته بازی آماده نیست.');
    var index = difficulty == null
        ? _deck.length - 1
        : _deck.lastIndexWhere((word) => word.difficulty == difficulty);
    if (index < 0 && difficulty != null) {
      ContentHistoryService.reset('drawing');
      _deck
        ..clear()
        ..addAll(_allWords.where((word) => word.difficulty == difficulty))
        ..shuffle();
      index = _deck.length - 1;
    }
    final word = _deck.removeAt(index);
    ContentHistoryService.markSeen('drawing', word.id);
    return word;
  }

  int get totalWords => _allWords.length;
}
