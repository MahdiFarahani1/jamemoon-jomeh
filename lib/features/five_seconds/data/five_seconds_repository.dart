import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/services/content_service.dart';
import 'package:flutter_application_1/core/services/content_history_service.dart';

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
    _deck.addAll(
      ContentHistoryService.freshDeck(
        'five_seconds',
        _allQuestions,
        (question) => question.id,
      ),
    );
  }

  FiveSecondsQuestion getNextQuestion({int? difficulty}) {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    if (_deck.isEmpty) throw StateError('بسته بازی آماده نیست.');
    var index = difficulty == null
        ? _deck.length - 1
        : _deck.lastIndexWhere(
            (question) => _bucket(question.id) == difficulty,
          );
    if (index < 0 && difficulty != null) {
      ContentHistoryService.reset('five_seconds');
      _deck
        ..clear()
        ..addAll(
          _allQuestions.where((question) => _bucket(question.id) == difficulty),
        )
        ..shuffle();
      index = _deck.length - 1;
    }
    final question = _deck.removeAt(index);
    ContentHistoryService.markSeen('five_seconds', question.id);
    return question;
  }

  int _bucket(String id) =>
      id.codeUnits.fold<int>(0, (sum, value) => sum + value) % 3 + 1;

  int get totalQuestions => _allQuestions.length;
}
