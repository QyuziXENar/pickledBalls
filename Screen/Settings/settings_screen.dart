// lib/Screen/Settings/settings_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
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
          backgroundColor: AppColors.darkBg,
          body: AmbientCourtBackground(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      BouncyButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.glassFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'MATCH RULES & SETTINGS',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. THE SLIDER
                            GlassCard(
                              borderColor: AppColors.opticYellow,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.tune_rounded, color: AppColors.opticYellow, size: 20),
                                          SizedBox(width: 8),
                                          Text('SCREEN SIZE SLIDER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.opticYellow, borderRadius: BorderRadius.circular(8)),
                                        child: Text('${(state.uiScale * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Adjust the slider to shrink the screen layout so all menus fit without feeling oversized.', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.3)),
                                  const SizedBox(height: 10),

                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.opticYellow,
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: AppColors.opticYellow,
                                      trackHeight: 6,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                                      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
                                      activeTickMarkColor: Colors.black,
                                      inactiveTickMarkColor: Colors.white54,
                                      valueIndicatorColor: AppColors.opticYellow,
                                      valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                                    ),
                                    child: Slider(
                                      value: state.uiScale,
                                      min: 0.80,
                                      max: 1.00,
                                      divisions: 4,
                                      label: '${(state.uiScale * 100).round()}%',
                                      onChanged: (val) {
                                        state.setUiScale(val);
                                        AppAudio.playFeatureSfx(AppAssets.sfxClick);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      _buildPointBtn(state, 0.80, '80%\nCompact'),
                                      const SizedBox(width: 5),
                                      _buildPointBtn(state, 0.85, '85%'),
                                      const SizedBox(width: 5),
                                      _buildPointBtn(state, 0.90, '90%\nMedium'),
                                      const SizedBox(width: 5),
                                      _buildPointBtn(state, 0.95, '95%'),
                                      const SizedBox(width: 5),
                                      _buildPointBtn(state, 1.00, '100%\nDefault'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 2. ORIENTATION
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SCREEN ORIENTATION LOCK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  const Text('Lock to portrait or landscape to prevent accidental tilt rotation.', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: BouncyButton(
                                          onTap: () {
                                            state.setOrientationMode(AppOrientationMode.portrait);
                                            AppAudio.playFeatureSfx(AppAssets.sfxClick);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: state.isPortraitMode ? AppColors.opticYellow : Colors.white10,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: state.isPortraitMode ? AppColors.opticYellow : Colors.white12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.stay_current_portrait_rounded, size: 16, color: state.isPortraitMode ? Colors.black : Colors.white70),
                                                const SizedBox(width: 6),
                                                Text('PORTRAIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: state.isPortraitMode ? Colors.black : Colors.white70)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: BouncyButton(
                                          onTap: () {
                                            state.setOrientationMode(AppOrientationMode.landscape);
                                            AppAudio.playFeatureSfx(AppAssets.sfxClick);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: state.isLandscapeMode ? AppColors.opticYellow : Colors.white10,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: state.isLandscapeMode ? AppColors.opticYellow : Colors.white12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.stay_current_landscape_rounded, size: 16, color: state.isLandscapeMode ? Colors.black : Colors.white70),
                                                const SizedBox(width: 6),
                                                Text('LANDSCAPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: state.isLandscapeMode ? Colors.black : Colors.white70)),
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

  Widget _buildPointBtn(GameState state, double targetVal, String label) {
    final isSelected = (state.uiScale - targetVal).abs() < 0.01;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          state.setUiScale(targetVal);
          AppAudio.playFeatureSfx(AppAssets.sfxClick);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.opticYellow : Colors.black45,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.opticYellow : Colors.white24, width: isSelected ? 1.8 : 1.0),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: isSelected ? Colors.black : Colors.white70, height: 1.1),
          ),
        ),
      ),
    );
  }
}