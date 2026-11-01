import 'dart:convert';
import 'package:flutter/services.dart';
import 'taboo_card_model.dart';

class TabooRepository {
  List<TabooCard> _allCards = [];
  final List<TabooCard> _deck = [];

  bool get isLoaded => _allCards.isNotEmpty;

  Future<void> loadCards() async {
    if (_allCards.isNotEmpty) return;
    final jsonString = await rootBundle.loadString('assets/data/taboo/pack_free.json');
    final List decoded = jsonDecode(jsonString);
    _allCards = decoded.map((e) => TabooCard.fromJson(e)).toList();
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
    return _deck.removeLast();
  }

  int get totalCards => _allCards.length;
}

