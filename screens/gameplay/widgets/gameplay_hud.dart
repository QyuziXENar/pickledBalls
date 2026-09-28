// lib/screens/gameplay/physics/widgets/gameplay_hud.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/game_state.dart';
import '../../../../widgets/game_components.dart';

class GameplayScoreboard extends StatelessWidget {
  final GameState state;
  final CharacterModel opponentChar;
  final int playerScore;
  final int aiScore;
  final VoidCallback onPause;

  const GameplayScoreboard({
    super.key,
    required this.state,
    required this.opponentChar,
    required this.playerScore,
    required this.aiScore,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BouncyButton(
          onTap: onPause,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.pause_rounded, size: 20, color: Colors.white),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Text('${state.selectedCharacter.name.split(" ")[0].toUpperCase()}: $playerScore',
                  style: TextStyle(color: state.selectedCharacter.accentColor, fontWeight: FontWeight.w900, fontSize: 13)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('•', style: TextStyle(color: Colors.white30)),
              ),
              Text('${opponentChar.name.split(" ")[0].toUpperCase()}: $aiScore',
                  style: TextStyle(color: opponentChar.accentColor, fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'FIRST TO ${state.targetScore}',
            style: const TextStyle(color: AppColors.mintAccent, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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

class GameOverModal extends StatelessWidget {
  final bool playerWon;
  final int playerScore;
  final int aiScore;
  final VoidCallback onRematch;
  final VoidCallback onReturn;

  const GameOverModal({
    super.key,
    required this.playerWon,
    required this.playerScore,
    required this.aiScore,
    required this.onRematch,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          borderColor: playerWon ? AppColors.opticYellow : AppColors.electricCoral,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                playerWon ? Icons.emoji_events_rounded : Icons.highlight_off_rounded,
                size: 54,
                color: playerWon ? AppColors.opticYellow : AppColors.electricCoral,
              ),
              const SizedBox(height: 10),
              Text(
                playerWon ? 'VICTORY!' : 'MATCH DEFEAT',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              Text(
                'Final: $playerScore - $aiScore',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              BouncyButton(
                onTap: onRematch,
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.opticYellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('PLAY REMATCH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              BouncyButton(
                onTap: onReturn,
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.glassFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('RETURN TO LOBBY', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}