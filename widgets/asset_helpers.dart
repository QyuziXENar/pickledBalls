// lib/widgets/asset_helpers.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';

// ============================================================================
// ZERO-CRASH ASSET MANIFEST REGISTRY
// ============================================================================
class AppAssetRegistry {
  static Set<String> _bundledAssets = {};
  static bool _initialized = false;

  /// Inspects the app's compiled asset bundle at runtime.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _bundledAssets = manifest.listAssets().toSet();
      _initialized = true;
    } catch (e) {
      debugPrint('AssetManifest index note: $e');
    }
  }

  /// Verifies if an asset file actually exists inside the bundle.
  static bool hasAsset(String path) {
    if (!_initialized) return true; // If manifest not ready, allow safe attempt
    return _bundledAssets.contains(path);
  }
}

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
    if (!AppAssetRegistry.hasAsset(assetPath)) {
      return fallback;
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

// ============================================================================
// LOW-LATENCY ZERO-CRASH AUDIO CONTROLLER (iOS AMBIENT & MIX-WITH-OTHERS)
// ============================================================================
class AppAudio {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static bool _initialized = false;

  /// Configures iOS AVAudioSessionCategory.ambient and Android gainTransientMayDuck
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            // Uses Set<AVAudioSessionOptions> with curly braces {} to satisfy audioplayers 6.x
            options: const {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      _musicPlayer.audioCache.prefix = '';
      _sfxPlayer.audioCache.prefix = '';
      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);

      _initialized = true;
    } catch (e) {
      debugPrint('Audio initialization note: $e');
    }
  }

  /// Plays dedicated in-game SFX with safe path and manifest checking
  static Future<void> playFeatureSfx(String soundPath) async {
    if (!GameState.instance.soundEnabled) return;
    await init();

    // Resolves both full paths ('lib/assets/sounds/sfx/...') and raw filenames ('click.mp3')
    final cleanPath = soundPath.startsWith('lib/') || soundPath.startsWith('assets/')
        ? soundPath
        : 'lib/assets/sounds/sfx/$soundPath';

    if (!AppAssetRegistry.hasAsset(cleanPath)) {
      return; // Safe silent bypass (Zero 404!)
    }

    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('SFX playback note ($cleanPath): $e');
    }
  }

  /// Backward-compatible alias for existing dialogs and widgets
  static Future<void> playSfx(String soundFileName) async {
    await playFeatureSfx(soundFileName);
  }

  /// Plays background music and intro tracks
  static Future<void> playMusic(String soundPath) async {
    if (!GameState.instance.soundEnabled) return;
    await init();

    final isSfxFolder = soundPath.contains('intro') || soundPath.contains('fault') || soundPath.contains('bounce');
    final folder = isSfxFolder ? 'sfx' : 'music';

    final cleanPath = soundPath.startsWith('lib/') || soundPath.startsWith('assets/')
        ? soundPath
        : 'lib/assets/sounds/$folder/$soundPath';

    if (!AppAssetRegistry.hasAsset(cleanPath)) {
      // Automatic bridge: if xccr_intro is called but canzed_intro is on disk, fallback cleanly
      if (soundPath.contains('intro') && AppAssetRegistry.hasAsset('lib/assets/sounds/sfx/canzed_intro.mp3')) {
        try {
          await _musicPlayer.stop();
          await _musicPlayer.play(AssetSource('lib/assets/sounds/sfx/canzed_intro.mp3'));
        } catch (_) {}
      }
      return;
    }

    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Music playback note ($cleanPath): $e');
    }
  }

  /// Legacy dispatcher for intro and UI taps
  static Future<void> play(BuildContext? context, String soundFile, String placeholderText) async {
    if (soundFile.contains('jingle') || soundFile.contains('intro') || soundFile.contains('battle_start')) {
      await playMusic(soundFile);
    } else {
      await playFeatureSfx(soundFile);
    }
  }

  static Future<void> stop() async {
    try {
      await _musicPlayer.stop();
      await _sfxPlayer.stop();
    } catch (_) {}
  }
}