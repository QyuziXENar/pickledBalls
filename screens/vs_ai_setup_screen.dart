import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../widgets/ambient_background.dart';
import '../widgets/asset_helpers.dart';
import '../widgets/game_components.dart';
import 'gameplay_screen.dart';

// ============================================================================
// COURT VENUE METADATA
// ============================================================================
class CourtVenueData {
  final String name;
  final String tag;
  final String surfaceTrait;
  final Color primaryColor;
  final Color courtColor;
  final Color kitchenColor;
  final Color accentColor;
  final Color glowColor;
  final String perk;

  const CourtVenueData({
    required this.name,
    required this.tag,
    required this.surfaceTrait,
    required this.primaryColor,
    required this.courtColor,
    required this.kitchenColor,
    required this.accentColor,
    required this.glowColor,
    required this.perk,
  });
}

const List<CourtVenueData> kCourtVenues = [
  CourtVenueData(
    name: 'Tournament Arena',
    tag: 'OFFICIAL VENUE',
    surfaceTrait: 'CHAMPIONSHIP ACRYLIC',
    primaryColor: Color(0xFF102840),
    courtColor: Color(0xFF1C5382),
    kitchenColor: Color(0xFF163E63),
    accentColor: Color(0xFF64B5F6),
    glowColor: Color(0xFF1F598C),
    perk: 'True line response • Standard 1.0x regulation bounce',
  ),
  CourtVenueData(
    name: 'Midnight Stadium',
    tag: 'NIGHT ARENA',
    surfaceTrait: 'CYBER LED SYNTHETIC',
    primaryColor: Color(0xFF070B10),
    courtColor: Color(0xFF0D1826),
    kitchenColor: Color(0xFF142438),
    accentColor: Color(0xFF00E5FF),
    glowColor: Color(0xFF00E5FF),
    perk: 'Slick fast synthetic • Neon glow LED perimeter',
  ),
  CourtVenueData(
    name: 'Sunlit Beach',
    tag: 'TROPICAL RESORT',
    surfaceTrait: 'GOLDEN COAST HARDCOURT',
    primaryColor: Color(0xFFD4A373),
    courtColor: Color(0xFF2A9D8F),
    kitchenColor: Color(0xFF264653),
    accentColor: Color(0xFFFFF7E6),
    glowColor: Color(0xFFD4A373),
    perk: 'High sea-level altitude • High loop trajectory',
  ),
];

// ============================================================================
// DEDICATED VS. AI MATCH SETUP SCREEN
// ============================================================================
class VsAiSetupScreen extends StatefulWidget {
  const VsAiSetupScreen({super.key});

  @override
  State<VsAiSetupScreen> createState() => _VsAiSetupScreenState();
}

