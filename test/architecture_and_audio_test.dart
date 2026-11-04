import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('game pages keep gameplay state out of setState', () {
    final pages = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('game_page.dart'));

    expect(pages, isNotEmpty);
    for (final page in pages) {
      expect(
        page.readAsStringSync(),
        isNot(contains('setState(')),
        reason: '${page.path} must delegate gameplay state to its Cubit',
      );
    }
  });

  test('bomb fuse has escalating cues and a full explosion tail', () {
    for (final name in const [
      'tick_calm.wav',
      'tick_tense.wav',
      'tick_critical.wav',
    ]) {
      final file = File('assets/sounds/$name');
      expect(file.existsSync(), isTrue, reason: '$name is missing');
      expect(file.lengthSync(), greaterThan(5000));
    }
    expect(File('assets/sounds/boom.wav').lengthSync(), greaterThan(100000));
  });

  test(
    'bomb timer and ordinary effects use independent native players',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService(await SharedPreferences.getInstance());
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (_) async => null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (call) async {
          calls.add(call);
          if (call.method == 'getDuration' ||
              call.method == 'getCurrentPosition') {
            return 0;
          }
          return null;
        },
      );
      for (final id in const [
        AudioService.bombChannelId,
        AudioService.effectsChannelId,
      ]) {
        messenger.setMockMethodCallHandler(
          MethodChannel('xyz.luan/audioplayers/events/$id'),
          (_) async => null,
        );
      }

      final audio = AudioService(storage);
      await audio.playTick();
      // A turn cue is deliberately fired in the same 65 ms window. It must
      // not be throttled by the bomb channel's soft-cue limiter.
      await audio.playTurn();

      final createdIds = calls
          .where((call) => call.method == 'create')
          .map((call) => (call.arguments as Map)['playerId'])
          .toSet();
      expect(createdIds, {
        AudioService.bombChannelId,
        AudioService.effectsChannelId,
      });

      await audio.dispose();
      messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        null,
      );
    },
  );
}
