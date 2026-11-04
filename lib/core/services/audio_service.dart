import 'dart:async';

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

/// Separate channels keep important cues audible during rapid interaction.
class AudioService {
  static const effectsChannelId = 'party_effects_channel';
  static const softEffectsChannelId = 'party_ui_channel';
  static const bombChannelId = 'bomb_timer_channel';
  static const explosionChannelId = 'bomb_explosion_channel';
  static const musicChannelId = 'heist_music_channel';

  final StorageService _storageService;
  final AudioPlayer Function(String id) _playerFactory;
  final Map<String, int> _playerVersions = {};
  AudioPlayer? _effectsPlayer;
  AudioPlayer? _softEffectsPlayer;
  AudioPlayer? _bombPlayer;
  final Map<String, AudioPlayer> _bombPlayers = {};
  final Map<AudioPlayer, String> _preparedSources = {};
  AudioPlayer? _explosionPlayer;
  AudioPlayer? _musicPlayer;
  Future<void> _effectsQueue = Future.value();
  Future<void> _softEffectsQueue = Future.value();
  Future<void> _bombQueue = Future.value();
  Future<void> _explosionQueue = Future.value();
  Future<void> _musicQueue = Future.value();
  final Stopwatch _clock = Stopwatch()..start();
  int _effectsGeneration = 0;
  int _softEffectsGeneration = 0;
  int _bombGeneration = 0;
  int _explosionGeneration = 0;
  int _musicGeneration = 0;
  int _effectsCriticalPending = 0;
  int _explosionsPending = 0;
  bool _bombTickPending = false;
  int _effectsProtectedUntil = 0;
  int _bombProtectedUntil = 0;
  int _lastEffectsSoftCue = -1000;
  int _lastBombSoftCue = -1000;
  bool _active = true;
  bool _disposed = false;
  AudioService(
    this._storageService, {
    @visibleForTesting AudioPlayer Function(String id)? playerFactory,
  }) : _playerFactory = playerFactory ?? ((id) => AudioPlayer(playerId: id));

  AudioPlayer _newPlayer(String baseId) {
    final version = _playerVersions[baseId] ?? 0;
    _playerVersions[baseId] = version + 1;
    return _playerFactory(version == 0 ? baseId : '${baseId}_$version');
  }

  Future<AudioPlayer> _createEffectsPlayer(String id, PlayerMode mode) async {
    final player = _newPlayer(id);
    try {
      await player.setPlayerMode(mode).timeout(const Duration(seconds: 3));
      await player
          .setReleaseMode(ReleaseMode.stop)
          .timeout(const Duration(seconds: 3));
      await player
          .setAudioContext(
            AudioContext(
              android: const AudioContextAndroid(
                contentType: AndroidContentType.sonification,
                usageType: AndroidUsageType.game,
                audioFocus: AndroidAudioFocus.none,
              ),
            ),
          )
          .timeout(const Duration(seconds: 3));
      return player;
    } catch (_) {
      await _discardPlayer(player);
      rethrow;
    }
  }

  Future<void> _discardPlayer(AudioPlayer player) async {
    _preparedSources.remove(player);
    try {
      await player.dispose().timeout(const Duration(seconds: 1));
    } catch (_) {}
  }

  Future<void> _playPrepared(
    AudioPlayer player,
    String file,
    double volume,
    bool Function() canPlay,
  ) async {
    await player.stop().timeout(const Duration(seconds: 3));
    if (_preparedSources[player] != file) {
      await player
          .setSource(AssetSource('sounds/$file.wav'))
          .timeout(const Duration(seconds: 3));
      _preparedSources[player] = file;
    }
    await player.setVolume(volume).timeout(const Duration(seconds: 3));
    if (canPlay()) await player.resume().timeout(const Duration(seconds: 3));
  }

