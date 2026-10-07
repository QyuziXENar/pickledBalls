// lib/widgets/ambient_background.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'asset_helpers.dart';

// ============================================================================
// APP THEME DESIGN TOKENS
// ============================================================================
class AppTheme {
  static const Color darkBg = Color(0xFF0E1A16);
  static const Color deepGreen = Color(0xFF143026);
  static const Color opticYellow = Color(0xFFD6F800);
  static const Color mintAccent = Color(0xFF26E098);
  static const Color glassFill = Color(0x24FFFFFF);
  static const Color glassBorder = Color(0x40FFFFFF);
  static const Color textMuted = Color(0xFF9EB5AB);
}

// ============================================================================
// CRISP, VIBRANT & SHARP AMBIENT BACKGROUND
// ============================================================================
class AmbientCourtBackground extends StatelessWidget {
  final Widget child;
  final String? backgroundAsset;
  final String? fallbackAsset;

  const AmbientCourtBackground({
    super.key,
    required this.child,
    this.backgroundAsset,
    this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    final assetToLoad = (backgroundAsset != null && AppAssetRegistry.hasAsset(backgroundAsset!))
        ? backgroundAsset!
        : (fallbackAsset != null && AppAssetRegistry.hasAsset(fallbackAsset!)
            ? fallbackAsset!
            : (backgroundAsset ?? ''));

    final bool hasImage = assetToLoad.isNotEmpty && AppAssetRegistry.hasAsset(assetToLoad);

    return Stack(
      children: [
        // 1. Base Layer: Rich Stadium Green
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF153328),
                Color(0xFF10271F),
                Color(0xFF0A1813),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // 2. Crisp, Sharp Full-Screen Artwork (NO BLUR, Full Clarity!)
        if (hasImage) ...[
          Positioned.fill(
            child: AppAssetImage(
              assetPath: assetToLoad,
              fit: BoxFit.cover,
              fallback: const SizedBox.shrink(),
            ),
          ),
          // Subtle Dark Contrast Gradient (Keeps buttons and text readable over art)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ] else ...[
          // 3. Ambient Lighting & Blur ONLY when NO image is provided (e.g. Settings)
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mintAccent.withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.opticYellow.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],

        // 4. Subtle Court Grid Lines
        Positioned.fill(
          child: CustomPaint(painter: _CourtGridPainter()),
        ),

        // 5. Foreground Content
        SafeArea(child: child),
      ],
    );
  }
}

class _CourtGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(0, 90), Offset(size.width, 200), paint);
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.82),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}