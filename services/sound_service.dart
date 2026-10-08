// lib/services/sound_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _pointPlayer = AudioPlayer();

  bool isMuted = false;

  Future<void> init() async {
    try {
      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _pointPlayer.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('[SoundService] Init note: $e');
    }
  }

  Future<void> playHitSound() async {
    if (isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('lib/assets/sounds/sfx/click.mp3'), volume: 0.9);
    } catch (e) {
      debugPrint('[SoundService] Hit sound note: $e');
    }
  }

  Future<void> playPointScoredSound({required bool isPlayerPoint}) async {
    if (isMuted) return;
    try {
      final soundFile = isPlayerPoint ? 'round_winner.mp3' : 'round_lose.mp3';
      await _pointPlayer.stop();
      await _pointPlayer.play(AssetSource('lib/assets/sounds/sfx/$soundFile'), volume: 0.85);
    } catch (e) {
      debugPrint('[SoundService] Point sound note: $e');
    }
  }

  Future<void> playMatchEndSound({required bool isWinner}) async {
    if (isMuted) return;
    try {
      final soundFile = isWinner ? 'match_winner.mp3' : 'match_lose.mp3';
      await _pointPlayer.stop();
      await _pointPlayer.play(AssetSource('lib/assets/sounds/sfx/$soundFile'), volume: 1.0);
    } catch (e) {
      debugPrint('[SoundService] Match end note: $e');
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _pointPlayer.dispose();
  }
}