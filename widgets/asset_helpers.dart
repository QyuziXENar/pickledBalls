import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';

// ============================================================================
// SAFE ASSET IMAGE LOADER
// ============================================================================
class AppAssetImage extends StatelessWidget {
  final String assetPath;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppAssetImage({
    super.key,
    required this.assetPath,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return fallback;
      },
    );
  }
}

// ============================================================================
// MULTI-CHANNEL LOW-LATENCY AUDIO CONTROLLER
// ============================================================================
class AppAudio {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _musicPlayer.audioCache.prefix = '';
    _sfxPlayer.audioCache.prefix = '';
    // Enable low-latency mode for rapid gameplay Foley
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    _initialized = true;
  }

  /// General audio playback (menus, intro, fanfare)
  static Future<void> play(BuildContext? context, String soundFile, String placeholderText) async {
    if (!GameState.instance.soundEnabled) return;

    _init();

    try {
      final isMusic = soundFile.contains('jingle') || soundFile.contains('intro') || soundFile.contains('battle_start');
      final folder = isMusic ? 'music' : 'sfx';

      final path = soundFile == 'canzed_intro.mp3'
          ? 'lib/assets/sounds/sfx/$soundFile'
          : 'lib/assets/sounds/$folder/$soundFile';

      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint('Audio playback note ($soundFile): $e');
    }
  }

  /// Dedicated high-speed in-game SFX (Paddle hit, ball bounce, buzzer)
  /// Safe: Never throws or crashes if the .mp3 file is missing!
  static Future<void> playSfx(String soundFile) async {
    if (!GameState.instance.soundEnabled) return;

    _init();

    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('lib/assets/sounds/sfx/$soundFile'));
    } catch (e) {
      debugPrint('SFX note ($soundFile): $e');
    }
  }

  static Future<void> stop() async {
    await _musicPlayer.stop();
    await _sfxPlayer.stop();
  }
}