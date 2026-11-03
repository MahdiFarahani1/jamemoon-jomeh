import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

enum GameSound {
  tap,
  start,
  reveal,
  correct,
  wrong,
  skip,
  timeUp,
  turn,
  win,
  lose,
  explosion,
  select,
  victory,
  tick,
  switchOn,
  switchOff,
}

/// A single effects channel with latest-event ordering and critical-cue priority.
class AudioService {
  final StorageService _storageService;
  AudioPlayer? _player;
  Future<void> _queue = Future.value();
  final Stopwatch _clock = Stopwatch()..start();
  int _generation = 0;
  int _protectedUntil = 0;
  int _lastSoftCue = -1000;
  bool _active = true;
  bool _disposed = false;
  AudioService(this._storageService);

  Future<void> play(GameSound cue) {
    final allowEvenIfMuted = cue == GameSound.switchOn;
    if (_disposed || !_active || (!_storageService.isSoundEnabled && !allowEvenIfMuted)) {
      return Future.value();
    }
    final now = _clock.elapsedMilliseconds;
    final soft = {
      GameSound.tap,
      GameSound.tick,
      GameSound.reveal,
      GameSound.select,
      GameSound.skip,
      GameSound.turn,
    }.contains(cue);
    if (soft && (now < _protectedUntil || now - _lastSoftCue < 65)) {
      return Future.value();
    }
    if (soft) _lastSoftCue = now;
    final file = switch (cue) {
      GameSound.explosion => 'boom',
      GameSound.victory || GameSound.win => 'victory',
      GameSound.wrong || GameSound.lose || GameSound.timeUp => 'buzzer',
      GameSound.correct || GameSound.start => 'correct',
      GameSound.switchOn => 'switch_on',
      GameSound.switchOff => 'switch_off',
      _ => 'tick',
    };
    if (!soft) {
      _protectedUntil =
          now +
          (file == 'victory'
              ? 1200
              : file == 'boom'
              ? 800
              : 350);
    }
    final ticket = ++_generation;
    _queue = _queue.then((_) async {
      if (ticket != _generation ||
          _disposed ||
          !_active ||
          (!_storageService.isSoundEnabled && !allowEvenIfMuted)) {
        return;
      }
      try {
        if (_player == null) {
          _player = AudioPlayer();
          await _player!.setAudioContext(
            AudioContext(
              android: const AudioContextAndroid(
                contentType: AndroidContentType.sonification,
                usageType: AndroidUsageType.game,
                audioFocus: AndroidAudioFocus.gainTransientMayDuck,
              ),
            ),
          );
        }
        await _player!.stop();
        if (ticket != _generation ||
            !_active ||
            !_storageService.isSoundEnabled) {
          return;
        }
        await _player!.play(
          AssetSource('sounds/$file.wav'),
          volume: file == 'boom'
              ? 0.7
              : file.startsWith('switch_')
              ? 0.32
              : 0.8,
        );
      } catch (error) {
        debugPrint('Sound unavailable: $error');
      }
    });
    return _queue;
  }

  Future<void> playTick() => play(GameSound.tick);
  Future<void> playBoom() => play(GameSound.explosion);
  Future<void> playBuzzer() => play(GameSound.timeUp);
  Future<void> playCorrect() => play(GameSound.correct);
  Future<void> playVictory() => play(GameSound.victory);
  Future<void> playTap() => play(GameSound.tap);
  Future<void> playReveal() => play(GameSound.reveal);
  Future<void> playTurn() => play(GameSound.turn);
  Future<void> playSkip() => play(GameSound.skip);
  Future<void> playStart() => play(GameSound.start);
  Future<void> playSwitch(bool enabled) =>
      play(enabled ? GameSound.switchOn : GameSound.switchOff);

  void setActive(bool active) {
    _active = active;
    if (!active) stop();
  }

  Future<void> stop() {
    ++_generation;
    _protectedUntil = 0;
    _queue = _queue.then((_) async {
      try {
        await _player?.stop();
      } catch (_) {}
    });
    return _queue;
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _player?.dispose();
    _clock.stop();
  }
}
