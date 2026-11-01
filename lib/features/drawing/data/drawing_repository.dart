import 'dart:convert';
import 'package:flutter/services.dart';
import 'drawing_word_model.dart';

class DrawingRepository {
  List<DrawingWord> _allWords = [];
  final List<DrawingWord> _deck = [];

  bool get isLoaded => _allWords.isNotEmpty;

  Future<void> loadWords() async {
    if (_allWords.isNotEmpty) return;
    final jsonString = await rootBundle.loadString('assets/data/drawing/pack_free.json');
    final List decoded = jsonDecode(jsonString);
    _allWords = decoded.map((e) => DrawingWord.fromJson(e)).toList();
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
    return _deck.removeLast();
  }

  int get totalWords => _allWords.length;
}
