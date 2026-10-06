// lib/screens/gameplay/physics/tactical_ai_controller.dart

import 'dart:math' as math;
import '../../../core/constants/app_assets.dart';
import '../../../models/game_state.dart';
import '../gameplay_models.dart';

class TacticalAiController {
  double x = 0.0;
  double targetX = 0.0;
  double velocityX = 0.0;

  double y = 0.92;
  double targetY = 0.92;
  double velocityY = 0.0;

  double swingAngle = 0.0;
  bool isSwinging = false;
  SpriteAction action = SpriteAction.idle;
  ShotType currentShot = ShotType.normal;
  bool isDiving = false;

  double _reactionLagTimer = 0.0;
  double _currentReactionLag = 0.12;
  double _unforcedErrorChance = 0.08;
  bool _isWrongFooted = false;
  double _wrongFootRecoveryTimer = 0.0;
  AiCourtZone courtZone = AiCourtZone.baseline;

  void reset() {
    x = 0.0;
    targetX = 0.0;
    velocityX = 0.0;
    y = 0.92;
    targetY = 0.92;
    velocityY = 0.0;
    swingAngle = 0.0;
    isSwinging = false;
    action = SpriteAction.idle;
    currentShot = ShotType.normal;
    isDiving = false;
    _reactionLagTimer = 0.0;
    _isWrongFooted = false;
    _wrongFootRecoveryTimer = 0.0;
    courtZone = AiCourtZone.baseline;
  }

  void onPlayerHitBall({
    required AIDifficulty difficulty,
    required double ballVx,
  }) {
    final rng = math.Random();
    switch (difficulty) {
      case AIDifficulty.rookie:
        _currentReactionLag = 0.24 + (rng.nextDouble() * 0.08); // 240ms - 320ms
        _unforcedErrorChance = 0.22;
        break;
      case AIDifficulty.pro:
        _currentReactionLag = 0.11 + (rng.nextDouble() * 0.05); // 110ms - 160ms
        _unforcedErrorChance = 0.08;
        break;
      case AIDifficulty.legend:
        _currentReactionLag = 0.03 + (rng.nextDouble() * 0.03); // 30ms - 60ms
        _unforcedErrorChance = 0.02;
        break;
    }
    _reactionLagTimer = _currentReactionLag;

    // Wrong-foot momentum detection
    if ((ballVx > 0.18 && velocityX < -0.25) || (ballVx < -0.18 && velocityX > 0.25)) {
      _isWrongFooted = true;
      _wrongFootRecoveryTimer = (difficulty == AIDifficulty.rookie) ? 0.35 : 0.18;
    }
  }

  void updatePosition({
    required double dt,
    required double ballX,
    required double ballY,
    required double ballZ,
    required double ballVx,
    required double ballVy,
    required CharacterModel aiChar,
    required AIDifficulty difficulty,
    required int currentRally,
    required double playerY,
  }) {
    final double aiMultiplier = difficulty.speedMultiplier;

    if (_reactionLagTimer > 0) _reactionLagTimer -= dt;
    if (_wrongFootRecoveryTimer > 0) {
      _wrongFootRecoveryTimer -= dt;
      if (_wrongFootRecoveryTimer <= 0) _isWrongFooted = false;
    }

    // 1. 2D Depth Positioning Engine (Kitchen NVZ, Transition, Baseline)
    if (ballVy > 0) {
      if (currentRally <= 1) {
        // Holding baseline to receive serve
        targetY = 0.92;
        courtZone = AiCourtZone.baseline;
      } else if (ballZ < 1.35 && ballVy < 0.70) {
        // Soft dink: Advance to NVZ Kitchen line!
        targetY = (difficulty == AIDifficulty.rookie) ? 0.82 : 0.68;
        courtZone = AiCourtZone.kitchen;
      } else if (ballZ > 1.8 && ballVy > 0.75) {
        // Deep lob: Retreat to deep baseline
        targetY = 1.02;
        courtZone = AiCourtZone.baseline;
      } else {
        targetY = (difficulty == AIDifficulty.rookie) ? 0.95 : 0.86;
        courtZone = AiCourtZone.transition;
      }
    } else {
      if (difficulty == AIDifficulty.legend && currentRally > 2) {
        targetY = 0.70;
      } else if (difficulty == AIDifficulty.pro && currentRally > 2) {
        targetY = 0.80;
      } else {
        targetY = 0.92;
      }
    }

    // 2. Trajectory Intercept Calculation
    if (_reactionLagTimer <= 0) {
      final double flightTime = ((y - ballY) / (ballVy.abs() + 0.001)).clamp(0.0, 1.2);
      final double predictedX = (ballX + (ballVx * flightTime)).clamp(-0.85, 0.85);
      targetX = predictedX;
    }

    final double inertiaPenalty = _isWrongFooted ? 0.45 : 1.0;
    final double oldX = x;
    final double oldY = y;

    final double speedX = 3.6 * aiChar.moveSpeed * aiMultiplier * inertiaPenalty;
    final double speedY = 2.2 * aiChar.moveSpeed * aiMultiplier;

    x += (targetX - x) * math.min(1.0, speedX * dt);
    y += (targetY - y) * math.min(1.0, speedY * dt);

    velocityX = (x - oldX) / dt;
    velocityY = (y - oldY) / dt;

    if (velocityX.abs() > 0.20 || velocityY.abs() > 0.20) {
      action = SpriteAction.walk;
    } else if (y < 0.74) {
      action = SpriteAction.defend;
    } else {
      action = SpriteAction.idle;
    }
  }

