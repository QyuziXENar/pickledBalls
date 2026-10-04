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

  // Visual Trail & Physics Predictor
  final List<TrailNode>? smoothTrail;
  final List<Offset>? ballTrail;
  final CourtPhysicsEngine? physics;
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
    this.smoothTrail,
    this.ballTrail,
    this.physics,
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
    final farY = isLandscape ? size.height * 0.22 : size.height * 0.24;

    final nearWidth = isLandscape
        ? math.min(size.width * 0.58, 620.0)
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
    Color nearCourtColor;
    Color farCourtColor;
    Color kitchenColor;
    Color lineCol;
    bool hasNeonGlow = false;

    if (courtVenue == 'Training Facility') {
      apronColor = const Color(0xFF0F172A);
      nearCourtColor = const Color(0xFF1E3A8A);
      farCourtColor = const Color(0xFF1E3A8A);
      kitchenColor = const Color(0xFFD97706);
      lineCol = Colors.white;
      hasNeonGlow = false;
    } else if (courtVenue == 'Rivalry Clash') {
      apronColor = const Color(0xFF090D14);
      nearCourtColor = const Color(0xFF0D47A1);
      farCourtColor = const Color(0xFFB71C1C);
      kitchenColor = const Color(0xFF141E28);
      lineCol = AppColors.cyberCyan;
      hasNeonGlow = true;
    } else if (courtVenue == 'Monochrome Street') {
      apronColor = const Color(0xFF121212);
      nearCourtColor = const Color(0xFF1E1E1E);
      farCourtColor = const Color(0xFF1E1E1E);
      kitchenColor = const Color(0xFF282828);
      lineCol = Colors.white;
      hasNeonGlow = false;
    } else if (courtVenue == 'Midnight Stadium') {
      apronColor = const Color(0xFF070B10);
      nearCourtColor = const Color(0xFF0D1826);
      farCourtColor = const Color(0xFF0D1826);
      kitchenColor = const Color(0xFF142438);
      lineCol = AppColors.cyberCyan;
      hasNeonGlow = true;
    } else if (courtVenue == 'Sunlit Beach') {
      apronColor = const Color(0xFFD4A373);
      nearCourtColor = const Color(0xFF2A9D8F);
      farCourtColor = const Color(0xFF2A9D8F);
      kitchenColor = const Color(0xFF264653);
      lineCol = const Color(0xFFFFF7E6);
    } else {
      apronColor = const Color(0xFF102840);
      nearCourtColor = const Color(0xFF1C5382);
      farCourtColor = const Color(0xFF1C5382);
      kitchenColor = const Color(0xFF163E63);
      lineCol = Colors.white;
    }

    final pLeft = project3D(-1.40, 1.06, 0, size);
    final pRight = project3D(1.40, 1.06, 0, size);

    // 1. Atmosphere Horizon Background
    StadiumBackgrounds.drawAtmosphericBackground(
      canvas: canvas,
      size: size,
      courtVenue: courtVenue,
      accentColor: lineCol,
      pLeft: pLeft,
      pRight: pRight,
      gameTime: gameTime,
    );

    // 2. 3D Apron Slab with 10px Bevel Drop
    _draw3DCourtSlab(canvas, size, apronColor);

    // 3. Playable Court Floor
    if (nearCourtColor != farCourtColor) {
      final nearPath = Path()
        ..moveTo(project3D(-1.0, 0.0, 0, size).dx, project3D(-1.0, 0.0, 0, size).dy)
        ..lineTo(project3D(1.0, 0.0, 0, size).dx, project3D(1.0, 0.0, 0, size).dy)
        ..lineTo(project3D(1.0, 0.5, 0, size).dx, project3D(1.0, 0.5, 0, size).dy)
        ..lineTo(project3D(-1.0, 0.5, 0, size).dx, project3D(-1.0, 0.5, 0, size).dy)
        ..close();
      canvas.drawPath(nearPath, Paint()..color = nearCourtColor);

      final farPath = Path()
        ..moveTo(project3D(-1.0, 0.5, 0, size).dx, project3D(-1.0, 0.5, 0, size).dy)
        ..lineTo(project3D(1.0, 0.5, 0, size).dx, project3D(1.0, 0.5, 0, size).dy)
        ..lineTo(project3D(1.0, 1.0, 0, size).dx, project3D(1.0, 1.0, 0, size).dy)
        ..lineTo(project3D(-1.0, 1.0, 0, size).dx, project3D(-1.0, 1.0, 0, size).dy)
        ..close();
      canvas.drawPath(farPath, Paint()..color = farCourtColor);
    } else {
      final courtPath = Path()
        ..moveTo(project3D(-1.0, 0.0, 0, size).dx, project3D(-1.0, 0.0, 0, size).dy)
        ..lineTo(project3D(1.0, 0.0, 0, size).dx, project3D(1.0, 0.0, 0, size).dy)
        ..lineTo(project3D(1.0, 1.0, 0, size).dx, project3D(1.0, 1.0, 0, size).dy)
        ..lineTo(project3D(-1.0, 1.0, 0, size).dx, project3D(-1.0, 1.0, 0, size).dy)
        ..close();
      canvas.drawPath(courtPath, Paint()..color = nearCourtColor);
    }

    // 4. NVZ Kitchen
    final kitchenPath = Path()
      ..moveTo(project3D(-1.0, 0.34, 0, size).dx, project3D(-1.0, 0.34, 0, size).dy)
      ..lineTo(project3D(1.0, 0.34, 0, size).dx, project3D(1.0, 0.34, 0, size).dy)
      ..lineTo(project3D(1.0, 0.66, 0, size).dx, project3D(1.0, 0.66, 0, size).dy)
      ..lineTo(project3D(-1.0, 0.66, 0, size).dx, project3D(-1.0, 0.66, 0, size).dy)
      ..close();
    canvas.drawPath(kitchenPath, Paint()..color = kitchenColor);

    // 5. White Regulation Lines
    final linePaint = Paint()
      ..color = lineCol.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    if (hasNeonGlow) {
      canvas.drawPath(
        kitchenPath,
        Paint()
          ..color = lineCol.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    final perimeterPath = Path()
      ..moveTo(project3D(-1.0, 0.0, 0, size).dx, project3D(-1.0, 0.0, 0, size).dy)
      ..lineTo(project3D(1.0, 0.0, 0, size).dx, project3D(1.0, 0.0, 0, size).dy)
      ..lineTo(project3D(1.0, 1.0, 0, size).dx, project3D(1.0, 1.0, 0, size).dy)
      ..lineTo(project3D(-1.0, 1.0, 0, size).dx, project3D(-1.0, 1.0, 0, size).dy)
      ..close();
    canvas.drawPath(perimeterPath, linePaint);

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

    // 8. Serve Reticle
    if (isServing) {
      _drawServeTimingReticle(canvas, size);
    }

    // 9. Ball, Trajectory Tracer & Shadow
    _drawBallAndShadow(canvas, size);

    // 10. Particles & Shockwaves
    _drawShockwaves(canvas, size);
    _drawParticles(canvas, size);

    // 11. Local Player Rig
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

  // ==========================================================================
  // HOLOGRAPHIC PREDICTIVE TRACER ARC / PIPREVIEW
  // ==========================================================================
  void _drawPredictiveTracer(Canvas canvas, Size size) {
    if (ballZ <= 0.02 || ballVy.abs() < 0.12) return;

    final List<Vector3D> trajectoryPoints = physics != null
        ? physics!.computePredictedTrajectory(samples: 16)
        : [];

    if (trajectoryPoints.length < 2) return;

    final tracerPath = Path();
    for (int i = 0; i < trajectoryPoints.length; i++) {
      final p = trajectoryPoints[i];
      final screenPos = project3D(p.x, p.y, p.z, size);
      if (i == 0) {
        tracerPath.moveTo(screenPos.dx, screenPos.dy);
      } else {
        tracerPath.lineTo(screenPos.dx, screenPos.dy);
      }
    }

    final beamPaint = Paint()
      ..color = (blitzActive ? blitzColor : AppColors.opticYellow).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(tracerPath, beamPaint);

    // Forward flowing light pips along the arc
    for (int i = 1; i < trajectoryPoints.length; i += 2) {
      final p = trajectoryPoints[i];
      final screenPos = project3D(p.x, p.y, p.z, size);
      final phase = ((gameTime * 4.0) + (i * 0.35)) % 1.0;
      final pipAlpha = (phase * 0.85).clamp(0.2, 0.9);

      canvas.drawCircle(
        screenPos,
        2.5,
        Paint()
          ..color = Colors.white.withValues(alpha: pipAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );
    }

    // Target Landing Spot
    final finalPoint = trajectoryPoints.last;
    final floorLandingPos = project3D(finalPoint.x, finalPoint.y, 0.0, size);
    final scale = getScale(finalPoint.y);

    canvas.drawOval(
      Rect.fromCenter(center: floorLandingPos, width: 28 * scale, height: 12 * scale),
      Paint()
        ..color = (blitzActive ? blitzColor : AppColors.opticYellow).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(floorLandingPos, 3.5 * scale, Paint()..color = Colors.white);
  }

  // ==========================================================================
  // JITTER-FREE SMOOTH RIBBON TRAIL
  // ==========================================================================
  void _drawSmoothRibbonTrail(Canvas canvas, Size size) {
    final trail = smoothTrail;
    if (trail == null || trail.length < 2) return;

    final trailColor = blitzActive ? blitzColor : AppColors.opticYellow;

    for (int i = 0; i < trail.length - 1; i++) {
      final nodeA = trail[i];
      final nodeB = trail[i + 1];

      final posA = project3D(nodeA.x, nodeA.y, nodeA.z, size);
      final posB = project3D(nodeB.x, nodeB.y, nodeB.z, size);

      final progress = (i / trail.length).clamp(0.0, 1.0);
      final alpha = (progress * 0.65).clamp(0.05, 0.70);
      final width = (progress * 6.5) + 1.2;

      canvas.drawLine(
        posA,
        posB,
        Paint()
          ..color = trailColor.withValues(alpha: alpha)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ==========================================================================
  // TRUE 3D PERFORATED SHADED WIFFLE BALL
  // ==========================================================================
  void _drawBallAndShadow(Canvas canvas, Size size) {
    _drawPredictiveTracer(canvas, size);
    _drawSmoothRibbonTrail(canvas, size);

    final floorPos = project3D(ballX, ballY, 0.0, size);
    final ballPos = project3D(ballX, ballY, ballZ, size);
    final scale = getScale(ballY);

    // Grounding Drop Shadow
    final shadowSize = (1.0 + ballZ * 0.55) * scale;
    final shadowOpacity = (0.52 / (1.0 + ballZ * 0.75)).clamp(0.12, 0.55);

    canvas.drawOval(
      Rect.fromCenter(center: floorPos, width: 22 * shadowSize, height: 10 * shadowSize),
      Paint()..color = Colors.black.withValues(alpha: shadowOpacity),
    );

    final radius = (11.0 * scale).clamp(5.0, 15.0);

    // Blitz Glow
    if (blitzActive) {
      canvas.drawCircle(
        ballPos,
        radius * 2.3,
        Paint()
          ..color = blitzColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0),
      );
    }

    // 3D Sphere Convex Shading
    final sphereRect = Rect.fromCircle(center: ballPos, radius: radius);
    final sphereShader = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.90,
      colors: const [
        Color(0xFFFFFF99),
        AppColors.opticYellow,
        Color(0xFF829E00),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(sphereRect);

    canvas.drawCircle(ballPos, radius, Paint()..shader = sphereShader);

    // 3D Rotating Wiffle Holes
    final holePaint = Paint()..color = const Color(0xFF556B00);
    const int numHoles = 5;

    for (int i = 0; i < numHoles; i++) {
      final angle = ballRotationAngle + (i * (2 * math.pi / numHoles));
      final cosVal = math.cos(angle);
      final sinVal = math.sin(angle);

      if (sinVal > -0.15) {
        final holeX = ballPos.dx + (cosVal * radius * 0.62);
        final holeY = ballPos.dy + (sinVal * radius * 0.38);

        final holeWidth = (radius * 0.28 * (1.0 - (cosVal.abs() * 0.4))).clamp(1.5, 4.5);
        final holeHeight = (radius * 0.22).clamp(1.5, 3.5);

        canvas.drawOval(
          Rect.fromCenter(center: Offset(holeX, holeY), width: holeWidth, height: holeHeight),
          holePaint,
        );
      }
    }

    // Specular Highlight Gleam
    canvas.drawCircle(
      ballPos + Offset(-radius * 0.32, -radius * 0.32),
      radius * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
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