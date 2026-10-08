// lib/screens/gameplay/rendering/humanoid_character_rig.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../models/game_state.dart';
import '../gameplay_models.dart';

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
    canvas.save();

    final double s = scale;
    final bool isBack = view == SpriteView.back;

    final double moveSpeed = math.sqrt(velocityX * velocityX + velocityY * velocityY);
    final double walkCycle = (gameTime * 9.5 * (moveSpeed > 0.05 ? 1.0 : 0.4)) % (math.pi * 2);
    final double bobOffset = (moveSpeed > 0.05 ? math.sin(walkCycle * 2).abs() * 3.5 : math.sin(gameTime * 3.0) * 1.5) * s;

    final Color skinTone = _getSkinTone(charId);
    final Color hairColor = _getHairColor(charId);

    final Color primaryJersey = bodyColor;
    final Color secondaryJersey = accentColor;
    final Color shortsColor = isOpponent ? const Color(0xFF1E293B) : const Color(0xFF0F172A);

    _drawFloorShadow(canvas, s);

    canvas.translate(0, -bobOffset);

    // 1. LEGS & SNEAKERS
    _drawLegsAndSneakers(
      canvas: canvas,
      s: s,
      skinTone: skinTone,
      walkCycle: walkCycle,
      moveSpeed: moveSpeed,
      isDiving: isDiving,
      accentColor: secondaryJersey,
    );

    // 2. SHORTS
    _drawAthleticShorts(
      canvas: canvas,
      s: s,
      shortsColor: shortsColor,
      accentColor: secondaryJersey,
      walkCycle: walkCycle,
      moveSpeed: moveSpeed,
    );

    // 3. JERSEY
    _drawProJersey(
      canvas: canvas,
      s: s,
      primaryColor: primaryJersey,
      accentColor: secondaryJersey,
      charId: charId,
      isBack: isBack,
      skinTone: skinTone,
    );

    // 4. ARMS & PADDLE
    _drawArmsAndPaddle(
      canvas: canvas,
      s: s,
      skinTone: skinTone,
      jerseyColor: primaryJersey,
      accentColor: secondaryJersey,
      swingAngle: swingAngle,
      action: action,
      equippedPaddle: equippedPaddle,
      isBack: isBack,
      blitzActive: blitzActive,
    );

    // 5. HEAD & HAIR
    _drawHeadAndHair(
      canvas: canvas,
      s: s,
      charId: charId,
      skinTone: skinTone,
      hairColor: hairColor,
      isBack: isBack,
      accentColor: secondaryJersey,
    );

    canvas.restore();
  }

  static void _drawLegsAndSneakers({
    required Canvas canvas,
    required double s,
    required Color skinTone,
    required double walkCycle,
    required double moveSpeed,
    required bool isDiving,
    required Color accentColor,
  }) {
    final double leftLegAngle = moveSpeed > 0.05 ? math.sin(walkCycle) * 0.35 : 0.0;
    final double rightLegAngle = moveSpeed > 0.05 ? -math.sin(walkCycle) * 0.35 : 0.0;

    _drawSingleLeg(canvas, s, isLeft: true, angle: leftLegAngle, skinTone: skinTone, accentColor: accentColor);
    _drawSingleLeg(canvas, s, isLeft: false, angle: rightLegAngle, skinTone: skinTone, accentColor: accentColor);
  }

  static void _drawSingleLeg(
    Canvas canvas,
    double s, {
    required bool isLeft,
    required double angle,
    required Color skinTone,
    required Color accentColor,
  }) {
    canvas.save();
    final double hipX = (isLeft ? -7.0 : 7.0) * s;
    const double hipY = 22.0;
    canvas.translate(hipX, hipY * s);
    canvas.rotate(angle);

    // Leg
    final legPaint = Paint()..color = skinTone;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-3.2 * s, 0, 6.4 * s, 18.0 * s), Radius.circular(3.0 * s)),
      legPaint,
    );

    // Crew Sock
    final sockRect = Rect.fromLTWH(-3.4 * s, 11.0 * s, 6.8 * s, 8.0 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(sockRect, Radius.circular(1.5 * s)), Paint()..color = const Color(0xFFF8FAFC));

    final stripePaint = Paint()..color = accentColor;
    canvas.drawRect(Rect.fromLTWH(-3.4 * s, 12.5 * s, 6.8 * s, 1.2 * s), stripePaint);
    canvas.drawRect(Rect.fromLTWH(-3.4 * s, 14.5 * s, 6.8 * s, 1.2 * s), stripePaint);

    // Sneaker
    const double footY = 18.5;
    final double footX = isLeft ? -4.5 : -1.5;

    // Outsole (Gum rubber tread)
    final outsolePath = Path();
    outsolePath.moveTo((footX - 2.5) * s, (footY + 7.5) * s);
    outsolePath.lineTo((footX + 9.5) * s, (footY + 7.5) * s);
    outsolePath.lineTo((footX + 8.5) * s, (footY + 8.8) * s);
    outsolePath.lineTo((footX - 2.0) * s, (footY + 8.8) * s);
    outsolePath.close();
    canvas.drawPath(outsolePath, Paint()..color = const Color(0xFFD97706));

    // Midsole (White EVA cushion)
    final midsoleRect = Rect.fromLTWH((footX - 2.5) * s, (footY + 5.0) * s, 12.0 * s, 2.5 * s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(midsoleRect, Radius.circular(1.2 * s)),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Upper
    final upperPath = Path();
    upperPath.moveTo((footX - 2.0) * s, (footY + 5.0) * s);
    upperPath.lineTo((footX - 1.5) * s, (footY + 0.5) * s);
    upperPath.lineTo((footX + 3.0) * s, (footY + 0.5) * s);
    upperPath.lineTo((footX + 6.0) * s, (footY + 2.5) * s);
    upperPath.lineTo((footX + 9.0) * s, (footY + 5.0) * s);
    upperPath.close();

    canvas.drawPath(
      upperPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE2E8F0),
            accentColor.withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromLTWH(footX * s, footY * s, 10 * s, 6 * s)),
    );

    // Sport Swoosh
    final swooshPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset((footX + 0.5) * s, (footY + 4.0) * s),
      Offset((footX + 5.5) * s, (footY + 2.8) * s),
      swooshPaint,
    );

    // Toe Cap
    canvas.drawOval(
      Rect.fromCenter(center: Offset((footX + 7.5) * s, (footY + 4.5) * s), width: 3.5 * s, height: 2.2 * s),
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.65),
    );

    canvas.restore();
  }

  static void _drawAthleticShorts({
    required Canvas canvas,
    required double s,
    required Color shortsColor,
    required Color accentColor,
    required double walkCycle,
    required double moveSpeed,
  }) {
    const double waistY = 10.0;
    const double shortsH = 15.0;

    final shortsPath = Path();
    shortsPath.moveTo(-13.0 * s, waistY * s);
    shortsPath.lineTo(13.0 * s, waistY * s);
    shortsPath.lineTo(15.5 * s, (waistY + shortsH) * s);
    shortsPath.lineTo(2.0 * s, (waistY + shortsH) * s);
    shortsPath.lineTo(0.0 * s, (waistY + shortsH - 4.0) * s);
    shortsPath.lineTo(-2.0 * s, (waistY + shortsH) * s);
    shortsPath.lineTo(-15.5 * s, (waistY + shortsH) * s);
    shortsPath.close();

    canvas.drawPath(
      shortsPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            shortsColor,
            Color.lerp(shortsColor, Colors.black, 0.25)!,
          ],
        ).createShader(Rect.fromLTWH(-16 * s, waistY * s, 32 * s, shortsH * s)),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-13.2 * s, (waistY - 1.5) * s, 26.4 * s, 3.2 * s), Radius.circular(1.5 * s)),
      Paint()..color = const Color(0xFF0F172A),
    );

    final pipingPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.8 * s
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(-13.0 * s, (waistY + 2.0) * s), Offset(-15.5 * s, (waistY + shortsH) * s), pipingPaint);
    canvas.drawLine(Offset(-15.5 * s, (waistY + shortsH) * s), Offset(-2.0 * s, (waistY + shortsH) * s), pipingPaint);

    canvas.drawLine(Offset(13.0 * s, (waistY + 2.0) * s), Offset(15.5 * s, (waistY + shortsH) * s), pipingPaint);
    canvas.drawLine(Offset(15.5 * s, (waistY + shortsH) * s), Offset(2.0 * s, (waistY + shortsH) * s), pipingPaint);
  }

  static void _drawProJersey({
    required Canvas canvas,
    required double s,
    required Color primaryColor,
    required Color accentColor,
    required String charId,
    required bool isBack,
    required Color skinTone,
  }) {
    const double chestTopY = -12.0;
    const double torsoH = 22.0;

    final jerseyPath = Path();
    jerseyPath.moveTo(-12.5 * s, chestTopY * s);
    jerseyPath.lineTo(12.5 * s, chestTopY * s);
    jerseyPath.lineTo(13.5 * s, (chestTopY + torsoH) * s);
    jerseyPath.lineTo(-13.5 * s, (chestTopY + torsoH) * s);
    jerseyPath.close();

    canvas.drawPath(
      jerseyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            Color.lerp(primaryColor, Colors.black, 0.18)!,
          ],
        ).createShader(Rect.fromLTWH(-14 * s, chestTopY * s, 28 * s, torsoH * s)),
    );

    final ventPaint = Paint()..color = accentColor.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-13.5 * s, (chestTopY + 4.0) * s, 3.2 * s, 16.0 * s), Radius.circular(1.0 * s)),
      ventPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(10.3 * s, (chestTopY + 4.0) * s, 3.2 * s, 16.0 * s), Radius.circular(1.0 * s)),
      ventPaint,
    );

    final collarPath = Path();
    if (isBack) {
      collarPath.moveTo(-6.5 * s, chestTopY * s);
      collarPath.quadraticBezierTo(0, (chestTopY + 2.5) * s, 6.5 * s, chestTopY * s);
    } else {
      collarPath.moveTo(-6.5 * s, chestTopY * s);
      collarPath.lineTo(0, (chestTopY + 6.0) * s);
      collarPath.lineTo(6.5 * s, chestTopY * s);
    }
    canvas.drawPath(
      collarPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * s
        ..strokeCap = StrokeCap.round,
    );

    final String initial = charId.isNotEmpty ? charId[0].toUpperCase() : 'A';
    _drawJerseyBadge(canvas, s, initial, Offset(0, (chestTopY + 10.0) * s), isBack);
  }

  static void _drawJerseyBadge(Canvas canvas, double s, String initial, Offset center, bool isBack) {
    canvas.drawCircle(center, 6.2 * s, Paint()..color = Colors.white);
    canvas.drawCircle(center, 5.2 * s, Paint()..color = const Color(0xFF0F172A));

    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5 * s,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)));
  }

  static void _drawArmsAndPaddle({
    required Canvas canvas,
    required double s,
    required Color skinTone,
    required Color jerseyColor,
    required Color accentColor,
    required double swingAngle,
    required SpriteAction action,
    required PaddleModel equippedPaddle,
    required bool isBack,
    required bool blitzActive,
  }) {
    final armSkin = Paint()..color = skinTone;
    final sleevePaint = Paint()..color = jerseyColor;

    canvas.save();
    canvas.translate(-13.0 * s, -8.0 * s);
    canvas.rotate(-0.25 + math.sin(swingAngle) * 0.2);
    canvas.drawCircle(Offset.zero, 3.8 * s, sleevePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-2.5 * s, 0, 5.0 * s, 18.0 * s), Radius.circular(2.5 * s)), armSkin);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-2.8 * s, 11.0 * s, 5.6 * s, 3.8 * s), Radius.circular(1.0 * s)), Paint()..color = accentColor);
    canvas.restore();

    canvas.save();
    canvas.translate(13.0 * s, -8.0 * s);
    final double armRotation = (action == SpriteAction.hit || action == SpriteAction.serve)
        ? -1.2 + (swingAngle * 1.6)
        : 0.35 + math.sin(swingAngle) * 0.15;
    canvas.rotate(armRotation);

    canvas.drawCircle(Offset.zero, 3.8 * s, sleevePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-2.5 * s, 0, 5.0 * s, 18.0 * s), Radius.circular(2.5 * s)), armSkin);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-3.0 * s, 12.0 * s, 6.0 * s, 4.2 * s), Radius.circular(1.2 * s)),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(Rect.fromLTWH(-3.0 * s, 13.5 * s, 6.0 * s, 1.2 * s), Paint()..color = accentColor);

    canvas.drawCircle(Offset(0, 19.5 * s), 3.2 * s, armSkin);

    canvas.save();
    canvas.translate(0, 20.0 * s);
    canvas.rotate(0.35);

    _drawProPaddle(canvas, s, equippedPaddle, blitzActive);

    canvas.restore();
    canvas.restore();
  }

  static void _drawProPaddle(Canvas canvas, double s, PaddleModel paddle, bool blitzActive) {
    final handleRect = Rect.fromLTWH(-2.0 * s, 0, 4.0 * s, 14.0 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(handleRect, Radius.circular(1.0 * s)), Paint()..color = const Color(0xFF1E293B));

    final tapeLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.0 * s;
    for (double y = 2.5; y < 12.0; y += 2.5) {
      canvas.drawLine(Offset(-2.0 * s, y * s), Offset(2.0 * s, (y + 1.5) * s), tapeLine);
    }
    canvas.drawRect(Rect.fromLTWH(-2.4 * s, 12.0 * s, 4.8 * s, 2.0 * s), Paint()..color = Colors.black);

    final paddleCenter = Offset(0, 26.0 * s);
    final paddleW = 20.0 * s;
    final paddleH = 26.0 * s;
    final paddleRect = Rect.fromCenter(center: paddleCenter, width: paddleW, height: paddleH);

    if (blitzActive) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(paddleRect.inflate(4.0 * s), Radius.circular(7.0 * s)),
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(paddleRect, Radius.circular(6.0 * s)),
      Paint()..color = const Color(0xFF0A0F1D),
    );

    final faceRect = Rect.fromCenter(center: paddleCenter, width: paddleW - 2.8 * s, height: paddleH - 2.8 * s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, Radius.circular(4.5 * s)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            paddle.primaryColor,
            Color.lerp(paddle.primaryColor, Colors.black, 0.35)!,
          ],
        ).createShader(faceRect),
    );

    final graphicPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round;

    final chevron = Path()
      ..moveTo(-5.0 * s, 22.0 * s)
      ..lineTo(0, 27.0 * s)
      ..lineTo(5.0 * s, 22.0 * s);
    canvas.drawPath(chevron, graphicPaint);
  }

  static void _drawHeadAndHair({
    required Canvas canvas,
    required double s,
    required String charId,
    required Color skinTone,
    required Color hairColor,
    required bool isBack,
    required Color accentColor,
  }) {
    const double headCenterY = -22.0;

    canvas.drawCircle(Offset(0, headCenterY * s), 9.0 * s, Paint()..color = skinTone);

    if (!isBack) {
      final eyePaint = Paint()..color = const Color(0xFF0F172A);
      canvas.drawOval(Rect.fromCenter(center: Offset(-3.2 * s, (headCenterY + 1.0) * s), width: 1.8 * s, height: 2.6 * s), eyePaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(3.2 * s, (headCenterY + 1.0) * s), width: 1.8 * s, height: 2.6 * s), eyePaint);

      canvas.drawLine(
        Offset(-1.8 * s, (headCenterY + 4.8) * s),
        Offset(1.8 * s, (headCenterY + 4.8) * s),
        Paint()
          ..color = const Color(0xFF78350F)
          ..strokeWidth = 1.2 * s
          ..strokeCap = StrokeCap.round,
      );
    }

    final lowerId = charId.toLowerCase();

    if (lowerId.contains('aria')) {
      _drawHeadband(canvas, s, headCenterY, Colors.white);
      final hairPath = Path();
      hairPath.moveTo(-8.0 * s, (headCenterY - 3.0) * s);
      hairPath.quadraticBezierTo(0, (headCenterY - 12.0) * s, 8.0 * s, (headCenterY - 3.0) * s);
      hairPath.lineTo(6.0 * s, (headCenterY + 2.0) * s);
      hairPath.lineTo(-6.0 * s, (headCenterY + 2.0) * s);
      hairPath.close();
      canvas.drawPath(hairPath, Paint()..color = hairColor);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(isBack ? 0 : 7.0 * s, (headCenterY - 4.0) * s), width: 8.0 * s, height: 14.0 * s),
        Paint()..color = hairColor,
      );
    } else if (lowerId.contains('jax')) {
      final capPaint = Paint()..color = const Color(0xFF0F172A);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(0, headCenterY * s), radius: 9.6 * s),
        math.pi,
        math.pi,
        true,
        capPaint,
      );
      final billRect = Rect.fromLTWH(-6.0 * s, (headCenterY - 1.0) * s, 12.0 * s, 3.5 * s);
      canvas.drawRRect(RRect.fromRectAndRadius(billRect, Radius.circular(1.5 * s)), Paint()..color = accentColor);
    } else if (lowerId.contains('marcus')) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(0, headCenterY * s), radius: 9.3 * s),
        math.pi * 0.95,
        math.pi * 1.1,
        true,
        Paint()..color = hairColor,
      );
      _drawHeadband(canvas, s, headCenterY, accentColor);
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(0, headCenterY * s), radius: 9.2 * s),
        math.pi,
        math.pi,
        true,
        Paint()..color = hairColor,
      );
      _drawHeadband(canvas, s, headCenterY, Colors.white);
      canvas.drawCircle(Offset(0, (headCenterY - 9.0) * s), 4.5 * s, Paint()..color = hairColor);
    }
  }

  static void _drawHeadband(Canvas canvas, double s, double headCenterY, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-9.4 * s, (headCenterY - 4.0) * s, 18.8 * s, 3.4 * s), Radius.circular(1.5 * s)),
      Paint()..color = color,
    );
  }

  static void _drawFloorShadow(Canvas canvas, double s) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 38.0 * s), width: 34.0 * s, height: 11.0 * s),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );
  }

  static Color _getSkinTone(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('marcus')) return const Color(0xFF8D5524);
    if (lower.contains('jax')) return const Color(0xFFC68642);
    if (lower.contains('elena')) return const Color(0xFFE0AC69);
    return const Color(0xFFFFDBAC);
  }

  static Color _getHairColor(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('aria')) return const Color(0xFF991B1B);
    if (lower.contains('elena')) return const Color(0xFF6B21A8);
    if (lower.contains('marcus')) return const Color(0xFF1E293B);
    return const Color(0xFF451A03);
  }
}