// lib/screens/gameplay/physics/gameplay_controls.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/game_components.dart';
import '../gameplay_screen.dart';

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
        width: radius * 2 + 4,
        height: radius * 2 + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.40),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Transform.translate(
            offset: knobOffset,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.opticYellow,
              ),
              child: const Icon(Icons.control_camera_rounded, size: 18, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

class GameplayActionCluster extends StatelessWidget {
  final MatchPhase phase;
  final bool playerServing;
  final double blitzEnergy;
  final bool isLandscape;
  final VoidCallback onToss;
  final VoidCallback onDriveServe;
  final VoidCallback onLobServe;
  final Function(ShotType) onSwing;

  const GameplayActionCluster({
    super.key,
    required this.phase,
    required this.playerServing,
    required this.blitzEnergy,
    required this.isLandscape,
    required this.onToss,
    required this.onDriveServe,
    required this.onLobServe,
    required this.onSwing,
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
    } else if (phase == MatchPhase.serveBallInAir && playerServing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _serveButton(label: 'LOB SERVE', color: AppColors.mintAccent, onTap: onLobServe),
          const SizedBox(width: 10),
          _serveButton(label: 'DRIVE SERVE', color: AppColors.opticYellow, onTap: onDriveServe),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _actionCircle(
            label: 'BLITZ',
            icon: Icons.bolt,
            size: 50,
            color: blitzEnergy >= 1.0 ? AppColors.opticYellow : Colors.white12,
            textColor: blitzEnergy >= 1.0 ? Colors.black : Colors.white38,
            onTap: () {
              if (blitzEnergy >= 1.0) onSwing(ShotType.signatureBlitz);
            },
          ),
          const SizedBox(width: 10),
          _actionCircle(
            label: 'SMASH',
            icon: Icons.flash_on_rounded,
            size: 58,
            color: AppColors.electricCoral,
            textColor: Colors.white,
            onTap: () => onSwing(ShotType.smash),
          ),
          const SizedBox(width: 10),
          _actionCircle(
            label: 'DRIVE',
            icon: Icons.sports_tennis,
            size: 68,
            color: AppColors.mintAccent,
            textColor: Colors.black,
            onTap: () => onSwing(ShotType.normal),
          ),
        ],
      );
    }
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

  Widget _actionCircle({
    required String label,
    required IconData icon,
    required double size,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.85),
          border: Border.all(color: Colors.white38, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size * 0.38, color: textColor),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: textColor)),
          ],
        ),
      ),
    );
  }
}