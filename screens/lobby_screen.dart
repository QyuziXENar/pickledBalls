import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../widgets/ambient_background.dart';
import '../widgets/game_components.dart';
import 'character_selection_screen.dart';
import 'gameplay_screen.dart';
import 'paddle_locker_screen.dart';
import 'settings_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  void _openCampaignStageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CampaignStageMapSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameState.instance,
      builder: (context, _) {
        final state = GameState.instance;

        return Scaffold(
          body: AmbientCourtBackground(
            child: Column(
              children: [
                // Top Custom Header: Player Level & XP
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      BouncyButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.glassFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'PLAYER LEVEL ${state.playerLevel}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: AppTheme.opticYellow,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${state.careerWins} WINS)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Live XP Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                width: 140,
                                child: LinearProgressIndicator(
                                  value: state.xpProgress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white12,
                                  valueColor: const AlwaysStoppedAnimation(AppTheme.mintAccent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // DUPR Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.deepGreen,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.mintAccent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, size: 14, color: AppTheme.mintAccent),
                            const SizedBox(width: 6),
                            Text(
                              '${(3.0 + (state.playerLevel * 0.4)).toStringAsFixed(1)} DUPR',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Lobby Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ================================================
                            // 1. HERO BUTTON: SINGLE-PLAYER CAREER CAMPAIGN
                            // ================================================
                            BouncyButton(
                              onTap: () => _openCampaignStageSelector(context),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFD6F800), Color(0xFFA6C200)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.opticYellow.withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events_rounded,
                                        color: AppTheme.opticYellow,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'PRO TOUR CAMPAIGN',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Stage ${state.completedStages + 1} of 3 • Level Up & Unlock Paddles',
                                            style: const TextStyle(
                                              color: Color(0xBF000000),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ================================================
                            // 2. LOADOUT SECTION (Athlete + Paddle)
                            // ================================================
                            const Text(
                              'YOUR ATHLETE & EQUIPMENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Athlete Card
                            GlassCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CharacterSelectionScreen()),
                                );
                              },
                              borderColor: state.selectedCharacter.bodyColor.withValues(alpha: 0.6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: state.selectedCharacter.bodyColor,
                                      border: Border.all(
                                        color: state.selectedCharacter.accentColor,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        state.selectedCharacter.name[0],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              state.selectedCharacter.name,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: state.selectedCharacter.bodyColor.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: state.selectedCharacter.bodyColor, width: 0.8),
                                              ),
                                              child: Text(
                                                state.selectedCharacter.archetype.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: state.selectedCharacter.accentColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Special: ${state.selectedCharacter.abilityName}',
                                          style: const TextStyle(fontSize: 11.5, color: AppTheme.mintAccent, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.white60),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Paddle Card
                            GlassCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PaddleLockerScreen()),
                                );
                              },
                              borderColor: state.selectedPaddle.accentColor.withValues(alpha: 0.5),
                              child: Row(
                                children: [
                                  PaddleGraphic(paddle: state.selectedPaddle, width: 50, height: 70),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.selectedPaddle.brand,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: state.selectedPaddle.accentColor, letterSpacing: 1.2),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(state.selectedPaddle.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            MiniStat(label: 'PWR', value: state.selectedPaddle.power),
                                            const SizedBox(width: 10),
                                            MiniStat(label: 'CTL', value: state.selectedPaddle.control),
                                            const SizedBox(width: 10),
                                            MiniStat(label: 'SPN', value: state.selectedPaddle.spin),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.white60),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ================================================
                            // 3. SECONDARY MODE: EXHIBITION MATCH (CUSTOM)
                            // ================================================
                            const Text(
                              'QUICK EXHIBITION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GlassCard(
                              onTap: () {
                                state.startExhibitionMatch();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CourtGameplayScreen()),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.glassFill,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.mintAccent),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Casual Exhibition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text(
                                          'Practice match • First to ${state.targetScore} on ${state.courtVenue}',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.play_arrow_rounded, color: Colors.white54),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Settings Tile
                            GlassCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.glassFill,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.tune_rounded, color: AppTheme.opticYellow),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Match Rules & Venues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text('Set match points, venues, and audio', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// MODAL: SINGLE-PLAYER CAMPAIGN STAGE SELECTOR MAP
// ============================================================================
class _CampaignStageMapSheet extends StatelessWidget {
  const _CampaignStageMapSheet();

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1411),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black87, blurRadius: 40, spreadRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(Icons.emoji_events, color: AppTheme.opticYellow, size: 24),
              SizedBox(width: 10),
              Text(
                'PRO TOUR CAMPAIGN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Defeat all 3 tournament stages to unlock professional gear and claim the championship.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 20),

          // 3 Stages
          for (int i = 0; i < kCampaignStages.length; i++) ...[
            Builder(builder: (context) {
              final stage = kCampaignStages[i];
              final isUnlocked = state.playerLevel >= stage.requiredPlayerLevel;
              final isCompleted = state.completedStages > i;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  onTap: isUnlocked
                      ? () {
                          state.startCampaignStage(i);
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CourtGameplayScreen()),
                          );
                        }
                      : null,
                  borderColor: isCompleted
                      ? AppTheme.opticYellow
                      : isUnlocked
                          ? AppTheme.mintAccent
                          : Colors.white10,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppTheme.opticYellow
                              : isUnlocked
                                  ? AppTheme.deepGreen
                                  : Colors.white10,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : isUnlocked
                                  ? Icons.play_arrow_rounded
                                  : Icons.lock_rounded,
                          color: isCompleted ? Colors.black : Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isUnlocked ? Colors.white : Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stage.subtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isUnlocked ? AppTheme.textMuted : Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reward: ${stage.unlockRewardName} (+${stage.xpReward} XP)',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isUnlocked ? AppTheme.opticYellow : Colors.white24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}