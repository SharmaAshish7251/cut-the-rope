import 'package:flutter/widgets.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:logger/logger.dart';

/// Centralized audio controller handling background music and sound effects.
class AudioService with WidgetsBindingObserver {
  bool _musicEnabled = true;
  bool _soundEnabled = true;
  bool _pausedByBackground = false;
  final _log = Logger();

  AudioService() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      // App went to background -> pause BGM sound!
      if (_musicEnabled) {
        _pausedByBackground = true;
        pauseBgMusic();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground -> resume BGM sound!
      if (_pausedByBackground && _musicEnabled) {
        _pausedByBackground = false;
        resumeBgMusic();
      }
    }
  }

  static const String bgmMain = 'music/main_theme.wav';
  static const String sfxRopeCut = 'sfx/rope_cut.wav';
  static const String sfxStarCollect = 'sfx/star_collect.wav';
  static const String sfxNomNom = 'sfx/nom_nom.wav';
  static const String sfxLevelComplete = 'sfx/level_complete.wav';
  static const String sfxLevelFail = 'sfx/level_fail.wav';
  static const String sfxBoosterUse = 'sfx/booster_use.wav';
  static const String sfxBubblePop = 'sfx/bubble_pop.wav';
  static const String sfxUiClick = 'sfx/ui_click.wav';

  bool get musicEnabled => _musicEnabled;
  bool get soundEnabled => _soundEnabled;

  /// Update audio settings and pause/resume BGM accordingly.
  void configure({required bool music, required bool sound}) {
    final oldMusic = _musicEnabled;
    _musicEnabled = music;
    _soundEnabled = sound;

    if (oldMusic && !music) {
      stopBgMusic();
    } else if (!oldMusic && music) {
      startBgm();
    }
  }

  // ── Background Music ────────────────────────────────────────────────────────

  Future<void> startBgm({String filename = bgmMain, double volume = 0.45}) async {
    if (!_musicEnabled) return;
    try {
      await FlameAudio.bgm.play(filename, volume: volume);
    } catch (e) {
      _log.w('Could not play music: $filename', error: e);
    }
  }

  Future<void> stopBgMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  Future<void> pauseBgMusic() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (_) {}
  }

  Future<void> resumeBgMusic() async {
    if (!_musicEnabled) return;
    try {
      await FlameAudio.bgm.resume();
    } catch (_) {}
  }

  // ── Sound Effects ──────────────────────────────────────────────────────────

  Future<void> playSfx(String filename, {double volume = 1.0}) async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(filename, volume: volume);
    } catch (e) {
      _log.w('Could not play sfx: $filename', error: e);
    }
  }

  Future<void> playRopeCut() => playSfx(sfxRopeCut, volume: 0.9);
  Future<void> playStarCollect() => playSfx(sfxStarCollect, volume: 1.0);
  Future<void> playNomNom() => playSfx(sfxNomNom, volume: 0.95);
  Future<void> playLevelComplete() => playSfx(sfxLevelComplete, volume: 1.0);
  Future<void> playLevelFail() => playSfx(sfxLevelFail, volume: 0.85);
  Future<void> playBooster() => playSfx(sfxBoosterUse, volume: 0.9);
  Future<void> playBubblePop() => playSfx(sfxBubblePop, volume: 0.85);
  Future<void> playUiClick() => playSfx(sfxUiClick, volume: 0.7);

  void toggleMusic() {
    configure(music: !_musicEnabled, sound: _soundEnabled);
  }

  void toggleSound() {
    configure(music: _musicEnabled, sound: !_soundEnabled);
  }
}
