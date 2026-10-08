// lib/Screen/Lobby/tabs/battle_home_tab.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/game_state.dart';
import '../../../../widgets/asset_helpers.dart';
import '../../../../widgets/gacha_unboxing_dialog.dart';
import '../../../../widgets/game_components.dart';
import '../../Gameplay/gameplay_screen.dart';
import '../../Multiplayer/multiplayer_select_screen.dart';
import '../../Multiplayer/vs_ai_setup_screen.dart';
import '../../Practice/practice_court_screen.dart';

class BattleHomeTab extends StatelessWidget {
  final GameState state;
  final Function(int) onNavigateToTab;

  const BattleHomeTab({
    super.key,
    required this.state,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final stageIndex = state.completedStages.clamp(0, kCampaignStages.length - 1);
    final activeStage = kCampaignStages[stageIndex];
    final athlete = state.selectedCharacter;
    final paddle = state.selectedPaddle;

    final teamOvr = (72 + (athlete.swingPower * 8) + (paddle.power * 10)).round().clamp(60, 99);

    if (isLandscape) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildStageHeader(stageIndex, activeStage, state),
                        const SizedBox(height: 8),
                        _buildLoadoutCard(athlete, paddle, teamOvr),
                        const SizedBox(height: 8),
                        _buildCratesRow(context, state),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeroBattleButton(context, stageIndex, activeStage, isLandscape),
                        const SizedBox(height: 8),
                        _buildModesRow(context),
                        const SizedBox(height: 8),
                        _buildPracticeCard(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              _buildStageHeader(stageIndex, activeStage, state),
              const SizedBox(height: 12),
              _buildLoadoutCard(athlete, paddle, teamOvr),
              const SizedBox(height: 12),
              _buildCratesRow(context, state),
              const SizedBox(height: 16),
              _buildHeroBattleButton(context, stageIndex, activeStage, false),
              const SizedBox(height: 12),
              _buildModesRow(context),
              const SizedBox(height: 10),
              _buildPracticeCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageHeader(int stageIndex, CampaignStage activeStage, GameState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF143026), Color(0xFF0F241C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.opticYellow.withValues(alpha: 0.35)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.opticYellow.withValues(alpha: 0.2)),
                      child: const Icon(Icons.shield_rounded, color: AppColors.opticYellow, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STAGE ${stageIndex + 1}: ${activeStage.title.split(": ")[1].toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8),
                          ),
                          Text(
                            'PRO TOUR ARENA • ${activeStage.venue}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white12)),
                child: Text(
                  'VS ${state.opponentCharacter.name.split(" ")[0].toUpperCase()}',
                  style: TextStyle(color: state.opponentCharacter.accentColor, fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ((stageIndex + 1) / kCampaignStages.length).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppColors.opticYellow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadoutCard(CharacterModel athlete, PaddleModel paddle, int teamOvr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102636),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: athlete.accentColor.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [BoxShadow(color: athlete.bodyColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE BATTLE LOADOUT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)]),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('$teamOvr OVR', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onNavigateToTab(3),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: athlete.bodyColor,
                          child: Text(athlete.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(athlete.name.split(' ')[0].toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                              Text(athlete.archetype.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: athlete.accentColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.link_rounded, color: Colors.white38, size: 18),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onNavigateToTab(1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                    child: Row(
                      children: [
                        PaddleGraphic(paddle: paddle, width: 22, height: 34),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(paddle.name.split(' ')[0].toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                              Text('LVL. ${paddle.level}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.opticYellow)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCratesRow(BuildContext context, GameState state) {
    return Row(
      children: [
        _buildChestSlot(
          title: 'RALLY CRATE',
          status: 'OPEN NOW!',
          icon: Icons.card_giftcard_rounded,
          accent: AppColors.opticYellow,
          isReady: true,
          onTap: () {
            GachaUnboxingDialog.show(
              context: context,
              crateName: 'Rally Crate',
              crateAccent: AppColors.opticYellow,
              rewards: const [
                GachaRewardItem(title: 'Rally Winnings', amount: '+150 Coins', icon: Icons.monetization_on_rounded, color: AppColors.coinGold),
                GachaRewardItem(title: 'Training Rep', amount: '+75 XP', icon: Icons.star_rounded, color: AppColors.mintAccent),
              ],
              onClaimed: () {
                state.addGoldCoins(150);
                state.addMatchExperience(wonMatch: true, rallyHits: 4, smashes: 1);
              },
            );
          },
        ),
        const SizedBox(width: 6),
        _buildChestSlot(title: 'SILVER VAULT', status: '1h 45m', icon: Icons.lock_clock_rounded, accent: const Color(0xFF4FC3F7), isReady: false, onTap: () {}),
        const SizedBox(width: 6),
        _buildChestSlot(title: 'GOLD VAULT', status: 'LOCKED', icon: Icons.lock_outline_rounded, accent: Colors.white38, isReady: false, onTap: () {}),
        const SizedBox(width: 6),
        _buildChestSlot(title: 'SLOT 4', status: 'EMPTY', icon: Icons.add_circle_outline_rounded, accent: Colors.white24, isReady: false, isEmpty: true, onTap: () {}),
      ],
    );
  }

  Widget _buildHeroBattleButton(BuildContext context, int stageIndex, CampaignStage activeStage, bool isLandscape) {
    return GestureDetector(
      onTap: () {
        AppAudio.play(context, AppAssets.musicBattleStart, 'Clash Fanfare');
        state.startCampaignStage(stageIndex);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CourtGameplayScreen()));
      },
      child: Container(
        height: isLandscape ? 60 : 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFA000), Color(0xFFFF6F00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE082), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6F00).withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on_rounded, color: Colors.black, size: isLandscape ? 28 : 34),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'BATTLE',
                        style: TextStyle(
                          fontSize: isLandscape ? 22 : 25,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          shadows: const [Shadow(color: Color(0xFF8D3B00), offset: Offset(0, 2), blurRadius: 4)],
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'STAGE ${stageIndex + 1} • +${activeStage.xpReward} XP • First to ${state.targetScore}',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF5D2800)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModesRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BouncyButton(
            onTap: () {
              AppAudio.playFeatureSfx(AppAssets.sfxClick);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VsAiSetupScreen()));
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF14382B), Color(0xFF0E281E)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.8), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy_rounded, color: AppColors.mintAccent, size: 17),
                  SizedBox(width: 6),
                  Text('VS. AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BouncyButton(
            onTap: () {
              AppAudio.playFeatureSfx(AppAssets.sfxClick);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiplayerSelectScreen()));
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF13283E), Color(0xFF0B1928)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cyberCyan.withValues(alpha: 0.8), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_rounded, color: AppColors.cyberCyan, size: 17),
                  SizedBox(width: 6),
                  Text('MULTIPLAYER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeCard(BuildContext context) {
    return BouncyButton(
      onTap: () {
        AppAudio.playFeatureSfx(AppAssets.sfxClick);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeCourtScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFF16252C), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.opticYellow.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.school_rounded, color: AppColors.opticYellow, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRACTICE & TUTORIAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white)),
                  Text('Coach Boomer • 9 Interactive Lessons • +500 Coins', style: TextStyle(fontSize: 8.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
          ],
        ),
      ),
    );
  }

  Widget _buildChestSlot({
    required String title,
    required String status,
    required IconData icon,
    required Color accent,
    required bool isReady,
    required VoidCallback onTap,
    bool isEmpty = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isReady ? accent.withValues(alpha: 0.18) : const Color(0xFF0F241C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isReady ? accent : (isEmpty ? Colors.white10 : Colors.white24), width: isReady ? 1.6 : 1.0),
            boxShadow: isReady ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 6)] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: isReady ? Colors.white : Colors.white60),
              ),
              Text(status, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: isReady ? accent : Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }
}