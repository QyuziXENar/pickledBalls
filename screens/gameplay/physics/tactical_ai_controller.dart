// lib/screens/gameplay/physics/tactical_ai_controller.dart

import 'dart:math' as math;
import '../../../core/constants/app_assets.dart';
import '../../../models/game_state.dart';
import '../gameplay_screen.dart';

enum AiCourtZone { baseline, transition, kitchen }

class TacticalAiController {
  double x = 0.0;
  double targetX = 0.0;
  double velocityX = 0.0;

  double y = 0.88;
  double targetY = 0.88;
  double velocityY = 0.0;

  double swingAngle = 0.0;
  bool isSwinging = false;
  SpriteAction action = SpriteAction.idle;
  ShotType currentShot = ShotType.normal;
  bool isDiving = false;

  double _reactionLagTimer = 0.0;
  double _currentReactionLag = 0.08;
  double _unforcedErrorChance = 0.08;
  bool _isWrongFooted = false;
  double _wrongFootRecoveryTimer = 0.0;
  AiCourtZone courtZone = AiCourtZone.baseline;

  void reset() {
    x = 0.0;
    targetX = 0.0;
    velocityX = 0.0;
    y = 0.88;
    targetY = 0.88;
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
        _currentReactionLag = 0.12 + rng.nextDouble() * 0.05;
        _unforcedErrorChance = 0.20;
        break;
      case AIDifficulty.pro:
        _currentReactionLag = 0.06 + rng.nextDouble() * 0.04;
        _unforcedErrorChance = 0.07;
        break;
      case AIDifficulty.legend:
        _currentReactionLag = 0.02 + rng.nextDouble() * 0.02;
        _unforcedErrorChance = 0.02;
        break;
    }
    _reactionLagTimer = _currentReactionLag;

    if ((ballVx > 0.18 && velocityX < -0.25) || (ballVx < -0.18 && velocityX > 0.25)) {
      _isWrongFooted = true;
      _wrongFootRecoveryTimer = (difficulty == AIDifficulty.rookie) ? 0.25 : 0.12;
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
    final aiMultiplier = difficulty.speedMultiplier;

    if (_reactionLagTimer > 0) {
      _reactionLagTimer -= dt;
    }

    if (_wrongFootRecoveryTimer > 0) {
      _wrongFootRecoveryTimer -= dt;
      if (_wrongFootRecoveryTimer <= 0) {
        _isWrongFooted = false;
      }
    }

    // 1. 2D Depth Positioning: Moves into position to hit the ball
    if (ballVy > 0) {
      if (currentRally <= 1) {
        // Receiving serve: Hold baseline position to receive the bounce
        targetY = 0.88;
        courtZone = AiCourtZone.baseline;
      } else if (ballZ < 1.25 && ballVy < 0.65) {
        // Soft drop/dink: Move forward to NVZ Kitchen line
        targetY = (difficulty == AIDifficulty.rookie) ? 0.80 : 0.68;
        courtZone = AiCourtZone.kitchen;
      } else if (ballZ > 1.8 && ballVy > 0.75) {
        // Deep lob: Retreat to baseline
        targetY = 0.98;
        courtZone = AiCourtZone.baseline;
      } else {
        targetY = (difficulty == AIDifficulty.rookie) ? 0.92 : 0.84;
        courtZone = AiCourtZone.transition;
      }
    } else {
      // Ball traveling back to player: Reset to ready spot
      if (difficulty == AIDifficulty.legend && currentRally > 2) {
        targetY = 0.72;
      } else if (difficulty == AIDifficulty.pro && currentRally > 2) {
        targetY = 0.80;
      } else {
        targetY = 0.88;
      }
    }

    // 2. Lateral Tracking: Steers to intercept ball X
    if (_reactionLagTimer <= 0) {
      final double flightTimeRemaining = ((y - ballY) / (ballVy.abs() + 0.001)).clamp(0.0, 1.2);
      final double predictedX = (ballX + (ballVx * flightTimeRemaining)).clamp(-0.84, 0.84);
      targetX = predictedX;
    }

    final double inertiaPenalty = _isWrongFooted ? 0.65 : 1.0;
    final oldX = x;
    final oldY = y;

    // Responsive athletic shuffle
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
    final playerIsDeep = playerY < 0.05;
    final playerIsAtKitchen = playerY > 0.22;

    if (isUnderPressure && rng.nextDouble() < _unforcedErrorChance) {
      final errorType = rng.nextBool();
      if (errorType) {
        onApplyShot(-0.50 * pace, 0.35, (rng.nextDouble() - 0.5) * 0.25, 0.0, 0.0, ShotType.normal);
      } else {
        final outSide = rng.nextBool() ? 1.08 : -1.08;
        onApplyShot(-0.70 * pace, 1.7, (outSide - x) * 0.5, 0.0, 0.0, ShotType.normal);
      }
      return;
    }

    double openCourtX;
    if (playerX > 0.2) {
      openCourtX = -0.50 + (rng.nextDouble() - 0.5) * 0.20;
    } else if (playerX < -0.2) {
      openCourtX = 0.50 + (rng.nextDouble() - 0.5) * 0.20;
    } else {
      openCourtX = (rng.nextBool() ? 0.55 : -0.55);
    }
    openCourtX = openCourtX.clamp(-0.75, 0.75);

    if (ballZ > 1.15 && !playerIsAtKitchen) {
      currentShot = ShotType.smash;
      onApplyShot(
        -0.88 * aiChar.swingPower * pace,
        1.25,
        (openCourtX - x) * 0.45,
        (rng.nextDouble() - 0.5) * 0.10,
        0.20,
        ShotType.smash,
      );
    } else if (playerIsDeep && (courtZone == AiCourtZone.kitchen || rng.nextDouble() < 0.40)) {
      currentShot = ShotType.drive;
      onApplyShot(
        -0.42 * pace,
        1.35,
        (openCourtX - x) * 0.32,
        0.0,
        -0.12,
        ShotType.drive,
      );
    } else if (playerIsAtKitchen && rng.nextDouble() < 0.35) {
      currentShot = ShotType.lob;
      onApplyShot(
        -0.60 * aiChar.swingPower * pace,
        2.45,
        (openCourtX - x) * 0.28,
        0.0,
        -0.15,
        ShotType.lob,
      );
    } else {
      currentShot = ShotType.normal;
      onApplyShot(
        -0.66 * aiChar.swingPower * pace,
        1.80,
        (openCourtX - x) * 0.40,
        (rng.nextDouble() - 0.5) * 0.08,
        0.08,
        ShotType.normal,
      );
    }
  }
}