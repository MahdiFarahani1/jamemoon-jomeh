import 'dart:convert';
import 'package:flutter/services.dart';
import 'hot_potato_topic_model.dart';

class HotPotatoRepository {
  List<HotPotatoTopic> _allTopics = [];
  final List<HotPotatoTopic> _deck = [];

  bool get isLoaded => _allTopics.isNotEmpty;

  Future<void> loadTopics() async {
    if (_allTopics.isNotEmpty) return;
    final jsonString = await rootBundle.loadString('assets/data/hot_potato/pack_free.json');
    final List decoded = jsonDecode(jsonString);
    _allTopics = decoded.map((e) => HotPotatoTopic.fromJson(e)).toList();
    _resetDeck();
  }

  void _resetDeck() {
    _deck.clear();
    _deck.addAll(_allTopics);
    _deck.shuffle();
  }

  HotPotatoTopic getNextTopic() {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    return _deck.removeLast();
  }

  int get totalTopics => _allTopics.length;
}

