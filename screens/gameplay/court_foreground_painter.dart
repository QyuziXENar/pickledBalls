// lib/screens/gameplay/court_foreground_painter.dart

import 'package:flutter/material.dart';

class CourtForegroundPainter {
  static void drawForeground({
    required Canvas canvas,
    required Size size,
    required String courtVenue,
    required Offset pBottomLeft,
    required Offset pBottomRight,
  }) {
    final double baselineY = pBottomLeft.dy;
    final double screenBottom = size.height;
    if (baselineY >= screenBottom) return;

    if (courtVenue == 'Sunlit Beach') {
      // Tropical Sand & Wooden Boardwalk Planks
      final sandRect = Rect.fromLTRB(0, baselineY, size.width, screenBottom);
      canvas.drawRect(
        sandRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFD4A373), Color(0xFFC6925B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(sandRect),
      );

      // Wooden Boardwalk Planks
      final plankPaint = Paint()
        ..color = const Color(0xFF8D5B36)
        ..strokeWidth = 2.0;
      for (double py = baselineY + 8; py < screenBottom; py += 14) {
        canvas.drawLine(Offset(0, py), Offset(size.width, py), plankPaint);
      }

    } else if (courtVenue == 'Midnight Stadium') {
      // Cyberpunk Dark Steel Floor Grate with Cyan LED Edge
      final floorRect = Rect.fromLTRB(0, baselineY, size.width, screenBottom);
      canvas.drawRect(floorRect, Paint()..color = const Color(0xFF06090F));

      // Glowing Neon Cyan Railing along bottom camera buffer
      canvas.drawLine(
        Offset(0, baselineY + 4),
        Offset(size.width, baselineY + 4),
        Paint()
          ..color = const Color(0xFF00E5FF)
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

    } else if (courtVenue == 'Training Facility') {
      // Gymnasium Hardwood Perimeter & Team Duffel Benches
      final woodRect = Rect.fromLTRB(0, baselineY, size.width, screenBottom);
      canvas.drawRect(
        woodRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(woodRect),
      );

      // Court boundary white safety buffer line
      canvas.drawLine(
        Offset(0, baselineY + 6),
        Offset(size.width, baselineY + 6),
        Paint()..color = Colors.white24..strokeWidth = 2.5,
      );

    } else {
      // Tournament Arena: LED Ribbon Advertising Boards & TV Broadcast Cameras
      final apronRect = Rect.fromLTRB(0, baselineY, size.width, screenBottom);
      canvas.drawRect(apronRect, Paint()..color = const Color(0xFF081420));

      // LED Sponsor Ribbon Board
      final boardRect = Rect.fromLTWH(0, baselineY + 2, size.width, 18);
      canvas.drawRect(boardRect, Paint()..color = const Color(0xFF0A2238));
      canvas.drawLine(
        Offset(0, baselineY + 2),
        Offset(size.width, baselineY + 2),
        Paint()..color = const Color(0xFFD6F800)..strokeWidth = 2.0,
      );

      // TV Broadcast Camera on Tripod (Left Corner)
      _drawCameraTripod(canvas, Offset(size.width * 0.12, baselineY + 22));
      // TV Broadcast Camera on Tripod (Right Corner)
      _drawCameraTripod(canvas, Offset(size.width * 0.88, baselineY + 22));
    }
  }

  static void _drawCameraTripod(Canvas canvas, Offset base) {
    final metalPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.2;

    // Legs
    canvas.drawLine(base, base + const Offset(-8, 16), metalPaint);
    canvas.drawLine(base, base + const Offset(8, 16), metalPaint);
    canvas.drawLine(base, base + const Offset(0, 16), metalPaint);

    // Camera Body & Red Tally Light
    final camRect = Rect.fromCenter(center: base - const Offset(0, 6), width: 14, height: 8);
    canvas.drawRect(camRect, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(base - const Offset(4, 8), 1.8, Paint()..color = const Color(0xFFFF1744));
  }
}