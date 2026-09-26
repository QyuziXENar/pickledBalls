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

    if (courtVenue == 'Sunlit Beach') {
      // 1. Tropical Sun Sky Gradient
      final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6), Color(0xFFFFE082)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(skyRect),
      );

      final sunPos = Offset(size.width * 0.76, horizonY * 0.35);
      canvas.drawCircle(
        sunPos,
        34,
        Paint()
          ..color = const Color(0xFFFFF9C4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );

      // Ocean Shimmer
      final oceanRect = Rect.fromLTWH(0, horizonY * 0.65, size.width, horizonY * 0.35);
      canvas.drawRect(
        oceanRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF007791), Color(0xFF00A896)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(oceanRect),
      );

      // Palm silhouettes
      _drawPalm(canvas, Offset(size.width * 0.08, horizonY), 38.0);
      _drawPalm(canvas, Offset(size.width * 0.92, horizonY), 42.0);

    } else if (courtVenue == 'Midnight Stadium') {
      // 2. Cyberpunk Skyline
      final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF020408), Color(0xFF0A1128), Color(0xFF001F3F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(skyRect),
      );

      final rng = math.Random(42);
      for (double x = 10; x < size.width; x += 28) {
        final bHeight = 35.0 + (rng.nextDouble() * 45);
        final bRect = Rect.fromLTWH(x, horizonY - bHeight, 22, bHeight);
        canvas.drawRect(bRect, Paint()..color = const Color(0xFF050D18));
        canvas.drawRect(
          bRect,
          Paint()
            ..color = AppColors.cyberCyan.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke,
        );
      }

      // Sweeping neon spotlights
      final sweepAngle = math.sin(gameTime * 1.5) * 0.3;
      final spotPaint = Paint()
        ..color = AppColors.cyberCyan.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(size.width * 0.25 + (sweepAngle * 80), horizonY * 0.4), 48, spotPaint);
      canvas.drawCircle(Offset(size.width * 0.75 - (sweepAngle * 80), horizonY * 0.4), 48, spotPaint);

    } else {
      // 3. Tournament Arena: Stadium Grandstands & Jumbotron
      final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
      canvas.drawRect(
        skyRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF0A1520), Color(0xFF102538)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(skyRect),
      );

      final jumboRect = Rect.fromCenter(
        center: Offset(size.width / 2, horizonY * 0.45),
        width: 130,
        height: 38,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(jumboRect, const Radius.circular(6)),
        Paint()..color = const Color(0xFF050A0E),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(jumboRect, const Radius.circular(6)),
        Paint()
          ..color = AppColors.opticYellow.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Crowds
      final crowdBaseY = horizonY;
      for (int row = 0; row < 5; row++) {
        final rowY = crowdBaseY - (row * 8);
        canvas.drawLine(
          Offset(0, rowY),
          Offset(size.width, rowY),
          Paint()..color = Colors.white.withValues(alpha: 0.08),
        );
        for (double cx = 12; cx < size.width; cx += 14) {
          final bob = (math.sin(gameTime * 4 + cx) * 1.5).abs();
          canvas.drawCircle(
            Offset(cx, rowY - 3 - bob),
            2.2,
            Paint()..color = (cx % 28 == 0) ? AppColors.opticYellow.withValues(alpha: 0.5) : Colors.white30,
          );
        }
      }

      // Floodlight beams
      final leftTower = Offset(size.width * 0.15, horizonY * 0.2);
      final rightTower = Offset(size.width * 0.85, horizonY * 0.2);
      final beamPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(leftTower, 38, beamPaint);
      canvas.drawCircle(rightTower, 38, beamPaint);
    }

    // Commercial LED Board
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

  static void _drawPalm(Canvas canvas, Offset base, double height) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF071B12)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final top = Offset(base.dx + 4, base.dy - height);
    canvas.drawLine(base, top, trunkPaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF0C2B1C)
      ..strokeWidth = 2.0;

    for (int i = -3; i <= 3; i++) {
      final leafEnd = Offset(top.dx + (i * 9), top.dy + (i.abs() * 3) - 6);
      canvas.drawLine(top, leafEnd, leafPaint);
    }
  }
}