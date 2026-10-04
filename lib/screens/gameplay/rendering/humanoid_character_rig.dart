// lib/screens/gameplay/rendering/humanoid_character_rig.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/game_state.dart';
import '../gameplay_screen.dart';

class HumanoidCharacterRig {
  static void draw({
    required Canvas canvas,
    required double scale,
    required String charId,
    required SpriteView view,
    required SpriteAction action,
    required ShotType shotType,
    required bool isDiving,
    required Color bodyColor,
    required Color accentColor,
    required double swingAngle,
    required bool isOpponent,
    required double velocityX,
    required double velocityY,
    required double gameTime,
    required PaddleModel equippedPaddle,
    required bool isServing,
    required double playerSwingAngle,
    required double aiSwingAngle,
    required bool blitzActive,
  }) {
    final isMovingX = velocityX.abs() > 0.15;
    final isMovingY = velocityY.abs() > 0.15;
    final isMoving = isMovingX || isMovingY;

    final isRunningUp = velocityY < -0.20;
    final isRunningDown = velocityY > 0.20;
    final isMovingRight = velocityX > 0.20;
    final isMovingLeft = velocityX < -0.20;

    final strideCycle = isMoving ? math.sin(gameTime * 12.0) : 0.0;

    final isLoss = action == SpriteAction.loss;
    final headDropY = isLoss ? (6.0 * scale) : 0.0;
    final breathBob = isLoss ? 0.0 : math.sin(gameTime * 4.5) * 1.4 * scale;

    final isSmash = (shotType == ShotType.smash || shotType == ShotType.signatureBlitz) &&
        (action == SpriteAction.hit || swingAngle > 0.0);
    final jumpElevateY = isSmash ? -math.sin((swingAngle / math.pi).clamp(0.0, 1.0) * math.pi) * 16 * scale : 0.0;

    final isCoachBoomer = charId == 'boomer' || charId == 'coach_boomer';

    // Grounding Oval Shadow
    final shadowScale = (1.0 - (jumpElevateY.abs() * 0.04)).clamp(0.5, 1.0);
    final shadowWidth = (isDiving ? 52.0 : 38.0) * scale * shadowScale;
    final shadowHeight = (isDiving ? 12.0 : 14.0) * scale * shadowScale;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset((isDiving ? (velocityX.sign * 12 * scale) : 0), 10 * scale),
        width: shadowWidth,
        height: shadowHeight,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45 * shadowScale),
    );

    canvas.save();

    if (isDiving) {
      canvas.rotate(isOpponent ? -0.38 : 0.38);
    } else if (isMovingRight) {
      canvas.rotate(0.12);
    } else if (isMovingLeft) {
      canvas.rotate(-0.12);
    }

    final forwardLeanY = isRunningUp ? -2.5 * scale : (isRunningDown ? 1.5 * scale : 0.0);

    if (shotType == ShotType.signatureBlitz && (blitzActive || swingAngle > 0.0)) {
      final auraPaint = Paint()
        ..color = (isOpponent ? bodyColor : accentColor).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.drawCircle(Offset(0, -14 * scale + jumpElevateY), 30 * scale, auraPaint);
    }

    // Legs & Sneakers
    final skinPaint = Paint()..color = const Color(0xFFFFCC80);
    final legPaint = Paint()
      ..color = const Color(0xFFE0A96D)
      ..strokeWidth = 4.2 * scale
      ..strokeCap = StrokeCap.round;

    double leftLegStride = (strideCycle * 6);
    double rightLegStride = (-strideCycle * 6);
    if (isMovingX && !isMovingY) {
      leftLegStride = math.sin(gameTime * 14.0) * 4;
      rightLegStride = -math.sin(gameTime * 14.0) * 4;
    }

    final leftLegOffset = Offset(
      (-6 + (isMovingRight ? 2 : 0)) * scale,
      (14 + (isSmash ? -6 : leftLegStride)) * scale + jumpElevateY,
    );
    final rightLegOffset = Offset(
      (6 + (isMovingLeft ? -2 : 0)) * scale,
      (14 - (isSmash ? -6 : rightLegStride)) * scale + jumpElevateY,
    );

    canvas.drawLine(Offset(-6 * scale, jumpElevateY), leftLegOffset, legPaint);
    canvas.drawLine(Offset(6 * scale, jumpElevateY), rightLegOffset, legPaint);

    final shoePaint = Paint()..color = isCoachBoomer ? const Color(0xFF1E293B) : Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftLegOffset + Offset(0, 3 * scale), width: 10 * scale, height: 5 * scale),
        Radius.circular(2 * scale),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightLegOffset + Offset(0, 3 * scale), width: 10 * scale, height: 5 * scale),
        Radius.circular(2 * scale),
      ),
      shoePaint,
    );

    // Shorts
    final shortsRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, 2 * scale + jumpElevateY), width: 22 * scale, height: 12 * scale),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(shortsRect, Paint()..color = isCoachBoomer ? Colors.black : const Color(0xFF1E293B));
    canvas.drawRRect(
      shortsRect,
      Paint()
        ..color = isCoachBoomer ? Colors.white70 : accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale,
    );

    // Torso / Jersey (Coach Boomer has Referee Black & White Stripes)
    final jerseyCenter = Offset(0, (-14 + breathBob + jumpElevateY + forwardLeanY) * scale);
    final jerseyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: jerseyCenter, width: 26 * scale, height: 22 * scale),
      Radius.circular(6 * scale),
    );

    if (isCoachBoomer) {
      canvas.drawRRect(jerseyRect, Paint()..color = Colors.white);
      final stripePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 3.2 * scale;
      for (double sx = -9 * scale; sx <= 9 * scale; sx += 6 * scale) {
        canvas.drawLine(
          Offset(jerseyCenter.dx + sx, jerseyCenter.dy - 10 * scale),
          Offset(jerseyCenter.dx + sx, jerseyCenter.dy + 10 * scale),
          stripePaint,
        );
      }
    } else {
      canvas.drawRRect(jerseyRect, Paint()..color = bodyColor);
      canvas.drawRRect(
        jerseyRect,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * scale,
      );
    }

    if (!isCoachBoomer) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: charId[0].toUpperCase(),
          style: TextStyle(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        jerseyCenter - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Head & Headwear
    final headCenter = Offset(0, (-32 + breathBob + headDropY + jumpElevateY + (forwardLeanY * 1.3)) * scale);
    final headRadius = 10.0 * scale;

    canvas.drawCircle(headCenter + Offset(0, 2 * scale), headRadius, Paint()..color = Colors.black45);
    canvas.drawCircle(headCenter, headRadius, skinPaint);

    if (isCoachBoomer) {
      // Coach Boomer: Silver-Grey Hair & Whistle Lanyard
      final hairPaint = Paint()..color = const Color(0xFFCFD8DC);
      canvas.drawCircle(headCenter - Offset(0, 3 * scale), 9.5 * scale, hairPaint);
      final capPaint = Paint()..color = Colors.black;
      canvas.drawCircle(headCenter - Offset(0, 4 * scale), 9 * scale, capPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: headCenter + Offset((isOpponent ? -5 : 5) * scale, 3 * scale), width: 10 * scale, height: 3 * scale),
          Radius.circular(1.5 * scale),
        ),
        capPaint,
      );

      // Whistle Lanyard & Silver Whistle
      canvas.drawLine(headCenter + Offset(0, 8 * scale), jerseyCenter - Offset(0, 4 * scale), Paint()..color = Colors.black87..strokeWidth = 1.2 * scale);
      canvas.drawCircle(jerseyCenter - Offset(0, 2 * scale), 2.5 * scale, Paint()..color = const Color(0xFFFFD54F));
    } else if (charId == 'aria') {
      final hairPaint = Paint()..color = const Color(0xFFD84315);
      canvas.drawCircle(headCenter - Offset(0, 3 * scale), 9 * scale, hairPaint);
      final ponytailDir = isMovingLeft ? 8 : (isMovingRight ? -8 : (isOpponent ? -8 : 8));
      canvas.drawOval(
        Rect.fromCenter(
          center: headCenter + Offset(ponytailDir * scale, -2 * scale),
          width: 8 * scale,
          height: 12 * scale,
        ),
        hairPaint,
      );
    } else if (charId == 'marcus') {
      final hairPaint = Paint()..color = const Color(0xFF3E2723);
      canvas.drawCircle(headCenter - Offset(0, 3 * scale), 9.5 * scale, hairPaint);
      final bandRect = Rect.fromCenter(center: headCenter - Offset(0, 1 * scale), width: 19 * scale, height: 4 * scale);
      canvas.drawRect(bandRect, Paint()..color = AppColors.opticYellow);
    } else if (charId == 'elena') {
      final hairPaint = Paint()..color = const Color(0xFFBA68C8);
      canvas.drawCircle(headCenter - Offset(0, 3 * scale), 9 * scale, hairPaint);
      canvas.drawCircle(headCenter + Offset(0, -10 * scale), 5 * scale, hairPaint);
    } else {
      final capPaint = Paint()..color = Colors.white;
      canvas.drawCircle(headCenter - Offset(0, 4 * scale), 9.5 * scale, capPaint);
      final brimDir = isMovingLeft ? -5 : (isMovingRight ? 5 : (isOpponent ? -5 : 5));
      final brimRect = Rect.fromCenter(
        center: headCenter + Offset(brimDir * scale, 3 * scale),
        width: 10 * scale,
        height: 3 * scale,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(brimRect, Radius.circular(1.5 * scale)), capPaint);
    }

    // Left Arm (Free hand / Toss)
    final leftShoulder = jerseyCenter + Offset(-12 * scale, -6 * scale);
    Offset leftHand = leftShoulder + Offset(-4 * scale, 12 * scale);

    if (action == SpriteAction.serve && isServing) {
      leftHand = leftShoulder + Offset(-3 * scale, -18 * scale);
    } else if (isSmash) {
      leftHand = leftShoulder + Offset(-8 * scale, -8 * scale);
    } else if (isMovingX) {
      leftHand = leftShoulder + Offset((isMovingLeft ? -6 : 2) * scale, 10 * scale);
    }

    final armPaint = Paint()
      ..color = const Color(0xFFFFCC80)
      ..strokeWidth = 3.6 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(leftShoulder, leftHand, armPaint);

    // Right Paddle Arm
    final rightShoulder = jerseyCenter + Offset(12 * scale, -6 * scale);
    double armAngle = isOpponent ? 0.35 : -0.35;

    if (isLoss) {
      armAngle = isOpponent ? -0.1 : 0.1;
    } else if (isSmash) {
      final smashProgress = (swingAngle / math.pi).clamp(0.0, 1.0);
      armAngle = isOpponent ? (1.5 - (smashProgress * 2.8)) : (-1.5 + (smashProgress * 2.8));
    } else if (shotType == ShotType.lob && (action == SpriteAction.hit || swingAngle > 0.0)) {
      final lobProgress = (swingAngle / math.pi).clamp(0.0, 1.0);
      armAngle = isOpponent ? (-0.6 + (lobProgress * 1.8)) : (0.6 - (lobProgress * 1.8));
    } else if (action == SpriteAction.hit || swingAngle > 0.0) {
      final activeSwing = isOpponent ? aiSwingAngle : playerSwingAngle;
      armAngle += (isOpponent ? activeSwing : -activeSwing);
    } else if (action == SpriteAction.serve) {
      armAngle = isOpponent ? -0.4 : 0.4;
    } else if (isMovingRight) {
      armAngle += (isOpponent ? -0.2 : 0.2);
    }

    canvas.save();
    canvas.translate(rightShoulder.dx, rightShoulder.dy);
    canvas.rotate(armAngle);

    final wristPos = Offset(0, 16 * scale);
    canvas.drawLine(Offset.zero, wristPos, armPaint);
    canvas.drawCircle(wristPos, 3.2 * scale, Paint()..color = const Color(0xFFE0A96D));

    final handleRect = Rect.fromLTWH(-2 * scale, wristPos.dy - (2 * scale), 4 * scale, 10 * scale);
    canvas.drawRect(handleRect, Paint()..color = const Color(0xFF1E293B));

    final paddleCenter = Offset(0, wristPos.dy + 22 * scale);
    final paddleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: paddleCenter, width: 22 * scale, height: 30 * scale),
      Radius.circular(6 * scale),
    );

    canvas.drawRRect(
      paddleRect,
      Paint()..color = isCoachBoomer ? const Color(0xFF263238) : (isOpponent ? const Color(0xFF1E293B) : equippedPaddle.primaryColor),
    );
    canvas.drawRRect(
      paddleRect,
      Paint()
        ..color = isCoachBoomer ? AppColors.opticYellow : (isOpponent ? AppColors.opticYellow : equippedPaddle.accentColor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * scale,
    );

    canvas.restore();
    canvas.restore();
  }
}