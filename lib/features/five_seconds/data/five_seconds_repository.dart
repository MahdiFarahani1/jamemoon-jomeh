import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/services/content_service.dart';

import 'five_seconds_model.dart';

class FiveSecondsRepository {
  List<FiveSecondsQuestion> _allQuestions = [];
  final List<FiveSecondsQuestion> _deck = [];

  bool get isLoaded => _allQuestions.isNotEmpty;

  Future<void> loadQuestions() async {
    final List decoded;
    if (sl.isRegistered<ContentService>()) {
      decoded = await sl<ContentService>().load('five_seconds');
    } else {
      final jsonString = await rootBundle.loadString(
        'assets/data/five_seconds/pack_free.json',
      );
      decoded = jsonDecode(jsonString) as List;
    }
    if (decoded.isEmpty) throw const FormatException('بسته بازی خالی است.');
    final loaded = decoded
        .map(
          (e) =>
              FiveSecondsQuestion.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    _allQuestions = loaded;
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
    if (_deck.isEmpty) throw StateError('بسته بازی آماده نیست.');
    return _deck.removeLast();
  }

  int get totalQuestions => _allQuestions.length;
}
