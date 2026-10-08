// lib/screens/gameplay/gameplay_controller.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../models/online_profile_models.dart';
import '../../services/online_repository.dart';
import '../../widgets/asset_helpers.dart';
import 'gameplay_models.dart';
import 'physics/court_physics_engine.dart';
import 'physics/tactical_ai_controller.dart';

class GameplayController extends ChangeNotifier {
  final CourtPhysicsEngine physics;
  final TacticalAiController ai;
  final MatchMode matchMode;

  MatchPhase phase = MatchPhase.cinematicSplash;
  int countdownNumber = 3;
  double phaseTimer = 1.8;

  bool playerServing = true;
  double matchTimeRemaining = 180.0;

  // Anti-Spam Recovery Cooldowns
  double driveCooldown = 0.0;
  double smashCooldown = 0.0;
  double lobCooldown = 0.0;
  static const double kMaxDriveCooldown = 0.28;
  static const double kMaxSmashCooldown = 0.50;
  static const double kMaxLobCooldown = 0.32;

  double playerBlitzEnergy = 0.0;
  bool blitzActive = false;

  int playerScore = 0;
  int aiScore = 0;
  int currentRally = 0;
  int longestRally = 0;
  int totalSmashes = 0;
  int totalDinks = 0;
  int kitchenFaults = 0;

  double reticleScale = 1.0;
  double serveTossVz = 0.0;
  bool sweetSpotAudioPlayed = false;

  String feedbackText = '';
  Color feedbackColor = AppColors.opticYellow;
  double feedbackTimer = 0.0;

  String pointToastText = '';
  double pointToastTimer = 0.0;

  String? activeQuickChat;
  double quickChatTimer = 0.0;

  MatchPerformanceStats? matchSummaryStats;

  double targetPlayerBoxX = 0.38;
  double targetAiBoxX = -0.38;

  Timer? _aiServeTimer;

  GameplayController({
    required this.physics,
    required this.ai,
    this.matchMode = MatchMode.vsAi,
  });

  void startMatchIntro() {
    phase = MatchPhase.cinematicSplash;
    phaseTimer = 1.8;
    AppAudio.play(null, AppAssets.musicBattleStart, 'Match Intro');
    notifyListeners();
  }

  void resetFullMatch() {
    _aiServeTimer?.cancel();
    playerScore = 0;
    aiScore = 0;
    currentRally = 0;
    longestRally = 0;
    totalSmashes = 0;
    totalDinks = 0;
    kitchenFaults = 0;
    matchTimeRemaining = 180.0;
    playerBlitzEnergy = 0.0;
    blitzActive = false;
    playerServing = true;
    matchSummaryStats = null;
    startMatchIntro();
  }

  void showQuickChat(String text) {
    activeQuickChat = text;
    quickChatTimer = 2.5;
    AppAudio.playFeatureSfx(AppAssets.sfxClick);
    notifyListeners();
  }

  void beginAutomatedRepositioning({required VoidCallback onReady}) {
    phase = MatchPhase.repositioning;
    phaseTimer = 0.70;

    final int serverScore = playerServing ? playerScore : aiScore;
    final bool isRightSide = (serverScore % 2 == 0);

    if (playerServing) {
      targetPlayerBoxX = isRightSide ? 0.38 : -0.38;
      targetAiBoxX = isRightSide ? -0.38 : 0.38;
    } else {
      targetAiBoxX = isRightSide ? 0.38 : -0.38;
      targetPlayerBoxX = isRightSide ? -0.38 : 0.38;
    }

    notifyListeners();
  }

  void completeRepositioning({required double playerX, required double playerY}) {
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

    // AI only auto-serves in Single Player mode
    if (!playerServing && matchMode == MatchMode.vsAi) {
      scheduleAiServe();
    }

    notifyListeners();
  }

