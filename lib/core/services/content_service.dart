import 'dart:convert';

import 'package:flutter/services.dart';

import 'storage_service.dart';

/// One local content boundary for the original five games. Entitlements affect
/// only real bundled packs; historical plain custom words suit drawing/acting.
class ContentService {
  final StorageService storage;
  final AssetBundle bundle;
  final Map<String, List<Map<String, dynamic>>> _bundles = {};
  ContentService(this.storage, {AssetBundle? bundle})
    : bundle = bundle ?? rootBundle;

  static const productIds = {
    'taboo': 'pack_taboo_full',
    'hot_potato': 'pack_bomb_full',
    'charades': 'pack_charades_full',
    'five_seconds': 'pack_five_full',
    'drawing': 'pack_drawing_full',
  };
  static String normalize(String value) => value
      .trim()
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp(r'[\s\u200c]+'), ' ');

  Future<List<Map<String, dynamic>>> _pack(String path) async {
    if (_bundles.containsKey(path)) return _bundles[path]!;
    final decoded = jsonDecode(await bundle.loadString(path));
    if (decoded is! List || decoded.isEmpty) {
      throw const FormatException('بسته بازی خالی یا نامعتبر است.');
    }
    final records = decoded
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    _bundles[path] = records;
    return records;
  }

  Future<List<Map<String, dynamic>>> load(String gameKey) async {
    if (!productIds.containsKey(gameKey)) {
      throw ArgumentError.value(gameKey, 'gameKey');
    }
    final records = <Map<String, dynamic>>[
      ...await _pack('assets/data/$gameKey/pack_free.json'),
      if (storage.isPackPurchased(productIds[gameKey]!))
        ...await _pack('assets/data/$gameKey/pack_full.json'),
    ];
    if (gameKey == 'charades' || gameKey == 'drawing') {
      for (final card in storage.getCustomCards()) {
        if (card['word'] is! String || (card['word'] as String).trim().isEmpty) {
          continue;
        }
        if (card['gameKey'] != null &&
            card['gameKey'] != gameKey &&
            card['gameKey'] != 'both') {
          continue;
        }
        records.add({
          ...card,
          'category': card['category'] ?? 'کارت جمع ما',
          'points': 2,
          'difficulty': 2,
        });
      }
    }
    final field = gameKey == 'hot_potato'
        ? 'topic'
        : gameKey == 'five_seconds'
        ? 'question'
        : 'word';
    final seen = <String>{};
    final ids = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final card in records) {
      final raw = card[field];
      final id = card['id'];
      if (raw is! String || id is! String || normalize(raw).isEmpty) {
        throw const FormatException('یک کارت بازی معتبر نیست.');
      }
      if (gameKey == 'taboo') {
        final forbidden = card['forbiddenWords'];
        if (forbidden is! List ||
            forbidden.length != 5 ||
            forbidden.any((word) => word is! String || word.trim().isEmpty)) {
          throw const FormatException(
            'کارت توضیح باید پنج کلمه ممنوع داشته باشد.',
          );
        }
      }
      if (seen.add(normalize(raw)) && ids.add(id)) {
        result.add(Map.unmodifiable(card));
      }
    }
    if (result.isEmpty) {
      throw const FormatException('برای این بازی کارتی پیدا نشد.');
    }
    return List.unmodifiable(result);
  }
}
