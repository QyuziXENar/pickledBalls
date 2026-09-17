import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF091210);
  static const Color deepGreen = Color(0xFF0A2920);
  static const Color opticYellow = Color(0xFFD6F800);
  static const Color mintAccent = Color(0xFF26E098);
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color textMuted = Color(0xFF8BA59B);
}

class AmbientCourtBackground extends StatelessWidget {
  final Widget child;

  const AmbientCourtBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppTheme.darkBg),
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.deepGreen.withValues(alpha: 0.8),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.opticYellow.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _CourtGridPainter()),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

class _CourtGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(0, 80), Offset(size.width, 180), paint);
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.85),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}