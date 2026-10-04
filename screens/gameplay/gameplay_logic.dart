// lib/screens/gameplay/gameplay_logic.dart

import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../widgets/asset_helpers.dart';
import 'gameplay_models.dart';
import 'physics/court_physics_engine.dart';
import 'physics/tactical_ai_controller.dart';

class GameplayLogic {
  final CourtPhysicsEngine physics;
  final TacticalAiController ai;

  MatchPhase phase = MatchPhase.intro;
  bool playerServing = true;
  double matchTimeRemaining = 180.0;

  double driveCooldown = 0.0;
  double smashCooldown = 0.0;
  double lobCooldown = 0.0;
  static const double kMaxDriveCooldown = 0.30;
  static const double kMaxSmashCooldown = 0.55;
  static const double kMaxLobCooldown = 0.35;

  double playerBlitzEnergy = 0.0;
  bool blitzActive = false;

  int playerScore = 0;
  int aiScore = 0;
  int currentRally = 0;
  int longestRally = 0;
  int totalSmashes = 0;

  double reticleScale = 1.0;
  double serveTossVz = 0.0;
  bool sweetSpotAudioPlayed = false;

  String feedbackText = '';
  Color feedbackColor = AppColors.opticYellow;
  double feedbackTimer = 0.0;

  String pointToastText = '';
  double pointToastTimer = 0.0;

  GameplayLogic({required this.physics, required this.ai});

  void resetMatch() {
    playerScore = 0;
    aiScore = 0;
    currentRally = 0;
    longestRally = 0;
    totalSmashes = 0;
    matchTimeRemaining = 180.0;
    playerBlitzEnergy = 0.0;
    blitzActive = false;
    playerServing = true;
    phase = MatchPhase.intro;
  }

  void startServeSequence({required double playerX, required double playerY}) {
    phase = MatchPhase.serveTossWait;
    reticleScale = 1.0;
    sweetSpotAudioPlayed = false;
    physics.resetBall(
      playerServing: playerServing,
      playerX: playerX,
      playerY: playerY,
      aiX: ai.x,
      aiY: ai.y,
    );
  }

  void executePlayerToss({required double playerX}) {
    if (phase != MatchPhase.serveTossWait || !playerServing) return;
    phase = MatchPhase.serveBallInAir;
    serveTossVz = math.sqrt(2 * 3.6 * (1.55 - 0.70));
    physics.ballX = playerX + 0.10;
    physics.ballY = 0.04;
    physics.ballZ = 0.70;
    physics.ballVx = 0;
    physics.ballVy = 0;
    physics.ballCurve = 0;
    physics.ballSpinVertical = 0;
    reticleScale = 1.0;
    sweetSpotAudioPlayed = false;
    AppAudio.playFeatureSfx(AppAssets.sfxServeToss);
    HapticFeedback.lightImpact();
  }

  void strikePlayerServe({
    required ShotType shotType,
    required double playerX,
    required double joystickX,
    required Function(double trauma) onTrauma,
  }) {
    if (phase != MatchPhase.serveBallInAir || !playerServing) return;

    final state = GameState.instance;
    final char = state.selectedCharacter;
    final pace = state.gamePace;

    final contactDiff = (physics.ballZ - 1.25).abs();
    final isSweetSpot = contactDiff < 0.28;

    phase = MatchPhase.activeRally;
    final power = state.effectivePaddlePower * char.swingPower * pace;

    if (isSweetSpot) {
      setFeedback(shotType == ShotType.drive ? '⚡ BULLET SERVE!' : '🎯 DEEP LOB SERVE!', AppColors.opticYellow);
      onTrauma(0.35);
    } else {
      setFeedback('GOOD SERVE', AppColors.mintAccent);
    }

    double targetX = (-playerX * 0.40).clamp(-0.70, 0.70);
    if (joystickX.abs() > 0.15) {
      targetX = (joystickX * 0.65).clamp(-0.75, 0.75);
    }

    if (shotType == ShotType.drive) {
      physics.ballVy = (isSweetSpot ? 0.86 : 0.78) * power;
      physics.ballVz = 1.85;
      physics.ballVx = (targetX - physics.ballX) * 0.45;
      physics.ballCurve = (joystickX * 0.20) * state.effectivePaddleSpin;
      physics.ballSpinVertical = 0.15;
      AppAudio.playFeatureSfx(AppAssets.sfxServeDrive);
    } else {
      physics.ballVy = 0.68 * power;
      physics.ballVz = 2.50;
      physics.ballVx = (targetX - physics.ballX) * 0.35;
      physics.ballCurve = 0;
      physics.ballSpinVertical = -0.10;
      AppAudio.playFeatureSfx(AppAssets.sfxServeLob);
    }

    currentRally = 1;
    physics.spawnHitSparks(playerX + 0.10, 0.04, physics.ballZ, AppColors.opticYellow);
    ai.onPlayerHitBall(difficulty: state.difficulty, ballVx: physics.ballVx);
    HapticFeedback.mediumImpact();
  }

