// lib/screens/gameplay/rendering/stadium_backgrounds.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

class StadiumBackgrounds {
  static void drawAtmosphericBackground({
    required Canvas canvas,
    required Size size,
    required dynamic courtVenue,
    required Color accentColor,
    required Offset pLeft,
    required Offset pRight,
    required double gameTime,
  }) {
    final venueName = courtVenue.toString().toLowerCase();

    if (venueName.contains('beach')) {
      _drawSunsetBeach(
        canvas: canvas,
        size: size,
        pLeft: pLeft,
        pRight: pRight,
        gameTime: gameTime,
      );
    } else {
      // Handles Indoor Arenas (Tournament Arena, Training Facility, etc.)
      _drawIndoorArena(
        canvas: canvas,
        size: size,
        pLeft: pLeft,
        pRight: pRight,
        gameTime: gameTime,
        accentColor: accentColor,
      );
    }
  }

  // =========================================================================
  // INDOOR ARENA: BLEACHERS, CROWD & STADIUM FLOODLIGHTS
  // =========================================================================
  static void _drawIndoorArena({
    required Canvas canvas,
    required Size size,
    required Offset pLeft,
    required Offset pRight,
    required double gameTime,
    required Color accentColor,
  }) {
    final w = size.width;
    final h = size.height;
    final horizonY = (pLeft.dy + pRight.dy) / 2.0;

    // 1. ARENA WALL & RAFTERS BACKGROUND (Dark Stadium Atmosphere)
    final wallRect = Rect.fromLTRB(0, 0, w, h);
    final wallGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF04080F), // Pitch dark high arena roof
        Color(0xFF0A131F), // Mid wall
        Color(0xFF0E1A2B), // Floor horizon
      ],
      stops: const [0.0, 0.45, 1.0],
    );
    canvas.drawRect(wallRect, Paint()..shader = wallGradient.createShader(wallRect));

    // Arena Floor base outside the court
    final floorRect = Rect.fromLTRB(0, horizonY, w, h);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF08121E),
            Color(0xFF050B14),
          ],
        ).createShader(floorRect),
    );

    // 2. STADIUM CEILING TRUSS & HANGING SCOREBOARD JUMBOTRON
    _drawArenaCeilingRafters(canvas, w, horizonY);

    // 3. PERSPECTIVE BLEACHER BENCHES & PACKED INDOOR CROWD
    final botLeftX = w * 0.08;
    final botRightX = w * 0.92;
    final leftTop = pLeft;
    final leftBot = Offset(botLeftX, h);
    final rightTop = pRight;
    final rightBot = Offset(botRightX, h);

    // Benches & Spectator Rows
    _drawIndoorBleachersAndCrowd(canvas, leftTop, leftBot, isLeft: true, gameTime: gameTime);
    _drawIndoorBleachersAndCrowd(canvas, rightTop, rightBot, isLeft: false, gameTime: gameTime);

    // 4. OVERHEAD HIGH-INTENSITY STADIUM FLOODLIGHTS & VOLUMETRIC LIGHT BEAMS
    _drawStadiumFloodlights(canvas, w, h, horizonY);

    // 5. COURT SPOTLIGHT POOLS (Bright lighting on the play surface)
    _drawCourtFloorLightingPuddles(canvas, w, h, horizonY);
  }

  /// Draws ceiling steel beams and arena rafters
  static void _drawArenaCeilingRafters(Canvas canvas, double w, double horizonY) {
    final trussPaint = Paint()
      ..color = const Color(0xFF132236)
      ..strokeWidth = 2.0;

    // Cross-bracing metal girders
    const numGirders = 8;
    for (int i = 0; i < numGirders; i++) {
      final x1 = (w / numGirders) * i;
      final x2 = (w / numGirders) * (i + 1);
      canvas.drawLine(Offset(x1, 0), Offset(x2, 28), trussPaint);
      canvas.drawLine(Offset(x2, 0), Offset(x1, 28), trussPaint);
      canvas.drawLine(Offset(x1, 28), Offset(x2, 28), trussPaint);
    }

    // Horizontal Arena LED Ribbon Board in background
    final ribbonRect = Rect.fromLTRB(0, horizonY - 14, w, horizonY - 2);
    canvas.drawRect(
      ribbonRect,
      Paint()
        ..color = const Color(0xFF091422),
    );
    canvas.drawLine(
      Offset(0, horizonY - 2),
      Offset(w, horizonY - 2),
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
        ..strokeWidth = 1.6,
    );
  }

  /// Draws multi-tiered grandstand benches filled with dense spectators
  static void _drawIndoorBleachersAndCrowd(
    Canvas canvas,
    Offset top,
    Offset bot, {
    required bool isLeft,
    required double gameTime,
  }) {
    final crowdColors = [
      const Color(0xFF1E88E5), // Blue
      const Color(0xFFE53935), // Red
      const Color(0xFFFDD835), // Yellow
      const Color(0xFF43A047), // Green
      const Color(0xFFFB8C00), // Orange
      const Color(0xFFFFFFFF), // White
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF00ACC1), // Cyan
    ];

    final skinColors = [
      const Color(0xFFFFDBAC),
      const Color(0xFFF1C27D),
      const Color(0xFFE0AC69),
      const Color(0xFFC68642),
    ];

    const tiers = 3; // 3 stepped bench tiers
    const spectatorsPerTier = 11;

    for (int tier = 0; tier < tiers; tier++) {
      // 1. Draw Stepped Wooden / Metal Bleacher Bench
      final benchPath = Path();
      for (int i = 0; i <= spectatorsPerTier; i++) {
        final t = i / spectatorsPerTier;
        final courtX = top.dx + (bot.dx - top.dx) * t;
        final y = top.dy + (bot.dy - top.dy) * t;
        final pScale = 0.45 + (t * 0.65);

        final dist = (35.0 + (tier * 28.0)) * pScale;
        final bx = isLeft ? courtX - dist : courtX + dist;

        if (i == 0) {
          benchPath.moveTo(bx, y);
        } else {
          benchPath.lineTo(bx, y);
        }
      }

      // Bench surface
      canvas.drawPath(
        benchPath,
        Paint()
          ..color = const Color(0xFF1E2E42).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7.0 + (tier * 3.0)
          ..strokeCap = StrokeCap.round,
      );

      // Bench metal highlight edge
      canvas.drawPath(
        benchPath,
        Paint()
          ..color = const Color(0xFF3B5373).withValues(alpha: 0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      // 2. Draw Cheering Spectators sitting and standing on the bench
      for (int i = 0; i < spectatorsPerTier; i++) {
        final t = (i + 0.5) / spectatorsPerTier;
        final courtX = top.dx + (bot.dx - top.dx) * t;
        final y = top.dy + (bot.dy - top.dy) * t;
        final pScale = 0.45 + (t * 0.65);

        final dist = (35.0 + (tier * 28.0)) * pScale;
        final sx = isLeft ? courtX - dist : courtX + dist;

        // Cheering excitement wave
        final phase = (i * 0.75) + (tier * 1.5);
        final isJumping = math.sin((gameTime * 4.0) + phase) > 0.45;
        final bounce = isJumping ? -6.0 * pScale : 0.0;
        final pos = Offset(sx, y + bounce - (4.0 * pScale));

        // Person drop shadow on bench
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(sx, y + (5 * pScale)),
            width: 14 * pScale,
            height: 5 * pScale,
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.45),
        );

        // Body / Jersey
        final shirtColor = crowdColors[(i * 3 + tier) % crowdColors.length];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(pos.dx, pos.dy + (2 * pScale)),
              width: 11 * pScale,
              height: 14 * pScale,
            ),
            Radius.circular(2.5 * pScale),
          ),
          Paint()..color = shirtColor,
        );

        // Head
        final skin = skinColors[(i + tier) % skinColors.length];
        canvas.drawCircle(Offset(pos.dx, pos.dy - (7 * pScale)), 5.0 * pScale, Paint()..color = skin);

        // Hair / Cap
        final capColor = crowdColors[(i + 2) % crowdColors.length];
        canvas.drawArc(
          Rect.fromCircle(center: Offset(pos.dx, pos.dy - (8 * pScale)), radius: 5.0 * pScale),
          math.pi,
          math.pi,
          true,
          Paint()..color = capColor,
        );

        // Cheering Arms up
        if (isJumping) {
          final armPaint = Paint()
            ..color = skin
            ..strokeWidth = 2.0 * pScale
            ..strokeCap = StrokeCap.round;

          canvas.drawLine(
            Offset(pos.dx - 4 * pScale, pos.dy),
            Offset(pos.dx - 8 * pScale, pos.dy - 10 * pScale),
            armPaint,
          );
          canvas.drawLine(
            Offset(pos.dx + 4 * pScale, pos.dy),
            Offset(pos.dx + 8 * pScale, pos.dy - 10 * pScale),
            armPaint,
          );
        }
      }
    }
  }

  /// Draws bright stadium light fixtures with translucent light beams cutting downward
  static void _drawStadiumFloodlights(Canvas canvas, double w, double h, double horizonY) {
    // 4 Main Floodlight Banks (Left Outer, Left Inner, Right Inner, Right Outer)
    final lightBanks = [
      Offset(w * 0.16, 24),
      Offset(w * 0.38, 16),
      Offset(w * 0.62, 16),
      Offset(w * 0.84, 24),
    ];

    for (int b = 0; b < lightBanks.length; b++) {
      final pos = lightBanks[b];
      final isOuter = b == 0 || b == 3;

      // 1. Translucent Volumetric Light Beams (Cones of stadium light)
      final beamPath = Path();
      beamPath.moveTo(pos.dx - 18, pos.dy);
      beamPath.lineTo(pos.dx + 18, pos.dy);
      // Expands wide as it hits the court floor
      beamPath.lineTo(pos.dx + (isOuter ? (b == 0 ? 110 : -110) : 60), h * 0.85);
      beamPath.lineTo(pos.dx + (isOuter ? (b == 0 ? -40 : 40) : -60), h * 0.85);
      beamPath.close();

      final beamGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE0F7FA).withValues(alpha: 0.18),
          const Color(0xFF80DEEA).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 1.0],
      );

      canvas.drawPath(
        beamPath,
        Paint()
          ..shader = beamGradient.createShader(beamPath.getBounds())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // 2. Halogen Bank Housing & Mount
      final housingRect = Rect.fromCenter(center: pos, width: 44, height: 16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(housingRect, const Radius.circular(4)),
        Paint()..color = const Color(0xFF263238),
      );

      // 3. Glowing Floodlight Bulbs
      const bulbCount = 4;
      for (int i = 0; i < bulbCount; i++) {
        final bx = pos.dx - 15 + (i * 10);
        final bulbPos = Offset(bx, pos.dy);

        // Core White Light
        canvas.drawCircle(bulbPos, 3.5, Paint()..color = const Color(0xFFFFFFFF));
        // Halogen lens flare
        canvas.drawCircle(
          bulbPos,
          7.5,
          Paint()
            ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      // Outer Lens Flare Glare
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: 70, height: 28),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  /// Soft light reflection pools directly illuminating the blue court floor
  static void _drawCourtFloorLightingPuddles(Canvas canvas, double w, double h, double horizonY) {
    final lightPuddle = RadialGradient(
      center: Alignment.center,
      radius: 0.85,
      colors: [
        const Color(0xFF64B5F6).withValues(alpha: 0.15),
        const Color(0xFF00E5FF).withValues(alpha: 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    // Main center court spotlight illumination
    final puddleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.58),
      width: w * 0.65,
      height: h * 0.55,
    );
    canvas.drawOval(
      puddleRect,
      Paint()
        ..shader = lightPuddle.createShader(puddleRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  // =========================================================================
  // SUNLIT BEACH BACKGROUND (UNCHANGED)
  // =========================================================================
  static void _drawSunsetBeach({
    required Canvas canvas,
    required Size size,
    required Offset pLeft,
    required Offset pRight,
    required double gameTime,
  }) {
    final w = size.width;
    final h = size.height;

    final horizonY = (pLeft.dy + pRight.dy) / 2.0;
    final seaHorizonY = horizonY * 0.42;

    final skyRect = Rect.fromLTRB(0, 0, w, seaHorizonY);
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF24143D),
        Color(0xFF5B2252),
        Color(0xFFA83A32),
        Color(0xFFE26B29),
        Color(0xFFFFBF48),
      ],
      stops: const [0.0, 0.28, 0.54, 0.80, 1.0],
    );
    canvas.drawRect(skyRect, Paint()..shader = skyGradient.createShader(skyRect));

    final sunPos = Offset(w * 0.72, seaHorizonY - 6.0);
    canvas.drawCircle(
      sunPos,
      50.0,
      Paint()
        ..color = const Color(0xFFFF9E3D).withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawCircle(sunPos, 22.0, Paint()..color = const Color(0xFFFFF7C4));

    _drawSunsetClouds(canvas, w, seaHorizonY);
    _drawTropicalIsland(canvas, w, seaHorizonY);

    final seaRect = Rect.fromLTRB(0, seaHorizonY, w, horizonY);
    final seaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF0F4351),
        Color(0xFF175F68),
        Color(0xFF2B7972),
      ],
    );
    canvas.drawRect(seaRect, Paint()..shader = seaGradient.createShader(seaRect));

    final sunReflectRect = Rect.fromLTRB(w * 0.64, seaHorizonY, w * 0.80, horizonY);
    final sunReflectGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFFE082).withValues(alpha: 0.65),
        const Color(0xFFFF9800).withValues(alpha: 0.38),
        const Color(0xFFFFD54F).withValues(alpha: 0.12),
      ],
    );
    canvas.drawRect(
      sunReflectRect,
      Paint()
        ..shader = sunReflectGrad.createShader(sunReflectRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    _drawOceanWaves(canvas, w, seaHorizonY, horizonY, gameTime);

    final sandRect = Rect.fromLTRB(0, horizonY - 1.0, w, h);
    final sandGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFC08F59),
        Color(0xFFE2AF74),
        Color(0xFFD69E61),
      ],
      stops: const [0.0, 0.45, 1.0],
    );
    canvas.drawRect(sandRect, Paint()..shader = sandGradient.createShader(sandRect));

    _drawSandDetails(canvas, w, h, horizonY);
    _drawLargePalmTrees(canvas, w, horizonY);

    final botLeftX = w * 0.08;
    final botRightX = w * 0.92;
    final leftTop = pLeft;
    final leftBot = Offset(botLeftX, h);
    final rightTop = pRight;
    final rightBot = Offset(botRightX, h);

    _drawBeachProps(canvas, leftTop, leftBot, isLeft: true);
    _drawBeachProps(canvas, rightTop, rightBot, isLeft: false);

    _drawDenseBeachCrowd(canvas, leftTop, leftBot, isLeft: true, gameTime: gameTime);
    _drawDenseBeachCrowd(canvas, rightTop, rightBot, isLeft: false, gameTime: gameTime);
  }

  static void _drawTropicalIsland(Canvas canvas, double w, double seaHorizonY) {
    final islandPath = Path();
    islandPath.moveTo(w * 0.28, seaHorizonY);
    islandPath.quadraticBezierTo(w * 0.36, seaHorizonY - 26, w * 0.42, seaHorizonY - 14);
    islandPath.quadraticBezierTo(w * 0.48, seaHorizonY - 32, w * 0.54, seaHorizonY - 10);
    islandPath.quadraticBezierTo(w * 0.58, seaHorizonY - 18, w * 0.63, seaHorizonY);
    islandPath.close();
    canvas.drawPath(islandPath, Paint()..color = const Color(0xFF132B33));

    _drawMiniPalm(canvas, Offset(w * 0.38, seaHorizonY - 20), height: 12.0);
    _drawMiniPalm(canvas, Offset(w * 0.46, seaHorizonY - 28), height: 15.0);
    _drawMiniPalm(canvas, Offset(w * 0.50, seaHorizonY - 22), height: 11.0);

    final boatX = w * 0.22;
    final boatY = seaHorizonY + 6;
    final hull = Path()
      ..moveTo(boatX - 9, boatY)
      ..lineTo(boatX + 9, boatY)
      ..lineTo(boatX + 6, boatY + 4)
      ..lineTo(boatX - 7, boatY + 4)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFF12242B));

    final sail = Path()
      ..moveTo(boatX, boatY)
      ..lineTo(boatX, boatY - 16)
      ..lineTo(boatX + 8, boatY - 3)
      ..close();
    canvas.drawPath(sail, Paint()..color = const Color(0xFFFFE0B2).withValues(alpha: 0.85));
  }

  static void _drawLargePalmTrees(Canvas canvas, double w, double horizonY) {
    _drawSinglePalm(canvas, Offset(w * 0.04, horizonY + 20), height: 75, slant: 16);
    _drawSinglePalm(canvas, Offset(w * 0.09, horizonY + 10), height: 62, slant: -10);
    _drawSinglePalm(canvas, Offset(w * 0.96, horizonY + 20), height: 75, slant: -16);
    _drawSinglePalm(canvas, Offset(w * 0.91, horizonY + 10), height: 62, slant: 10);
  }

  static void _drawSinglePalm(Canvas canvas, Offset base, {required double height, required double slant}) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF2E1C0C)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final top = Offset(base.dx + slant, base.dy - height);
    final trunk = Path();
    trunk.moveTo(base.dx, base.dy);
    trunk.quadraticBezierTo(base.dx + (slant * 0.3), base.dy - (height * 0.5), top.dx, top.dy);
    canvas.drawPath(trunk, trunkPaint);

    final frondPaint = Paint()
      ..color = const Color(0xFF1B382B)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final angles = [-2.6, -1.9, -1.2, -0.4, 0.4, 1.2, 1.9, 2.6];
    for (final ang in angles) {
      final endX = top.dx + math.cos(ang) * (height * 0.45);
      final endY = top.dy + math.sin(ang) * (height * 0.28) + 4;
      final frond = Path();
      frond.moveTo(top.dx, top.dy);
      frond.quadraticBezierTo(top.dx + math.cos(ang) * (height * 0.24), top.dy - 5, endX, endY);
      canvas.drawPath(frond, frondPaint);
    }
  }

  static void _drawMiniPalm(Canvas canvas, Offset base, {required double height}) {
    final p = Paint()
      ..color = const Color(0xFF0F2128)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final top = Offset(base.dx + 2, base.dy - height);
    canvas.drawLine(base, top, p);
    canvas.drawLine(top, Offset(top.dx - 7, top.dy + 4), p);
    canvas.drawLine(top, Offset(top.dx + 7, top.dy + 4), p);
    canvas.drawLine(top, Offset(top.dx - 5, top.dy - 3), p);
    canvas.drawLine(top, Offset(top.dx + 5, top.dy - 3), p);
  }

  static void _drawSunsetClouds(Canvas canvas, double w, double seaHorizonY) {
    final cloudPaint = Paint()
      ..color = const Color(0xFFFF8A65).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final p1 = Path();
    p1.moveTo(w * 0.04, seaHorizonY * 0.55);
    p1.quadraticBezierTo(w * 0.12, seaHorizonY * 0.35, w * 0.24, seaHorizonY * 0.55);
    p1.quadraticBezierTo(w * 0.30, seaHorizonY * 0.42, w * 0.38, seaHorizonY * 0.60);
    p1.lineTo(w * 0.04, seaHorizonY * 0.60);
    p1.close();
    canvas.drawPath(p1, cloudPaint);

    final p2 = Path();
    p2.moveTo(w * 0.52, seaHorizonY * 0.55);
    p2.quadraticBezierTo(w * 0.62, seaHorizonY * 0.30, w * 0.76, seaHorizonY * 0.55);
    p2.quadraticBezierTo(w * 0.84, seaHorizonY * 0.40, w * 0.94, seaHorizonY * 0.62);
    p2.lineTo(w * 0.52, seaHorizonY * 0.62);
    p2.close();
    canvas.drawPath(p2, cloudPaint..color = const Color(0xFFFFAB91).withValues(alpha: 0.38));
  }

  static void _drawOceanWaves(
    Canvas canvas,
    double w,
    double seaHorizonY,
    double horizonY,
    double gameTime,
  ) {
    final seaHeight = horizonY - seaHorizonY;
    for (int i = 1; i <= 4; i++) {
      final waveProgress = (gameTime * 0.35 + (i * 0.25)) % 1.0;
      final y = seaHorizonY + (seaHeight * waveProgress);

      final p = Path();
      p.moveTo(0, y);
      for (double x = 0; x <= w; x += 32) {
        final peak = math.sin((x * 0.02) + (gameTime * 2.5) + i) * 2.2;
        p.lineTo(x, y + peak);
      }

      final alpha = (0.25 + (waveProgress * 0.65)).clamp(0.0, 1.0);
      canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFFFF3E0).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.2 + waveProgress * 1.4),
      );
    }
  }

  static void _drawSandDetails(Canvas canvas, double w, double h, double horizonY) {
    final sandHeight = h - horizonY;

    final duneShadow = Paint()
      ..color = const Color(0xFFA56E3B).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final duneLight = Paint()
      ..color = const Color(0xFFFFF0B8).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    for (int i = 1; i <= 5; i++) {
      final y = horizonY + sandHeight * (i / 6.0);
      final curve = Path();
      curve.moveTo(0, y + math.sin(i * 1.8) * 9);
      curve.quadraticBezierTo(w * 0.28, y - 10 + math.cos(i) * 6, w * 0.52, y + 5);
      curve.quadraticBezierTo(w * 0.78, y + 12 - math.sin(i) * 5, w, y + math.cos(i) * 8);

      canvas.drawPath(curve, duneShadow);
      canvas.drawPath(curve.shift(const Offset(0, -2.5)), duneLight);
    }

    final darkGrain = Paint()..color = const Color(0xFF8C5528).withValues(alpha: 0.35);
    final lightGrain = Paint()..color = const Color(0xFFFFFDE7).withValues(alpha: 0.45);
    final rng = math.Random(42);

    for (int i = 0; i < 220; i++) {
      final gx = rng.nextDouble() * w;
      final gy = horizonY + (math.pow(rng.nextDouble(), 1.35) * sandHeight);
      final r = 0.9 + (rng.nextDouble() * 2.2);

      if (gx > w * 0.28 && gx < w * 0.72) continue;
      canvas.drawCircle(Offset(gx, gy), r, i.isEven ? darkGrain : lightGrain);
    }
  }

  static void _drawBeachProps(Canvas canvas, Offset top, Offset bot, {required bool isLeft}) {
    final steps = [0.22, 0.55, 0.85];
    for (int i = 0; i < steps.length; i++) {
      final t = steps[i];
      final sideX = top.dx + (bot.dx - top.dx) * t;
      final y = top.dy + (bot.dy - top.dy) * t;
      final scale = 0.55 + (t * 0.70);

      final px = isLeft ? sideX - (80 * scale) : sideX + (80 * scale);
      final pos = Offset(px, y);

      canvas.drawOval(
        Rect.fromCenter(center: pos.translate(isLeft ? -10 * scale : 10 * scale, 18 * scale), width: 72 * scale, height: 20 * scale),
        Paint()..color = const Color(0xFF6B4524).withValues(alpha: 0.32),
      );

      final chairPaint = Paint()..color = (i == 1 ? const Color(0xFF00E5FF) : const Color(0xFFFFD54F));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pos.translate(isLeft ? 22 * scale : -22 * scale, 12 * scale), width: 32 * scale, height: 14 * scale),
          Radius.circular(3 * scale),
        ),
        chairPaint,
      );

      canvas.drawLine(
        pos.translate(0, -14 * scale),
        pos.translate(0, 14 * scale),
        Paint()..color = const Color(0xFFE8E0D2)..strokeWidth = 2.5 * scale,
      );

      final canopyColor = i.isEven ? const Color(0xFFFF5722) : const Color(0xFFFFA000);
      final rect = Rect.fromCenter(center: pos.translate(0, -14 * scale), width: 62 * scale, height: 38 * scale);

      canvas.drawArc(rect, math.pi, math.pi, true, Paint()..color = canopyColor);
      final stripePaint = Paint()..color = const Color(0xFFFFECB3);
      canvas.drawArc(rect, math.pi + 0.6, 0.65, true, stripePaint);
      canvas.drawArc(rect, math.pi + 1.8, 0.65, true, stripePaint);
    }
  }

  static void _drawDenseBeachCrowd(
    Canvas canvas,
    Offset top,
    Offset bot, {
    required bool isLeft,
    required double gameTime,
  }) {
    final shirtColors = [
      const Color(0xFFFF5252),
      const Color(0xFFFFB300),
      const Color(0xFF00E5FF),
      const Color(0xFFAB47BC),
      const Color(0xFF76FF03),
      const Color(0xFFFFFFFF),
      const Color(0xFFFF7043),
      const Color(0xFF3F51B5),
    ];

    final skinColors = [
      const Color(0xFFFFCC80),
      const Color(0xFFE0AC69),
      const Color(0xFFC68642),
      const Color(0xFFF1C27D),
    ];

    const int totalPairs = 12;
    for (int i = 0; i < totalPairs; i++) {
      final t = (i + 0.5) / totalPairs;
      final sideX = top.dx + (bot.dx - top.dx) * t;
      final y = top.dy + (bot.dy - top.dy) * t;
      final scale = 0.42 + (t * 0.65);

      for (int row = 0; row < 3; row++) {
        final dist = (28.0 + (row * 28.0) + (i.isOdd ? 8.0 : 0.0)) * scale;
        final sx = isLeft ? sideX - dist : sideX + dist;

        final phase = (i * 0.85) + (row * 1.4);
        final isJumping = math.sin((gameTime * 3.8) + phase) > 0.40;
        final bounce = isJumping ? -6.5 * scale : 0.0;
        final pos = Offset(sx, y + bounce);

        canvas.drawOval(
          Rect.fromCenter(center: Offset(sx + (isLeft ? -4 * scale : 4 * scale), y + 14 * scale), width: 17 * scale, height: 6 * scale),
          Paint()..color = const Color(0xFF6B4524).withValues(alpha: 0.32),
        );

        final shirt = shirtColors[(i * 4 + row) % shirtColors.length];
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(pos.dx, pos.dy + 3 * scale), width: 13 * scale, height: 15 * scale), Radius.circular(3 * scale)),
          Paint()..color = shirt,
        );

        final skin = skinColors[(i + row) % skinColors.length];
        canvas.drawCircle(Offset(pos.dx, pos.dy - 8 * scale), 5.8 * scale, Paint()..color = skin);

        if ((i + row) % 2 == 0) {
          final hat = shirtColors[(i + 3) % shirtColors.length];
          canvas.drawArc(Rect.fromCircle(center: Offset(pos.dx, pos.dy - 9 * scale), radius: 5.8 * scale), math.pi, math.pi, true, Paint()..color = hat);
        } else {
          canvas.drawLine(Offset(pos.dx - 3 * scale, pos.dy - 8 * scale), Offset(pos.dx + 3 * scale, pos.dy - 8 * scale), Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = 2.0 * scale);
        }

        if (isJumping) {
          final armPaint = Paint()..color = skin..strokeWidth = 2.2 * scale..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(pos.dx - 5 * scale, pos.dy), Offset(pos.dx - 9 * scale, pos.dy - 11 * scale), armPaint);
          canvas.drawLine(Offset(pos.dx + 5 * scale, pos.dy), Offset(pos.dx + 9 * scale, pos.dy - 11 * scale), armPaint);
        }
      }
    }
  }
}