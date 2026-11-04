import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/charades/data/charades_word_model.dart';

void main() {
  group('JSON Content Validation Tests', () {
    test('visible prompts have no numbers or generated filler', () {
      const games = [
        'taboo',
        'hot_potato',
        'charades',
        'five_seconds',
        'drawing',
      ];
      final digits = RegExp(r'[0-9۰-۹٠-٩]');
      final filler = RegExp(r'شماره|موضوع بمب ساعتی دورهمی|در حال ');
      for (final game in games) {
        final field = game == 'hot_potato'
            ? 'topic'
            : game == 'five_seconds'
            ? 'question'
            : 'word';
        for (final pack in ['free', 'full']) {
          final rows = jsonDecode(
            File('assets/data/$game/pack_$pack.json').readAsStringSync(),
          ) as List;
          for (final row in rows) {
            final text = row[field] as String;
            expect(
              digits.hasMatch(text),
              isFalse,
              reason: '$game/$pack: $text',
            );
            expect(
              filler.hasMatch(text),
              isFalse,
              reason: '$game/$pack: $text',
            );
            if (game == 'taboo') {
              for (final forbidden in row['forbiddenWords'] as List) {
                expect(digits.hasMatch(forbidden as String), isFalse);
              }
            }
          }
        }
      }
    });

    test('charades prompts retain the points and difficulty in the pack', () {
      final categories = <String>{};
      for (final pack in ['free', 'full']) {
        final rows = jsonDecode(
          File('assets/data/charades/pack_$pack.json').readAsStringSync(),
        ) as List;
        for (final row in rows) {
          final word = row['word'] as String;
          expect(CharadesWord.isValid(word), isTrue, reason: word);
          final card = CharadesWord.fromJson(Map<String, dynamic>.from(row));
          expect(card.points, row['points'], reason: word);
          expect(card.difficulty, row['difficulty'], reason: word);
          categories.add(row['category'] as String);
        }
      }
      expect(categories.length, greaterThanOrEqualTo(8));
    });

    test(
      'Taboo pack has valid format and exactly 5 forbidden words per card',
      () {
        final file = File('assets/data/taboo/pack_free.json');
        expect(file.existsSync(), isTrue);
        final jsonList = jsonDecode(file.readAsStringSync()) as List;
        expect(jsonList.length, greaterThanOrEqualTo(20));

        final ids = <String>{};
        for (final item in jsonList) {
          final id = item['id'] as String;
          expect(ids.contains(id), isFalse, reason: 'Duplicate Taboo ID $id');
          ids.add(id);

          expect((item['word'] as String).trim().isNotEmpty, isTrue);
          final forbidden = (item['forbiddenWords'] as List);
          expect(
            forbidden.length,
            equals(5),
            reason: 'Card $id must have 5 forbidden words',
          );
          for (final f in forbidden) {
            expect((f as String).trim().isNotEmpty, isTrue);
          }
        }
      },
    );

    test('Hot Potato pack has valid topics and non-empty categories', () {
      final file = File('assets/data/hot_potato/pack_free.json');
      expect(file.existsSync(), isTrue);
      final jsonList = jsonDecode(file.readAsStringSync()) as List;
      expect(jsonList.length, greaterThanOrEqualTo(20));

      final ids = <String>{};
      for (final item in jsonList) {
        final id = item['id'] as String;
        expect(
          ids.contains(id),
          isFalse,
          reason: 'Duplicate Hot Potato ID $id',
        );
        ids.add(id);
        expect((item['topic'] as String).trim().isNotEmpty, isTrue);
      }
    });

    test('Charades pack has valid words and points between 1 and 3', () {
      final file = File('assets/data/charades/pack_free.json');
      expect(file.existsSync(), isTrue);
      final jsonList = jsonDecode(file.readAsStringSync()) as List;
      expect(jsonList.length, greaterThanOrEqualTo(20));

      final ids = <String>{};
      for (final item in jsonList) {
        final id = item['id'] as String;
        expect(ids.contains(id), isFalse, reason: 'Duplicate Charades ID $id');
        ids.add(id);
        expect((item['word'] as String).trim().isNotEmpty, isTrue);
        final points = item['points'] as int;
        expect(points, inInclusiveRange(1, 3));
      }
    });

    test('Five Seconds pack has valid questions', () {
      final file = File('assets/data/five_seconds/pack_free.json');
      expect(file.existsSync(), isTrue);
      final jsonList = jsonDecode(file.readAsStringSync()) as List;
      expect(jsonList.length, greaterThanOrEqualTo(20));

      final ids = <String>{};
      for (final item in jsonList) {
        final id = item['id'] as String;
        expect(
          ids.contains(id),
          isFalse,
          reason: 'Duplicate Five Seconds ID $id',
        );
        ids.add(id);
        expect((item['question'] as String).trim().isNotEmpty, isTrue);
      }
    });

    test('Drawing pack has valid words and difficulty ratings', () {
      final file = File('assets/data/drawing/pack_free.json');
      expect(file.existsSync(), isTrue);
      final jsonList = jsonDecode(file.readAsStringSync()) as List;
      expect(jsonList.length, greaterThanOrEqualTo(20));

      final ids = <String>{};
      for (final item in jsonList) {
        final id = item['id'] as String;
        expect(ids.contains(id), isFalse, reason: 'Duplicate Drawing ID $id');
        ids.add(id);
        expect((item['word'] as String).trim().isNotEmpty, isTrue);
      }
    });
  });
}
