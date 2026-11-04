import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/services/content_service.dart';
import 'package:flutter_application_1/core/services/content_history_service.dart';

import 'taboo_card_model.dart';

class TabooRepository {
  List<TabooCard> _allCards = [];
  final List<TabooCard> _deck = [];

  bool get isLoaded => _allCards.isNotEmpty;

  Future<void> loadCards() async {
    final List decoded;
    if (sl.isRegistered<ContentService>()) {
      decoded = await sl<ContentService>().load('taboo');
    } else {
      final jsonString = await rootBundle.loadString(
        'assets/data/taboo/pack_free.json',
      );
      decoded = jsonDecode(jsonString) as List;
    }
    if (decoded.isEmpty) throw const FormatException('بسته بازی خالی است.');
    final loaded = decoded
        .map((e) => TabooCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _allCards = loaded;
    _resetDeck();
  }

  void _resetDeck() {
    _deck.clear();
    _deck.addAll(
      ContentHistoryService.freshDeck('taboo', _allCards, (card) => card.id),
    );
  }

  TabooCard getNextCard({int? difficulty}) {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    if (_deck.isEmpty) throw StateError('بسته بازی آماده نیست.');
    var index = difficulty == null
        ? _deck.length - 1
        : _deck.lastIndexWhere((card) => card.difficulty == difficulty);
    if (index < 0 && difficulty != null) {
      ContentHistoryService.reset('taboo');
      _deck
        ..clear()
        ..addAll(_allCards.where((card) => card.difficulty == difficulty))
        ..shuffle();
      index = _deck.length - 1;
    }
    final card = _deck.removeAt(index);
    ContentHistoryService.markSeen('taboo', card.id);
    return card;
  }

  int get totalCards => _allCards.length;
}
