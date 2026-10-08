// lib/Screen/Lobby/tabs/settings_tab.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_state.dart';
import '../../../widgets/asset_helpers.dart';
import '../../../widgets/game_components.dart';

class SettingsTab extends StatefulWidget {
  final GameState state;

  const SettingsTab({super.key, required this.state});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _bgmEnabled = true;
  bool _highFpsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildScreenSizeSliderCard(state),
                        const SizedBox(height: 10),
                        _buildOrientationCard(state),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildAudioCard(state),
                        const SizedBox(height: 8),
                        _buildPerformanceCard(state),
                        const SizedBox(height: 8),
                        _buildPlaybookCard(context),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScreenSizeSliderCard(state),
              const SizedBox(height: 14),
              _buildOrientationCard(state),
              const SizedBox(height: 14),
              _buildAudioCard(state),
              const SizedBox(height: 14),
              _buildPerformanceCard(state),
              const SizedBox(height: 14),
              _buildPlaybookCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // PHYSICAL STEPPED SLIDER WITH 5 FIXED POINTS (80% TO 100%)
  // ==========================================================================
  Widget _buildScreenSizeSliderCard(GameState state) {
    return GlassCard(
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
                  Text(
                    'SCREEN SIZE SLIDER',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.opticYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(state.uiScale * 100).round()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Scale down the menus so all buttons and cards fit your phone without feeling oversized.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.3),
          ),
          const SizedBox(height: 10),

          // THE VISUAL SLIDER BAR
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.opticYellow,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppColors.opticYellow,
              overlayColor: AppColors.opticYellow.withValues(alpha: 0.2),
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
              divisions: 4, // 0.80, 0.85, 0.90, 0.95, 1.00
              label: '${(state.uiScale * 100).round()}%',
              onChanged: (val) {
                state.setUiScale(val);
                AppAudio.playFeatureSfx(AppAssets.sfxClick);
              },
            ),
          ),
          const SizedBox(height: 8),

          // 5 DIRECT CLICKABLE FIXED-POINT PRESETS
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
            border: Border.all(
              color: isSelected ? AppColors.opticYellow : Colors.white24,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.black : Colors.white70,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrientationCard(GameState state) {
    return GlassCard(
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
    );
  }

  Widget _buildAudioCard(GameState state) {
    return GlassCard(
      child: Column(
        children: [
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.opticYellow,
            title: const Text('Sound Effects (SFX)', style: TextStyle(fontSize: 12)),
            value: state.soundEnabled,
            onChanged: (val) {
              state.toggleSound(val);
              AppAudio.play(context, AppAssets.sfxClick, 'Toggle');
            },
          ),
          const Divider(color: Colors.white12, height: 8),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.opticYellow,
            title: const Text('Background Music (BGM)', style: TextStyle(fontSize: 12)),
            value: _bgmEnabled,
            onChanged: (val) => setState(() => _bgmEnabled = val),
          ),
          const Divider(color: Colors.white12, height: 8),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.opticYellow,
            title: const Text('Haptic Vibration', style: TextStyle(fontSize: 12)),
            value: state.hapticsEnabled,
            onChanged: state.toggleHaptics,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(GameState state) {
    return GlassCard(
      child: Column(
        children: [
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.mintAccent,
            title: const Text('60 FPS High Performance', style: TextStyle(fontSize: 12)),
            value: _highFpsEnabled,
            onChanged: (val) => setState(() => _highFpsEnabled = val),
          ),
          const Divider(color: Colors.white12, height: 8),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.mintAccent,
            title: const Text('Screen Shake FX', style: TextStyle(fontSize: 12)),
            value: state.screenShakeEnabled,
            onChanged: state.toggleScreenShake,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybookCard(BuildContext context) {
    return GlassCard(
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
          Icon(Icons.menu_book_rounded, color: AppColors.opticYellow, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickleball Playbook (Rules)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Two-Bounce Rule, NVZ Kitchen & Scoring Guide', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 20),
        ],
      ),
    );
  }
}