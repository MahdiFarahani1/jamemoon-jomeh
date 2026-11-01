import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JSON Content Validation Tests', () {
    test('Taboo pack has valid format and exactly 5 forbidden words per card', () {
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
        expect(forbidden.length, equals(5), reason: 'Card $id must have 5 forbidden words');
        for (final f in forbidden) {
          expect((f as String).trim().isNotEmpty, isTrue);
        }
      }
    });

    test('Hot Potato pack has valid topics and non-empty categories', () {
      final file = File('assets/data/hot_potato/pack_free.json');
      expect(file.existsSync(), isTrue);
      final jsonList = jsonDecode(file.readAsStringSync()) as List;
      expect(jsonList.length, greaterThanOrEqualTo(20));

      final ids = <String>{};
      for (final item in jsonList) {
        final id = item['id'] as String;
        expect(ids.contains(id), isFalse, reason: 'Duplicate Hot Potato ID $id');
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
        expect(ids.contains(id), isFalse, reason: 'Duplicate Five Seconds ID $id');
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

