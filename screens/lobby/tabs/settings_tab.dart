// lib/screens/lobby/tabs/settings_tab.dart

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
  bool _screenShakeEnabled = true;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

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
                      activeThumbColor: AppColors.opticYellow,
                      title: const Text('Sound Effects (SFX)'),
                      value: state.soundEnabled,
                      onChanged: (val) {
                        state.toggleSound(val);
                        AppAudio.play(context, AppAssets.sfxClick, 'Sound Effects Toggle');
                      },
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.opticYellow,
                      title: const Text('Background Music (BGM)'),
                      value: _bgmEnabled,
                      onChanged: (val) => setState(() => _bgmEnabled = val),
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.opticYellow,
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
                      activeThumbColor: AppColors.mintAccent,
                      title: const Text('60 FPS High Performance'),
                      value: _highFpsEnabled,
                      onChanged: (val) => setState(() => _highFpsEnabled = val),
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.mintAccent,
                      title: const Text('Screen Shake FX'),
                      value: _screenShakeEnabled,
                      onChanged: (val) => setState(() => _screenShakeEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Restored Pickleball Playbook Rulebook Bottom Sheet
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
                    Icon(Icons.menu_book_rounded, color: AppColors.opticYellow, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pickleball Playbook (Rules)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Two-Bounce Rule, NVZ Kitchen & Scoring Guide', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
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
                    const Text('PADDLE BLITZ 3.0', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'Created by XCCR Game Studios • Capstone Project 2026\nPowered by Pure Flutter & Dart 2.5D Projection Engine.',
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
}