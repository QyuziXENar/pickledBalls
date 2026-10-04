// lib/screens/gameplay/rendering/stadium_backgrounds.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StadiumBackgrounds {
  static void drawAtmosphericBackground({
    required Canvas canvas,
    required Size size,
    required String courtVenue,
    required Color accentColor,
    required Offset pLeft,
    required Offset pRight,
    required double gameTime,
  }) {
    final horizonY = pLeft.dy - 22.0;

    if (courtVenue == 'Training Facility') {
      // ======================================================================
      // TRAINING FACILITY (COACH BOOMER ACADEMY GYMNASIUM)
      // ======================================================================
      final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(skyRect),
      );

      // Steel Roof Trusses & Gymnasium Girders
      final trussPaint = Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 2.0;
      for (double tx = 0; tx <= size.width; tx += 48) {
        canvas.drawLine(Offset(tx, 0), Offset(tx + 24, horizonY * 0.45), trussPaint);
        canvas.drawLine(Offset(tx + 24, 0), Offset(tx, horizonY * 0.45), trussPaint);
      }
      canvas.drawLine(Offset(0, horizonY * 0.45), Offset(size.width, horizonY * 0.45), trussPaint..strokeWidth = 3.0);

      // High-Bay Gymnasium Lighting Fixtures
      for (double lx = 40; lx < size.width; lx += 90) {
        final lightPos = Offset(lx, horizonY * 0.35);
        canvas.drawCircle(
          lightPos,
          26,
          Paint()
            ..color = const Color(0xFFF8FAFC).withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
        );
        canvas.drawRect(Rect.fromCenter(center: lightPos, width: 22, height: 6), Paint()..color = Colors.white);
      }

      // Hanging Academy Championship Banners
      final bannerPaint = Paint()..color = const Color(0xFF1E3A8A);
      final goldTrim = Paint()..color = AppColors.opticYellow..style = PaintingStyle.stroke..strokeWidth = 1.5;

      for (double bx = size.width * 0.22; bx <= size.width * 0.78; bx += 80) {
        final bRect = Rect.fromLTWH(bx - 16, horizonY * 0.45, 32, 28);
        canvas.drawRect(bRect, bannerPaint);
        canvas.drawRect(bRect, goldTrim);
        canvas.drawCircle(Offset(bx, horizonY * 0.45 + 14), 4, Paint()..color = AppColors.opticYellow);
      }

    } else if (courtVenue == 'Sunlit Beach') {
      final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF0277BD), Color(0xFF4FC3F7), Color(0xFFFFE082)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(skyRect),
      );

      final sunPos = Offset(size.width * 0.78, horizonY * 0.32);
      canvas.drawCircle(
        sunPos,
        38,
        Paint()
          ..color = const Color(0xFFFFF9C4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );

      final oceanRect = Rect.fromLTWH(0, horizonY * 0.62, size.width, horizonY * 0.38);
      canvas.drawRect(
        oceanRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(oceanRect),
      );

      for (double wx = 0; wx < size.width; wx += 24) {
        final waveBob = math.sin(gameTime * 2.5 + wx) * 2.0;
        canvas.drawLine(
          Offset(wx, horizonY * 0.75 + waveBob),
          Offset(wx + 16, horizonY * 0.75 + waveBob),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..strokeWidth = 1.5,
        );
      }

      _drawDetailedPalm(canvas, Offset(size.width * 0.07, horizonY), 42.0);
      _drawDetailedPalm(canvas, Offset(size.width * 0.14, horizonY), 34.0);
      _drawDetailedPalm(canvas, Offset(size.width * 0.88, horizonY), 44.0);
      _drawDetailedPalm(canvas, Offset(size.width * 0.94, horizonY), 36.0);

    } else if (courtVenue == 'Midnight Stadium') {
      final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF020408), Color(0xFF090D1A), Color(0xFF05192D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(skyRect),
      );

      for (double gx = 0; gx <= size.width; gx += 32) {
        canvas.drawLine(
          Offset(size.width / 2, horizonY * 0.5),
          Offset(gx, horizonY),
          Paint()..color = AppColors.cyberCyan.withValues(alpha: 0.12),
        );
      }

      final rng = math.Random(101);
      for (double bx = 8; bx < size.width; bx += 26) {
        final bHeight = 30.0 + (rng.nextDouble() * 50);
        final bRect = Rect.fromLTWH(bx, horizonY - bHeight, 22, bHeight);
        canvas.drawRect(bRect, Paint()..color = const Color(0xFF060B14));
        canvas.drawRect(
          bRect,
          Paint()
            ..color = (bx % 52 == 0 ? const Color(0xFFE040FB) : AppColors.cyberCyan).withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke,
        );
      }

      final sweepAngle = math.sin(gameTime * 1.5) * 0.35;
      final spotPaint = Paint()
        ..color = AppColors.cyberCyan.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawCircle(Offset(size.width * 0.22 + (sweepAngle * 90), horizonY * 0.38), 50, spotPaint);
      canvas.drawCircle(Offset(size.width * 0.78 - (sweepAngle * 90), horizonY * 0.38), 50, spotPaint);

    } else if (courtVenue == 'Rivalry Clash') {
      final leftSkyRect = Rect.fromLTWH(0, 0, size.width / 2, horizonY);
      canvas.drawRect(
        leftSkyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF2B0508), Color(0xFF4A0A10), Color(0xFF140204)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(leftSkyRect),
      );

      final rightSkyRect = Rect.fromLTWH(size.width / 2, 0, size.width / 2, horizonY);
      canvas.drawRect(
        rightSkyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF04152A), Color(0xFF0B2E58), Color(0xFF020912)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rightSkyRect),
      );

      final centerBeam = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, horizonY), centerBeam);

      for (int row = 0; row < 4; row++) {
        final rowY = horizonY - (row * 9);
        for (double cx = 10; cx < (size.width / 2) - 10; cx += 14) {
          final bob = (math.sin(gameTime * 4.0 + cx) * 1.5).abs();
          canvas.drawCircle(
            Offset(cx, rowY - 3 - bob),
            2.2,
            Paint()..color = const Color(0xFFFF5252).withValues(alpha: 0.55),
          );
        }
      }

      for (int row = 0; row < 4; row++) {
        final rowY = horizonY - (row * 9);
        for (double cx = (size.width / 2) + 10; cx < size.width - 10; cx += 14) {
          final bob = (math.sin(gameTime * 4.0 + cx) * 1.5).abs();
          canvas.drawCircle(
            Offset(cx, rowY - 3 - bob),
            2.2,
            Paint()..color = const Color(0xFF40C4FF).withValues(alpha: 0.55),
          );
        }
      }

      final redSpotAngle = math.sin(gameTime * 1.8) * 60;
      final blueSpotAngle = -math.sin(gameTime * 1.8) * 60;

      canvas.drawCircle(
        Offset(size.width * 0.25 + redSpotAngle, horizonY * 0.4),
        44,
        Paint()
          ..color = const Color(0xFFFF1744).withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
      canvas.drawCircle(
        Offset(size.width * 0.75 + blueSpotAngle, horizonY * 0.4),
        44,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );

    } else if (courtVenue == 'Monochrome Street') {
      final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF0A0A0A), Color(0xFF161616), Color(0xFF222222)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(skyRect),
      );

      final fencePaint = Paint()
        ..color = Colors.white24
        ..strokeWidth = 1.0;
      for (double fx = 0; fx < size.width; fx += 12) {
        canvas.drawLine(Offset(fx, horizonY - 24), Offset(fx + 12, horizonY), fencePaint);
        canvas.drawLine(Offset(fx + 12, horizonY - 24), Offset(fx, horizonY), fencePaint);
      }
      canvas.drawLine(Offset(0, horizonY - 24), Offset(size.width, horizonY - 24), Paint()..color = Colors.white38..strokeWidth = 2.0);

      final brickRect = Rect.fromLTWH(size.width * 0.35, horizonY - 48, size.width * 0.30, 24);
      canvas.drawRRect(RRect.fromRectAndRadius(brickRect, const Radius.circular(4)), Paint()..color = const Color(0xFF141414));
      canvas.drawRRect(RRect.fromRectAndRadius(brickRect, const Radius.circular(4)), Paint()..color = Colors.white12..style = PaintingStyle.stroke);

      _drawSodiumStreetlamp(canvas, Offset(size.width * 0.12, horizonY));
      _drawSodiumStreetlamp(canvas, Offset(size.width * 0.88, horizonY));

    } else {
      final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF0A141E), Color(0xFF10263C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(skyRect),
      );

      final jumboRect = Rect.fromCenter(
        center: Offset(size.width / 2, horizonY * 0.42),
        width: 140,
        height: 42,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(jumboRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFF04080D),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(jumboRect, const Radius.circular(8)),
        Paint()
          ..color = AppColors.opticYellow.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      for (int row = 0; row < 5; row++) {
        final rowY = horizonY - (row * 9);
        canvas.drawLine(
          Offset(0, rowY),
          Offset(size.width, rowY),
          Paint()..color = Colors.white.withValues(alpha: 0.08),
        );
        for (double cx = 10; cx < size.width; cx += 13) {
          final cheerBob = (math.sin(gameTime * 4.5 + cx) * 1.5).abs();
          canvas.drawCircle(
            Offset(cx, rowY - 3 - cheerBob),
            2.2,
            Paint()..color = (cx % 26 == 0) ? AppColors.opticYellow.withValues(alpha: 0.5) : Colors.white30,
          );
        }
      }

      _drawFloodlightTower(canvas, Offset(size.width * 0.14, horizonY * 0.2));
      _drawFloodlightTower(canvas, Offset(size.width * 0.86, horizonY * 0.2));
    }

    final hoardingPath = Path()
      ..moveTo(pLeft.dx, pLeft.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..lineTo(pRight.dx, horizonY)
      ..lineTo(pLeft.dx, horizonY)
      ..close();

    canvas.drawPath(hoardingPath, Paint()..color = const Color(0xFF05080C));
    canvas.drawLine(
      Offset(pLeft.dx, horizonY),
      Offset(pRight.dx, horizonY),
      Paint()
        ..color = accentColor.withValues(alpha: 0.85)
        ..strokeWidth = 2.2,
    );
  }

  static void _drawSodiumStreetlamp(Canvas canvas, Offset base) {
    const lampHeight = 54.0;
    final top = Offset(base.dx, base.dy - lampHeight);

    canvas.drawLine(base, top, Paint()..color = const Color(0xFF333333)..strokeWidth = 3.0);
    canvas.drawLine(top, Offset(top.dx + 8, top.dy - 4), Paint()..color = const Color(0xFF555555)..strokeWidth = 2.5);

    final conePath = Path()
      ..moveTo(top.dx + 8, top.dy - 4)
      ..lineTo(base.dx - 28, base.dy)
      ..lineTo(base.dx + 38, base.dy)
      ..close();

    canvas.drawPath(
      conePath,
      Paint()
        ..color = const Color(0xFFFFB74D).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  static void _drawFloodlightTower(Canvas canvas, Offset towerPos) {
    canvas.drawCircle(
      towerPos,
      42,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    final beamPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 2.5;
    canvas.drawLine(towerPos + const Offset(-12, 16), towerPos + const Offset(12, 16), beamPaint);
    canvas.drawLine(towerPos + const Offset(-10, 0), towerPos + const Offset(10, 32), beamPaint);
    canvas.drawLine(towerPos + const Offset(10, 0), towerPos + const Offset(-10, 32), beamPaint);
  }

  static void _drawDetailedPalm(Canvas canvas, Offset base, double height) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF1B2A1E)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final top = Offset(base.dx + 6, base.dy - height);
    canvas.drawLine(base, top, trunkPaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF0F3B25)
      ..strokeWidth = 2.2;

    for (int i = -4; i <= 4; i++) {
      final leafEnd = Offset(top.dx + (i * 9), top.dy + (i.abs() * 3) - 7);
      canvas.drawLine(top, leafEnd, leafPaint);
    }
  }
}