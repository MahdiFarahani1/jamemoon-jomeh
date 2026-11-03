import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/services/content_service.dart';

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
    _deck.addAll(_allCards);
    _deck.shuffle();
  }

  TabooCard getNextCard() {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    if (_deck.isEmpty) throw StateError('بسته بازی آماده نیست.');
    return _deck.removeLast();
  }

  int get totalCards => _allCards.length;
}
