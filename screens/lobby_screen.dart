import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../widgets/ambient_background.dart';
import '../widgets/asset_helpers.dart';
import '../widgets/game_components.dart';
import 'gameplay_screen.dart';
import 'vs_ai_setup_screen.dart';

// ============================================================================
// CLASH ROYALE STYLE LOBBY SCREEN (5 TABS)
// ============================================================================

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late PageController _rootPageController;
  int _currentTabIndex = 2; // Starts on Center "Battle" Tab

  // Tab 1: Split-View Paddle Selection State
  PaddleModel? _previewPaddle;

  // Tab 3: Athlete Carousel Controller
  late PageController _athletePageController;
  int _currentAthleteIndex = 0;

  // System Settings State
  bool _bgmEnabled = true;
  bool _highFpsEnabled = true;
  bool _screenShakeEnabled = true;

  @override
  void initState() {
    super.initState();
    _rootPageController = PageController(initialPage: _currentTabIndex);

    final initialCharIdx = kCharacters.indexWhere(
      (c) => c.id == GameState.instance.selectedCharacter.id,
    );
    _currentAthleteIndex = initialCharIdx >= 0 ? initialCharIdx : 0;
    _athletePageController = PageController(
      viewportFraction: 0.55,
      initialPage: _currentAthleteIndex,
    );
  }

  @override
  void dispose() {
    _rootPageController.dispose();
    _athletePageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentTabIndex == index) return;
    AppAudio.play(context, 'tab_swipe.mp3', 'Mechanical Tab Click');
    if (GameState.instance.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _currentTabIndex = index;
    });
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
                      _buildShopTab(),
                      _buildSplitPaddlesTab(state),  // Tab 1: Paddles
                      _buildBattleHomeTab(state),    // Tab 2: Battle Home (Overhauled)
                      _buildAthleteCarouselTab(state), // Tab 3: Roster
                      _buildSettingsTab(state),      // Tab 4: Settings
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

  // ==========================================================================
  // TOP RESOURCE BAR
  // ==========================================================================
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
                  backgroundColor: AppTheme.opticYellow,
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
                      valueColor: const AlwaysStoppedAnimation(AppTheme.mintAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _resourceBadge(Icons.monetization_on_rounded, '2,450', const Color(0xFFFFD54F)),
          _resourceBadge(Icons.diamond_rounded, '140', const Color(0xFF4FC3F7)),
          _resourceBadge(Icons.emoji_events_rounded, '${1200 + (state.careerWins * 35)}', AppTheme.opticYellow),
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
        border: Border.all(color: Colors.white12),
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

  // ==========================================================================
  // TAB 2: OVERHAULED BATTLE HOME TAB (CLASH ROYALE DUO & PROGRESSION)
  // ==========================================================================
  Widget _buildBattleHomeTab(GameState state) {
    final stageIndex = state.completedStages.clamp(0, kCampaignStages.length - 1);
    final activeStage = kCampaignStages[stageIndex];
    final athlete = state.selectedCharacter;
    final paddle = state.selectedPaddle;

    // Computed OVR team score based on athlete & paddle stats
    final teamOvr = (72 + (athlete.swingPower * 8) + (paddle.power * 10)).round().clamp(60, 99);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              // 1. TROPHY ROAD / PRO TOUR PROGRESS BANNER
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
                  border: Border.all(color: AppTheme.opticYellow.withValues(alpha: 0.3)),
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
                                color: AppTheme.opticYellow.withValues(alpha: 0.2),
                              ),
                              child: const Icon(Icons.shield_rounded, color: AppTheme.opticYellow, size: 18),
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
                                    color: AppTheme.textMuted,
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
                    // Road Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ((stageIndex + 1) / kCampaignStages.length).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.opticYellow),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. EQUIPPED COMBAT LOADOUT (DUO CARD: ATHLETE + PADDLE)
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
                            color: AppTheme.textMuted,
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
                        // Left: Equipped Athlete (Tap to open Roster)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onTabTapped(3),
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

                        // Right: Equipped Paddle (Tap to open Paddle Vault)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onTabTapped(1),
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
                                            color: AppTheme.opticYellow,
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

              // 3. 4-SLOT CLASH ROYALE MATCH CHEST VAULT
              Row(
                children: [
                  _buildChestSlot(
                    title: 'RALLY CRATE',
                    status: 'OPEN NOW!',
                    icon: Icons.card_giftcard_rounded,
                    accent: AppTheme.opticYellow,
                    isReady: true,
                    onTap: () {
                      AppAudio.play(context, 'click.mp3', 'Crate Opened! +150 Gold');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('🎉 Opened Rally Crate: +150 Gold & 2 Cards!'),
                          backgroundColor: const Color(0xFF0F1B16),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.opticYellow),
                          ),
                        ),
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

              // 4. BIG CAMPAIGN HERO "BATTLE" BUTTON
              GestureDetector(
                onTap: () {
                  AppAudio.play(context, 'battle_start.mp3', 'Clash Horn Fanfare');
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
                      const Icon(Icons.flash_on_rounded, color: Colors.white, size: 36),
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

              // 5. SIDE-BY-SIDE LAUNCHERS: VS. AI & VS. PLAYER
              Row(
                children: [
                  // 1. VS. AI BUTTON (Navigates to VsAiSetupScreen!)
                  Expanded(
                    child: BouncyButton(
                      onTap: () {
                        AppAudio.play(context, 'click.mp3', 'Opening AI Match Setup');
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
                            color: AppTheme.mintAccent.withValues(alpha: 0.8),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.mintAccent.withValues(alpha: 0.25),
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
                                color: AppTheme.mintAccent.withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: AppTheme.mintAccent,
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
                                    color: AppTheme.mintAccent,
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

                  // 2. VS. PLAYER BUTTON (Placeholder with Coming Soon Toast)
                  Expanded(
                    child: BouncyButton(
                      onTap: () {
                        AppAudio.play(context, 'click.mp3', 'VS Player 1v1 coming in v2.1!');
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.sports_esports_rounded, color: Color(0xFF00E5FF), size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '👥 VS. Player (Local & Online 1v1) is under construction for v2.1!',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF0F1B26),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
                            ),
                          ),
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
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                width: 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
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
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                  ),
                                  child: const Icon(
                                    Icons.people_alt_rounded,
                                    color: Color(0xFF00E5FF),
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
                                      'ONLINE & 1v1',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00E5FF),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ARCADE "COMING SOON" CHIP BADGE
                          Positioned(
                            top: -6,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                                ),
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
                                'SOON',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
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

  // Clash Royale 4-Slot Chest Widget
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

  // ==========================================================================
  // TAB 1: SPLIT-VIEW PADDLES VAULT TAB
  // ==========================================================================
  Widget _buildSplitPaddlesTab(GameState state) {
    final activePaddle = _previewPaddle ?? state.selectedPaddle;
    final isEquipped = state.selectedPaddle.id == activePaddle.id;
    final isUnlocked = state.playerLevel >= activePaddle.unlockLevel;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1829),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activePaddle.accentColor.withValues(alpha: 0.7), width: 2.0),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 75,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: activePaddle.primaryColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                PaddleGraphic(paddle: activePaddle, width: 56, height: 82, glow: isUnlocked),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LVL. ${activePaddle.level}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0277BD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${activePaddle.cardsCollected}/${activePaddle.cardsNeeded}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activePaddle.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            Text(
                              activePaddle.brand,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: activePaddle.accentColor),
                            ),
                            const SizedBox(height: 6),
                            _compactStatRow('SPIN', activePaddle.statSpin, 25),
                            _compactStatRow('SWING', activePaddle.statSwing, 25),
                            _compactStatRow('AGILITY', activePaddle.statAgility, 25),
                            _compactStatRow('ACCURACY', activePaddle.statAccuracy, 25),
                            _compactStatRow('STAMINA', activePaddle.statStamina, 25),
                            _compactStatRow('POWER', activePaddle.statPower, 25),
                            _compactStatRow('SPEED', activePaddle.statSpeed, 25),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: isUnlocked
                        ? () {
                            state.selectPaddle(activePaddle);
                            AppAudio.play(context, 'equip.mp3', 'Paddle Equipped Sound');
                            setState(() {});
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      height: 38,
                      decoration: BoxDecoration(
                        color: !isUnlocked
                            ? Colors.white12
                            : isEquipped
                                ? AppTheme.glassFill
                                : AppTheme.opticYellow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isEquipped ? AppTheme.glassBorder : Colors.transparent),
                      ),
                      child: Center(
                        child: Text(
                          !isUnlocked
                              ? 'LOCKED (REQUIRES LEVEL ${activePaddle.unlockLevel})'
                              : isEquipped
                                  ? 'CURRENTLY EQUIPPED'
                                  : 'EQUIP THIS PADDLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: !isUnlocked
                                ? Colors.white38
                                : isEquipped
                                    ? Colors.white70
                                    : Colors.black,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PADDLE COLLECTION (9)',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.2),
                  ),
                  Text(
                    'TAP TO INSPECT',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: kPaddles.length,
                  itemBuilder: (context, index) {
                    final paddle = kPaddles[index];
                    final isEquipped = state.selectedPaddle.id == paddle.id;
                    final isInspected = activePaddle.id == paddle.id;
                    final isUnlocked = state.playerLevel >= paddle.unlockLevel;

                    return GestureDetector(
                      onTap: () {
                        AppAudio.play(context, 'card_tap.mp3', 'Card Select');
                        setState(() => _previewPaddle = paddle);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B26),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEquipped
                                ? AppTheme.opticYellow
                                : isInspected
                                    ? Colors.white
                                    : isUnlocked
                                        ? const Color(0xFF7B1FA2)
                                        : Colors.white12,
                            width: isEquipped || isInspected ? 2.2 : 1.2,
                          ),
                          boxShadow: isEquipped
                              ? [BoxShadow(color: AppTheme.opticYellow.withValues(alpha: 0.35), blurRadius: 8)]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: PaddleGraphic(paddle: paddle, width: 50, height: 74),
                            ),
                            if (isEquipped)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.opticYellow,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text('USED', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.black)),
                                ),
                              ),
                            if (!isUnlocked)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.lock_rounded, color: Colors.white70, size: 18),
                                      Text('LV. ${paddle.unlockLevel}', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.opticYellow)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactStatRow(String label, int value, int max) {
    final fill = (value / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white70)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(height: 5, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: fill,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 16,
            child: Text('$value', textAlign: TextAlign.end, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: 3D ATHLETE CAROUSEL IN ROSTER TAB
  // ==========================================================================
  Widget _buildAthleteCarouselTab(GameState state) {
    final activeChar = kCharacters[_currentAthleteIndex];
    final isEquipped = state.selectedCharacter.id == activeChar.id;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ATHLETE ROSTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  Text('${_currentAthleteIndex + 1} OF ${kCharacters.length}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _athletePageController,
                    itemCount: kCharacters.length,
                    onPageChanged: (idx) {
                      setState(() => _currentAthleteIndex = idx);
                      AppAudio.play(context, 'swipe.mp3', 'Athlete Slide');
                      if (state.hapticsEnabled) {
                        HapticFeedback.selectionClick();
                      }
                    },
                    itemBuilder: (ctx, i) {
                      final character = kCharacters[i];
                      final isSelected = i == _currentAthleteIndex;

                      return AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: isSelected ? 1.0 : 0.78,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: isSelected ? 1.0 : 0.45,
                          child: Center(
                            child: _buildAthletePreviewRig(character, state.selectedPaddle, isSelected),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 4,
                    child: GestureDetector(
                      onTap: () {
                        if (_currentAthleteIndex > 0) {
                          _athletePageController.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                        child: Icon(Icons.chevron_left_rounded, color: _currentAthleteIndex > 0 ? Colors.white : Colors.white24, size: 24),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        if (_currentAthleteIndex < kCharacters.length - 1) {
                          _athletePageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                        child: Icon(Icons.chevron_right_rounded, color: _currentAthleteIndex < kCharacters.length - 1 ? Colors.white : Colors.white24, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(kCharacters.length, (idx) {
                  final char = kCharacters[idx];
                  final isSelected = idx == _currentAthleteIndex;

                  return GestureDetector(
                    onTap: () {
                      _athletePageController.animateToPage(idx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: EdgeInsets.symmetric(horizontal: isSelected ? 10 : 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? char.bodyColor : AppTheme.glassFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? char.accentColor : Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 3.5, backgroundColor: isSelected ? Colors.white : char.bodyColor),
                          if (isSelected) ...[
                            const SizedBox(width: 5),
                            Text(char.name.split(' ')[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1B16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${activeChar.gender.toUpperCase()} • ${activeChar.archetype.toUpperCase()}',
                          style: TextStyle(color: activeChar.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.8),
                        ),
                        const SizedBox(height: 2),
                        Text(activeChar.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        Text(activeChar.perkDescription, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    Column(
                      children: [
                        StatBar(label: 'Sprint Speed', value: (activeChar.moveSpeed / 1.5).clamp(0.0, 1.0), color: activeChar.accentColor),
                        const SizedBox(height: 5),
                        StatBar(label: 'Swing Power', value: (activeChar.swingPower / 1.5).clamp(0.0, 1.0), color: activeChar.accentColor),
                        const SizedBox(height: 5),
                        StatBar(label: 'Strike Reach', value: (activeChar.reachFactor / 1.4).clamp(0.0, 1.0), color: activeChar.accentColor),
                      ],
                    ),
                    BouncyButton(
                      onTap: () {
                        state.selectCharacter(activeChar);
                        AppAudio.play(context, 'character_select.mp3', 'Athlete Chosen');
                      },
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isEquipped ? AppTheme.glassFill : activeChar.accentColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isEquipped ? AppTheme.glassBorder : Colors.transparent),
                        ),
                        child: Center(
                          child: Text(
                            isEquipped ? 'CURRENTLY EQUIPPED' : 'EQUIP ATHLETE',
                            style: TextStyle(color: isEquipped ? Colors.white70 : Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0),
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
      ),
    );
  }

  Widget _buildAthletePreviewRig(CharacterModel character, PaddleModel paddle, bool glow) {
    return Container(
      width: 150,
      height: 200,
      decoration: BoxDecoration(
        boxShadow: glow
            ? [BoxShadow(color: character.bodyColor.withValues(alpha: 0.35), blurRadius: 32, spreadRadius: 3)]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 14,
            child: Container(
              width: 90,
              height: 20,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
            ),
          ),
          Positioned(
            top: 15,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: character.bodyColor,
                    border: Border.all(color: character.accentColor, width: 3),
                  ),
                  child: Center(
                    child: Text(character.name[0], style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1B16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: character.accentColor, width: 1.0),
                    ),
                    child: Text(character.archetype.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: character.accentColor)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 4,
            bottom: 30,
            child: Transform.rotate(
              angle: 0.25,
              child: PaddleGraphic(paddle: paddle, width: 44, height: 62),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 0: SHOP
  // ==========================================================================
  Widget _buildShopTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DAILY PRO SHOP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 36, color: AppTheme.opticYellow),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Daily Reward', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('+250 Gold Coins & 5 VoltStrike Cards', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.opticYellow, foregroundColor: Colors.black),
                  onPressed: () {},
                  child: const Text('CLAIM', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: SETTINGS
  // ==========================================================================
  Widget _buildSettingsTab(GameState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SYSTEM PREFERENCES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppTheme.opticYellow,
                      title: const Text('Sound Effects (SFX)'),
                      value: state.soundEnabled,
                      onChanged: (val) {
                        state.toggleSound(val);
                        AppAudio.play(context, 'sfx_toggle.mp3', 'Sound Effects Toggle');
                      },
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppTheme.opticYellow,
                      title: const Text('Background Music (BGM)'),
                      value: _bgmEnabled,
                      onChanged: (val) => setState(() => _bgmEnabled = val),
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppTheme.opticYellow,
                      title: const Text('Haptic Vibration'),
                      value: state.hapticsEnabled,
                      onChanged: state.toggleHaptics,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppTheme.mintAccent,
                      title: const Text('60 FPS High Performance'),
                      value: _highFpsEnabled,
                      onChanged: (val) => setState(() => _highFpsEnabled = val),
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppTheme.mintAccent,
                      title: const Text('Screen Shake FX'),
                      value: _screenShakeEnabled,
                      onChanged: (val) => setState(() => _screenShakeEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const HowToPlaySheet(),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: AppTheme.opticYellow, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pickleball Playbook (Rules)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Two-Bounce Rule, NVZ Kitchen & Scoring Guide', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PADDLE BLITZ 2.0', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'Created by CanZEd Game Studios • School Capstone Project 2026\nPowered by Flutter & Dart 2.5D Custom Projection Engine.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, height: 1.4),
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

  // ==========================================================================
  // CLASH ROYALE BOTTOM NAV BAR
  // ==========================================================================
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
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isSelected ? AppTheme.opticYellow : Colors.white38),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppTheme.opticYellow : Colors.white38,
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
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.opticYellow : Colors.white12,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.opticYellow.withValues(alpha: 0.4), blurRadius: 14)]
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