// lib/screens/gameplay/widgets/gameplay_hud.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/game_state.dart';
import '../../../../widgets/game_components.dart';

class GameplayScoreboard extends StatelessWidget {
  final GameState state;
  final CharacterModel opponentChar;
  final int playerScore;
  final int aiScore;
  final double matchTimeRemaining;
  final VoidCallback onPause;
  final VoidCallback onOpenChat;

  const GameplayScoreboard({
    super.key,
    required this.state,
    required this.opponentChar,
    required this.playerScore,
    required this.aiScore,
    required this.matchTimeRemaining,
    required this.onPause,
    required this.onOpenChat,
  });

  String _formatTime(double seconds) {
    final clamped = seconds.clamp(0.0, 3600.0).toInt();
    final mins = (clamped ~/ 60).toString().padLeft(2, '0');
    final secs = (clamped % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = matchTimeRemaining < 30.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Pause & Quick-Chat Button Cluster
            Row(
              children: [
                BouncyButton(
                  onTap: onPause,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(Icons.pause_rounded, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                BouncyButton(
                  onTap: onOpenChat,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.opticYellow.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 17, color: AppColors.opticYellow),
                  ),
                ),
              ],
            ),

            // Score Capsule [ 04 | 01 ]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1B26),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24, width: 1.8),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    playerScore.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: state.selectedCharacter.accentColor,
                    ),
                  ),
                  Container(
                    height: 18,
                    width: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: Colors.white24,
                  ),
                  Text(
                    aiScore.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: opponentChar.accentColor,
                    ),
                  ),
                ],
              ),
            ),

            // Target Points Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'TO ${state.targetScore}',
                style: const TextStyle(
                  color: AppColors.mintAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Round Timer (3:00 Clock)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLowTime ? AppColors.electricCoral : Colors.white10,
            ),
          ),
          child: Text(
            _formatTime(matchTimeRemaining),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isLowTime ? AppColors.electricCoral : Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class BetaWatermarkBadge extends StatelessWidget {
  const BetaWatermarkBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: const Text(
        'PADDLE BLITZ BETA v3.34',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class PauseMenuOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onForfeit;

  const PauseMenuOverlay({
    super.key,
    required this.onResume,
    required this.onForfeit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: GlassCard(
            borderColor: AppColors.opticYellow,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('MATCH PAUSED', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 16),
                BouncyButton(
                  onTap: onResume,
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.opticYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('RESUME MATCH', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                BouncyButton(
                  onTap: onForfeit,
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('FORFEIT TO LOBBY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}