// lib/screens/multiplayer/multiplayer_select_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
import '../../widgets/game_components.dart';
import 'vs_online_lobby_screen.dart';
import 'vs_player_lobby_screen.dart';

class MultiplayerSelectScreen extends StatelessWidget {
  const MultiplayerSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: AmbientCourtBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    BouncyButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1v1 MULTIPLAYER HUB',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                        ),
                        Text(
                          'CHOOSE YOUR CONNECTION MODE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Selection Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mode 1: LOCAL LAN
                      _buildModeCard(
                        context: context,
                        title: 'LOCAL LAN VS.',
                        subtitle: 'Same Wi-Fi Router or Direct Mobile Hotspot',
                        description: 'Peer-to-peer WebSocket connection. 0ms ping with no internet required. Ideal for playing side-by-side.',
                        badgeText: 'OFFLINE / READY',
                        badgeColor: AppColors.mintAccent,
                        accentColor: AppColors.cyberCyan,
                        icon: Icons.wifi_tethering_rounded,
                        onTap: () {
                          AppAudio.playFeatureSfx(AppAssets.sfxClick);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VsPlayerLobbyScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // Mode 2: ONLINE ARENA (WAN)
                      _buildModeCard(
                        context: context,
                        title: 'ONLINE ARENA VS.',
                        subtitle: 'Play Anywhere across 4G/5G Cellular & Different Wi-Fi',
                        description: 'Global room codes and internet matchmaking. Connect across different networks from home.',
                        badgeText: 'ONLINE CLIENT READY',
                        badgeColor: AppColors.opticYellow,
                        accentColor: AppColors.opticYellow,
                        icon: Icons.public_rounded,
                        onTap: () {
                          AppAudio.playFeatureSfx(AppAssets.sfxClick);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VsOnlineLobbyScreen()),
                          );
                        },
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

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required Color accentColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1824),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: badgeColor, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ENTER ARENA',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 1.0),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}