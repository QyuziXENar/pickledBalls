import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/game_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'MATCH RULES & SETTINGS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. MATCH LENGTH SELECTOR
                            const Text(
                              'MATCH LENGTH (FIRST TO WIN BY 2)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _matchScoreChip('5 PTS (QUICK)', 5, state.targetScore == 5, () => state.setTargetScore(5)),
                                const SizedBox(width: 8),
                                _matchScoreChip('11 PTS (STANDARD)', 11, state.targetScore == 11, () => state.setTargetScore(11)),
                                const SizedBox(width: 8),
                                _matchScoreChip('15 PTS (PRO)', 15, state.targetScore == 15, () => state.setTargetScore(15)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 2. COURT VENUE SELECTION
                            const Text(
                              'COURT VENUE & ENVIRONMENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _venueCard(
                              title: 'Tournament Arena',
                              subtitle: 'Official dual-tone blue court with stadium lighting',
                              swatch: const Color(0xFF1F598C),
                              selected: state.courtVenue == 'Tournament Arena',
                              onTap: () => state.setCourtVenue('Tournament Arena'),
                            ),
                            const SizedBox(height: 8),
                            _venueCard(
                              title: 'Midnight Stadium',
                              subtitle: 'Cyber night arena with glowing Neon Cyan LED lines',
                              swatch: const Color(0xFF00E5FF),
                              selected: state.courtVenue == 'Midnight Stadium',
                              onTap: () => state.setCourtVenue('Midnight Stadium'),
                            ),
                            const SizedBox(height: 8),
                            _venueCard(
                              title: 'Sunlit Beach',
                              subtitle: 'Golden sand perimeter with tropical teal ocean court',
                              swatch: const Color(0xFF2A9D8F),
                              selected: state.courtVenue == 'Sunlit Beach',
                              onTap: () => state.setCourtVenue('Sunlit Beach'),
                            ),
                            const SizedBox(height: 24),

                            // 3. GAME PACE MODE
                            const Text(
                              'GAMEPLAY PACE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GlassCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: BouncyButton(
                                      onTap: () => state.setGamePace(1.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: state.gamePace == 1.0 ? AppTheme.opticYellow : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'REGULATION (1.0x)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: state.gamePace == 1.0 ? Colors.black : Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: BouncyButton(
                                      onTap: () => state.setGamePace(1.25),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: state.gamePace == 1.25 ? AppTheme.opticYellow : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'BLITZ TURBO (1.25x)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: state.gamePace == 1.25 ? Colors.black : Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 4. AI DIFFICULTY
                            const Text(
                              'AI DIFFICULTY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (final diff in AIDifficulty.values) ...[
                              GlassCard(
                                onTap: () => state.setDifficulty(diff),
                                borderColor: state.difficulty == diff ? AppTheme.opticYellow : null,
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Icon(
                                      state.difficulty == diff ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: state.difficulty == diff ? AppTheme.opticYellow : Colors.white38,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(diff.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text(diff.description, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 24),

                            // 5. AUDIO & HAPTICS
                            const Text(
                              'AUDIO & HAPTICS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 10),
                            GlassCard(
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    activeThumbColor: AppTheme.opticYellow,
                                    title: const Text('Sound Effects & Dink Audio'),
                                    subtitle: const Text('Auditory paddle pop on contact', style: TextStyle(fontSize: 12)),
                                    value: state.soundEnabled,
                                    onChanged: state.toggleSound,
                                  ),
                                  const Divider(color: Colors.white12),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    activeThumbColor: AppTheme.opticYellow,
                                    title: const Text('Haptic Vibration'),
                                    subtitle: const Text('Tactile feedback on kitchen faults & rallies', style: TextStyle(fontSize: 12)),
                                    value: state.hapticsEnabled,
                                    onChanged: state.toggleHaptics,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _matchScoreChip(String label, int score, bool selected, VoidCallback onTap) {
    return Expanded(
      child: BouncyButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.opticYellow : AppTheme.glassFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppTheme.opticYellow : AppTheme.glassBorder),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.black : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _venueCard({
    required String title,
    required String subtitle,
    required Color swatch,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      borderColor: selected ? AppTheme.opticYellow : null,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: selected ? AppTheme.opticYellow : Colors.white24,
          ),
        ],
      ),
    );
  }
}