import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/ambient_background.dart';
import '../widgets/asset_helpers.dart';
import 'lobby_screen.dart';

// ============================================================================
// CLASH ROYALE STYLE TITLE & PROGRESS LOADING SCREEN
// ============================================================================

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  double _loadProgress = 0.0;
  bool _isReady = false;
  Timer? _progressTimer;

  int _tipIndex = 0;
  static const List<String> _pickleballTips = [
    'Tip: The serve and return must both bounce before you can volley!',
    'Tip: Stepping into the Kitchen on an air volley is an automatic fault.',
    'Tip: Right-click or tap SMASH when the ball is high for maximum velocity.',
    'Tip: Build your rally streak to fill your Blitz Meter to 100%!',
    'Tip: Different athletes have unique sprint speeds and power ratings.',
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsing "TAP TO START" text
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulated Clash Royale 0% -> 100% Loading Bar
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _loadProgress += 0.015;
        if (_loadProgress >= 0.5 && _tipIndex == 0) {
          _tipIndex = 1; // Cycle tip midway
        }
        if (_loadProgress >= 1.0) {
          _loadProgress = 1.0;
          _isReady = true;
          _progressTimer?.cancel();
          AppAudio.play(context, 'clash_start_jingle.mp3', 'Clash Trumpet Start Jingle');
        }
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onScreenTapped() {
    if (!_isReady) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LobbyScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScreenTapped,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: AmbientCourtBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Game Logo: Tries PNG file first, falls back to 3D badge
                  AppAssetImage(
                    assetPath: 'lib/assets/images/logos/game_logo.png',
                    width: 140,
                    height: 140,
                    fallback: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0E2E23),
                        border: Border.all(color: AppTheme.opticYellow, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.opticYellow.withValues(alpha: 0.35),
                            blurRadius: 36,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_tennis_rounded,
                        size: 56,
                        color: AppTheme.opticYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3D Game Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.opticYellow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '2.0',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PADDLE BLITZ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Precision Dinks. Electric Volleys.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted, letterSpacing: 1.0),
                  ),

                  const Spacer(flex: 3),

                  // BOTTOM SECTION: Clash Royale Loading Bar OR "Tap Anywhere"
                  if (!_isReady) ...[
                    // Pro Pickleball Tip
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _pickleballTips[_tipIndex],
                        key: ValueKey<int>(_tipIndex),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress Bar Container
                    Container(
                      width: double.infinity,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1B16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _loadProgress,
                              minHeight: 22,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
                            ),
                          ),
                          Text(
                            '${(_loadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Ready: Pulsing "Tap to Start"
                    FadeTransition(
                      opacity: _pulseAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'TAP ANYWHERE TO ENTER',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.opticYellow,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Touch anywhere on screen to step onto the court',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}