import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../widgets/ambient_background.dart';
import '../widgets/game_components.dart';
import 'gameplay_screen.dart';

// ============================================================================
// TASK 7: CLASH ROYALE ROOT HUB WITH 3x3 PADDLE GRID & 7-STAT INSPECTION
// ============================================================================

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late PageController _pageController;
  int _currentTabIndex = 2; // Starts on Center "Battle" Tab

  // Paddle Inspection View State (Reference Image 2)
  PaddleModel? _inspectedPaddle;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentTabIndex == index && _inspectedPaddle == null) return;
    if (GameState.instance.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _currentTabIndex = index;
      _inspectedPaddle = null; // Reset inspection when switching tabs
    });
    _pageController.animateToPage(
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
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentTabIndex = index;
                        _inspectedPaddle = null;
                      });
                      if (state.hapticsEnabled) {
                        HapticFeedback.selectionClick();
                      }
                    },
                    children: [
                      _buildShopTab(),
                      _buildPaddleCustomizeTab(state), // Task 7 (Images 2 & 3)
                      _buildBattleHomeTab(state),
                      _buildAthletesTab(state),
                      _buildSettingsTab(state),
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
  // TAB 1: PADDLE CUSTOMIZATION (3x3 GRID & 7-STAT INSPECTION CARD)
  // ==========================================================================
  Widget _buildPaddleCustomizeTab(GameState state) {
    // If a paddle is selected for inspection, show the detailed 7-stat card! (Image 2)
    if (_inspectedPaddle != null) {
      return _buildPaddleInspectionCard(state, _inspectedPaddle!);
    }

    // Otherwise, show the 3x3 cosmetic grid! (Image 3)
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              // Header Banner (Matching Image 3)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0277BD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF40C4FF), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'PADDLE VAULT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3x3 Grid Layout (9 Skins)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: kPaddles.length,
                itemBuilder: (context, index) {
                  final paddle = kPaddles[index];
                  final isEquipped = state.selectedPaddle.id == paddle.id;
                  final isUnlocked = state.playerLevel >= paddle.unlockLevel;

                  return GestureDetector(
                    onTap: () {
                      if (state.hapticsEnabled) {
                        HapticFeedback.lightImpact();
                      }
                      setState(() => _inspectedPaddle = paddle);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF151D2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEquipped
                              ? AppTheme.opticYellow
                              : isUnlocked
                                  ? const Color(0xFF7B1FA2)
                                  : Colors.white12,
                          width: isEquipped ? 2.5 : 1.8,
                        ),
                        boxShadow: isEquipped
                            ? [BoxShadow(color: AppTheme.opticYellow.withValues(alpha: 0.35), blurRadius: 10)]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: PaddleGraphic(paddle: paddle, width: 62, height: 88),
                          ),
                          if (isEquipped)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.opticYellow,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'EQUIPPED',
                                  style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.black),
                                ),
                              ),
                            ),
                          if (!isUnlocked)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lock_rounded, color: Colors.white70, size: 22),
                                    const SizedBox(height: 2),
                                    Text(
                                      'LV. ${paddle.unlockLevel}',
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.opticYellow),
                                    ),
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
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  // DETAILED 7-STAT INSPECTION CARD (MATCHING REFERENCE IMAGE 2)
  Widget _buildPaddleInspectionCard(GameState state, PaddleModel paddle) {
    final isEquipped = state.selectedPaddle.id == paddle.id;
    final isUnlocked = state.playerLevel >= paddle.unlockLevel;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              // Top Inspection Header with Red Hexagon Close Button (Image 2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INSPECTION',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _inspectedPaddle = null),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Main Purple Bevel Card (Image 2)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1829),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF7B1FA2), width: 3.0),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    // Paddle Graphic & Ball
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: paddle.primaryColor.withValues(alpha: 0.18),
                          ),
                        ),
                        PaddleGraphic(paddle: paddle, width: 85, height: 125, glow: isUnlocked),
                        Positioned(
                          right: 18,
                          top: 18,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(color: AppTheme.opticYellow, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),

                    // Level Badge
                    Text(
                      'LVL. ${paddle.level}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 10),

                    // 7 Detailed RPG Stat Meters (Matching Image 2)
                    _statBarRow('SPIN', paddle.statSpin, 25, Icons.sync_rounded),
                    _statBarRow('SWING', paddle.statSwing, 25, Icons.sports_tennis),
                    _statBarRow('AGILITY', paddle.statAgility, 25, Icons.directions_run_rounded),
                    _statBarRow('ACCURACY', paddle.statAccuracy, 25, Icons.gps_fixed_rounded),
                    _statBarRow('STAMINA', paddle.statStamina, 25, Icons.bolt_rounded),
                    _statBarRow('POWER', paddle.statPower, 25, Icons.local_fire_department_rounded),
                    _statBarRow('SPEED', paddle.statSpeed, 25, Icons.fast_forward_rounded),
                    const SizedBox(height: 16),

                    // Bottom Card Actions: 7/45 Upgrade Bar & Equip Button (Image 2)
                    Row(
                      children: [
                        // Card Collection Progress
                        Expanded(
                          flex: 5,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0277BD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF40C4FF)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_upward_rounded, color: Color(0xFF69F0AE), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '${paddle.cardsCollected}/${paddle.cardsNeeded}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Chunky Yellow Equip Button (Image 2)
                        Expanded(
                          flex: 5,
                          child: GestureDetector(
                            onTap: isUnlocked
                                ? () {
                                    state.selectPaddle(paddle);
                                    setState(() => _inspectedPaddle = null);
                                  }
                                : null,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: !isUnlocked
                                    ? Colors.white12
                                    : isEquipped
                                        ? AppTheme.glassFill
                                        : AppTheme.opticYellow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isEquipped ? AppTheme.glassBorder : Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  !isUnlocked
                                      ? 'LOCKED'
                                      : isEquipped
                                          ? 'EQUIPPED'
                                          : 'EQUIP',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: !isUnlocked
                                        ? Colors.white24
                                        : isEquipped
                                            ? Colors.white70
                                            : Colors.black,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _statBarRow(String label, int value, int max, IconData icon) {
    final fill = (value / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF0277BD),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                ),
                FractionallySizedBox(
                  widthFactor: fill,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
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
  // TAB 2: BATTLE HOME
  // ==========================================================================
  Widget _buildBattleHomeTab(GameState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1B16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stadium_rounded, color: AppTheme.opticYellow, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          state.courtVenue.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                    Text(
                      'STAGE ${state.completedStages + 1}/3',
                      style: const TextStyle(color: AppTheme.mintAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [state.selectedCharacter.bodyColor.withValues(alpha: 0.25), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: state.selectedCharacter.bodyColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.selectedCharacter.bodyColor,
                        border: Border.all(color: state.selectedCharacter.accentColor, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          state.selectedCharacter.name[0],
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(state.selectedCharacter.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    Text('${state.selectedCharacter.archetype} • Using ${state.selectedPaddle.name}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BouncyButton(
                onTap: () {
                  final stageIndex = state.completedStages.clamp(0, kCampaignStages.length - 1);
                  state.startCampaignStage(stageIndex);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourtGameplayScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD6F800), Color(0xFFA6C200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(color: AppTheme.opticYellow.withValues(alpha: 0.40), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'BATTLE (STAGE PLAY)',
                      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BouncyButton(
                onTap: () {
                  state.startExhibitionMatch();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourtGameplayScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.glassFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Center(
                    child: Text(
                      'CASUAL EXHIBITION',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 3: ATHLETES
  // ==========================================================================
  Widget _buildAthletesTab(GameState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ATHLETE ROSTER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          for (final char in kCharacters) ...[
            Builder(builder: (context) {
              final isEquipped = state.selectedCharacter.id == char.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  onTap: () => state.selectCharacter(char),
                  borderColor: isEquipped ? char.accentColor : Colors.white12,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: char.bodyColor,
                          border: Border.all(color: char.accentColor, width: 2),
                        ),
                        child: Center(
                          child: Text(char.name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(char.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(char.perkDescription, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      if (isEquipped)
                        const Icon(Icons.check_circle_rounded, color: AppTheme.opticYellow, size: 22)
                      else
                        const Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 22),
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

  // ==========================================================================
  // TAB 4: SETTINGS & RULES
  // ==========================================================================
  Widget _buildSettingsTab(GameState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MATCH RULES & SETTINGS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          const Text('MATCH TARGET SCORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              _matchScoreChip('5 PTS (QUICK)', 5, state.targetScore == 5, () => state.setTargetScore(5)),
              const SizedBox(width: 8),
              _matchScoreChip('11 PTS (PRO)', 11, state.targetScore == 11, () => state.setTargetScore(11)),
              const SizedBox(width: 8),
              _matchScoreChip('15 PTS (SLAM)', 15, state.targetScore == 15, () => state.setTargetScore(15)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('COURT VENUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          _venueChip('Tournament Arena', state.courtVenue == 'Tournament Arena', () => state.setCourtVenue('Tournament Arena')),
          const SizedBox(height: 6),
          _venueChip('Midnight Stadium (LED)', state.courtVenue == 'Midnight Stadium', () => state.setCourtVenue('Midnight Stadium')),
          const SizedBox(height: 6),
          _venueChip('Sunlit Beach', state.courtVenue == 'Sunlit Beach', () => state.setCourtVenue('Sunlit Beach')),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.opticYellow,
            title: const Text('Sound Effects & Audio'),
            value: state.soundEnabled,
            onChanged: state.toggleSound,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.opticYellow,
            title: const Text('Haptic Touch Vibration'),
            value: state.hapticsEnabled,
            onChanged: state.toggleHaptics,
          ),
        ],
      ),
    );
  }

  Widget _matchScoreChip(String label, int score, bool selected, VoidCallback onTap) {
    return Expanded(
      child: BouncyButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.opticYellow : AppTheme.glassFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: selected ? Colors.black : Colors.white70),
            ),
          ),
        ),
      ),
    );
  }

  Widget _venueChip(String title, bool selected, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      borderColor: selected ? AppTheme.opticYellow : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: selected ? AppTheme.opticYellow : Colors.white24, size: 18),
        ],
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
          _navTabItem(1, Icons.sports_tennis_rounded, 'CARDS'),
          _centerHeroBattleNavItem(2),
          _navTabItem(3, Icons.groups_rounded, 'ROSTER'),
          _navTabItem(4, Icons.tune_rounded, 'SETTINGS'),
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