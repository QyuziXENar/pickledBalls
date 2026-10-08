// lib/Screen/Lobby/lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';

import '../Multiplayer/online_leaderboard_screen.dart';
import 'tabs/athlete_roster_tab.dart';
import 'tabs/battle_home_tab.dart';
import 'tabs/paddles_vault_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/shop_tab.dart';

const double _kBarMaxWidth = 1080;

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late PageController _rootPageController;
  int _currentTabIndex = 2; // Starts on center "Battle" tab

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

  String? _getActiveBackgroundAsset() {
    switch (_currentTabIndex) {
      case 0: return AppAssets.bgShop;
      case 1: return AppAssets.bgPaddles;
      case 2: return AppAssets.bgBattle;
      case 3: return AppAssets.bgRoster;
      case 4: return null;
      default: return AppAssets.arenaDiorama;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AnimatedBuilder(
      animation: GameState.instance,
      builder: (context, _) {
        final state = GameState.instance;

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          // 100% Full-bleed background across physical phone glass
          body: AmbientCourtBackground(
            backgroundAsset: _getActiveBackgroundAsset(),
            fallbackAsset: AppAssets.arenaDiorama,
            child: Column(
              children: [
                _buildTopResourceBar(state, isLandscape),

                // Menu content scales cleanly without black borders
                Expanded(
                  child: Transform.scale(
                    scale: state.uiScale,
                    alignment: Alignment.center,
                    child: PageView(
                      controller: _rootPageController,
                      onPageChanged: (index) {
                        setState(() => _currentTabIndex = index);
                        if (state.hapticsEnabled) HapticFeedback.selectionClick();
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
                ),

                _buildBottomNavBar(isLandscape),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopResourceBar(GameState state, bool isLandscape) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kBarMaxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, isLandscape ? 4 : 8, 12, isLandscape ? 4 : 6),
          child: Row(
            children: [
              _levelPill(state, isLandscape),
              const SizedBox(width: 6),
              _resourcePill(Icons.monetization_on_rounded, '${state.goldCoins}', AppColors.coinGold, isLandscape),
              const SizedBox(width: 6),
              _resourcePill(Icons.diamond_rounded, '${state.diamonds}', AppColors.gemDiamond, isLandscape),
              const SizedBox(width: 6),
              _resourcePill(Icons.bolt_rounded, '${state.upgradePoints} UP', AppColors.upgradePoint, isLandscape),
              const SizedBox(width: 6),
              _resourcePill(
                Icons.emoji_events_rounded,
                '${1200 + (state.careerWins * 35)}',
                AppColors.opticYellow,
                isLandscape,
                highlight: true,
                onTap: () {
                  AppAudio.playFeatureSfx(AppAssets.sfxClick);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineLeaderboardScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelPill(GameState state, bool isLandscape) {
    return Container(
      padding: EdgeInsets.fromLTRB(4, isLandscape ? 3 : 5, 8, isLandscape ? 3 : 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F241C).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLandscape ? 24 : 28,
            height: isLandscape ? 24 : 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.opticYellow),
            child: Text(
              '${state.playerLevel}',
              style: TextStyle(fontSize: isLandscape ? 11 : 13, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level',
                style: TextStyle(fontSize: isLandscape ? 9 : 11, color: AppColors.textMuted, height: 1),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: isLandscape ? 40 : 52,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: state.xpProgress,
                    minHeight: isLandscape ? 3 : 5,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(AppColors.mintAccent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resourcePill(IconData icon, String value, Color color, bool isLandscape, {bool highlight = false, VoidCallback? onTap}) {
    final pill = Container(
      height: isLandscape ? 30 : 38,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F241C).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: highlight ? 0.8 : 0.4), width: highlight ? 1.6 : 1),
        boxShadow: highlight ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6)] : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isLandscape ? 14 : 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: isLandscape ? 11 : 13, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ],
        ),
      ),
    );
    return Flexible(child: onTap == null ? pill : GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: pill));
  }

  Widget _buildBottomNavBar(bool isLandscape) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1813),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SizedBox(
            height: isLandscape ? 52 : 68,
            child: Row(
              children: [
                Expanded(child: _navTabItem(0, Icons.storefront_rounded, 'Shop', isLandscape)),
                Expanded(child: _navTabItem(1, Icons.sports_tennis_rounded, 'Paddles', isLandscape)),
                Expanded(child: _centerBattleNavItem(2, isLandscape)),
                Expanded(child: _navTabItem(3, Icons.groups_rounded, 'Roster', isLandscape)),
                Expanded(child: _navTabItem(4, Icons.settings_rounded, 'Settings', isLandscape)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navTabItem(int index, IconData icon, String label, bool isLandscape) {
    final isSelected = _currentTabIndex == index;
    final color = isSelected ? AppColors.opticYellow : Colors.white60;

    return GestureDetector(
      onTap: () => onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? (isLandscape ? 16 : 20) : 0,
              height: 2.5,
              margin: EdgeInsets.only(bottom: isLandscape ? 2 : 4),
              decoration: BoxDecoration(color: AppColors.opticYellow, borderRadius: BorderRadius.circular(2)),
            ),
            Icon(icon, size: isLandscape ? 19 : 23, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isLandscape ? 9.5 : 10.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // ZERO-OVERFLOW BATTLE BUTTON (Scales down inside tight constraints)
  // ==========================================================================
  Widget _centerBattleNavItem(int index, bool isLandscape) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 8 : 10,
              vertical: isLandscape ? 4 : 7,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.opticYellow : Colors.white12,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.opticYellow.withValues(alpha: 0.4), blurRadius: 10)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: isLandscape ? 16 : 19,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
                const SizedBox(width: 2),
                Text(
                  'Battle',
                  style: TextStyle(
                    fontSize: isLandscape ? 10 : 11.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.black : Colors.white70,
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