  void scheduleAiServe() {
    _aiServeTimer?.cancel();
    final AIDifficulty diff = GameState.instance.difficulty;
    final int delayMs = diff == AIDifficulty.rookie
        ? 1200
        : (diff == AIDifficulty.pro ? 850 : 600);

    _aiServeTimer = Timer(Duration(milliseconds: delayMs), () {
      if (phase == MatchPhase.serveTossWait && !playerServing && matchMode == MatchMode.vsAi) {
        executeAiServe();
      }
    });
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
    notifyListeners();
  }

  void strikePlayerServe({
    required ShotType shotType,
    required double playerX,
    required double joystickX,
    required Function(double trauma) onTrauma,
    required Function(bool playerWon, String reason) onPointEnd,
  }) {
    if (phase != MatchPhase.serveBallInAir || !playerServing) return;

    if (physics.ballZ > 0.95) {
      setFeedback('TOO EARLY! (Above Waist)', AppColors.electricCoral);
      HapticFeedback.selectionClick();
      return;
    }

    final state = GameState.instance;
    final char = state.selectedCharacter;
    final pace = state.gamePace;

    final double contactDiff = (physics.ballZ - 0.68).abs();
    final bool isSweetSpot = contactDiff < 0.24;

    phase = MatchPhase.activeRally;
    final double power = state.effectivePaddlePower * char.swingPower * pace;

    if (isSweetSpot) {
      setFeedback(shotType == ShotType.drive ? '⚡ CRISP DRIVE SERVE!' : '🎯 DEEP LOB SERVE!', AppColors.opticYellow);
      onTrauma(0.35);
    } else {
      setFeedback('GOOD SERVE', AppColors.mintAccent);
    }

    double targetX = (-playerX * 0.40).clamp(-0.70, 0.70);
    if (joystickX.abs() > 0.15) {
      targetX = (joystickX * 0.65).clamp(-0.75, 0.75);
    }

    if (shotType == ShotType.drive) {
      physics.ballVy = (isSweetSpot ? 0.90 : 0.82) * power;
      physics.ballVz = 1.95;
      physics.ballVx = (targetX - physics.ballX) * 0.45;
      physics.ballCurve = (joystickX * 0.20) * state.effectivePaddleSpin;
      physics.ballSpinVertical = 0.15;
      AppAudio.playFeatureSfx(AppAssets.sfxServeDrive);
    } else {
      physics.ballVy = 0.72 * power;
      physics.ballVz = 2.65;
      physics.ballVx = (targetX - physics.ballX) * 0.35;
      physics.ballCurve = 0;
      physics.ballSpinVertical = -0.10;
      AppAudio.playFeatureSfx(AppAssets.sfxServeLob);
    }

    currentRally = 1;
    physics.spawnHitSparks(playerX + 0.10, 0.04, physics.ballZ, AppColors.opticYellow);
    if (matchMode == MatchMode.vsAi) {
      ai.onPlayerHitBall(difficulty: state.difficulty, ballVx: physics.ballVx);
    }
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void executeAiServe() {
    final state = GameState.instance;
    final aiChar = state.opponentCharacter;
    final pace = state.gamePace;
    final rng = math.Random();

    phase = MatchPhase.activeRally;
    final double targetX = (-ai.x * 0.45 + (rng.nextDouble() - 0.5) * 0.20).clamp(-0.70, 0.70);
    final bool isAggressive = rng.nextDouble() < 0.45;

    if (isAggressive) {
      physics.ballVy = -0.82 * aiChar.swingPower * pace;
      physics.ballVz = 1.95;
      ai.currentShot = ShotType.drive;
      physics.ballSpinVertical = 0.15;
      AppAudio.playFeatureSfx(AppAssets.sfxServeDrive);
    } else {
      physics.ballVy = -0.68 * aiChar.swingPower * pace;
      physics.ballVz = 2.65;
      ai.currentShot = ShotType.lob;
      physics.ballSpinVertical = -0.10;
      AppAudio.playFeatureSfx(AppAssets.sfxServeLob);
    }

    physics.ballVx = (targetX - ai.x) * 0.40;
    physics.ballCurve = (rng.nextDouble() - 0.5) * 0.12;
    ai.isSwinging = true;
    ai.swingAngle = 0.1;
    physics.spawnHitSparks(ai.x - 0.10, ai.y - 0.04, physics.ballZ, aiChar.accentColor);
    notifyListeners();
  }

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
        final double rawVy = (shot == ShotType.smash
            ? 0.85
            : (shot == ShotType.lob ? 0.60 : 0.70)) * aiPower;

        final double distToNet = (ai.y - 0.50).clamp(0.18, 0.85);
        final double timeToNet = distToNet / (rawVy.abs() + 0.001);

        const double targetClearanceZ = 0.62;
        final double requiredClearanceVz = (targetClearanceZ - physics.ballZ +
            (0.5 * CourtPhysicsEngine.gravity * timeToNet * timeToNet)) / timeToNet;

        double outVz;
        if (shot == ShotType.lob) {
          outVz = math.max(2.65, requiredClearanceVz + 0.50);
        } else if (shot == ShotType.smash) {
          outVz = math.max(1.35, requiredClearanceVz);
        } else {
          outVz = math.max(1.85, requiredClearanceVz);
        }

        physics.ballVy = -rawVy;
        physics.ballVz = outVz;
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
    notifyListeners();
  }