  void executeAiServe() {
    final state = GameState.instance;
    final aiChar = state.opponentCharacter;
    final pace = state.gamePace;
    final rng = math.Random();

    phase = MatchPhase.activeRally;
    final targetX = (-ai.x * 0.45 + (rng.nextDouble() - 0.5) * 0.20).clamp(-0.70, 0.70);
    final isAggressive = rng.nextDouble() < 0.45;

    if (isAggressive) {
      physics.ballVy = -0.76 * aiChar.swingPower * pace;
      physics.ballVz = 1.80;
      ai.currentShot = ShotType.drive;
      physics.ballSpinVertical = 0.15;
      AppAudio.playFeatureSfx(AppAssets.sfxServeDrive);
    } else {
      physics.ballVy = -0.62 * aiChar.swingPower * pace;
      physics.ballVz = 2.45;
      ai.currentShot = ShotType.lob;
      physics.ballSpinVertical = -0.10;
      AppAudio.playFeatureSfx(AppAssets.sfxServeLob);
    }

    physics.ballVx = (targetX - ai.x) * 0.38;
    physics.ballCurve = (rng.nextDouble() - 0.5) * 0.12;
    ai.isSwinging = true;
    ai.swingAngle = 0.1;
    physics.spawnHitSparks(ai.x - 0.10, ai.y - 0.04, physics.ballZ, aiChar.accentColor);
  }

  // ==========================================================================
  // BALANCED PLAYABLE AI RETURN (NO MORE ROCKETS OR WEAK PUFFBALLS)
  // ==========================================================================
  void executeAiReturn({
    required Function(double trauma) onTrauma,
    required VoidCallback onAiSwing,
  }) {
    final state = GameState.instance;
    final aiChar = state.opponentCharacter;

    ai.executeTacticalShot(
      aiChar: aiChar,
      pace: state.gamePace,
      playerX: 0.0,
      playerY: 0.0,
      ballZ: physics.ballZ,
      currentRally: currentRally,
      difficulty: state.difficulty,
      isUnderPressure: blitzActive,
      onApplyShot: (vy, vz, vx, curve, spinZ, shot) {
        final double aiPower = aiChar.swingPower * state.gamePace;

        // Controlled, playable velocity: lands softly at Y ≈ 0.20 - 0.25
        if (shot == ShotType.smash) {
          physics.ballVy = -0.82 * aiPower;
          physics.ballVz = 1.30;
        } else if (shot == ShotType.lob) {
          physics.ballVy = -0.58 * aiPower;
          physics.ballVz = 2.40;
        } else {
          // Clean, responsive drive
          physics.ballVy = -0.68 * aiPower;
          physics.ballVz = 1.60;
        }

        physics.ballVx = vx * 0.75;
        physics.ballCurve = curve * 0.5;
        physics.ballSpinVertical = spinZ;
        onAiSwing();

        if (shot == ShotType.smash) {
          onTrauma(0.40);
          AppAudio.playFeatureSfx(AppAssets.sfxPaddleSmash);
        } else {
          AppAudio.playFeatureSfx(AppAssets.sfxPaddleDrive);
        }
      },
    );

    physics.spawnHitSparks(ai.x - 0.08, ai.y - 0.03, physics.ballZ, aiChar.accentColor);
    currentRally++;
    if (currentRally > longestRally) longestRally = currentRally;
    if (currentRally >= 5 && currentRally % 5 == 0) {
      AppAudio.playFeatureSfx(AppAssets.sfxRallyStreak);
    }
  }

  // ==========================================================================
  // FAST, UN-FROZEN POINT RESOLUTION (SNAPPY 0.6s RESET)
  // ==========================================================================
  void resolvePoint({
    required bool playerWonRally,
    required String reason,
    required VoidCallback onMatchEnd,
    required VoidCallback onQuickReset,
  }) {
    final target = GameState.instance.targetScore;
    phase = MatchPhase.pointScored;

    if (playerWonRally) {
      if (playerServing) {
        playerScore++;
        pointToastText = 'POINT: YOU! ($reason)';
        AppAudio.playFeatureSfx(AppAssets.sfxPointCheer);
      } else {
        playerServing = true;
        pointToastText = 'SIDE-OUT TO YOU';
        AppAudio.playFeatureSfx(AppAssets.sfxPointCheer);
      }
    } else {
      if (!playerServing) {
        aiScore++;
        pointToastText = 'POINT: OPPONENT ($reason)';
        AppAudio.playFeatureSfx(AppAssets.sfxRoundLose);
      } else {
        playerServing = false;
        pointToastText = 'SIDE-OUT TO OPPONENT';
        AppAudio.playFeatureSfx(AppAssets.sfxFaultBuzzer);
      }
    }

    pointToastTimer = 0.8;
    currentRally = 0;
    blitzActive = false;

    final playerWonMatch = playerScore >= target && (playerScore - aiScore) >= 2;
    final aiWonMatch = aiScore >= target && (aiScore - playerScore) >= 2;

    if (playerWonMatch || aiWonMatch) {
      GameState.instance.addMatchExperience(
        wonMatch: playerWonMatch,
        rallyHits: longestRally,
        smashes: totalSmashes,
      );
      phase = MatchPhase.gameOver;
      AppAudio.playFeatureSfx(playerWonMatch ? AppAssets.sfxMatchWinner : AppAssets.sfxMatchLose);
      onMatchEnd();
    } else {
      // Snappy 0.6s reset: NO MORE 3-SECOND SCREEN FREEZES!
      Future.delayed(const Duration(milliseconds: 600), () {
        onQuickReset();
      });
    }
  }

  void setFeedback(String text, Color color) {
    feedbackText = text;
    feedbackColor = color;
    feedbackTimer = 1.0;
  }
}