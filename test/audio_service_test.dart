import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';
import 'package:flutter_application_1/features/settings/presentation/cubit/settings_cubit.dart';

class _FakePlayer implements AudioPlayer {
  _FakePlayer(this.id, this.events, {this.onPlay});
  final String id;
  final List<String> events;
  final Future<void> Function(String path)? onPlay;
  String? sourcePath;

  @override
  Future<void> setPlayerMode(PlayerMode mode) async {}
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {}
  @override
  Future<void> setAudioContext(AudioContext context) async {}
  @override
  Future<void> setSource(Source source) async {
    sourcePath = (source as AssetSource).path;
    events.add('$id:prepare:$sourcePath');
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> resume() async {
    final path = sourcePath!;
    events.add('$id:$path');
    await onPlay?.call(path);
  }

  @override
  Future<void> stop() async => events.add('$id:stop');
  @override
  Future<void> dispose() async => events.add('$id:dispose');
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    final path = (source as AssetSource).path;
    events.add('$id:$path');
    await onPlay?.call(path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('explosion plays even when a tick is still preparing', () async {
    final events = <String>[];
    final tickStarted = Completer<void>();
    final finishTick = Completer<void>();
    final audio = AudioService(
      StorageService(),
      playerFactory: (id) => _FakePlayer(
        id,
        events,
        onPlay: (path) async {
          if (id == AudioService.bombChannelId) {
            tickStarted.complete();
            await finishTick.future;
          }
        },
      ),
    );

    final tick = audio.playTick();
    await tickStarted.future;
    await audio.playTick();
    await audio.playBoom().timeout(const Duration(seconds: 1));
    expect(
      events,
      contains('${AudioService.explosionChannelId}:sounds/boom.wav'),
    );
    expect(
      events.where(
        (event) =>
            event == '${AudioService.bombChannelId}:sounds/tick_calm.wav',
      ),
      hasLength(1),
    );
    finishTick.complete();
    await tick;
    await audio.dispose();
  });

  test('a slow important sound is not displaced by a button tap', () async {
    final events = <String>[];
    final started = Completer<void>();
    final finish = Completer<void>();
    final audio = AudioService(
      StorageService(),
      playerFactory: (id) => _FakePlayer(
        id,
        events,
        onPlay: (path) async {
          if (path == 'sounds/correct.wav') {
            started.complete();
            await finish.future;
          }
        },
      ),
    );
    final correct = audio.playCorrect();
    await started.future;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await audio.playTap();
    finish.complete();
    await correct;
    expect(
      events,
      contains('${AudioService.effectsChannelId}:sounds/correct.wav'),
    );
    expect(
      events.where((event) => event.endsWith('sounds/select.wav')),
      isEmpty,
    );
    await audio.dispose();
  });

  test('a slow button sound cannot delay an important game sound', () async {
    final events = <String>[];
    final tapStarted = Completer<void>();
    final finishTap = Completer<void>();
    final audio = AudioService(
      StorageService(),
      playerFactory: (id) => _FakePlayer(
        id,
        events,
        onPlay: (path) async {
          if (path == 'sounds/select.wav') {
            tapStarted.complete();
            await finishTap.future;
          }
        },
      ),
    );
    final tap = audio.playTap();
    await tapStarted.future;
    await audio.playCorrect().timeout(const Duration(seconds: 1));
    expect(
      events,
      contains('${AudioService.effectsChannelId}:sounds/correct.wav'),
    );
    finishTap.complete();
    await tap;
    await audio.dispose();
  });

  test(
    'important sounds requested together are not silently discarded',
    () async {
      final events = <String>[];
      final audio = AudioService(
        StorageService(),
        playerFactory: (id) => _FakePlayer(id, events),
      );
      await Future.wait([
        audio.playStart(),
        audio.playCorrect(),
        audio.playBuzzer(),
      ]);
      expect(
        events.where(
          (event) =>
              event == '${AudioService.effectsChannelId}:sounds/start.wav',
        ),
        hasLength(1),
      );
      expect(
        events.where(
          (event) =>
              event == '${AudioService.effectsChannelId}:sounds/correct.wav',
        ),
        hasLength(1),
      );
      expect(
        events.where(
          (event) =>
              event == '${AudioService.effectsChannelId}:sounds/buzzer.wav',
        ),
        hasLength(1),
      );
      await audio.dispose();
    },
  );

  test(
    'each bomb tick sound is prepared once and reused after transitions',
    () async {
      final events = <String>[];
      final audio = AudioService(
        StorageService(),
        playerFactory: (id) => _FakePlayer(id, events),
      );
      for (final tension in [.1, .6, .9, .1, .6, .9]) {
        await Future<void>.delayed(const Duration(milliseconds: 70));
        await audio.playBombTick(tension);
      }
      for (final name in ['tick_calm', 'tick_tense', 'tick_critical']) {
        expect(
          events.where((event) => event.endsWith(':prepare:sounds/$name.wav')),
          hasLength(1),
        );
        expect(
          events.where(
            (event) =>
                event.endsWith(':sounds/$name.wav') &&
                !event.contains(':prepare:'),
          ),
          hasLength(2),
        );
      }
      await audio.dispose();
    },
  );

  test('a player failure is disposed and the next sound retries', () async {
    final events = <String>[];
    var attempts = 0;
    final audio = AudioService(
      StorageService(),
      playerFactory: (id) {
        final attempt = ++attempts;
        return _FakePlayer(
          id,
          events,
          onPlay: (_) async {
            if (attempt == 1) throw StateError('test failure');
          },
        );
      },
    );
    await audio.playCorrect();
    await audio.playBuzzer();
    expect(attempts, 2);
    expect(events, contains('${AudioService.effectsChannelId}:dispose'));
    expect(
      events,
      contains('${AudioService.effectsChannelId}_1:sounds/buzzer.wav'),
    );
    await audio.dispose();
  });

  testWidgets('a stalled player times out and the next sound retries', (
    tester,
  ) async {
    final events = <String>[];
    final finish = Completer<void>();
    var attempts = 0;
    final audio = AudioService(
      StorageService(),
      playerFactory: (id) {
        final attempt = ++attempts;
        return _FakePlayer(
          id,
          events,
          onPlay: (_) => attempt == 1 ? finish.future : Future.value(),
        );
      },
    );

    final first = audio.playCorrect();
    await tester.pump();
    expect(
      events,
      contains('${AudioService.effectsChannelId}:sounds/correct.wav'),
    );
    await tester.pump(const Duration(seconds: 4));
    await first;
    final second = audio.playBuzzer();
    await tester.pump();
    await second;
    expect(
      events,
      contains('${AudioService.effectsChannelId}_1:sounds/buzzer.wav'),
    );
    finish.complete();
    await tester.pump();
    await audio.dispose();
  });

  test(
    'sound switch feedback survives the change to the mute setting',
    () async {
      final events = <String>[];
      final storage = StorageService();
      await storage.setSoundEnabled(false);
      final audio = AudioService(
        storage,
        playerFactory: (id) => _FakePlayer(id, events),
      );
      await audio.playSwitch(true);
      expect(
        events,
        contains('${AudioService.effectsChannelId}:sounds/switch_on.wav'),
      );

      await storage.setSoundEnabled(true);
      final off = audio.playSwitch(false);
      await storage.setSoundEnabled(false);
      await off;
      expect(
        events,
        contains('${AudioService.effectsChannelId}:sounds/switch_off.wav'),
      );
      await audio.playCorrect();
      expect(
        events.where((event) => event.endsWith('sounds/correct.wav')),
        isEmpty,
      );
      await audio.dispose();
    },
  );

  test('stopping music while it loads leaves the player stopped', () async {
    final events = <String>[];
    final started = Completer<void>();
    final finish = Completer<void>();
    final audio = AudioService(
      StorageService(),
      playerFactory: (id) => _FakePlayer(
        id,
        events,
        onPlay: (_) async {
          started.complete();
          await finish.future;
        },
      ),
    );
    final playing = audio.playHeistMusic(tension: true);
    await started.future;
    final stopped = audio.stopMusic();
    finish.complete();
    await playing;
    await stopped;
    expect(events.last, '${AudioService.musicChannelId}:stop');
    await audio.dispose();
  });

  test('reset restores music setting both in memory and storage', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    final settings = SettingsCubit(storage);
    await settings.toggleMusic();
    expect(storage.isMusicEnabled, false);
    await settings.resetAll();
    expect(settings.state.musicEnabled, true);
    expect(storage.isMusicEnabled, true);
    await settings.close();
  });
}
