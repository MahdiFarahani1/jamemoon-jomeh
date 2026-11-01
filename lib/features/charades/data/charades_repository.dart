import 'dart:convert';
import 'package:flutter/services.dart';
import 'charades_word_model.dart';

class CharadesRepository {
  List<CharadesWord> _allWords = [];
  final List<CharadesWord> _deck = [];

  bool get isLoaded => _allWords.isNotEmpty;

  Future<void> loadWords() async {
    if (_allWords.isNotEmpty) return;
    final jsonString = await rootBundle.loadString('assets/data/charades/pack_free.json');
    final List decoded = jsonDecode(jsonString);
    _allWords = decoded.map((e) => CharadesWord.fromJson(e)).toList();
    _resetDeck();
  }

  void _resetDeck() {
    _deck.clear();
    _deck.addAll(_allWords);
    _deck.shuffle();
  }

  CharadesWord getNextWord({int? filterPoints}) {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    if (filterPoints != null) {
      final matchingIndex = _deck.indexWhere((w) => w.points == filterPoints);
      if (matchingIndex != -1) {
        return _deck.removeAt(matchingIndex);
      }
    }
    return _deck.removeLast();
  }

  int get totalWords => _allWords.length;
}
