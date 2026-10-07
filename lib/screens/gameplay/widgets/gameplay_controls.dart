// lib/screens/gameplay/widgets/gameplay_controls.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/game_components.dart';
import '../gameplay_screen.dart';

// ============================================================================
// TRUE 360° OMNIDIRECTIONAL CIRCULAR JOYSTICK (NO DIAMONDS, NO DRIFT)
// ============================================================================
class VirtualJoystickWidget extends StatelessWidget {
  final Offset knobOffset;
  final double radius;
  final Function(Offset delta) onUpdate;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const VirtualJoystickWidget({
    super.key,
    required this.knobOffset,
    required this.radius,
    required this.onUpdate,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => onStart(),
      onPanUpdate: (details) => onUpdate(details.delta),
      onPanEnd: (_) => onEnd(),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.50),
          border: Border.all(color: Colors.white30, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner 360-degree Guide Ring
            Container(
              width: radius * 1.25,
              height: radius * 1.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.opticYellow.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),
            // Smooth Analog Thumb Knob
            Transform.translate(
              offset: knobOffset,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.opticYellow,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.opticYellow.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.circle, size: 14, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// RADIAL 4-BUTTON CLUSTER WITH FIRM INPUT
// ============================================================================
class GameplayActionCluster extends StatelessWidget {
  final MatchPhase phase;
  final bool playerServing;
  final double blitzEnergy;
  final double driveCooldown;
  final double smashCooldown;
  final double lobCooldown;
  final bool isLandscape;
  final VoidCallback onToss;
  final VoidCallback onDriveServe;
  final VoidCallback onLobServe;
  final Function(ShotType) onSwing;
  final VoidCallback onBlitzNotReady;

  const GameplayActionCluster({
    super.key,
    required this.phase,
    required this.playerServing,
    required this.blitzEnergy,
    required this.driveCooldown,
    required this.smashCooldown,
    required this.lobCooldown,
    required this.isLandscape,
    required this.onToss,
    required this.onDriveServe,
    required this.onLobServe,
    required this.onSwing,
    required this.onBlitzNotReady,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == MatchPhase.serveTossWait && playerServing) {
      return BouncyButton(
        onTap: onToss,
        child: Container(
          width: 140,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.lanHostGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 24),
              SizedBox(width: 6),
              Text('TOSS BALL', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (phase == MatchPhase.serveBallInAir && playerServing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _serveButton(label: 'LOB SERVE', color: AppColors.mintAccent, onTap: onLobServe),
          const SizedBox(width: 12),
          _serveButton(label: 'DRIVE SERVE', color: AppColors.opticYellow, onTap: onDriveServe),
        ],
      );
    }

    final isBlitzReady = blitzEnergy >= 1.0;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 4,
            bottom: 4,
            child: _cooldownActionButton(
              label: 'DRIVE',
              icon: Icons.sports_tennis,
              size: 72,
              color: AppColors.mintAccent,
              textColor: Colors.black,
              cooldownProgress: driveCooldown,
              onTap: () => onSwing(ShotType.normal),
            ),
          ),
          Positioned(
            right: 18,
            top: 14,
            child: _cooldownActionButton(
              label: 'SMASH',
              icon: Icons.flash_on_rounded,
              size: 56,
              color: AppColors.electricCoral,
              textColor: Colors.white,
              cooldownProgress: smashCooldown,
              onTap: () => onSwing(ShotType.smash),
            ),
          ),
          Positioned(
            left: 28,
            top: 28,
            child: _cooldownActionButton(
              label: 'LOB',
              icon: Icons.expand_less_rounded,
              size: 48,
              color: const Color(0xFFFFA726),
              textColor: Colors.black,
              cooldownProgress: lobCooldown,
              onTap: () => onSwing(ShotType.lob),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 12,
            child: _cooldownActionButton(
              label: 'BLITZ',
              icon: Icons.bolt,
              size: 42,
              color: isBlitzReady ? AppColors.opticYellow : const Color(0xFF2C3E50),
              textColor: isBlitzReady ? Colors.black : Colors.white38,
              cooldownProgress: isBlitzReady ? 0.0 : (1.0 - blitzEnergy),
              onTap: () {
                if (isBlitzReady) {
                  onSwing(ShotType.signatureBlitz);
                } else {
                  onBlitzNotReady();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _serveButton({required String label, required Color color, required VoidCallback onTap}) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _cooldownActionButton({
    required String label,
    required IconData icon,
    required double size,
    required Color color,
    required Color textColor,
    required double cooldownProgress,
    required VoidCallback onTap,
  }) {
    final isOnCooldown = cooldownProgress > 0.0;

    return GestureDetector(
      onTapDown: (_) {
        if (isOnCooldown && label != 'BLITZ') {
          HapticFeedback.selectionClick();
          return;
        }
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isOnCooldown && label != 'BLITZ' ? 0.40 : 1.0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.90),
                border: Border.all(
                  color: label == 'BLITZ' && cooldownProgress == 0.0
                      ? AppColors.opticYellow
                      : Colors.white38,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: size * 0.38, color: textColor),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: (size * 0.16).clamp(7.0, 10.0),
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOnCooldown)
            SizedBox(
              width: size + 4,
              height: size + 4,
              child: CircularProgressIndicator(
                value: cooldownProgress,
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  label == 'BLITZ'
                      ? AppColors.opticYellow.withValues(alpha: 0.7)
                      : AppColors.electricCoral.withValues(alpha: 0.7),
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}