// lib/screens/gameplay/physics/tactical_ai_controller.dart

import 'dart:math' as math;
import '../../../core/constants/app_assets.dart';
import '../../../models/game_state.dart';
import '../gameplay_screen.dart';

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
  }) {
    final aiMultiplier = difficulty.speedMultiplier;
    final rng = math.Random();

    // 1. 2D Y Positioning: Advances to NVZ Kitchen or retreats to Baseline
    if (ballVy > 0 && ballY > 0.4) {
      if (ballZ < 1.4 && ballVy < 0.70) {
        targetY = 0.68; // Kitchen dink line
      } else {
        targetY = 0.95; // Deep baseline
      }
    } else if (ballVy < 0) {
      if (currentRally > 2 && rng.nextDouble() < 0.35) {
        targetY = 0.75; // Mid-court balance
      } else {
        targetY = 0.95;
      }
    }

    // 2. Trajectory prediction & wrong-footing inertia penalty
    final predictedX = (ballX + ballVx * 0.35).clamp(-0.90, 0.90);
    final movingAway = (ballVx > 0 && velocityX < -0.2) || (ballVx < 0 && velocityX > 0.2);
    final inertiaPenalty = movingAway ? 0.65 : 1.0;

    targetX = predictedX;

    final oldX = x;
    final oldY = y;

    final speedX = 4.4 * aiChar.moveSpeed * aiMultiplier * inertiaPenalty;
    final speedY = 2.8 * aiChar.moveSpeed * aiMultiplier;

    x += (targetX - x) * math.min(1.0, speedX * dt);
    y += (targetY - y) * math.min(1.0, speedY * dt);

    velocityX = (x - oldX) / dt;
    velocityY = (y - oldY) / dt;

    if (velocityX.abs() > 0.25 || velocityY.abs() > 0.25) {
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
    required Function(double vy, double vz, double vx, double curve, double spinZ, ShotType shot) onApplyShot,
  }) {
    final rng = math.Random();
    final playerIsDeep = playerY < 0.05;
    final playerIsAtKitchen = playerY > 0.22;

    // AI identifies open court space away from player
    final openCourtX = (-playerX * 0.60 + (rng.nextDouble() - 0.5) * 0.20).clamp(-0.80, 0.80);

    if (ballZ > 1.15 && !playerIsAtKitchen) {
      // Overhead Smash
      currentShot = ShotType.smash;
      onApplyShot(
        -0.92 * aiChar.swingPower * pace,
        1.30,
        (openCourtX - x) * 0.50,
        (rng.nextDouble() - 0.5) * 0.12,
        0.20,
        ShotType.smash,
      );
    } else if (playerIsDeep && rng.nextDouble() < 0.40 && currentRally > 1) {
      // Kitchen Drop / Dink
      currentShot = ShotType.drive;
      onApplyShot(
        -0.46 * pace,
        1.45,
        (openCourtX - x) * 0.35,
        0.0,
        -0.15,
        ShotType.drive,
      );
    } else if (playerIsAtKitchen && rng.nextDouble() < 0.35) {
      // Deep Lob over player
      currentShot = ShotType.lob;
      onApplyShot(
        -0.68 * aiChar.swingPower * pace,
        2.65,
        (openCourtX - x) * 0.30,
        0.0,
        -0.25,
        ShotType.lob,
      );
    } else {
      // Baseline Drive
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