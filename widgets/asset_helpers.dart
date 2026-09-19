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
// REAL AUDIO CONTROLLER (POWERED BY AUDIOPLAYERS)
// ============================================================================
class AppAudio {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    // Clears the default 'assets/' prefix so it looks inside 'lib/assets/'
    _player.audioCache.prefix = '';
    _initialized = true;
  }

  static Future<void> play(BuildContext? context, String soundFile, String placeholderText) async {
    if (!GameState.instance.soundEnabled) return;

    _init();

    try {
      // Determines whether to look in sfx or music
      final isMusic = soundFile.contains('jingle') || soundFile.contains('intro') || soundFile.contains('battle_start');
      final folder = isMusic ? 'music' : 'sfx';

      // First check if it's canzed_intro (which is in sfx)
      final path = soundFile == 'canzed_intro.mp3'
          ? 'lib/assets/sounds/sfx/$soundFile'
          : 'lib/assets/sounds/$folder/$soundFile';

      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (e) {
      debugPrint('Audio playback error for $soundFile: $e');
    }
  }

  static Future<void> stop() async {
    await _player.stop();
  }
}