import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/services/content_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';

class _FixtureBundle extends CachingAssetBundle {
  _FixtureBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Missing test asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

Map<String, dynamic> _word(String id, String word) => {
  'id': id,
  'word': word,
  'category': 'fixture',
  'points': 2,
  'difficulty': 2,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
  });

  group('Bundled content regression checks', () {
    const games = [
      'taboo',
      'hot_potato',
      'charades',
      'five_seconds',
      'drawing',
    ];

    test('each supported game has distinct, curated free and full cards', () {
      for (final game in games) {
        final free = _readPack('assets/data/$game/pack_free.json');
        final full = _readPack('assets/data/$game/pack_full.json');
        if (game == 'charades') {
          expect(full, hasLength(300), reason: 'charades full pack');
        }
        expect(
          free.length,
          greaterThanOrEqualTo(40),
          reason: '$game free pack',
        );
        expect(
          full.length,
          greaterThanOrEqualTo(20),
          reason: '$game full pack',
        );
        _validatePack(game, free);
        _validatePack(game, full);
        final primary = _primaryField(game);
        final normalizedFree = free
            .map((row) => ContentService.normalize(row[primary] as String))
            .toSet();
        final normalizedFull = full
            .map((row) => ContentService.normalize(row[primary] as String))
            .toSet();
        expect(
          normalizedFree,
          hasLength(free.length),
          reason: '$game free normalized duplicates',
        );
        expect(
          normalizedFull,
          hasLength(full.length),
          reason: '$game full normalized duplicates',
        );
        expect(
          normalizedFree.intersection(normalizedFull),
          isEmpty,
          reason: '$game overlaps free/full',
        );
      }
      expect(ContentService.productIds.keys, unorderedEquals(games));
      expect(ContentService.productIds, isNot(contains('decoder')));
    });

    test('charades subscription adds 300 different playable cards', () async {
      final free = _readPack('assets/data/charades/pack_free.json');
      final full = _readPack('assets/data/charades/pack_full.json');
      String compact(String word) =>
          ContentService.normalize(word)
              .replaceAll(RegExp(r'[\s\u200c\u200d-]'), '');
      final freeWords = free
          .map((row) => compact(row['word'] as String))
          .toSet();
      final fullWords = full
          .map((row) => compact(row['word'] as String))
          .toSet();
      expect(full, hasLength(300));
      expect(fullWords, hasLength(300));
      expect(fullWords.intersection(freeWords), isEmpty);

      await storage.addPurchasedPack('pack_charades_full');
      final loaded = await ContentService(storage).load('charades');
      expect(loaded, hasLength(600));
      expect(
        loaded.where((row) => row['id'].toString().endsWith('_full')),
        hasLength(300),
      );
    });

    test(
      'drawing has 300 distinct cards in each pack and loads all 600',
      () async {
        final free = _readPack('assets/data/drawing/pack_free.json');
        final full = _readPack('assets/data/drawing/pack_full.json');
        String compact(String word) =>
            ContentService.normalize(word)
                .replaceAll(RegExp(r'[\s\u200c\u200d-]'), '');
        final freeWords = free
            .map((row) => compact(row['word'] as String))
            .toSet();
        final fullWords = full
            .map((row) => compact(row['word'] as String))
            .toSet();
        expect(free, hasLength(300));
        expect(full, hasLength(300));
        expect(freeWords, hasLength(300));
        expect(fullWords, hasLength(300));
        expect(freeWords.intersection(fullWords), isEmpty);
        expect(
          [...free, ...full].map((row) => row['id']).toSet(),
          hasLength(600),
        );
        expect(
          [...free, ...full].every(
            (row) =>
                row['difficulty'] is int &&
                (row['difficulty'] as int) >= 1 &&
                (row['difficulty'] as int) <= 3,
          ),
          isTrue,
        );
        final service = ContentService(storage);
        expect(await service.load('drawing'), hasLength(300));
        await storage.addPurchasedPack('pack_drawing_full');
        expect(await service.load('drawing'), hasLength(600));
      },
    );

    test('five seconds loads 200 unique prompts per pack', () async {
      final free = _readPack('assets/data/five_seconds/pack_free.json');
      final full = _readPack('assets/data/five_seconds/pack_full.json');
      String compact(String question) =>
          ContentService.normalize(question)
              .replaceAll(RegExp(r'[\s\u200c\u200d!؟?,.،-]'), '');
      final freeQuestions = free
          .map((row) => compact(row['question'] as String))
          .toSet();
      final fullQuestions = full
          .map((row) => compact(row['question'] as String))
          .toSet();
      expect(free, hasLength(200));
      expect(full, hasLength(200));
      expect(freeQuestions, hasLength(200));
      expect(fullQuestions, hasLength(200));
      expect(freeQuestions.intersection(fullQuestions), isEmpty);
      expect(
        [...free, ...full].map((row) => row['id']).toSet(),
        hasLength(400),
      );
      final service = ContentService(storage);
      expect(await service.load('five_seconds'), hasLength(200));
      await storage.addPurchasedPack('pack_five_full');
      expect(await service.load('five_seconds'), hasLength(400));
    });
    test('hot potato loads 200 distinct topics per pack', () async {
      final free = _readPack('assets/data/hot_potato/pack_free.json');
      final full = _readPack('assets/data/hot_potato/pack_full.json');
      String compact(String topic) =>
          ContentService.normalize(topic)
              .replaceAll(RegExp(r'[\s\u200c\u200d!؟?,.،-]'), '');
      final freeTopics = free
          .map((row) => compact(row['topic'] as String))
          .toSet();
      final fullTopics = full
          .map((row) => compact(row['topic'] as String))
          .toSet();
      expect(free, hasLength(200));
      expect(full, hasLength(200));
      expect(freeTopics, hasLength(200));
      expect(fullTopics, hasLength(200));
      expect(freeTopics.intersection(fullTopics), isEmpty);
      expect(
        [...free, ...full].map((row) => row['id']).toSet(),
        hasLength(400),
      );
      final service = ContentService(storage);
      expect(await service.load('hot_potato'), hasLength(200));
      await storage.addPurchasedPack('pack_bomb_full');
      expect(await service.load('hot_potato'), hasLength(400));
    });
    test(
      'taboo loads 200 distinct cards per pack with five forbidden words',
      () async {
        final free = _readPack('assets/data/taboo/pack_free.json');
        final full = _readPack('assets/data/taboo/pack_full.json');
        String compact(String word) =>
            ContentService.normalize(word)
                .replaceAll(RegExp(r'[\s\u200c\u200d!؟?,.،-]'), '');
        final freeWords = free
            .map((row) => compact(row['word'] as String))
            .toSet();
        final fullWords = full
            .map((row) => compact(row['word'] as String))
            .toSet();
        expect(free, hasLength(200));
        expect(full, hasLength(200));
        expect(freeWords, hasLength(200));
        expect(fullWords, hasLength(200));
        expect(freeWords.intersection(fullWords), isEmpty);
        expect(
          [...free, ...full].map((row) => row['id']).toSet(),
          hasLength(400),
        );
        for (final card in [...free, ...full]) {
          final word = compact(card['word'] as String);
          final forbidden = (card['forbiddenWords'] as List).cast<String>();
          expect(forbidden, hasLength(5), reason: word);
          final forbiddenWords = forbidden.map(compact).toSet();
          expect(forbiddenWords, hasLength(5), reason: word);
          expect(forbiddenWords, isNot(contains('')), reason: word);
          expect(forbiddenWords, isNot(contains(word)), reason: word);
          expect(card['difficulty'], inInclusiveRange(1, 3), reason: word);
        }
        final service = ContentService(storage);
        expect(await service.load('taboo'), hasLength(200));
        await storage.addPurchasedPack('pack_taboo_full');
        expect(await service.load('taboo'), hasLength(400));
      },
    );
  });

  group('ContentService composition and validation', () {
    test('loads free content and unlocks only an owned pack plus compatible custom cards', () async {
      final bundle = _FixtureBundle({
        'assets/data/charades/pack_free.json': jsonEncode([
          _word('free', 'کتاب'),
        ]),
        'assets/data/charades/pack_full.json': jsonEncode([
          _word('full', 'دشت'),
        ]),
        'assets/data/drawing/pack_free.json': jsonEncode([
          _word('drawing-free', 'ابر'),
        ]),
        'assets/data/drawing/pack_full.json': jsonEncode([
          _word('drawing-full', 'خورشید'),
        ]),
      });
      await storage.saveCustomCards([
        {'id': 'custom-both', 'word': 'درخت', 'gameKey': 'both'},
        {'id': 'custom-charades', 'word': 'پرنده', 'gameKey': 'charades'},
        {'id': 'custom-drawing', 'word': 'دریا', 'gameKey': 'drawing'},
        {'id': 'wrong-game', 'word': 'wrong', 'gameKey': 'taboo'},
        {'id': 'blank', 'word': '  ', 'gameKey': 'both'},
        {'id': 'old-compatible', 'word': 'کوه'},
      ]);
      await storage.addPurchasedPack('pack_charades_full');
      await storage.addPurchasedPack('pack_future_game_full');
      final service = ContentService(storage, bundle: bundle);

      final charades = await service.load('charades');
      expect(
        charades.map((row) => row['id']),
        containsAll([
          'free',
          'full',
          'custom-both',
          'custom-charades',
          'old-compatible',
        ]),
      );
      expect(
        charades.map((row) => row['id']),
        isNot(contains('custom-drawing')),
      );
      expect(
        charades.firstWhere(
          (row) => row['id'] == 'custom-charades',
        )['category'],
        'کارت‌های من',
      );
      expect(charades.map((row) => row['id']), isNot(contains('wrong-game')));
      expect(charades.map((row) => row['id']), isNot(contains('blank')));

      final drawing = await service.load('drawing');
      expect(
        drawing.map((row) => row['id']),
        containsAll([
          'drawing-free',
          'custom-both',
          'custom-drawing',
          'old-compatible',
        ]),
      );
      expect(drawing.map((row) => row['id']), isNot(contains('drawing-full')));
    });

    test('deduplicates normalized primary words and rejects malformed or empty packs', () async {
      final bundle = _FixtureBundle({
        'assets/data/charades/pack_free.json': jsonEncode([
          _word('first', '  کتاب  '),
          _word('duplicate-normalized-word', 'کتاب'),
          _word('next', 'درخت'),
        ]),
        'assets/data/drawing/pack_free.json': '[]',
        'assets/data/taboo/pack_free.json': jsonEncode([
          {
            'id': 'bad-taboo',
            'word': 'مداد',
            'forbiddenWords': ['یک'],
          },
        ]),
      });
      final service = ContentService(storage, bundle: bundle);

      final deduplicated = await service.load('charades');
      expect(deduplicated.map((row) => row['id']), ['first', 'next']);
      await expectLater(service.load('drawing'), throwsFormatException);
      await expectLater(service.load('taboo'), throwsFormatException);
      await expectLater(service.load('unknown'), throwsArgumentError);
    });
  });
}

List<Map<String, dynamic>> _readPack(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync()) as List;
  return decoded.map((row) => Map<String, dynamic>.from(row as Map)).toList();
}

String _primaryField(String game) => switch (game) {
  'hot_potato' => 'topic',
  'five_seconds' => 'question',
  _ => 'word',
};

void _validatePack(String game, List<Map<String, dynamic>> pack) {
  final ids = <String>{};
  final field = _primaryField(game);
  for (final card in pack) {
    expect(card['id'], isA<String>());
    expect((card['id'] as String).trim(), isNotEmpty);
    expect(
      ids.add(card['id'] as String),
      isTrue,
      reason: '$game duplicate ID ${card['id']}',
    );
    expect(card[field], isA<String>());
    expect(
      (card[field] as String).trim(),
      isNotEmpty,
      reason: '${card['id']} empty $field',
    );
    if (game == 'taboo') {
      final forbidden = card['forbiddenWords'];
      expect(forbidden, isA<List>());
      expect(
        forbidden,
        hasLength(5),
        reason: '${card['id']} forbidden-word count',
      );
      expect(
        (forbidden as List).every((w) => w is String && w.trim().isNotEmpty),
        isTrue,
      );
    }
  }
}
