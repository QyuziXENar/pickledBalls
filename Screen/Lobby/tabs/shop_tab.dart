// lib/Screen/Lobby/tabs/shop_tab.dart

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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Daily Specials & Crates
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDailySpecialCard(context),
                        const SizedBox(height: 12),
                        const Text('TOURNAMENT CRATE VAULT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        _buildCratesList(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Right Column: Diamond Bank
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDiamondBankHeader(),
                        const SizedBox(height: 6),
                        _buildDiamondBankGrid(context),
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

    // Default Portrait
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDailySpecialCard(context),
          const SizedBox(height: 16),
          const Text('TOURNAMENT CRATE VAULT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          _buildCratesList(context),
          const SizedBox(height: 18),
          _buildDiamondBankHeader(),
          const SizedBox(height: 8),
          _buildDiamondBankGrid(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDailySpecialCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DAILY SPECIALS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.opticYellow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.card_giftcard_rounded, size: 26, color: AppColors.opticYellow),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free Daily Supply Drop', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
                    Text('+250 Gold Coins • +1 Upgrade Point', style: TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.opticYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(60, 32),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.opticYellow)),
                    ),
                  );
                },
                child: const Text('CLAIM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCratesList(BuildContext context) {
    return Column(
      children: [
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
        const SizedBox(height: 6),
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
        const SizedBox(height: 6),
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
      ],
    );
  }

  Widget _buildDiamondBankHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('DIAMOND BANK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
          child: const Text('TEST SANDBOX', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.gemDiamond)),
        ),
      ],
    );
  }

  Widget _buildDiamondBankGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.05,
      children: [
        _buildDiamondPack(context: context, amount: '80', bonus: '', price: '\$0.99', diamondsAwarded: 80),
        _buildDiamondPack(context: context, amount: '500', bonus: '+10% BONUS', price: '\$4.99', diamondsAwarded: 500),
        _buildDiamondPack(context: context, amount: '1,200', bonus: '+20% VALUE', price: '\$9.99', diamondsAwarded: 1200),
        _buildDiamondPack(context: context, amount: '2,500', bonus: 'BEST VALUE', price: '\$19.99', diamondsAwarded: 2500),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1824),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Colors.white)),
                Text(perks, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(55, 30),
            ),
            onPressed: onOpen,
            child: Text(cost, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 8.5)),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gemDiamond.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (bonus.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(color: AppColors.opticYellow, borderRadius: BorderRadius.circular(5)),
                child: Text(bonus, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.black)),
              )
            else
              const SizedBox(height: 8),
            const Icon(Icons.diamond_rounded, size: 30, color: AppColors.gemDiamond),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(width: 3),
                const Icon(Icons.diamond_rounded, size: 10, color: AppColors.gemDiamond),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0288D1), Color(0xFF01579B)]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(price, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white)),
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
            const Icon(Icons.diamond_rounded, color: AppColors.gemDiamond, size: 22),
            const SizedBox(width: 8),
            Text('POUCH OF $amount GEMS', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
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
                  Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Store Sandbox: Real IAPs coming in v3.1. Tap test to grant diamonds free!', style: TextStyle(fontSize: 9, color: Colors.white70)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Price: $price (Simulated)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gemDiamond, foregroundColor: Colors.black),
            onPressed: () {
              state.addDiamonds(diamondsAwarded);
              AppAudio.playFeatureSfx(AppAssets.sfxPointCheer);
              Navigator.pop(ctx);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.electricCoral)),
      ),
    );
  }
}