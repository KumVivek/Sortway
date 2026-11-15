import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Sfx { tap, correct, wrong, win, lose, coin, sticker }

abstract class AudioService {
  bool soundOn = true;
  bool musicOn = true;

  Future<void> preload();
  void play(Sfx sfx);
  void startMusic();
  void stopMusic();
  void pauseMusic();
  void resumeMusic();
}

class FlameAudioService extends AudioService {
  bool _musicPlaying = false;

  @override
  Future<void> preload() async {
    try {
      await FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([
        for (final s in Sfx.values) '${s.name}.wav',
        'music.wav',
      ]);
    } on Object catch (e) {
      debugPrint('audio preload failed: $e');
    }
  }

  @override
  void play(Sfx sfx) {
    if (!soundOn) return;
    FlameAudio.play('${sfx.name}.wav', volume: 0.8).catchError((Object e) {
      debugPrint('sfx failed: $e');
      return FlameAudio.bgm.audioPlayer;
    });
  }

  @override
  void startMusic() {
    if (!musicOn || _musicPlaying) return;
    _musicPlaying = true;
    FlameAudio.bgm.play('music.wav', volume: 0.35).catchError((Object e) {
      _musicPlaying = false;
      debugPrint('music failed: $e');
    });
  }

  @override
  void stopMusic() {
    _musicPlaying = false;
    FlameAudio.bgm.stop().catchError((Object _) {});
  }

  @override
  void pauseMusic() {
    if (_musicPlaying) FlameAudio.bgm.pause().catchError((Object _) {});
  }

  @override
  void resumeMusic() {
    if (_musicPlaying && musicOn) {
      FlameAudio.bgm.resume().catchError((Object _) {});
    }
  }
}

/// Fake: records what would have played.
class SilentAudioService extends AudioService {
  final List<Sfx> played = [];
  bool musicStarted = false;

  @override
  Future<void> preload() async {}
  @override
  void play(Sfx sfx) {
    if (soundOn) played.add(sfx);
  }

  @override
  void startMusic() => musicStarted = musicOn;
  @override
  void stopMusic() => musicStarted = false;
  @override
  void pauseMusic() {}
  @override
  void resumeMusic() {}
}

enum Haptic { light, success, error }

abstract class HapticsService {
  bool enabled = true;
  void fire(Haptic h);
}

class DeviceHapticsService extends HapticsService {
  @override
  void fire(Haptic h) {
    if (!enabled) return;
    switch (h) {
      case Haptic.light:
        HapticFeedback.selectionClick();
      case Haptic.success:
        HapticFeedback.lightImpact();
      case Haptic.error:
        HapticFeedback.heavyImpact();
    }
  }
}

class FakeHapticsService extends HapticsService {
  final List<Haptic> fired = [];

  @override
  void fire(Haptic h) {
    if (enabled) fired.add(h);
  }
}
