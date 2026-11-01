import 'dart:convert';
import 'package:flutter/services.dart';
import 'five_seconds_model.dart';

class FiveSecondsRepository {
  List<FiveSecondsQuestion> _allQuestions = [];
  final List<FiveSecondsQuestion> _deck = [];

  bool get isLoaded => _allQuestions.isNotEmpty;

  Future<void> loadQuestions() async {
    if (_allQuestions.isNotEmpty) return;
    final jsonString = await rootBundle.loadString('assets/data/five_seconds/pack_free.json');
    final List decoded = jsonDecode(jsonString);
    _allQuestions = decoded.map((e) => FiveSecondsQuestion.fromJson(e)).toList();
    _resetDeck();
  }

  void _resetDeck() {
    _deck.clear();
    _deck.addAll(_allQuestions);
    _deck.shuffle();
  }

  FiveSecondsQuestion getNextQuestion() {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    return _deck.removeLast();
  }

  int get totalQuestions => _allQuestions.length;
}

