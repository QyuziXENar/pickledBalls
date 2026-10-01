// lib/screens/gameplay/widgets/pc_controller_override.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../gameplay_screen.dart';

enum InputDeviceOverride {
  auto,        // Uses real-time OS check
  forceTouch,  // Useful for Windows touchscreen testing
  forcePC,     // Useful for Android tablets with keyboard/mouse
}

// ============================================================================
// 1. HARDWARE PLATFORM DETECTOR & IF-STATEMENT ENGINE
// ============================================================================
class PlatformInputManager {
  static InputDeviceOverride overrideMode = InputDeviceOverride.auto;

  /// Returns TRUE if running on Android or iOS phone/tablet
  static bool get isMobile {
    if (overrideMode == InputDeviceOverride.forceTouch) return true;
    if (overrideMode == InputDeviceOverride.forcePC) return false;

    if (kIsWeb) {
      // Safe web check for mobile browsers
      return defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
    }

    return Platform.isAndroid || Platform.isIOS;
  }

  /// Returns TRUE if running on Windows, macOS, Linux, or Desktop Web
  static bool get isPC => !isMobile;

  /// The IF-Statement check used by UI to show or hide touch clusters
  static bool get shouldShowTouchControls => isMobile;
}

// ============================================================================
// 2. SLEEK PC KEYBINDING HUD OVERLAY (REPLACES CLUNKY TOUCH BUTTONS ON PC)
// ============================================================================
class PcKeyHintsOverlay extends StatelessWidget {
  final MatchPhase phase;
  final bool playerServing;
  final double blitzEnergy;

  const PcKeyHintsOverlay({
    super.key,
    required this.phase,
    required this.playerServing,
    required this.blitzEnergy,
  });

  @override
  Widget build(BuildContext context) {
    final isBlitzReady = blitzEnergy >= 1.0;

    return Positioned(
      bottom: 14,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: Movement Keys Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _keyBadge('W'),
                const SizedBox(width: 3),
                _keyBadge('A'),
                const SizedBox(width: 3),
                _keyBadge('S'),
                const SizedBox(width: 3),
                _keyBadge('D'),
                const SizedBox(width: 8),
                const Text(
                  'MOVE / SHUFFLE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white70,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Center: Serve Prompt on PC
          if (phase == MatchPhase.serveTossWait && playerServing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cyberCyan.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyberCyan, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _keyBadge('SPACE', width: 54),
                  const SizedBox(width: 8),
                  const Text(
                    'TOSS BALL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
            )
          else if (phase == MatchPhase.serveBallInAir && playerServing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.opticYellow.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.opticYellow, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _keyBadge('SPACE', width: 54),
                  const SizedBox(width: 6),
                  const Text('DRIVE SERVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 10),
                  _keyBadge('L'),
                  const SizedBox(width: 6),
                  const Text('LOB SERVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),

          // Right: Action Keys Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _keyBadge('SPACE / J', width: 68),
                const SizedBox(width: 5),
                const Text('DRIVE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.mintAccent)),
                const SizedBox(width: 10),

                _keyBadge('SHIFT / K', width: 66),
                const SizedBox(width: 5),
                const Text('SMASH', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.electricCoral)),
                const SizedBox(width: 10),

                _keyBadge('L'),
                const SizedBox(width: 5),
                const Text('LOB', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFFFA726))),
                const SizedBox(width: 10),

                _keyBadge(
                  'Q',
                  color: isBlitzReady ? AppColors.opticYellow : Colors.white24,
                  textColor: isBlitzReady ? Colors.black : Colors.white38,
                ),
                const SizedBox(width: 5),
                Text(
                  'BLITZ',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isBlitzReady ? AppColors.opticYellow : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyBadge(String keyText, {double? width, Color? color, Color? textColor}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white30, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text(
          keyText,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}