  // ==========================================================================
  // SHOT GENERATION WITH OPEN-COURT VISION & GUARANTEED NET CLEARANCE
  // ==========================================================================
  void executeTacticalShot({
    required CharacterModel aiChar,
    required double pace,
    required double playerX,
    required double playerY,
    required double ballZ,
    required int currentRally,
    required AIDifficulty difficulty,
    required bool isUnderPressure,
    required Function(double vy, double vz, double vx, double curve, double spinZ, ShotType shot) onApplyShot,
  }) {
    final rng = math.Random();
    final bool playerIsDeep = playerY < 0.05;
    final bool playerIsAtKitchen = playerY > 0.22;

    // 1. Unforced Error Simulation (Only under heavy pressure)
    if (isUnderPressure && rng.nextDouble() < _unforcedErrorChance) {
      final bool errorType = rng.nextBool();
      if (errorType) {
        onApplyShot(-0.55 * pace, 0.35, (rng.nextDouble() - 0.5) * 0.3, 0.0, 0.0, ShotType.normal);
      } else {
        final double outX = rng.nextBool() ? 1.10 : -1.10;
        onApplyShot(-0.70 * pace, 1.8, (outX - x) * 0.5, 0.0, 0.0, ShotType.normal);
      }
      return;
    }

    // 2. Open Court Scanning: Attacks space player has vacated
    double openCourtX;
    if (playerX > 0.20) {
      openCourtX = -0.55 + (rng.nextDouble() - 0.5) * 0.20;
    } else if (playerX < -0.20) {
      openCourtX = 0.55 + (rng.nextDouble() - 0.5) * 0.20;
    } else {
      openCourtX = rng.nextBool() ? 0.60 : -0.60;
    }
    openCourtX = openCourtX.clamp(-0.78, 0.78);

    // 3. Selection Hierarchy (Balanced & Fair Velocities)
    if (ballZ > 1.20 && !playerIsAtKitchen) {
      // Overhead Smash Spike
      currentShot = ShotType.smash;
      onApplyShot(
        -0.88 * aiChar.swingPower * pace,
        1.35,
        (openCourtX - x) * 0.45,
        (rng.nextDouble() - 0.5) * 0.10,
        0.20,
        ShotType.smash,
      );
    } else if (playerIsDeep && (courtZone == AiCourtZone.kitchen || rng.nextDouble() < 0.45)) {
      // Kitchen Drop / Dink
      currentShot = ShotType.drive;
      onApplyShot(
        -0.45 * pace,
        1.45,
        (openCourtX - x) * 0.32,
        0.0,
        -0.12,
        ShotType.drive,
      );
    } else if (playerIsAtKitchen && rng.nextDouble() < 0.38) {
      // Defensive Lob clearing player's reach
      currentShot = ShotType.lob;
      onApplyShot(
        -0.62 * aiChar.swingPower * pace,
        2.60,
        (openCourtX - x) * 0.28,
        0.0,
        -0.15,
        ShotType.lob,
      );
    } else {
      // Regulation Flat Penetrating Drive
      currentShot = ShotType.normal;
      onApplyShot(
        -0.68 * aiChar.swingPower * pace,
        1.68,
        (openCourtX - x) * 0.40,
        (rng.nextDouble() - 0.5) * 0.08,
        0.08,
        ShotType.normal,
      );
    }
  }
}