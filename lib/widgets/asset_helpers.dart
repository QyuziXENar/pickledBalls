// lib/widgets/asset_helpers.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';

// ============================================================================
// ASSET MANIFEST REGISTRY
// ============================================================================
class AppAssetRegistry {
  static Set<String> _bundledAssets = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _bundledAssets = manifest.listAssets().toSet();
      _initialized = true;
      debugPrint('[AppAssetRegistry] Indexed ${_bundledAssets.length} assets.');
    } catch (e) {
      debugPrint('[AppAssetRegistry init error]: $e');
    }
  }

  static bool hasAsset(String path) {
    if (!_initialized || _bundledAssets.isEmpty) return true;
    final clean = path.replaceAll('\\', '/');
    return _bundledAssets.contains(clean) ||
        _bundledAssets.contains('lib/$clean') ||
        (clean.startsWith('lib/') && _bundledAssets.contains(clean.substring(4)));
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
// FAILSAFE AUDIO CONTROLLER (AUTO-CHECKS MUSIC AND SFX DIRECTORIES)
// ============================================================================
class AppAudio {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      AudioCache.instance = AudioCache(prefix: '');
      _musicPlayer.audioCache.prefix = '';
      _sfxPlayer.audioCache.prefix = '';

      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
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

      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _musicPlayer.setVolume(1.0);
      await _sfxPlayer.setVolume(1.0);

      _initialized = true;
    } catch (e) {
      debugPrint('[AppAudio init note]: $e');
    }
  }

  /// Builds all possible asset paths to guarantee audio is found
  static List<String> _resolvePaths(String input) {
    final clean = input.replaceAll('\\', '/');
    final filename = clean.split('/').last;

    return [
      clean,
      if (clean.startsWith('lib/')) clean.substring(4),
      'lib/assets/sounds/music/$filename',
      'assets/sounds/music/$filename',
      'lib/assets/sounds/sfx/$filename',
      'assets/sounds/sfx/$filename',
    ];
  }

  /// Plays background music and intro sequences
  static Future<void> playMusic(String soundPath) async {
    if (!GameState.instance.soundEnabled) return;
    await init();

    final candidatePaths = _resolvePaths(soundPath);
    bool played = false;

    for (final path in candidatePaths) {
      try {
        await _musicPlayer.stop();
        await _musicPlayer.setVolume(1.0);
        await _musicPlayer.play(AssetSource(path));
        debugPrint('[AppAudio] Playing music track: $path');
        played = true;
        break;
      } catch (_) {
        // Try next candidate path
      }
    }

    if (!played) {
      debugPrint('[AppAudio] Could not play music for: $soundPath');
    }
  }

  /// Plays gameplay sound effects
  static Future<void> playFeatureSfx(String soundPath) async {
    if (!GameState.instance.soundEnabled) return;
    await init();

    final candidatePaths = _resolvePaths(soundPath);

    for (final path in candidatePaths) {
      try {
        await _sfxPlayer.stop();
        await _sfxPlayer.setVolume(1.0);
        await _sfxPlayer.play(AssetSource(path));
        break;
      } catch (_) {
        // Try next candidate
      }
    }
  }

  static Future<void> playSfx(String soundFileName) async {
    await playFeatureSfx(soundFileName);
  }

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