  Future<void> play(GameSound cue) {
    final allowEvenIfMuted =
        cue == GameSound.switchOn ||
        (cue == GameSound.switchOff && _storageService.isSoundEnabled);
    if (_disposed ||
        !_active ||
        (!_storageService.isSoundEnabled && !allowEvenIfMuted)) {
      return Future.value();
    }
    if (cue == GameSound.explosion) return _playExplosion();
    final isBombTick = {
      GameSound.tick,
      GameSound.tickTense,
      GameSound.tickCritical,
    }.contains(cue);
    final isBombChannel = isBombTick;
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
      if (now < protectedUntil ||
          now - lastSoftCue < 65 ||
          (isBombChannel && (_bombTickPending || _explosionsPending > 0)) ||
          (!isBombChannel && _effectsCriticalPending > 0)) {
        return Future.value();
      }
      if (isBombChannel) {
        _lastBombSoftCue = now;
      } else {
        _lastEffectsSoftCue = now;
      }
    }
    if (isBombTick) _bombTickPending = true;
    if (!soft) {
      _effectsCriticalPending++;
      ++_softEffectsGeneration;
      final softPlayer = _softEffectsPlayer;
      if (softPlayer != null) {
        unawaited(softPlayer.stop().catchError((Object _) {}));
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
    final ticket = isBombChannel
        ? ++_bombGeneration
        : soft
        ? ++_softEffectsGeneration
        : _effectsGeneration;
    final previousQueue = isBombChannel
        ? _bombQueue
        : soft
        ? _softEffectsQueue
        : _effectsQueue;
    final nextQueue = previousQueue.then((_) async {
      AudioPlayer? player;
      try {
        final currentGeneration = isBombChannel
            ? _bombGeneration
            : soft
            ? _softEffectsGeneration
            : _effectsGeneration;
        if (ticket != currentGeneration ||
            _disposed ||
            !_active ||
            (!_storageService.isSoundEnabled && !allowEvenIfMuted)) {
          return;
        }
        player = isBombChannel
            ? _bombPlayers[file]
            : soft
            ? _softEffectsPlayer
            : _effectsPlayer;
        if (player == null) {
          player = await _createEffectsPlayer(
            isBombChannel
                ? file == 'tick_calm'
                      ? bombChannelId
                      : '${bombChannelId}_$file'
                : soft
                ? softEffectsChannelId
                : effectsChannelId,
            PlayerMode.mediaPlayer,
          );
          if (isBombChannel) {
            _bombPlayers[file] = player;
          } else if (soft) {
            _softEffectsPlayer = player;
          } else {
            _effectsPlayer = player;
          }
        }
        if (isBombChannel) {
          final previous = _bombPlayer;
          _bombPlayer = player;
          if (previous != null && !identical(previous, player)) {
            await previous.stop().timeout(const Duration(seconds: 3));
          }
        }
        await _playPrepared(
          player,
          file,
          file.startsWith('switch_')
              ? 0.32
              : file == 'tick_calm'
              ? 0.38
              : file == 'tick_tense'
              ? 0.40
              : file == 'tick_critical'
              ? 0.42
              : 0.8,
          () =>
              ticket ==
                  (isBombChannel
                      ? _bombGeneration
                      : soft
                      ? _softEffectsGeneration
                      : _effectsGeneration) &&
              !_disposed &&
              _active &&
              (_storageService.isSoundEnabled || allowEvenIfMuted),
        );
        if (!soft) {
          _effectsProtectedUntil =
              _clock.elapsedMilliseconds + (file == 'victory' ? 1200 : 350);
        }
      } catch (error) {
        debugPrint('Sound unavailable: $error');
        if (player != null) {
          if (identical(_bombPlayer, player)) _bombPlayer = null;
          _bombPlayers.removeWhere((_, value) => identical(value, player));
          if (identical(_softEffectsPlayer, player)) _softEffectsPlayer = null;
          if (identical(_effectsPlayer, player)) _effectsPlayer = null;
          await _discardPlayer(player);
        }
      } finally {
        if (isBombTick) _bombTickPending = false;
        if (!soft) _effectsCriticalPending--;
      }
    });
    if (isBombChannel) {
      _bombQueue = nextQueue;
    } else if (soft) {
      _softEffectsQueue = nextQueue;
    } else {
      _effectsQueue = nextQueue;
    }
    return nextQueue;
  }

  Future<void> _playExplosion() {
    final ticket = ++_explosionGeneration;
    ++_bombGeneration;
    final tickPlayer = _bombPlayer;
    if (tickPlayer != null) {
      unawaited(tickPlayer.stop().catchError((Object _) {}));
    }
    _explosionsPending++;
    _bombProtectedUntil = _clock.elapsedMilliseconds + 1600;
    final next = _explosionQueue.then((_) async {
      AudioPlayer? player;
      try {
        if (ticket != _explosionGeneration ||
            _disposed ||
            !_active ||
            !_storageService.isSoundEnabled) {
          return;
        }
        player = _explosionPlayer ??= await _createEffectsPlayer(
          explosionChannelId,
          PlayerMode.mediaPlayer,
        );
        await _playPrepared(
          player,
          'boom',
          .82,
          () =>
              ticket == _explosionGeneration &&
              !_disposed &&
              _active &&
              _storageService.isSoundEnabled,
        );
        _bombProtectedUntil = _clock.elapsedMilliseconds + 1600;
      } catch (error) {
        debugPrint('Explosion sound unavailable: $error');
        if (player != null) {
          if (identical(_explosionPlayer, player)) _explosionPlayer = null;
          await _discardPlayer(player);
        }
      } finally {
        _explosionsPending--;
      }
    });
    _explosionQueue = next;
    return next;
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

  Future<void> playHeistMusic({required bool tension}) {
    if (_disposed || !_active || !_storageService.isMusicEnabled) {
      return Future.value();
    }
    final ticket = ++_musicGeneration;
    final next = _musicQueue.then((_) async {
      AudioPlayer? player;
      try {
        if (ticket != _musicGeneration ||
            _disposed ||
            !_active ||
            !_storageService.isMusicEnabled) {
          return;
        }
        player = _musicPlayer ??= _newPlayer(musicChannelId);
        await player
            .setReleaseMode(ReleaseMode.loop)
            .timeout(const Duration(seconds: 3));
        await player
            .setAudioContext(
              AudioContext(
                android: const AudioContextAndroid(
                  contentType: AndroidContentType.music,
                  usageType: AndroidUsageType.game,
                  audioFocus: AndroidAudioFocus.none,
                ),
              ),
            )
            .timeout(const Duration(seconds: 3));
        await player.stop().timeout(const Duration(seconds: 3));
        if (ticket != _musicGeneration ||
            _disposed ||
            !_active ||
            !_storageService.isMusicEnabled) {
          return;
        }
        await player
            .play(
              AssetSource(
                'sounds/${tension ? 'heist_tension' : 'heist_planning'}.wav',
              ),
              volume: tension ? .22 : .18,
            )
            .timeout(const Duration(seconds: 3));
      } catch (error) {
        debugPrint('Music unavailable: $error');
        if (player != null) {
          if (identical(_musicPlayer, player)) _musicPlayer = null;
          await _discardPlayer(player);
        }
      }
    });
    _musicQueue = next;
    return next;
  }

  Future<void> stopMusic() {
    ++_musicGeneration;
    _musicQueue = _musicQueue.then((_) async {
      try {
        await _musicPlayer?.stop().timeout(const Duration(seconds: 3));
      } catch (_) {}
    });
    return _musicQueue;
  }

  void setActive(bool active) {
    _active = active;
    if (!active) {
      unawaited(stop());
      unawaited(stopMusic());
    }
  }

  Future<void> stop() {
    ++_effectsGeneration;
    ++_softEffectsGeneration;
    ++_bombGeneration;
    ++_explosionGeneration;
    _effectsProtectedUntil = 0;
    _bombProtectedUntil = 0;
    _effectsQueue = _effectsQueue.then((_) async {
      try {
        await _effectsPlayer?.stop();
      } catch (_) {}
    });
    _bombQueue = _bombQueue.then((_) async {
      try {
        for (final player in _bombPlayers.values) {
          await player.stop().timeout(const Duration(seconds: 3));
        }
      } catch (_) {}
    });
    _softEffectsQueue = _softEffectsQueue.then((_) async {
      try {
        await _softEffectsPlayer?.stop().timeout(const Duration(seconds: 3));
      } catch (_) {}
    });
    _explosionQueue = _explosionQueue.then((_) async {
      try {
        await _explosionPlayer?.stop().timeout(const Duration(seconds: 3));
      } catch (_) {}
    });
    return Future.wait<void>([
      _effectsQueue,
      _softEffectsQueue,
      _bombQueue,
      _explosionQueue,
    ]);
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await stopMusic();
    await _effectsPlayer?.dispose();
    await _softEffectsPlayer?.dispose();
    for (final player in _bombPlayers.values) {
      await player.dispose();
    }
    await _explosionPlayer?.dispose();
    await _musicPlayer?.dispose();
    _clock.stop();
  }
}
