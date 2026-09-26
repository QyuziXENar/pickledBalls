// lib/screens/lobby/lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
import 'tabs/athlete_roster_tab.dart';
import 'tabs/battle_home_tab.dart';
import 'tabs/paddles_vault_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/shop_tab.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late PageController _rootPageController;
  int _currentTabIndex = 2; // Starts on Center "Battle" Tab

  @override
  void initState() {
    super.initState();
    _rootPageController = PageController(initialPage: _currentTabIndex);
  }

  @override
  void dispose() {
    _rootPageController.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    if (_currentTabIndex == index) return;
    AppAudio.play(context, AppAssets.sfxTabSwipe, 'Mechanical Tab Click');
    if (GameState.instance.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    setState(() => _currentTabIndex = index);
    _rootPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameState.instance,
      builder: (context, _) {
        final state = GameState.instance;

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          body: AmbientCourtBackground(
            child: Column(
              children: [
                _buildTopResourceBar(state),
                Expanded(
                  child: PageView(
                    controller: _rootPageController,
                    onPageChanged: (index) {
                      setState(() => _currentTabIndex = index);
                      if (state.hapticsEnabled) {
                        HapticFeedback.selectionClick();
                      }
                    },
                    children: [
                      ShopTab(state: state),
                      PaddlesVaultTab(state: state),
                      BattleHomeTab(state: state, onNavigateToTab: onTabTapped),
                      AthleteRosterTab(state: state),
                      SettingsTab(state: state),
                    ],
                  ),
                ),
                _buildClashBottomNavBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopResourceBar(GameState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1B16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.opticYellow,
                  child: Text(
                    '${state.playerLevel}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 55,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: state.xpProgress,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(AppColors.mintAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _resourceBadge(Icons.monetization_on_rounded, '${state.goldCoins}', AppColors.coinGold),
          _resourceBadge(Icons.diamond_rounded, '${state.diamonds}', AppColors.gemDiamond),
          _resourceBadge(Icons.bolt_rounded, '${state.upgradePoints} UP', AppColors.upgradePoint),
          _resourceBadge(Icons.emoji_events_rounded, '${1200 + (state.careerWins * 35)}', AppColors.opticYellow),
        ],
      ),
    );
  }

  Widget _resourceBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildClashBottomNavBar() {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFF091310),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navTabItem(0, Icons.storefront_rounded, 'SHOP'),
          _navTabItem(1, Icons.sports_tennis_rounded, 'PADDLES'),
          _centerHeroBattleNavItem(2),
          _navTabItem(3, Icons.groups_rounded, 'ROSTER'),
          _navTabItem(4, Icons.settings_rounded, 'SETTINGS'),
        ],
      ),
    );
  }

  Widget _navTabItem(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.opticYellow : Colors.white38),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppColors.opticYellow : Colors.white38,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerHeroBattleNavItem(int index) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.opticYellow : Colors.white12,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.opticYellow.withValues(alpha: 0.4), blurRadius: 14)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on_rounded, size: 20, color: isSelected ? Colors.black : Colors.white70),
            const SizedBox(width: 4),
            Text(
              'BATTLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.black : Colors.white70,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}