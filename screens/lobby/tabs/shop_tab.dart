// lib/screens/lobby/tabs/shop_tab.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_state.dart';
import '../../../widgets/gacha_unboxing_dialog.dart';
import '../../../widgets/game_components.dart';

class ShopTab extends StatelessWidget {
  final GameState state;

  const ShopTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DAILY PRO SHOP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 14),

          // Daily Free Reward
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 36, color: AppColors.opticYellow),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Daily Reward', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('+250 Gold Coins & 1 Upgrade Point', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.opticYellow, foregroundColor: Colors.black),
                  onPressed: () {
                    state.addGoldCoins(250);
                    state.addUpgradePoints(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('🎉 Claimed Daily Reward: +250 Gold Coins & +1 UP!'),
                        backgroundColor: const Color(0xFF0F1B16),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.opticYellow),
                        ),
                      ),
                    );
                  },
                  child: const Text('CLAIM', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('TOURNAMENT CRATES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0)),
          const SizedBox(height: 10),

          _buildCrateCard(
            context: context,
            title: 'RECRUIT CRATE',
            cost: '500 COINS',
            accent: AppColors.mintAccent,
            rewardText: '+200 XP • 1 Upgrade Point • 100 Bonus Coins',
            onOpen: () {
              if (state.spendGoldCoins(500)) {
                GachaUnboxingDialog.show(
                  context: context,
                  crateName: 'Recruit Crate',
                  crateAccent: AppColors.mintAccent,
                  rewards: const [
                    GachaRewardItem(title: 'Player Experience', amount: '+200 XP', icon: Icons.star_rounded, color: AppColors.mintAccent),
                    GachaRewardItem(title: 'Upgrade Point', amount: '+1 UP', icon: Icons.bolt_rounded, color: AppColors.upgradePoint),
                    GachaRewardItem(title: 'Bonus Payout', amount: '+100 Coins', icon: Icons.monetization_on_rounded, color: AppColors.coinGold),
                  ],
                  onClaimed: () {
                    state.addGoldCoins(100);
                    state.addUpgradePoints(1);
                    state.addMatchExperience(wonMatch: true, rallyHits: 5, smashes: 2);
                  },
                );
              } else {
                _showErrorSnackbar(context, 'Insufficient Coins! Win matches to earn Gold.');
              }
            },
          ),
          const SizedBox(height: 10),

          _buildCrateCard(
            context: context,
            title: 'TOUR PRO CHEST',
            cost: '1,500 COINS',
            accent: AppColors.opticYellow,
            rewardText: '+500 XP • 3 Upgrade Points • 5 Diamonds',
            onOpen: () {
              if (state.spendGoldCoins(1500)) {
                GachaUnboxingDialog.show(
                  context: context,
                  crateName: 'Tour Pro Chest',
                  crateAccent: AppColors.opticYellow,
                  rewards: const [
                    GachaRewardItem(title: 'Tournament Rep', amount: '+500 XP', icon: Icons.emoji_events_rounded, color: AppColors.opticYellow),
                    GachaRewardItem(title: 'Tech Upgrade', amount: '+3 UP', icon: Icons.bolt_rounded, color: AppColors.upgradePoint),
                    GachaRewardItem(title: 'Premium Cache', amount: '+5 Gems', icon: Icons.diamond_rounded, color: AppColors.gemDiamond),
                  ],
                  onClaimed: () {
                    state.addDiamonds(5);
                    state.addUpgradePoints(3);
                    state.addMatchExperience(wonMatch: true, rallyHits: 15, smashes: 5);
                  },
                );
              } else {
                _showErrorSnackbar(context, 'Insufficient Coins! Complete stages to claim more.');
              }
            },
          ),
          const SizedBox(height: 10),

          _buildCrateCard(
            context: context,
            title: 'GRAND SLAM VAULT',
            cost: '25 GEMS',
            accent: AppColors.gemDiamond,
            rewardText: '+2,000 Gold Coins • 6 Upgrade Points',
            onOpen: () {
              if (state.spendDiamonds(25)) {
                GachaUnboxingDialog.show(
                  context: context,
                  crateName: 'Grand Slam Vault',
                  crateAccent: AppColors.gemDiamond,
                  rewards: const [
                    GachaRewardItem(title: 'Gold Reserves', amount: '+2,000 Coins', icon: Icons.monetization_on_rounded, color: AppColors.coinGold),
                    GachaRewardItem(title: 'Championship Tech', amount: '+6 UP', icon: Icons.bolt_rounded, color: AppColors.upgradePoint),
                  ],
                  onClaimed: () {
                    state.addGoldCoins(2000);
                    state.addUpgradePoints(6);
                  },
                );
              } else {
                _showErrorSnackbar(context, 'Need More Gems! Earn Diamonds by completing tournaments.');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCrateCard({
    required BuildContext context,
    required String title,
    required String cost,
    required Color accent,
    required String rewardText,
    required VoidCallback onOpen,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1824),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, size: 36, color: accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                Text(rewardText, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
            onPressed: onOpen,
            child: Text(cost, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1B0F12),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.electricCoral),
        ),
      ),
    );
  }
}