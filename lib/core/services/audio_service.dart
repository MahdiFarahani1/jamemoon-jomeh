import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

// Audio management for party game sound effects
class AudioService {
  final StorageService _storageService;
  final AudioPlayer _player = AudioPlayer();

  AudioService(this._storageService) {
    // Configure player mode for low latency sound effects
    _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  Future<void> playTick() async {
    await _playSound('sounds/tick.wav');
  }

  Future<void> playBoom() async {
    await _playSound('sounds/boom.wav');
  }

  Future<void> playBuzzer() async {
    await _playSound('sounds/buzzer.wav');
  }

  Future<void> playCorrect() async {
    await _playSound('sounds/correct.wav');
  }

  Future<void> playVictory() async {
    await _playSound('sounds/victory.wav');
  }

  Future<void> _playSound(String assetRelativePath) async {
    if (!_storageService.isSoundEnabled) return;
    try {
      // audioplayers AssetSource resolves from the assets folder
      await _player.stop();
      await _player.play(AssetSource(assetRelativePath));
    } catch (e) {
      debugPrint('Audio playback error for $assetRelativePath: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}

