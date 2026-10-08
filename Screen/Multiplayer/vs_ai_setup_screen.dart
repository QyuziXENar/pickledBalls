// lib/Screen/Multiplayer/vs_ai_setup_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
import '../../widgets/game_components.dart';
import '../Gameplay/gameplay_screen.dart';

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
    name: 'Training Facility',
    tag: 'CLIMATE CONTROLLED',
    surfaceTrait: 'POLISHED HARDWOOD OAK',
    primaryColor: Color(0xFF0F172A),
    courtColor: Color(0xFF1E3A8A),
    kitchenColor: Color(0xFFD97706),
    accentColor: Color(0xFFFBBF24),
    glowColor: Color(0xFF3B82F6),
    perk: 'Zero wind drag • True acoustic pop • High traction',
  ),
  CourtVenueData(
    name: 'Sunlit Beach',
    tag: 'TROPICAL RESORT',
    surfaceTrait: 'GOLDEN COAST HARDCOURT',
    primaryColor: Color(0xFFD4A373),
    courtColor: Color(0xFFD66046),
    kitchenColor: Color(0xFF1B3D4A),
    accentColor: Color(0xFFFFF7E6),
    glowColor: Color(0xFFD4A373),
    perk: 'High sea-level altitude • High loop trajectory',
  ),
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
];

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
    AppAudio.playFeatureSfx(AppAssets.sfxSwipe);
    if (GameState.instance.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _goToPreviousVenue() {
    if (_selectedVenueIndex > 0) {
      _courtPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    } else {
      _courtPageController.animateToPage(kCourtVenues.length - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
  }

  void _goToNextVenue() {
    if (_selectedVenueIndex < kCourtVenues.length - 1) {
      _courtPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    } else {
      _courtPageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
  }

  void _startMatch() {
    final state = GameState.instance;
    final venue = kCourtVenues[_selectedVenueIndex];

    state.setCourtVenue(venue.name);
    state.setTargetScore(_selectedTargetScore);
    state.setDifficulty(_selectedDifficulty);
    state.startExhibitionMatch();

    AppAudio.play(context, AppAssets.musicBattleStart, 'Clash Fanfare');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CourtGameplayScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
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
              // Header Top Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 4 : 8),
                child: Row(
                  children: [
                    BouncyButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUSTOM EXHIBITION',
                          style: TextStyle(fontSize: isLandscape ? 14 : 16, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
                        ),
                        const Text(
                          'TUNE COURT • LENGTH • AI THREAT',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textMuted),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.opticYellow),
                      ),
                    ),
                  ],
                ),
              ),

              // Responsive Body
              Expanded(
                child: isLandscape
                    ? _buildLandscapeLayout(currentVenue)
                    : _buildPortraitLayout(currentVenue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2-Column Console Layout for Landscape Mode
  Widget _buildLandscapeLayout(CourtVenueData currentVenue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: 3D Turntable Carousel
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(child: _buildCourtCarousel(currentVenue, true)),
                const SizedBox(height: 4),
                _buildCarouselDots(currentVenue),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Column: Match Configuration & Start Button
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TARGET SCORE (WIN BY 2)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: currentVenue.accentColor)),
                  const SizedBox(height: 6),
                  _buildScoreRow(currentVenue),
                  const SizedBox(height: 10),
                  Text('AI BOT THREAT LEVEL', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: currentVenue.accentColor)),
                  const SizedBox(height: 6),
                  _buildThreatRow(currentVenue),
                  const SizedBox(height: 12),
                  _buildLaunchButton(currentVenue, true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Single-Column Layout for Portrait Mode
  Widget _buildPortraitLayout(CourtVenueData currentVenue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 220, child: _buildCourtCarousel(currentVenue, false)),
          const SizedBox(height: 6),
          _buildCarouselDots(currentVenue),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('TARGET SCORE (WIN BY 2)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: currentVenue.accentColor)),
          ),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildScoreRow(currentVenue)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('AI BOT THREAT LEVEL', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: currentVenue.accentColor)),
          ),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildThreatRow(currentVenue)),
          const SizedBox(height: 24),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildLaunchButton(currentVenue, false)),
        ],
      ),
    );
  }

  Widget _buildCourtCarousel(CourtVenueData currentVenue, bool isLandscape) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          controller: _courtPageController,
          itemCount: kCourtVenues.length,
          onPageChanged: _onVenueChanged,
          itemBuilder: (context, index) {
            final venue = kCourtVenues[index];
            final isSelected = index == _selectedVenueIndex;

            return AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                final yaw = math.sin(_rotationController.value * 2 * math.pi) * 0.08;

                return AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: isSelected ? 1.0 : 0.88,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E161C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? venue.accentColor : Colors.white12, width: isSelected ? 2.0 : 1.0),
                      boxShadow: isSelected ? [BoxShadow(color: venue.glowColor.withValues(alpha: 0.4), blurRadius: 14)] : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _MiniCourtTurntablePainter(venue: venue, yawAngle: isSelected ? yaw : 0.0)),
                          ),
                          Positioned(
                            top: 8,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6), border: Border.all(color: venue.accentColor.withValues(alpha: 0.5))),
                              child: Text(venue.tag, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: venue.accentColor)),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(venue.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                                  Text(venue.perk, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.5, color: venue.accentColor, fontWeight: FontWeight.bold)),
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
        Positioned(left: 4, child: _buildArrowButton(icon: Icons.chevron_left_rounded, onTap: _goToPreviousVenue)),
        Positioned(right: 4, child: _buildArrowButton(icon: Icons.chevron_right_rounded, onTap: _goToNextVenue)),
      ],
    );
  }

  Widget _buildCarouselDots(CourtVenueData currentVenue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(kCourtVenues.length, (idx) {
        final isSelected = idx == _selectedVenueIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isSelected ? 16 : 5,
          height: 4,
          decoration: BoxDecoration(color: isSelected ? currentVenue.accentColor : Colors.white24, borderRadius: BorderRadius.circular(2)),
        );
      }),
    );
  }

  Widget _buildScoreRow(CourtVenueData currentVenue) {
    return Row(
      children: [
        _buildScoreCard(points: 5, title: 'BLITZ', duration: '~2M', icon: Icons.bolt_rounded, accent: currentVenue.accentColor),
        const SizedBox(width: 6),
        _buildScoreCard(points: 11, title: 'REGULATION', duration: '~5M', icon: Icons.sports_tennis_rounded, accent: currentVenue.accentColor),
        const SizedBox(width: 6),
        _buildScoreCard(points: 15, title: 'PRO SLAM', duration: '~8M', icon: Icons.emoji_events_rounded, accent: currentVenue.accentColor),
      ],
    );
  }

  Widget _buildThreatRow(CourtVenueData currentVenue) {
    return Row(
      children: [
        _buildThreatCard(diff: AIDifficulty.rookie, dupr: '2.5', name: 'ROOKIE', badgeColor: const Color(0xFF00E676), icon: Icons.sentiment_satisfied_alt_rounded),
        const SizedBox(width: 6),
        _buildThreatCard(diff: AIDifficulty.pro, dupr: '4.0', name: 'PRO', badgeColor: AppColors.opticYellow, icon: Icons.offline_bolt_rounded),
        const SizedBox(width: 6),
        _buildThreatCard(diff: AIDifficulty.legend, dupr: '5.5+', name: 'TITAN', badgeColor: const Color(0xFFFF3D00), icon: Icons.whatshot_rounded),
      ],
    );
  }

  Widget _buildLaunchButton(CourtVenueData currentVenue, bool isLandscape) {
    return BouncyButton(
      onTap: _startMatch,
      child: Container(
        height: isLandscape ? 48 : 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [currentVenue.accentColor, currentVenue.glowColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: currentVenue.glowColor.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
            SizedBox(width: 6),
            Text('STEP ONTO COURT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton({required IconData icon, required VoidCallback onTap}) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: const Color(0xFF0F172A).withValues(alpha: 0.85), shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildScoreCard({required int points, required String title, required String duration, required IconData icon, required Color accent}) {
    final isSelected = _selectedTargetScore == points;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTargetScore = points);
          AppAudio.playFeatureSfx(AppAssets.sfxClick);
          if (GameState.instance.hapticsEnabled) HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.2) : const Color(0xFF0F1822),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? accent : Colors.white12, width: isSelected ? 1.8 : 1.0),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? accent : Colors.white54),
              const SizedBox(height: 2),
              Text('$points PTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.white70)),
              Text(title, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: isSelected ? accent : Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThreatCard({required AIDifficulty diff, required String dupr, required String name, required Color badgeColor, required IconData icon}) {
    final isSelected = _selectedDifficulty == diff;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedDifficulty = diff);
          AppAudio.playFeatureSfx(AppAssets.sfxClick);
          if (GameState.instance.hapticsEnabled) HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? badgeColor.withValues(alpha: 0.2) : const Color(0xFF0F1822),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? badgeColor : Colors.white12, width: isSelected ? 1.8 : 1.0),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: badgeColor),
              const SizedBox(height: 2),
              Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.white70)),
              Text('$dupr DUPR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: badgeColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCourtTurntablePainter extends CustomPainter {
  final CourtVenueData venue;
  final double yawAngle;

  _MiniCourtTurntablePainter({required this.venue, required this.yawAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;

    canvas.save();
    canvas.translate(cx, cy);

    final courtW = size.width * 0.62;
    final courtH = size.height * 0.54;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 36), width: courtW * 1.15, height: courtH * 0.45),
      Paint()..color = Colors.black.withValues(alpha: 0.55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final tilt = Matrix4.identity()..setEntry(3, 2, 0.0025)..rotateX(1.05)..rotateZ(yawAngle);
    canvas.transform(tilt.storage);

    final apronRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: courtW * 1.35, height: courtH * 1.4), const Radius.circular(16));
    canvas.drawRRect(apronRect, Paint()..color = venue.primaryColor);

    final courtRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: courtW, height: courtH), const Radius.circular(8));
    canvas.drawRRect(courtRect, Paint()..color = venue.courtColor);

    final kitchenRect = Rect.fromCenter(center: Offset.zero, width: courtW, height: courtH * 0.32);
    canvas.drawRect(kitchenRect, Paint()..color = venue.kitchenColor);

    final linePaint = Paint()..color = venue.accentColor.withValues(alpha: 0.90)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.drawRRect(courtRect, linePaint);
    canvas.drawLine(Offset(-courtW / 2, -courtH * 0.16), Offset(courtW / 2, -courtH * 0.16), linePaint);
    canvas.drawLine(Offset(-courtW / 2, courtH * 0.16), Offset(courtW / 2, courtH * 0.16), linePaint);
    canvas.drawLine(Offset(0, -courtH / 2), Offset(0, -courtH * 0.16), linePaint);
    canvas.drawLine(Offset(0, courtH * 0.16), Offset(0, courtH / 2), linePaint);

    final netPaint = Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 3.0;
    canvas.drawLine(Offset(-courtW / 2 - 4, 0), Offset(courtW / 2 + 4, 0), netPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniCourtTurntablePainter oldDelegate) {
    return oldDelegate.yawAngle != yawAngle || oldDelegate.venue != venue;
  }
}