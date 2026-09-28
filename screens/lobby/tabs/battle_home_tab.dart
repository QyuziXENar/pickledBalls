// lib/screens/lobby/tabs/battle_home_tab.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_state.dart';
import '../../../widgets/asset_helpers.dart';
import '../../../widgets/gacha_unboxing_dialog.dart';
import '../../../widgets/game_components.dart';
import '../../gameplay/gameplay_screen.dart';
import '../../multiplayer/vs_ai_setup_screen.dart';
import '../../multiplayer/vs_player_lobby_screen.dart';

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
    final stageIndex = state.completedStages.clamp(0, kCampaignStages.length - 1);
    final activeStage = kCampaignStages[stageIndex];
    final athlete = state.selectedCharacter;
    final paddle = state.selectedPaddle;

    final teamOvr = (72 + (athlete.swingPower * 8) + (paddle.power * 10)).round().clamp(60, 99);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              // Pro Tour Arena Stage Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14241D), Color(0xFF0C1613)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.opticYellow.withValues(alpha: 0.3)),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.opticYellow.withValues(alpha: 0.2),
                              ),
                              child: const Icon(Icons.shield_rounded, color: AppColors.opticYellow, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STAGE ${stageIndex + 1}: ${activeStage.title.split(": ")[1].toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'PRO TOUR ARENA • ${activeStage.venue}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            'VS ${state.opponentCharacter.name.split(" ")[0].toUpperCase()}',
                            style: TextStyle(
                              color: state.opponentCharacter.accentColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ((stageIndex + 1) / kCampaignStages.length).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(AppColors.opticYellow),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Active Battle Loadout Card with Team OVR
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1824),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: athlete.accentColor.withValues(alpha: 0.5), width: 1.6),
                  boxShadow: [
                    BoxShadow(
                      color: athlete.bodyColor.withValues(alpha: 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ACTIVE BATTLE LOADOUT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$teamOvr OVR',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onNavigateToTab(3),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: athlete.bodyColor,
                                    child: Text(
                                      athlete.name[0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          athlete.name.split(' ')[0].toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          athlete.archetype.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: athlete.accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.link_rounded, color: Colors.white38, size: 20),
                        ),

                        Expanded(
                          child: GestureDetector(
                            onTap: () => onNavigateToTab(1),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  PaddleGraphic(
                                    paddle: paddle,
                                    width: 24,
                                    height: 38,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          paddle.name.split(' ')[0].toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'LVL. ${paddle.level}',
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.opticYellow,
                                          ),
                                        ),
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
              ),

              const SizedBox(height: 12),

              // 4 Restored Chest Slots
              Row(
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
                  const SizedBox(width: 8),
                  _buildChestSlot(
                    title: 'SILVER VAULT',
                    status: '1h 45m',
                    icon: Icons.lock_clock_rounded,
                    accent: const Color(0xFF4FC3F7),
                    isReady: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildChestSlot(
                    title: 'GOLD VAULT',
                    status: 'LOCKED',
                    icon: Icons.lock_outline_rounded,
                    accent: Colors.white38,
                    isReady: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildChestSlot(
                    title: 'SLOT 4',
                    status: 'EMPTY',
                    icon: Icons.add_circle_outline_rounded,
                    accent: Colors.white24,
                    isReady: false,
                    isEmpty: true,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Hero Battle Button
              GestureDetector(
                onTap: () {
                  AppAudio.play(context, AppAssets.musicBattleStart, 'Clash Fanfare');
                  state.startCampaignStage(stageIndex);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourtGameplayScreen()),
                  );
                },
                child: Container(
                  height: 74,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFA000), Color(0xFFFF6F00)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFE082), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6F00).withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on_rounded, color: Colors.black, size: 36),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BATTLE',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                              shadows: [Shadow(color: Color(0xFF8D3B00), offset: Offset(0, 2), blurRadius: 4)],
                            ),
                          ),
                          Text(
                            'STAGE ${stageIndex + 1} • +${activeStage.xpReward} XP • First to ${state.targetScore}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D2800)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: BouncyButton(
                      onTap: () {
                        AppAudio.play(context, AppAssets.sfxClick, 'Opening AI Match Setup');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VsAiSetupScreen()),
                        );
                      },
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14382B), Color(0xFF0E281E)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.mintAccent.withValues(alpha: 0.8),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mintAccent.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.mintAccent.withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: AppColors.mintAccent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VS. AI',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  'EXHIBITION',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mintAccent,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: BouncyButton(
                      onTap: () {
                        AppAudio.play(context, AppAssets.sfxClick, 'Opening 1v1 Local Duel Lobby');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VsPlayerLobbyScreen()),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF13283E), Color(0xFF0B1928)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.cyberCyan.withValues(alpha: 0.8),
                                width: 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cyberCyan.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.cyberCyan.withValues(alpha: 0.2),
                                  ),
                                  child: const Icon(
                                    Icons.people_alt_rounded,
                                    color: AppColors.cyberCyan,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'VS. PLAYER',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'LOCAL 1v1',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.cyberCyan,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppColors.lanHostGradient,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '1v1 LAN',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isReady
                ? accent.withValues(alpha: 0.18)
                : const Color(0xFF0C141E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isReady
                  ? accent
                  : (isEmpty ? Colors.white10 : Colors.white24),
              width: isReady ? 1.8 : 1.0,
            ),
            boxShadow: isReady
                ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 8)]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  color: isReady ? Colors.white : Colors.white60,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                status,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isReady ? accent : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}