class _VsAiSetupScreenState extends State<VsAiSetupScreen>
    with SingleTickerProviderStateMixin {
  late PageController _courtPageController;
  late AnimationController _rotationController;
  int _selectedVenueIndex = 0;

  int _selectedTargetScore = 11;
  AIDifficulty _selectedDifficulty = AIDifficulty.pro;

  @override
  void initState() {
    super.initState();
    final state = GameState.instance;

    final initialVenueIdx = kCourtVenues.indexWhere((v) => v.name == state.courtVenue);
    _selectedVenueIndex = initialVenueIdx >= 0 ? initialVenueIdx : 0;
    _selectedTargetScore = state.targetScore;
    _selectedDifficulty = state.difficulty;

    _courtPageController = PageController(
      viewportFraction: 0.84,
      initialPage: _selectedVenueIndex,
    );

    // Continuous slow camera yaw drift for the 3D court diorama
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _courtPageController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onVenueChanged(int index) {
    setState(() => _selectedVenueIndex = index);
    AppAudio.play(context, 'swipe.mp3', 'Venue Switch');
    if (GameState.instance.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _startMatch() {
    final state = GameState.instance;
    final venue = kCourtVenues[_selectedVenueIndex];

    state.setCourtVenue(venue.name);
    state.setTargetScore(_selectedTargetScore);
    state.setDifficulty(_selectedDifficulty);
    state.startExhibitionMatch();

    AppAudio.play(context, 'battle_start.mp3', 'Clash Fanfare');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CourtGameplayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentVenue = kCourtVenues[_selectedVenueIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF070B0A),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.4),
            radius: 1.2,
            colors: [
              currentVenue.glowColor.withValues(alpha: 0.35),
              const Color(0xFF0B1412),
              const Color(0xFF050807),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUSTOM EXHIBITION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'TUNE COURT • LENGTH • AI THREAT',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    BouncyButton(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const HowToPlaySheet(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.glassFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: const Icon(Icons.help_outline_rounded, size: 18, color: AppTheme.opticYellow),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========================================================
                      // 1. TOP HALF: 3D SLIDING / ROTATING COURT CAROUSEL
                      // ========================================================
                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          controller: _courtPageController,
                          itemCount: kCourtVenues.length,
                          onPageChanged: _onVenueChanged,
                          itemBuilder: (context, index) {
                            final venue = kCourtVenues[index];
                            final isSelected = index == _selectedVenueIndex;

                            return AnimatedBuilder(
                              animation: _rotationController,
                              builder: (context, child) {
                                // Subtle oscillating camera angle (-0.08 to +0.08 rad)
                                final yaw = math.sin(_rotationController.value * 2 * math.pi) * 0.08;

                                return AnimatedScale(
                                  duration: const Duration(milliseconds: 250),
                                  scale: isSelected ? 1.0 : 0.88,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0E161C),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isSelected
                                            ? venue.accentColor
                                            : Colors.white12,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: venue.glowColor.withValues(alpha: 0.4),
                                                blurRadius: 18,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // 3D Mini Court CustomPainter
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: _MiniCourtTurntablePainter(
                                                venue: venue,
                                                yawAngle: isSelected ? yaw : 0.0,
                                              ),
                                            ),
                                          ),

                                          // Top Venue Badge
                                          Positioned(
                                            top: 12,
                                            left: 14,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.65),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: venue.accentColor.withValues(alpha: 0.5)),
                                              ),
                                              child: Text(
                                                venue.tag,
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: venue.accentColor,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Bottom Venue Info Overlay
                                          Positioned(
                                            bottom: 12,
                                            left: 14,
                                            right: 14,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.75),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.white12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    venue.name.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.white,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    venue.perk,
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      color: venue.accentColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // Carousel Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(kCourtVenues.length, (idx) {
                          final isSelected = idx == _selectedVenueIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            width: isSelected ? 18 : 6,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected ? currentVenue.accentColor : Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 16),

                      // ========================================================
                      // 2. UNIQUE MATCH LENGTH: "REGULATION MATCH DIAL"
                      // ========================================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'TARGET SCORE (WIN BY 2)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: currentVenue.accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _buildScoreCard(
                              points: 5,
                              title: 'BLITZ SPRINT',
                              duration: '~2 MINS',
                              icon: Icons.bolt_rounded,
                              accent: currentVenue.accentColor,
                            ),
                            const SizedBox(width: 8),
                            _buildScoreCard(
                              points: 11,
                              title: 'REGULATION',
                              duration: '~5 MINS',
                              icon: Icons.sports_tennis_rounded,
                              accent: currentVenue.accentColor,
                            ),
                            const SizedBox(width: 8),
                            _buildScoreCard(
                              points: 15,
                              title: 'PRO SLAM',
                              duration: '~8 MINS',
                              icon: Icons.emoji_events_rounded,
                              accent: currentVenue.accentColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ========================================================
                      // 3. UNIQUE AI DIFFICULTY: "OPPONENT THREAT CARDS"
                      // ========================================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'AI BOT THREAT LEVEL',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: currentVenue.accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _buildThreatCard(
                              diff: AIDifficulty.rookie,
                              dupr: '2.5 DUPR',
                              name: 'ROOKIE',
                              desc: 'Casual Pace',
                              badgeColor: const Color(0xFF00E676),
                              icon: Icons.sentiment_satisfied_alt_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildThreatCard(
                              diff: AIDifficulty.pro,
                              dupr: '4.0 DUPR',
                              name: 'PRO TOUR',
                              desc: 'Sharp Dinks',
                              badgeColor: AppTheme.opticYellow,
                              icon: Icons.offline_bolt_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildThreatCard(
                              diff: AIDifficulty.legend,
                              dupr: '5.5+ DUPR',
                              name: 'TITAN',
                              desc: 'Relentless',
                              badgeColor: const Color(0xFFFF3D00),
                              icon: Icons.whatshot_rounded,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ========================================================
                      // 4. ACTION LAUNCHER: "STEP ONTO COURT"
                      // ========================================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: BouncyButton(
                          onTap: _startMatch,
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  currentVenue.accentColor,
                                  currentVenue.glowColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: currentVenue.glowColor.withValues(alpha: 0.5),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                                const SizedBox(width: 8),
                                const Text(
                                  'STEP ONTO COURT',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  // Segmented Match Length Card
  Widget _buildScoreCard({
    required int points,
    required String title,
    required String duration,
    required IconData icon,
    required Color accent,
  }) {
    final isSelected = _selectedTargetScore == points;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTargetScore = points);
          if (GameState.instance.hapticsEnabled) {
            HapticFeedback.lightImpact();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.20) : const Color(0xFF0F1822),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accent : Colors.white12,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 10)]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? accent : Colors.white54),
              const SizedBox(height: 4),
              Text(
                '$points PTS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? accent : Colors.white38,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(fontSize: 7.5, color: Colors.white54, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Arcade Threat Card
  Widget _buildThreatCard({
    required AIDifficulty diff,
    required String dupr,
    required String name,
    required String desc,
    required Color badgeColor,
    required IconData icon,
  }) {
    final isSelected = _selectedDifficulty == diff;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedDifficulty = diff);
          if (GameState.instance.hapticsEnabled) {
            HapticFeedback.lightImpact();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? badgeColor.withValues(alpha: 0.20) : const Color(0xFF0F1822),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? badgeColor : Colors.white12,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: badgeColor.withValues(alpha: 0.3), blurRadius: 12)]
                : null,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor.withValues(alpha: 0.25),
                ),
                child: Icon(icon, size: 20, color: badgeColor),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : Colors.white70,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                dupr,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 8,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3D MINI COURT TURNTABLE PAINTER
// ============================================================================
class _MiniCourtTurntablePainter extends CustomPainter {
  final CourtVenueData venue;
  final double yawAngle;

  _MiniCourtTurntablePainter({required this.venue, required this.yawAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;

    // Apply 3D perspective rotation matrix
    canvas.save();
    canvas.translate(cx, cy);

    final courtW = size.width * 0.62;
    final courtH = size.height * 0.54;

    // 3D Drop Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 36), width: courtW * 1.15, height: courtH * 0.45),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Dynamic camera tilt
    final tilt = Matrix4.identity()
      ..setEntry(3, 2, 0.0025)
      ..rotateX(1.05)
      ..rotateZ(yawAngle);
    canvas.transform(tilt.storage);

    // 1. Apron Floor Slab
    final apronRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: courtW * 1.35, height: courtH * 1.4),
      const Radius.circular(16),
    );
    canvas.drawRRect(apronRect, Paint()..color = venue.primaryColor);

    // 2. Playable Court
    final courtRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: courtW, height: courtH),
      const Radius.circular(8),
    );
    canvas.drawRRect(courtRect, Paint()..color = venue.courtColor);

    // 3. Kitchen (NVZ)
    final kitchenRect = Rect.fromCenter(center: Offset.zero, width: courtW, height: courtH * 0.32);
    canvas.drawRect(kitchenRect, Paint()..color = venue.kitchenColor);

    // 4. White Line Markings
    final linePaint = Paint()
      ..color = venue.accentColor.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(courtRect, linePaint);
    canvas.drawLine(Offset(-courtW / 2, -courtH * 0.16), Offset(courtW / 2, -courtH * 0.16), linePaint);
    canvas.drawLine(Offset(-courtW / 2, courtH * 0.16), Offset(courtW / 2, courtH * 0.16), linePaint);
    canvas.drawLine(Offset(0, -courtH / 2), Offset(0, -courtH * 0.16), linePaint);
    canvas.drawLine(Offset(0, courtH * 0.16), Offset(0, courtH / 2), linePaint);

    // 5. 3D Net
    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(-courtW / 2 - 4, 0), Offset(courtW / 2 + 4, 0), netPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniCourtTurntablePainter oldDelegate) {
    return oldDelegate.yawAngle != yawAngle || oldDelegate.venue != venue;
  }
}