  void resolvePoint({
    required bool playerWonRally,
    required String reason,
    required VoidCallback onMatchEnd,
    required Function(double playerX, double playerY) onStartRepositioning,
  }) {
    final int target = GameState.instance.targetScore;
    phase = MatchPhase.pointScored;

    if (reason.contains('KITCHEN')) {
      kitchenFaults++;
    }

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

    pointToastTimer = 1.0;
    currentRally = 0;
    blitzActive = false;

    final bool playerWonMatch = playerScore >= target && (playerScore - aiScore) >= 2;
    final bool aiWonMatch = aiScore >= target && (aiScore - playerScore) >= 2;

    if (playerWonMatch || aiWonMatch) {
      const double currentDupr = 3.42;
      final double oppDupr = GameState.instance.difficulty == AIDifficulty.rookie
          ? 2.50
          : (GameState.instance.difficulty == AIDifficulty.pro ? 4.00 : 5.50);

      final double delta = DUPRCalculator.calculateDelta(
        playerRating: currentDupr,
        opponentRating: oppDupr,
        won: playerWonMatch,
        scoreDiff: playerScore - aiScore,
      );

      matchSummaryStats = MatchPerformanceStats(
        playerScore: playerScore,
        opponentScore: aiScore,
        totalDinks: totalDinks,
        overheadSmashes: totalSmashes,
        kitchenFaults: kitchenFaults,
        longestRally: longestRally,
        won: playerWonMatch,
        previousDupr: currentDupr,
        duprDelta: delta,
        xpEarned: playerWonMatch ? 150 : 50,
        coinsEarned: playerWonMatch ? 200 : 75,
      );

      if (matchMode == MatchMode.vsAi) {
        MockOnlineRepository.instance.submitMatchResult(matchSummaryStats!);
        GameState.instance.addMatchExperience(
          wonMatch: playerWonMatch,
          rallyHits: longestRally,
          smashes: totalSmashes,
        );
      }

      phase = MatchPhase.gameOver;
      AppAudio.playFeatureSfx(playerWonMatch ? AppAssets.sfxMatchWinner : AppAssets.sfxMatchLose);
      onMatchEnd();
    } else {
      Future.delayed(const Duration(milliseconds: 400), () {
        beginAutomatedRepositioning(onReady: () {});
      });
    }

    notifyListeners();
  }

  void setFeedback(String text, Color color) {
    feedbackText = text;
    feedbackColor = color;
    feedbackTimer = 1.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _aiServeTimer?.cancel();
    super.dispose();
  }
}