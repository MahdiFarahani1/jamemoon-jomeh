import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/services/content_service.dart';

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
    _deck.addAll(_allWords);
    _deck.shuffle();
  }

  DrawingWord getNextWord() {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    if (_deck.isEmpty) throw StateError('بسته بازی آماده نیست.');
    return _deck.removeLast();
  }

  int get totalWords => _allWords.length;
}
