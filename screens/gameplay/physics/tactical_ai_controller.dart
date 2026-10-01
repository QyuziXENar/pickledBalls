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

  double y = 0.95;
  double targetY = 0.95;
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
    y = 0.95;
    targetY = 0.95;
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
        _currentReactionLag = 0.24 + rng.nextDouble() * 0.08;
        _unforcedErrorChance = 0.22;
        break;
      case AIDifficulty.pro:
        _currentReactionLag = 0.11 + rng.nextDouble() * 0.05;
        _unforcedErrorChance = 0.08;
        break;
      case AIDifficulty.legend:
        _currentReactionLag = 0.03 + rng.nextDouble() * 0.03;
        _unforcedErrorChance = 0.02;
        break;
    }
    _reactionLagTimer = _currentReactionLag;

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

    // 1. 2D Y Positioning
    if (ballVy > 0) {
      if (ballZ < 1.35 && ballVy < 0.72) {
        targetY = (difficulty == AIDifficulty.rookie) ? 0.82 : 0.68;
        courtZone = AiCourtZone.kitchen;
      } else if (ballZ > 1.8 && ballVy > 0.8) {
        targetY = 1.02;
        courtZone = AiCourtZone.baseline;
      } else {
        targetY = (difficulty == AIDifficulty.rookie) ? 0.98 : 0.88;
        courtZone = AiCourtZone.transition;
      }
    } else {
      if (difficulty == AIDifficulty.legend && currentRally > 1) {
        targetY = 0.70;
      } else if (difficulty == AIDifficulty.pro && currentRally > 2) {
        targetY = 0.78;
      } else {
        targetY = 0.95;
      }
    }

    // 2. Trajectory intercept
    if (_reactionLagTimer <= 0) {
      final flightTimeRemaining = ((y - ballY) / (ballVy.abs() + 0.001)).clamp(0.0, 1.2);
      final predictedX = (ballX + (ballVx * flightTimeRemaining)).clamp(-0.88, 0.88);
      targetX = predictedX;
    }

    final double inertiaPenalty = _isWrongFooted ? 0.45 : 1.0;

    final oldX = x;
    final oldY = y;

    // SPRINT D SPEED RETUNING: Down from 4.4 to a realistic 3.0 m/s
    final speedX = 3.0 * aiChar.moveSpeed * aiMultiplier * inertiaPenalty;
    final speedY = 1.9 * aiChar.moveSpeed * aiMultiplier;

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
        onApplyShot(-0.55 * pace, 0.32, (rng.nextDouble() - 0.5) * 0.3, 0.0, 0.0, ShotType.normal);
      } else {
        final outSide = rng.nextBool() ? 1.15 : -1.15;
        onApplyShot(-0.75 * pace, 1.8, (outSide - x) * 0.6, 0.0, 0.0, ShotType.normal);
      }
      return;
    }

    double openCourtX;
    if (playerX > 0.2) {
      openCourtX = -0.55 + (rng.nextDouble() - 0.5) * 0.25;
    } else if (playerX < -0.2) {
      openCourtX = 0.55 + (rng.nextDouble() - 0.5) * 0.25;
    } else {
      openCourtX = (rng.nextBool() ? 0.60 : -0.60);
    }
    openCourtX = openCourtX.clamp(-0.80, 0.80);

    if (ballZ > 1.18 && !playerIsAtKitchen) {
      currentShot = ShotType.smash;
      onApplyShot(
        -0.94 * aiChar.swingPower * pace,
        1.30,
        (openCourtX - x) * 0.52,
        (rng.nextDouble() - 0.5) * 0.12,
        0.25,
        ShotType.smash,
      );
    } else if (playerIsDeep && (courtZone == AiCourtZone.kitchen || rng.nextDouble() < 0.45)) {
      currentShot = ShotType.drive;
      onApplyShot(
        -0.44 * pace,
        1.40,
        (openCourtX - x) * 0.35,
        0.0,
        -0.15,
        ShotType.drive,
      );
    } else if (playerIsAtKitchen && rng.nextDouble() < 0.38) {
      currentShot = ShotType.lob;
      onApplyShot(
        -0.66 * aiChar.swingPower * pace,
        2.65,
        (openCourtX - x) * 0.30,
        0.0,
        -0.20,
        ShotType.lob,
      );
    } else {
      currentShot = ShotType.normal;
      onApplyShot(
        -0.72 * aiChar.swingPower * pace,
        1.95,
        (openCourtX - x) * 0.45,
        (rng.nextDouble() - 0.5) * 0.10,
        0.10,
        ShotType.normal,
      );
    }
  }
}