// lib/screens/lobby/tabs/shop_tab.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_state.dart';
import '../../../widgets/asset_helpers.dart';
import '../../../widgets/gacha_unboxing_dialog.dart';
import '../../../widgets/game_components.dart';

class ShopTab extends StatelessWidget {
  final GameState state;

  const ShopTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------------
          // 1. DAILY FREE DEALS
          // ------------------------------------------------------------------
          const Text('DAILY SPECIALS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 8),

          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.opticYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded, size: 32, color: AppColors.opticYellow),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Daily Supply Drop', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('+250 Gold Coins • +1 Upgrade Point', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.opticYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    state.addGoldCoins(250);
                    state.addUpgradePoints(1);
                    AppAudio.playFeatureSfx(AppAssets.sfxPointCheer);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('🎉 Claimed Free Daily Supply: +250 Coins & +1 UP!'),
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
                  child: const Text('CLAIM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------------------
          // 2. TOURNAMENT CRATE VAULT (GACHA)
          // ------------------------------------------------------------------
          const Text('TOURNAMENT CRATE VAULT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 8),

          // Recruit Crate
          _buildCrateTile(
            context: context,
            title: 'RECRUIT CRATE',
            cost: '500 COINS',
            accent: AppColors.mintAccent,
            perks: '+200 XP • 1 Upgrade Point • 100 Bonus Coins',
            icon: Icons.inventory_2_rounded,
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
                _showError(context, 'Insufficient Coins! Win matches to earn Gold.');
              }
            },
          ),
          const SizedBox(height: 8),

          // Tour Pro Chest
          _buildCrateTile(
            context: context,
            title: 'TOUR PRO CHEST',
            cost: '1,500 COINS',
            accent: AppColors.opticYellow,
            perks: '+500 XP • 3 Upgrade Points • 5 Diamonds',
            icon: Icons.archive_rounded,
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
                _showError(context, 'Insufficient Coins! Complete stages to claim more.');
              }
            },
          ),
          const SizedBox(height: 8),

          // Grand Slam Vault
          _buildCrateTile(
            context: context,
            title: 'GRAND SLAM VAULT',
            cost: '25 GEMS',
            accent: AppColors.gemDiamond,
            perks: '+2,000 Gold Coins • 6 Upgrade Points',
            icon: Icons.lock_open_rounded,
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
                _showError(context, 'Need More Gems! Buy Diamonds below or win tournaments.');
              }
            },
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------------------
          // 3. DIAMOND BANK (SIMULATED IAP WITH COMING SOON OVERLAY)
          // ------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DIAMOND BANK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                child: const Text('TEST SANDBOX', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.gemDiamond)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: [
              _buildDiamondPack(
                context: context,
                amount: '80',
                bonus: '',
                price: '\$0.99',
                diamondsAwarded: 80,
              ),
              _buildDiamondPack(
                context: context,
                amount: '500',
                bonus: '+10% BONUS',
                price: '\$4.99',
                diamondsAwarded: 500,
              ),
              _buildDiamondPack(
                context: context,
                amount: '1,200',
                bonus: '+20% VALUE',
                price: '\$9.99',
                diamondsAwarded: 1200,
              ),
              _buildDiamondPack(
                context: context,
                amount: '2,500',
                bonus: 'BEST VALUE',
                price: '\$19.99',
                diamondsAwarded: 2500,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCrateTile({
    required BuildContext context,
    required String title,
    required String cost,
    required Color accent,
    required String perks,
    required IconData icon,
    required VoidCallback onOpen,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 34, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Colors.white)),
                const SizedBox(height: 2),
                Text(perks, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: onOpen,
            child: Text(cost, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildDiamondPack({
    required BuildContext context,
    required String amount,
    required String bonus,
    required String price,
    required int diamondsAwarded,
  }) {
    return GestureDetector(
      onTap: () => _showSimulatedIapDialog(context, amount, price, diamondsAwarded),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gemDiamond.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gemDiamond.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (bonus.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.opticYellow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bonus,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              )
            else
              const SizedBox(height: 12),

            Icon(Icons.diamond_rounded, size: 38, color: AppColors.gemDiamond),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  amount,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.diamond_rounded, size: 12, color: AppColors.gemDiamond),
              ],
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0288D1), Color(0xFF01579B)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  price,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSimulatedIapDialog(BuildContext context, String amount, String price, int diamondsAwarded) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.gemDiamond)),
        title: Row(
          children: [
            const Icon(Icons.diamond_rounded, color: AppColors.gemDiamond, size: 24),
            const SizedBox(width: 8),
            Text('POUCH OF $amount GEMS', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Store Sandbox Mode: Real in-app purchases are coming in v3.1. Tap test to grant diamonds free!',
                      style: TextStyle(fontSize: 9.5, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Price: $price (Simulated)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gemDiamond, foregroundColor: Colors.black),
            onPressed: () {
              state.addDiamonds(diamondsAwarded);
              AppAudio.playFeatureSfx(AppAssets.sfxPointCheer);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('💎 Sandbox Purchase Complete: +$amount Diamonds added!'),
                  backgroundColor: const Color(0xFF0F1B16),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.gemDiamond),
                  ),
                ),
              );
            },
            child: const Text('TEST BUY (FREE)', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    AppAudio.playFeatureSfx(AppAssets.sfxError);
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