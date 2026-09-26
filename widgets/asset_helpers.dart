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
    // If asset is not in bundle, render the procedural fallback immediately (No 404!)
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
// LOW-LATENCY ZERO-CRASH AUDIO CONTROLLER
// ============================================================================
class AppAudio {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static bool _audioConfigured = false;

  static void _ensureAudioConfigured() {
    if (_audioConfigured) return;
    _musicPlayer.audioCache.prefix = '';
    _sfxPlayer.audioCache.prefix = '';
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    _audioConfigured = true;
  }

  /// Plays dedicated in-game SFX with safe existence verification.
  /// If the .mp3 file is missing from disk, it skips cleanly without crashing or logging 404s.
  static Future<void> playFeatureSfx(String soundFileName) async {
    if (!GameState.instance.soundEnabled) return;
    _ensureAudioConfigured();

    final candidatePath = 'lib/assets/sounds/sfx/$soundFileName';
    final fallbackDrive = 'lib/assets/sounds/sfx/paddle_drive.mp3';

    String pathToPlay = candidatePath;

    // The IF Statement Check:
    if (!AppAssetRegistry.hasAsset(candidatePath)) {
      // If specific sound missing, try base paddle drive or return cleanly
      if (soundFileName.contains('serve') || soundFileName.contains('dink')) {
        if (AppAssetRegistry.hasAsset(fallbackDrive)) {
          pathToPlay = fallbackDrive;
        } else {
          return;
        }
      } else {
        return; // Silent fail without errors
      }
    }

    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(pathToPlay));
    } catch (_) {}
  }

  /// Backward-compatible alias for existing code
  static Future<void> playSfx(String soundFileName) async {
    await playFeatureSfx(soundFileName);
  }

  /// Plays background music and intro sequences
  static Future<void> playMusic(String soundFile) async {
    if (!GameState.instance.soundEnabled) return;
    _ensureAudioConfigured();

    final isSfxFolder = soundFile.contains('intro') || soundFile.contains('fault') || soundFile.contains('bounce');
    final folder = isSfxFolder ? 'sfx' : 'music';
    final path = 'lib/assets/sounds/$folder/$soundFile';

    if (!AppAssetRegistry.hasAsset(path)) {
      // If xccr_intro is called but canzed_intro is on disk, bridge cleanly
      if (soundFile == 'xccr_intro.mp3' && AppAssetRegistry.hasAsset('lib/assets/sounds/sfx/canzed_intro.mp3')) {
        try {
          await _musicPlayer.stop();
          await _musicPlayer.play(AssetSource('lib/assets/sounds/sfx/canzed_intro.mp3'));
        } catch (_) {}
        return;
      }
      return;
    }

    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource(path));
    } catch (_) {}
  }

  /// Legacy menu sound dispatcher
  static Future<void> play(BuildContext? context, String soundFile, String placeholderText) async {
    if (soundFile.contains('jingle') || soundFile.contains('intro') || soundFile.contains('battle_start')) {
      await playMusic(soundFile);
    } else {
      await playFeatureSfx(soundFile);
    }
  }

  static Future<void> stop() async {
    await _musicPlayer.stop();
    await _sfxPlayer.stop();
  }
}