import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/services/content_service.dart';
import 'package:flutter_application_1/core/services/content_history_service.dart';

import 'hot_potato_topic_model.dart';

class HotPotatoRepository {
  List<HotPotatoTopic> _allTopics = [];
  final List<HotPotatoTopic> _deck = [];

  bool get isLoaded => _allTopics.isNotEmpty;

  Future<void> loadTopics() async {
    final List decoded;
    if (sl.isRegistered<ContentService>()) {
      decoded = await sl<ContentService>().load('hot_potato');
    } else {
      final jsonString = await rootBundle.loadString(
        'assets/data/hot_potato/pack_free.json',
      );
      decoded = jsonDecode(jsonString) as List;
    }
    if (decoded.isEmpty) throw const FormatException('بسته بازی خالی است.');
    final loaded = decoded
        .map(
          (e) => HotPotatoTopic.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    _allTopics = loaded;
    _resetDeck();
  }

  void _resetDeck() {
    _deck.clear();
    _deck.addAll(
      ContentHistoryService.freshDeck(
        'hot_potato',
        _allTopics,
        (topic) => topic.id,
      ),
    );
  }

  HotPotatoTopic getNextTopic({int? difficulty}) {
    if (_deck.isEmpty) {
      _resetDeck();
    }
    if (_deck.isEmpty) throw StateError('بسته بازی آماده نیست.');
    var index = difficulty == null
        ? _deck.length - 1
        : _deck.lastIndexWhere((topic) => _bucket(topic.id) == difficulty);
    if (index < 0 && difficulty != null) {
      ContentHistoryService.reset('hot_potato');
      _deck
        ..clear()
        ..addAll(_allTopics.where((topic) => _bucket(topic.id) == difficulty))
        ..shuffle();
      index = _deck.length - 1;
    }
    final topic = _deck.removeAt(index);
    ContentHistoryService.markSeen('hot_potato', topic.id);
    return topic;
  }

  int _bucket(String id) =>
      id.codeUnits.fold<int>(0, (sum, value) => sum + value) % 3 + 1;

  int get totalTopics => _allTopics.length;
}
