// lib/screens/opening/welcome_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
import '../lobby/lobby_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  double _loadProgress = 0.0;
  bool _isReady = false;

  int _tipIndex = 0;
  static const List<String> _pickleballTips = [
    'Tip: The serve and return must both bounce before you can volley!',
    'Tip: Stepping into the Kitchen on an air volley is an automatic fault.',
    'Tip: Strike SMASH when the ball is at apex for a thunderous spike.',
    'Tip: Build your rally streak to fill your Blitz Gauge to 100%!',
    'Tip: Distribute Upgrade Points (UP) to boost Power, Control, and Agility.',
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulated Loading Bar
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 32));
      if (!mounted) return false;
      setState(() {
        _loadProgress += 0.018;
        if (_loadProgress >= 0.5 && _tipIndex == 0) {
          _tipIndex = 1;
        }
        if (_loadProgress >= 1.0) {
          _loadProgress = 1.0;
          _isReady = true;
          AppAudio.play(context, AppAssets.musicBattleStart, 'Title Start Fanfare');
        }
      });
      return _loadProgress < 1.0;
    });
  }

  @override
  void dispose() {
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
        backgroundColor: AppColors.darkBg,
        // ====================================================================
        // FULL-SCREEN ARENA DIORAMA BACKGROUND
        // ====================================================================
        body: AmbientCourtBackground(
          backgroundAsset: AppAssets.arenaDiorama,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Game Logo with Glowing Halo
                  AppAssetImage(
                    assetPath: AppAssets.gameLogo,
                    width: 140,
                    height: 140,
                    fallback: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0E2E23),
                        border: Border.all(color: AppColors.opticYellow, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.opticYellow.withValues(alpha: 0.35),
                            blurRadius: 36,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_tennis_rounded,
                        size: 56,
                        color: AppColors.opticYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3D Game Title Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.opticYellow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '3.0',
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
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, letterSpacing: 1.0),
                  ),

                  const Spacer(flex: 3),

                  // Bottom Section: Loading Bar OR "Tap Anywhere"
                  if (!_isReady) ...[
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
                              valueColor: const AlwaysStoppedAnimation(AppColors.mintAccent),
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
                    FadeTransition(
                      opacity: _pulseAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'TAP ANYWHERE TO ENTER',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.opticYellow,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Step onto the court and claim tournament glory',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
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