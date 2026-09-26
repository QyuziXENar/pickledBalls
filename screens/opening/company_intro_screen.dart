// lib/screens/company_intro_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/asset_helpers.dart';
import 'welcome_screen.dart';

// ============================================================================
// XCCR GAME STUDIOS — TWO-STAGE CINEMATIC INTRO SEQUENCE
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

  // 0 = XCCR Game Studios, 1 = Flutter Engine
  int _currentStage = 0;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppAudio.play(context, AppAssets.musicXccrIntro, 'XCCR Intro Resonance');
    });

    _runCinematicSequence();
  }

  Future<void> _runCinematicSequence() async {
    // Stage 1: Ambient silence to XCCR Logo
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted || _hasNavigated) return;

    _fadeController.duration = const Duration(milliseconds: 1200);
    await _fadeController.forward();
    if (!mounted || _hasNavigated) return;

    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted || _hasNavigated) return;

    _fadeController.duration = const Duration(milliseconds: 1000);
    await _fadeController.reverse();
    if (!mounted || _hasNavigated) return;

    // Stage 2: Flutter 2.5D Custom Engine
    setState(() => _currentStage = 1);

    _fadeController.duration = const Duration(milliseconds: 1200);
    await _fadeController.forward();
    if (!mounted || _hasNavigated) return;

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _hasNavigated) return;

    _fadeController.duration = const Duration(milliseconds: 600);
    await _fadeController.reverse();
    if (!mounted || _hasNavigated) return;

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
        backgroundColor: AppColors.darkBg,
        body: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _currentStage == 0
                    ? _buildXccrStage(context)
                    : _buildFlutterEngineStage(context),
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: Text(
                'TAP TO SKIP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // STAGE 1: XCCR GAME STUDIOS LOGO & BRANDING
  // ==========================================================================
  Widget _buildXccrStage(BuildContext context) {
    final maxDimension = (MediaQuery.sizeOf(context).width * 0.78).clamp(240.0, 400.0);

    return AppAssetImage(
      assetPath: AppAssets.logoXccr,
      width: maxDimension,
      height: maxDimension,
      fallback: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF14171A),
          border: Border.all(color: AppColors.cyberCyan, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyberCyan.withValues(alpha: 0.35),
              blurRadius: 36,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'XCCR',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 26,
                  letterSpacing: 3.0,
                ),
              ),
              Text(
                'GAME STUDIOS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyberCyan,
                  fontSize: 9,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // STAGE 2: CUSTOM 2.5D FLUTTER ENGINE
  // ==========================================================================
  Widget _buildFlutterEngineStage(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0288D1).withValues(alpha: 0.40),
                blurRadius: 50,
                spreadRadius: 6,
              ),
            ],
          ),
          child: const FlutterLogo(size: 100),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 7.0,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'CUSTOM 2.5D CANVAS',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyberCyan,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}