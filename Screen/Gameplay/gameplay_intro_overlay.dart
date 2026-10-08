// lib/screens/gameplay/gameplay_intro_overlay.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import 'gameplay_models.dart';

class GameplayIntroOverlay extends StatelessWidget {
  final MatchPhase phase;
  final int countdownNumber;
  final CharacterModel playerChar;
  final CharacterModel opponentChar;
  final String venueName;
  final AIDifficulty difficulty;

  const GameplayIntroOverlay({
    super.key,
    required this.phase,
    required this.countdownNumber,
    required this.playerChar,
    required this.opponentChar,
    required this.venueName,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == MatchPhase.cinematicSplash) {
      return _buildVsCardSplash(context);
    } else if (phase == MatchPhase.countdown) {
      return _buildCountdown(context);
    }
    return const SizedBox.shrink();
  }

  Widget _buildVsCardSplash(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.opticYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.opticYellow.withValues(alpha: 0.5)),
              ),
              child: Text(
                venueName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.opticYellow,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAthleteCard(
                  athlete: playerChar,
                  isPlayer: true,
                  subtag: 'YOU',
                  width: (screenW * 0.36).clamp(130.0, 180.0),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F1B26),
                      border: Border.all(color: AppColors.opticYellow, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.opticYellow.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                _buildAthleteCard(
                  athlete: opponentChar,
                  isPlayer: false,
                  subtag: difficulty.label.toUpperCase(),
                  width: (screenW * 0.36).clamp(130.0, 180.0),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'FIRST TO WIN BY 2',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white60,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteCard({
    required CharacterModel athlete,
    required bool isPlayer,
    required String subtag,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPlayer ? AppColors.mintAccent : AppColors.electricCoral,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPlayer ? AppColors.mintAccent : AppColors.electricCoral).withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: athlete.bodyColor,
            child: Text(
              athlete.name[0],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            athlete.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            subtag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: isPlayer ? AppColors.mintAccent : AppColors.electricCoral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(BuildContext context) {
    final String text = countdownNumber <= 0 ? 'SERVE!' : '$countdownNumber';
    final Color color = countdownNumber <= 0 ? AppColors.mintAccent : AppColors.opticYellow;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: countdownNumber <= 0 ? 54 : 76,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 3.0,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.8), blurRadius: 28),
                const Shadow(color: Colors.black, blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}