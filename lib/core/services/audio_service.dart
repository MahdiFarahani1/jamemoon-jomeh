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
  tickTense,
  tickCritical,
  switchOn,
  switchOff,
  heistAlarm,
  heistVault,
  heistCash,
  heistBetrayal,
}

/// A single effects channel with latest-event ordering and critical-cue priority.
class AudioService {
  static const effectsChannelId = 'party_effects_channel';
  static const bombChannelId = 'bomb_timer_channel';
  static const musicChannelId = 'heist_music_channel';

  final StorageService _storageService;
  AudioPlayer? _effectsPlayer;
  AudioPlayer? _bombPlayer;
  AudioPlayer? _musicPlayer;
  Future<void> _effectsQueue = Future.value();
  Future<void> _bombQueue = Future.value();
  final Stopwatch _clock = Stopwatch()..start();
  int _effectsGeneration = 0;
  int _bombGeneration = 0;
  int _effectsProtectedUntil = 0;
  int _bombProtectedUntil = 0;
  int _lastEffectsSoftCue = -1000;
  int _lastBombSoftCue = -1000;
  bool _active = true;
  bool _disposed = false;
  AudioService(this._storageService);

  Future<void> play(GameSound cue) {
    final allowEvenIfMuted = cue == GameSound.switchOn;
    if (_disposed ||
        !_active ||
        (!_storageService.isSoundEnabled && !allowEvenIfMuted)) {
      return Future.value();
    }
    final isBombTick = {
      GameSound.tick,
      GameSound.tickTense,
      GameSound.tickCritical,
    }.contains(cue);
    final isBombChannel = isBombTick || cue == GameSound.explosion;
    final now = _clock.elapsedMilliseconds;
    final soft = {
      GameSound.tap,
      GameSound.tick,
      GameSound.tickTense,
      GameSound.tickCritical,
      GameSound.reveal,
      GameSound.select,
      GameSound.skip,
      GameSound.turn,
    }.contains(cue);
    if (soft) {
      final protectedUntil = isBombChannel
          ? _bombProtectedUntil
          : _effectsProtectedUntil;
      final lastSoftCue = isBombChannel
          ? _lastBombSoftCue
          : _lastEffectsSoftCue;
      if (now < protectedUntil || now - lastSoftCue < 65) {
        return Future.value();
      }
      if (isBombChannel) {
        _lastBombSoftCue = now;
      } else {
        _lastEffectsSoftCue = now;
      }
    }
    final file = switch (cue) {
      GameSound.explosion => 'boom',
      GameSound.victory || GameSound.win => 'victory',
      GameSound.wrong || GameSound.lose || GameSound.timeUp => 'buzzer',
      GameSound.correct => 'correct',
      GameSound.switchOn => 'switch_on',
      GameSound.switchOff => 'switch_off',
      GameSound.select || GameSound.tap => 'select',
      GameSound.start => 'start',
      GameSound.reveal => 'reveal',
      GameSound.skip => 'skip',
      GameSound.turn => 'turn',
      GameSound.tick => 'tick_calm',
      GameSound.tickTense => 'tick_tense',
      GameSound.tickCritical => 'tick_critical',
      GameSound.heistAlarm => 'heist_alarm',
      GameSound.heistVault => 'heist_vault',
      GameSound.heistCash => 'heist_cash',
      GameSound.heistBetrayal => 'heist_betrayal',
    };
    if (!soft) {
      final protectedUntil =
          now +
          (file == 'victory'
              ? 1200
              : file == 'boom'
              ? 1600
              : 350);
      if (isBombChannel) {
        _bombProtectedUntil = protectedUntil;
      } else {
        _effectsProtectedUntil = protectedUntil;
      }
    }
    final ticket = isBombChannel ? ++_bombGeneration : ++_effectsGeneration;
    final previousQueue = isBombChannel ? _bombQueue : _effectsQueue;
    final nextQueue = previousQueue.then((_) async {
      final currentGeneration = isBombChannel
          ? _bombGeneration
          : _effectsGeneration;
      if (ticket != currentGeneration ||
          _disposed ||
          !_active ||
          (!_storageService.isSoundEnabled && !allowEvenIfMuted)) {
        return;
      }
      try {
        var player = isBombChannel ? _bombPlayer : _effectsPlayer;
        if (player == null) {
          player = AudioPlayer(
            playerId: isBombChannel ? bombChannelId : effectsChannelId,
          );
          await player.setPlayerMode(
            isBombTick ? PlayerMode.lowLatency : PlayerMode.mediaPlayer,
          );
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setAudioContext(
            AudioContext(
              android: const AudioContextAndroid(
                contentType: AndroidContentType.sonification,
                usageType: AndroidUsageType.game,
                // Both in-app channels must be allowed to overlap. Requesting
                // focus per player can pause the bomb fuse when a UI cue plays.
                audioFocus: AndroidAudioFocus.none,
              ),
            ),
          );
          if (isBombChannel) {
            _bombPlayer = player;
          } else {
            _effectsPlayer = player;
          }
        }
        await player.stop();
        final latestGeneration = isBombChannel
            ? _bombGeneration
            : _effectsGeneration;
        if (ticket != latestGeneration ||
            !_active ||
            !_storageService.isSoundEnabled) {
          return;
        }
        await player.play(
          AssetSource('sounds/$file.wav'),
          volume: file == 'boom'
              ? 0.82
              : file.startsWith('switch_')
              ? 0.32
              : file == 'tick_calm'
              ? 0.42
              : file == 'tick_tense'
              ? 0.54
              : file == 'tick_critical'
              ? 0.64
              : 0.8,
        );
      } catch (error) {
        debugPrint('Sound unavailable: $error');
      }
    });
    if (isBombChannel) {
      _bombQueue = nextQueue;
    } else {
      _effectsQueue = nextQueue;
    }
    return nextQueue;
  }

  Future<void> playTick() => play(GameSound.tick);
  Future<void> playBombTick(double tension) => play(
    tension >= .82
        ? GameSound.tickCritical
        : tension >= .52
        ? GameSound.tickTense
        : GameSound.tick,
  );
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

  Future<void> playHeistMusic({required bool tension}) async {
    if (_disposed || !_active || !_storageService.isMusicEnabled) return;
    try {
      _musicPlayer ??= AudioPlayer(playerId: musicChannelId);
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer!.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
      await _musicPlayer!.stop();
      await _musicPlayer!.play(
        AssetSource(
          'sounds/${tension ? 'heist_tension' : 'heist_planning'}.wav',
        ),
        volume: tension ? .22 : .18,
      );
    } catch (error) {
      debugPrint('Music unavailable: $error');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer?.stop();
    } catch (_) {}
  }

  void setActive(bool active) {
    _active = active;
    if (!active) stop();
  }

  Future<void> stop() {
    ++_effectsGeneration;
    ++_bombGeneration;
    _effectsProtectedUntil = 0;
    _bombProtectedUntil = 0;
    _effectsQueue = _effectsQueue.then((_) async {
      try {
        await _effectsPlayer?.stop();
      } catch (_) {}
    });
    _bombQueue = _bombQueue.then((_) async {
      try {
        await _bombPlayer?.stop();
      } catch (_) {}
    });
    return Future.wait<void>([_effectsQueue, _bombQueue]);
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _effectsPlayer?.dispose();
    await _bombPlayer?.dispose();
    await _musicPlayer?.dispose();
    _clock.stop();
  }
}
