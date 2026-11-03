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
    const games = ['taboo', 'hot_potato', 'charades', 'five_seconds', 'drawing'];

    test('each supported game contains 20 free and 20 full unique cards', () {
      for (final game in games) {
        final free = _readPack('assets/data/$game/pack_free.json');
        final full = _readPack('assets/data/$game/pack_full.json');
        expect(free, hasLength(20), reason: '$game free pack');
        expect(full, hasLength(20), reason: '$game full pack');
        _validatePack(game, free);
        _validatePack(game, full);
        final primary = _primaryField(game);
        final normalizedFree = free.map((row) => ContentService.normalize(row[primary] as String)).toSet();
        final normalizedFull = full.map((row) => ContentService.normalize(row[primary] as String)).toSet();
        expect(normalizedFree, hasLength(free.length), reason: '$game free normalized duplicates');
        expect(normalizedFull, hasLength(full.length), reason: '$game full normalized duplicates');
        expect(normalizedFree.intersection(normalizedFull), isEmpty, reason: '$game overlaps free/full');
      }
      expect(ContentService.productIds.keys, unorderedEquals(games));
      expect(ContentService.productIds, isNot(contains('decoder')));
    });
  });

  group('ContentService composition and validation', () {
    test('loads free content and unlocks only an owned pack plus compatible custom cards', () async {
      final bundle = _FixtureBundle({
        'assets/data/charades/pack_free.json': jsonEncode([_word('free', 'کتاب')]),
        'assets/data/charades/pack_full.json': jsonEncode([_word('full', 'باران')]),
        'assets/data/drawing/pack_free.json': jsonEncode([_word('drawing-free', 'ابر')]),
        'assets/data/drawing/pack_full.json': jsonEncode([_word('drawing-full', 'خورشید')]),
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
      expect(charades.map((row) => row['id']), containsAll([
        'free', 'full', 'custom-both', 'custom-charades', 'old-compatible',
      ]));
      expect(charades.map((row) => row['id']), isNot(contains('custom-drawing')));
      expect(charades.map((row) => row['id']), isNot(contains('wrong-game')));
      expect(charades.map((row) => row['id']), isNot(contains('blank')));

      final drawing = await service.load('drawing');
      expect(drawing.map((row) => row['id']), containsAll([
        'drawing-free', 'custom-both', 'custom-drawing', 'old-compatible',
      ]));
      expect(drawing.map((row) => row['id']), isNot(contains('drawing-full')));
    });

    test('deduplicates normalized primary words and rejects malformed or empty packs', () async {
      final bundle = _FixtureBundle({
        'assets/data/charades/pack_free.json': jsonEncode([
          _word('first', '  کتاب  '),
          _word('duplicate-normalized-word', 'کتاب'),
          _word('next', 'باران'),
        ]),
        'assets/data/drawing/pack_free.json': '[]',
        'assets/data/taboo/pack_free.json': jsonEncode([
          {'id': 'bad-taboo', 'word': 'مداد', 'forbiddenWords': ['یک']},
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
    expect(ids.add(card['id'] as String), isTrue, reason: '$game duplicate ID ${card['id']}');
    expect(card[field], isA<String>());
    expect((card[field] as String).trim(), isNotEmpty, reason: '${card['id']} empty $field');
    if (game == 'taboo') {
      final forbidden = card['forbiddenWords'];
      expect(forbidden, isA<List>());
      expect(forbidden, hasLength(5), reason: '${card['id']} forbidden-word count');
      expect((forbidden as List).every((w) => w is String && w.trim().isNotEmpty), isTrue);
    }
  }
}
