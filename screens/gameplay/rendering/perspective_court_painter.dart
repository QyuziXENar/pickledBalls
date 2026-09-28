// lib/screens/gameplay/rendering/perspective_court_painter.dart

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/game_state.dart';
import '../gameplay_screen.dart';
import '../physics/court_physics_engine.dart';
import 'humanoid_character_rig.dart';
import 'stadium_backgrounds.dart';

class PerspectiveCourtPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final double playerVelocityX;
  final double playerVelocityY;
  final double playerSwingAngle;
  final bool playerIsSwinging;
  final Color playerColor;
  final Color playerAccent;
  final String playerCharId;
  final SpriteAction playerAction;
  final ShotType playerShotType;
  final bool playerIsDiving;

  final double aiX;
  final double aiY;
  final double aiVelocityX;
  final double aiVelocityY;
  final double aiSwingAngle;
  final bool aiIsSwinging;
  final Color aiColor;
  final Color aiAccent;
  final String aiCharId;
  final SpriteAction aiAction;
  final ShotType aiShotType;
  final bool aiIsDiving;

  final double ballX;
  final double ballY;
  final double ballZ;
  final double ballVx;
  final double ballVy;
  final double ballVz;
  final double ballRotationAngle;
  final List<Offset> ballTrail;
  final List<CourtParticle> particles;
  final List<BounceShockwave> shockwaves;

  final bool blitzActive;
  final Color blitzColor;
  final PaddleModel equippedPaddle;
  final String courtVenue;

  final Map<String, ui.Image> sprites;
  final bool isLandscape;
  final bool isServing;
  final double reticleScale;
  final double gameTime;

  PerspectiveCourtPainter({
    required this.playerX,
    required this.playerY,
    required this.playerVelocityX,
    required this.playerVelocityY,
    required this.playerSwingAngle,
    required this.playerIsSwinging,
    required this.playerColor,
    required this.playerAccent,
    required this.playerCharId,
    required this.playerAction,
    required this.playerShotType,
    required this.playerIsDiving,
    required this.aiX,
    required this.aiY,
    required this.aiVelocityX,
    required this.aiVelocityY,
    required this.aiSwingAngle,
    required this.aiIsSwinging,
    required this.aiColor,
    required this.aiAccent,
    required this.aiCharId,
    required this.aiAction,
    required this.aiShotType,
    required this.aiIsDiving,
    required this.ballX,
    required this.ballY,
    required this.ballZ,
    required this.ballVx,
    required this.ballVy,
    required this.ballVz,
    required this.ballRotationAngle,
    required this.ballTrail,
    required this.particles,
    required this.shockwaves,
    required this.blitzActive,
    required this.blitzColor,
    required this.equippedPaddle,
    required this.courtVenue,
    required this.sprites,
    required this.isLandscape,
    required this.isServing,
    required this.reticleScale,
    required this.gameTime,
  });

  double _perspectiveDepth(double y) {
    final clampedY = y.clamp(-0.25, 1.15);
    if (clampedY >= 0) {
      return (clampedY * 1.65) / (1.0 + 0.65 * clampedY);
    } else {
      return clampedY * 1.65;
    }
  }

  Offset project3D(double x, double y, double z, Size size) {
    final centerX = size.width / 2;
    final nearY = isLandscape ? size.height * 0.88 : size.height * 0.81;
    final farY = isLandscape ? size.height * 0.20 : size.height * 0.24;
    final nearWidth = isLandscape
        ? math.min(size.width * 0.72, 620.0)
        : math.min(size.width * 0.90, 540.0);
    final farWidth = nearWidth * (isLandscape ? 0.44 : 0.48);

    final t = _perspectiveDepth(y);
    final courtWidthAtY = nearWidth + (farWidth - nearWidth) * t;
    final groundY = nearY + (farY - nearY) * t;

    final screenX = centerX + (x * (courtWidthAtY / 2));
    final depthScale = (1.0 - (t.clamp(0.0, 1.0) * 0.50)).clamp(0.25, 1.0);
    final screenY = groundY - (z * (isLandscape ? 150.0 : 135.0) * depthScale);

    return Offset(screenX, screenY);
  }

  double getScale(double y) {
    final t = _perspectiveDepth(y);
    return (1.0 - (t.clamp(0.0, 1.0) * 0.48)).clamp(0.40, 1.15);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Color apronColor;
    Color courtColor;
    Color kitchenColor;
    Color lineCol;
    bool hasNeonGlow = false;

    if (courtVenue == 'Midnight Stadium') {
      apronColor = const Color(0xFF070B10);
      courtColor = const Color(0xFF0D1826);
      kitchenColor = const Color(0xFF142438);
      lineCol = AppColors.cyberCyan;
      hasNeonGlow = true;
    } else if (courtVenue == 'Sunlit Beach') {
      apronColor = const Color(0xFFD4A373);
      courtColor = const Color(0xFF2A9D8F);
      kitchenColor = const Color(0xFF264653);
      lineCol = const Color(0xFFFFF7E6);
    } else {
      apronColor = const Color(0xFF102840);
      courtColor = const Color(0xFF1C5382);
      kitchenColor = const Color(0xFF163E63);
      lineCol = Colors.white;
    }

    final pLeft = project3D(-1.40, 1.06, 0, size);
    final pRight = project3D(1.40, 1.06, 0, size);

    // 1. Doom-Style Backgrounds
    StadiumBackgrounds.drawAtmosphericBackground(
      canvas: canvas,
      size: size,
      courtVenue: courtVenue,
      accentColor: lineCol,
      pLeft: pLeft,
      pRight: pRight,
      gameTime: gameTime,
    );

    // 2. 3D Apron Slab with 10px Bevel
    _draw3DCourtSlab(canvas, size, apronColor);

    // 3. Playable Court Floor
    final courtPath = Path()
      ..moveTo(project3D(-1.0, 0.0, 0, size).dx, project3D(-1.0, 0.0, 0, size).dy)
      ..lineTo(project3D(1.0, 0.0, 0, size).dx, project3D(1.0, 0.0, 0, size).dy)
      ..lineTo(project3D(1.0, 1.0, 0, size).dx, project3D(1.0, 1.0, 0, size).dy)
      ..lineTo(project3D(-1.0, 1.0, 0, size).dx, project3D(-1.0, 1.0, 0, size).dy)
      ..close();
    canvas.drawPath(courtPath, Paint()..color = courtColor);

    // 4. NVZ Kitchen
    final kitchenPath = Path()
      ..moveTo(project3D(-1.0, 0.34, 0, size).dx, project3D(-1.0, 0.34, 0, size).dy)
      ..lineTo(project3D(1.0, 0.34, 0, size).dx, project3D(1.0, 0.34, 0, size).dy)
      ..lineTo(project3D(1.0, 0.66, 0, size).dx, project3D(1.0, 0.66, 0, size).dy)
      ..lineTo(project3D(-1.0, 0.66, 0, size).dx, project3D(-1.0, 0.66, 0, size).dy)
      ..close();
    canvas.drawPath(kitchenPath, Paint()..color = kitchenColor);

    // 5. White Lines
    final linePaint = Paint()
      ..color = lineCol.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    if (hasNeonGlow) {
      canvas.drawPath(
        courtPath,
        Paint()
          ..color = lineCol.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawPath(courtPath, linePaint);
    canvas.drawLine(project3D(-1.0, 0.34, 0, size), project3D(1.0, 0.34, 0, size), linePaint);
    canvas.drawLine(project3D(-1.0, 0.66, 0, size), project3D(1.0, 0.66, 0, size), linePaint);
    canvas.drawLine(project3D(0.0, 0.0, 0, size), project3D(0.0, 0.34, 0, size), linePaint);
    canvas.drawLine(project3D(0.0, 0.66, 0, size), project3D(0.0, 1.0, 0, size), linePaint);

    // 6. Opponent Rig
    _drawBillboardOrHumanoid(
      canvas: canvas,
      size: size,
      x: aiX,
      y: aiY,
      charId: aiCharId,
      view: SpriteView.front,
      action: aiAction,
      shotType: aiShotType,
      isDiving: aiIsDiving,
      velocityX: aiVelocityX,
      velocityY: aiVelocityY,
      bodyColor: aiColor,
      accentColor: aiAccent,
      isOpponent: true,
      swingAngle: aiSwingAngle,
    );

    // 7. Net Geometry
    _draw3DPickleballNet(canvas, size, lineCol);

    // 8. Reticles
    if (isServing) {
      _drawServeTimingReticle(canvas, size);
    } else {
      _drawLandingReticle(canvas, size);
    }

    // 9. Ball & FX
    _drawShockwaves(canvas, size);
    _drawBallTrailAndShadows(canvas, size);
    _drawParticles(canvas, size);

    // 10. Local Player Rig
    _drawBillboardOrHumanoid(
      canvas: canvas,
      size: size,
      x: playerX,
      y: playerY,
      charId: playerCharId,
      view: SpriteView.back,
      action: playerAction,
      shotType: playerShotType,
      isDiving: playerIsDiving,
      velocityX: playerVelocityX,
      velocityY: playerVelocityY,
      bodyColor: playerColor,
      accentColor: playerAccent,
      isOpponent: false,
      swingAngle: playerSwingAngle,
    );
  }

  void _draw3DCourtSlab(Canvas canvas, Size size, Color apronColor) {
    const bevelDrop = 10.0;

    final pTopLeft = project3D(-1.35, 1.05, 0, size);
    final pTopRight = project3D(1.40, 1.05, 0, size);
    final pBottomRight = project3D(1.35, -0.22, 0, size);
    final pBottomLeft = project3D(-1.35, -0.22, 0, size);

    final shadowPath = Path()
      ..moveTo(pBottomLeft.dx, pBottomLeft.dy + bevelDrop + 6)
      ..lineTo(pBottomRight.dx, pBottomRight.dy + bevelDrop + 6)
      ..lineTo(pTopRight.dx, pTopRight.dy + 8)
      ..lineTo(pTopLeft.dx, pTopLeft.dy + 8)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final frontBevelPath = Path()
      ..moveTo(pBottomLeft.dx, pBottomLeft.dy)
      ..lineTo(pBottomRight.dx, pBottomRight.dy)
      ..lineTo(pBottomRight.dx, pBottomRight.dy + bevelDrop)
      ..lineTo(pBottomLeft.dx, pBottomLeft.dy + bevelDrop)
      ..close();
    canvas.drawPath(frontBevelPath, Paint()..color = apronColor.withValues(alpha: 0.65));

    final sideBevelPath = Path()
      ..moveTo(pBottomRight.dx, pBottomRight.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy + bevelDrop * 0.4)
      ..lineTo(pBottomRight.dx, pBottomRight.dy + bevelDrop)
      ..close();
    canvas.drawPath(sideBevelPath, Paint()..color = apronColor.withValues(alpha: 0.45));

    final apronPath = Path()
      ..moveTo(pBottomLeft.dx, pBottomLeft.dy)
      ..lineTo(pBottomRight.dx, pBottomRight.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pTopLeft.dx, pTopLeft.dy)
      ..close();
    canvas.drawPath(apronPath, Paint()..color = apronColor);
  }

  void _draw3DPickleballNet(Canvas canvas, Size size, Color cordColor) {
    const postHeightZ = 0.44;
    const centerDipZ = 0.40;

    final leftBase = project3D(-1.08, 0.5, 0.0, size);
    final leftTop = project3D(-1.08, 0.5, postHeightZ, size);
    final rightBase = project3D(1.08, 0.5, 0.0, size);
    final rightTop = project3D(1.08, 0.5, postHeightZ, size);
    final centerTop = project3D(0.0, 0.5, centerDipZ, size);
    final centerBase = project3D(0.0, 0.5, 0.0, size);

    final shadowFloorPath = Path()
      ..moveTo(leftBase.dx, leftBase.dy - 3)
      ..lineTo(rightBase.dx, rightBase.dy - 3)
      ..lineTo(rightBase.dx, rightBase.dy + 8)
      ..lineTo(leftBase.dx, leftBase.dy + 8)
      ..close();
    canvas.drawPath(
      shadowFloorPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final meshPath = Path()
      ..moveTo(leftBase.dx, leftBase.dy)
      ..lineTo(rightBase.dx, rightBase.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..quadraticBezierTo(centerTop.dx, centerTop.dy, leftTop.dx, leftTop.dy)
      ..close();
    canvas.drawPath(meshPath, Paint()..color = cordColor.withValues(alpha: 0.30));

    final tapePath = Path()
      ..moveTo(leftTop.dx, leftTop.dy)
      ..quadraticBezierTo(centerTop.dx, centerTop.dy, rightTop.dx, rightTop.dy);
    canvas.drawPath(
      tapePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6,
    );

    canvas.drawLine(
      centerTop,
      centerBase,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.90)
        ..strokeWidth = 2.4,
    );

    final postPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final capPaint = Paint()
      ..color = AppColors.opticYellow
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(leftBase, leftTop, postPaint);
    canvas.drawLine(rightBase, rightTop, postPaint);
    canvas.drawCircle(leftTop, 3.5, capPaint);
    canvas.drawCircle(rightTop, 3.5, capPaint);
  }

  void _drawLandingReticle(Canvas canvas, Size size) {
    if (ballZ <= 0.04 || ballVy >= 0) return;

    const g = 4.6;
    final discriminant = (ballVz * ballVz) + (2 * g * ballZ);
    if (discriminant < 0) return;

    final timeToFloor = (ballVz + math.sqrt(discriminant)) / g;
    if (timeToFloor <= 0.02 || timeToFloor > 1.8) return;

    final landingX = (ballX + (ballVx * timeToFloor)).clamp(-0.95, 0.95);
    final landingY = (ballY + (ballVy * timeToFloor));

    if (landingY < -0.22 || landingY > 0.55) return;

    final targetPos = project3D(landingX, landingY, 0.0, size);
    final scale = getScale(landingY);

    final outerRadius = 24.0 * scale;
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawOval(
      Rect.fromCenter(center: targetPos, width: outerRadius * 2, height: outerRadius * 0.9),
      ringPaint,
    );

    final progress = (ballZ / 1.6).clamp(0.0, 1.0);
    final innerRadius = outerRadius * progress;
    if (innerRadius > 1.5) {
      final innerPaint = Paint()
        ..color = AppColors.opticYellow.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawOval(
        Rect.fromCenter(center: targetPos, width: innerRadius * 2, height: innerRadius * 0.9),
        innerPaint,
      );
    }

    canvas.drawCircle(targetPos, 3.0 * scale, Paint()..color = AppColors.opticYellow);

    final currentShadowPos = project3D(ballX, ballY, 0.0, size);
    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(currentShadowPos, targetPos, pathPaint);
  }

  void _drawServeTimingReticle(Canvas canvas, Size size) {
    final reticlePos = project3D(ballX, ballY, 0.0, size);
    final scale = getScale(ballY);
    final baseRadius = 40.0 * scale;
    final contractedRadius = math.max(6.0, baseRadius * reticleScale);

    final isSweet = reticleScale < 0.25;
    final ringColor = isSweet ? AppColors.mintAccent : AppColors.opticYellow;

    canvas.drawCircle(
      reticlePos,
      baseRadius,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      reticlePos,
      contractedRadius,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSweet ? 3.0 : 2.0,
    );

    canvas.drawCircle(
      reticlePos,
      4.0 * scale,
      Paint()..color = isSweet ? AppColors.mintAccent : Colors.white70,
    );
  }

  void _drawBallTrailAndShadows(Canvas canvas, Size size) {
    if (ballTrail.length >= 2) {
      for (int i = 0; i < ballTrail.length - 1; i++) {
        final p1 = project3D(ballTrail[i].dx, ballTrail[i].dy, ballZ, size);
        final p2 = project3D(ballTrail[i + 1].dx, ballTrail[i + 1].dy, ballZ, size);
        final alpha = ((i + 1) / ballTrail.length) * 0.35;

        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = (blitzActive ? blitzColor : AppColors.opticYellow).withValues(alpha: alpha)
            ..strokeWidth = (i * 0.9) + 1.2,
        );
      }
    }

    final floorPos = project3D(ballX, ballY, 0.0, size);
    final ballPos = project3D(ballX, ballY, ballZ, size);
    final scale = getScale(ballY);

    final shadowSize = (1.0 + ballZ * 0.65) * scale;
    final shadowOpacity = (0.50 / (1.0 + ballZ * 0.8)).clamp(0.12, 0.50);

    canvas.drawOval(
      Rect.fromCenter(center: floorPos, width: 20 * shadowSize, height: 9 * shadowSize),
      Paint()..color = Colors.black45,
    );

    final radius = (10.0 * scale).clamp(4.5, 14.0);

    if (blitzActive) {
      canvas.drawCircle(
        ballPos,
        radius * 2.2,
        Paint()
          ..color = blitzColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0),
      );
    }

    final ballPaint = Paint()..color = AppColors.opticYellow;
    canvas.drawCircle(ballPos, radius, ballPaint);

    canvas.save();
    canvas.translate(ballPos.dx, ballPos.dy);
    canvas.rotate(ballRotationAngle);

    final dimplePaint = Paint()..color = const Color(0xFF9EBF00);
    canvas.drawCircle(Offset.zero, radius * 0.22, dimplePaint);
    canvas.drawCircle(Offset(-radius * 0.4, -radius * 0.2), radius * 0.15, dimplePaint);
    canvas.drawCircle(Offset(radius * 0.4, radius * 0.2), radius * 0.15, dimplePaint);
    canvas.drawCircle(Offset(-radius * 0.15, radius * 0.4), radius * 0.14, dimplePaint);
    canvas.drawCircle(Offset(radius * 0.15, -radius * 0.4), radius * 0.14, dimplePaint);

    canvas.restore();
  }

  void _drawShockwaves(Canvas canvas, Size size) {
    for (final sw in shockwaves) {
      final pos = project3D(sw.x, sw.y, 0.0, size);
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: sw.radius * 2, height: sw.radius),
        Paint()
          ..color = sw.color.withValues(alpha: sw.opacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final p in particles) {
      final pos = project3D(p.x, p.y, p.z, size);
      final alpha = (p.life / 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(
        pos,
        2.2,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }

  void _drawBillboardOrHumanoid({
    required Canvas canvas,
    required Size size,
    required double x,
    required double y,
    required String charId,
    required SpriteView view,
    required SpriteAction action,
    required ShotType shotType,
    required bool isDiving,
    required double velocityX,
    required double velocityY,
    required Color bodyColor,
    required Color accentColor,
    required bool isOpponent,
    required double swingAngle,
  }) {
    final basePos = project3D(x, y, 0.0, size);
    final scale = getScale(y);
    final tiltAngle = (velocityX * 0.06).clamp(-0.20, 0.20);

    canvas.drawOval(
      Rect.fromCenter(center: basePos, width: 44 * scale, height: 16 * scale),
      Paint()..color = Colors.black54,
    );

    canvas.save();
    canvas.translate(basePos.dx, basePos.dy - (42 * scale));
    canvas.rotate(tiltAngle);

    int frameIndex = 1;
    switch (action) {
      case SpriteAction.idle:
        frameIndex = ((gameTime * 4).toInt() % 4) + 1;
        break;
      case SpriteAction.walk:
        frameIndex = (((velocityX.abs() + velocityY.abs()) * gameTime * 8).toInt() % 4) + 1;
        break;
      case SpriteAction.hit:
        if (swingAngle < 0.8) {
          frameIndex = 1;
        } else if (swingAngle < 1.8) {
          frameIndex = 2;
        } else if (swingAngle < 2.6) {
          frameIndex = 3;
        } else {
          frameIndex = 4;
        }
        break;
      case SpriteAction.serve:
        frameIndex = isServing ? 2 : 4;
        break;
      case SpriteAction.defend:
        frameIndex = ((gameTime * 3).toInt() % 4) + 1;
        break;
      case SpriteAction.loss:
        frameIndex = math.min(4, ((gameTime * 2).toInt() % 4) + 1);
        break;
    }

    final framePath = AppAssets.getCharacterFrame(charId, view, action, frameIndex);
    ui.Image? spriteImg = sprites[framePath];

    if (spriteImg == null) {
      final legacyKey = AppAssets.getLegacyPlaceholderKey(charId, action, frameIndex);
      if (legacyKey != null) {
        spriteImg = sprites[legacyKey];
      }
    }

    if (spriteImg != null) {
      final spriteW = 76.0 * scale;
      final spriteH = 92.0 * scale;
      final dst = Rect.fromCenter(center: Offset.zero, width: spriteW, height: spriteH);
      final src = Rect.fromLTWH(0, 0, spriteImg.width.toDouble(), spriteImg.height.toDouble());
      canvas.drawImageRect(spriteImg, src, dst, Paint()..filterQuality = FilterQuality.none);
    } else {
      HumanoidCharacterRig.draw(
        canvas: canvas,
        scale: scale,
        charId: charId,
        view: view,
        action: action,
        shotType: shotType,
        isDiving: isDiving,
        bodyColor: bodyColor,
        accentColor: accentColor,
        swingAngle: swingAngle,
        isOpponent: isOpponent,
        velocityX: velocityX,
        velocityY: velocityY,
        gameTime: gameTime,
        equippedPaddle: equippedPaddle,
        isServing: isServing,
        playerSwingAngle: playerSwingAngle,
        aiSwingAngle: aiSwingAngle,
        blitzActive: blitzActive,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PerspectiveCourtPainter oldDelegate) => true;
}