import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/ambient_background.dart';
import '../widgets/asset_helpers.dart';
import 'welcome_screen.dart';

// ============================================================================
// VALVE-STYLE TWO-STAGE INTRO WITH ATMOSPHERIC PACING
// ============================================================================

class CompanyIntroScreen extends StatefulWidget {
  const CompanyIntroScreen({super.key});

  @override
  State<CompanyIntroScreen> createState() => _CompanyIntroScreenState();
}

class _CompanyIntroScreenState extends State<CompanyIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // 0 = CanZEd Studios, 1 = Flutter Engine
  int _currentStage = 0;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100), // Default slow fade
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Audio starts playing immediately in the dark
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppAudio.play(context, 'canzed_intro.mp3', 'Valve Intro Resonance');
    });

    _runValveSequence();
  }

  Future<void> _runValveSequence() async {
    // 1. Black screen ambient silence (0.0s -> 1.3s)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _hasNavigated) return;

    // 2. Slow atmospheric fade-in of CanZEd logo (1.3s -> 2.4s)
    _fadeController.duration = const Duration(milliseconds: 1300);
    await _fadeController.forward();
    if (!mounted || _hasNavigated) return;

    // 3. Hold CanZEd logo (2.4s -> 5.4s)
    await Future.delayed(const Duration(milliseconds: 3500));
    if (!mounted || _hasNavigated) return;

    // 4. Quick fade-out (5.4s -> 5.8s)
    _fadeController.duration = const Duration(milliseconds: 1400);
    await _fadeController.reverse();
    if (!mounted || _hasNavigated) return;

    // 5. Switch to Stage 2: Flutter Engine
    setState(() => _currentStage = 1);

    // 6. Quick fade-in to Engine logo (5.8s -> 6.25s)
    _fadeController.duration = const Duration(milliseconds: 1450);
    await _fadeController.forward();
    if (!mounted || _hasNavigated) return;

    // 7. Hold Engine logo (6.25s -> 9.8s)
    await Future.delayed(const Duration(milliseconds: 1550));
    if (!mounted || _hasNavigated) return;

    // 8. Quick fade-out to black (9.8s -> 10.35s)
    _fadeController.duration = const Duration(milliseconds: 550);
    await _fadeController.reverse();
    if (!mounted || _hasNavigated) return;

    // 9. Step into the Welcome Screen
    _navigateToWelcome();
  }

  void _navigateToWelcome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const WelcomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToWelcome, // Tap anywhere to skip
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFF07080A),
        body: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _currentStage == 0
                    ? _buildCanZEdStage(context)
                    : _buildFlutterEngineStage(context),
              ),
            ),

            // Subtle developer skip hint
            Positioned(
              bottom: 24,
              right: 24,
              child: Text(
                'TAP TO SKIP',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // STAGE 1: CANZED LOGO
  // ==========================================================================
  Widget _buildCanZEdStage(BuildContext context) {
    final maxDimension = (MediaQuery.sizeOf(context).width * 0.78).clamp(240.0, 420.0);

    return AppAssetImage(
      assetPath: 'lib/assets/images/logos/canzed_logo.png',
      width: maxDimension,
      height: maxDimension,
      fallback: Container(
        width: maxDimension * 0.75,
        height: maxDimension * 0.75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF14171A),
          border: Border.all(color: const Color(0xFFD32F2F), width: 4.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
              blurRadius: 36,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 4, height: maxDimension * 0.5, color: const Color(0xFFD32F2F)),
            Container(width: maxDimension * 0.5, height: 4, color: const Color(0xFFD32F2F)),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD32F2F),
              ),
              child: const Icon(Icons.settings, color: Colors.black, size: 26),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // STAGE 2: SOURCE-STYLE FLUTTER ENGINE LOGO (PROCEDURAL)
  // ==========================================================================
  Widget _buildFlutterEngineStage(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(120, 120),
          painter: _FlutterEngineLogoPainter(),
        ),
        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 1.2),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'F L U T T E R',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 8.0,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'E N G I N E',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0288D1),
                  letterSpacing: 5.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'CUSTOM 2.5D CANVAS • POWERED BY DART',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.40),
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PROCEDURAL FLUTTER CHEVRON LOGO PAINTER
// ============================================================================
class _FlutterEngineLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shadowPaint = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.45, shadowPaint);

    final topWing = Path()
      ..moveTo(w * 0.88, h * 0.08)
      ..lineTo(w * 0.38, h * 0.58)
      ..lineTo(w * 0.56, h * 0.76)
      ..lineTo(w * 0.88, h * 0.44)
      ..close();
    canvas.drawPath(topWing, Paint()..color = const Color(0xFF40C4FF));

    final bottomSmall = Path()
      ..moveTo(w * 0.56, h * 0.76)
      ..lineTo(w * 0.38, h * 0.94)
      ..lineTo(w * 0.56, h * 1.12)
      ..lineTo(w * 0.74, h * 0.94)
      ..close();
    canvas.drawPath(bottomSmall, Paint()..color = const Color(0xFF00E5FF));

    final midShadow = Path()
      ..moveTo(w * 0.56, h * 0.76)
      ..lineTo(w * 0.46, h * 0.66)
      ..lineTo(w * 0.65, h * 0.47)
      ..lineTo(w * 0.74, h * 0.56)
      ..close();
    canvas.drawPath(midShadow, Paint()..color = const Color(0xFF01579B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}