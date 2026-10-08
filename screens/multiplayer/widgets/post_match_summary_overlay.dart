// lib/screens/multiplayer/widgets/post_match_summary_overlay.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/online_profile_models.dart';
import '../../../widgets/game_components.dart';

class PostMatchSummaryOverlay extends StatefulWidget {
  final MatchPerformanceStats stats;
  final VoidCallback onDismiss;
  final VoidCallback? onPaddleTap;

  const PostMatchSummaryOverlay({
    super.key,
    required this.stats,
    required this.onDismiss,
    this.onPaddleTap,
  });

  @override
  State<PostMatchSummaryOverlay> createState() => _PostMatchSummaryOverlayState();
}

class _PostMatchSummaryOverlayState extends State<PostMatchSummaryOverlay> {
  bool _tappedPaddles = false;

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final isDeltaPositive = stats.duprDelta >= 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          borderColor: stats.won ? AppColors.opticYellow : AppColors.electricCoral,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Win / Defeat Banner
              Text(
                stats.won ? 'VICTORY!' : 'MATCH DEFEAT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: stats.won ? AppColors.opticYellow : AppColors.electricCoral,
                ),
              ),
              Text(
                'Final: ${stats.playerScore} - ${stats.opponentScore}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 16),

              // Animated DUPR Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F2438), Color(0xFF091624)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DUPR RATING UPDATE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF00E5FF), letterSpacing: 1.0)),
                        const SizedBox(height: 2),
                        Text(
                          '${stats.previousDupr.toStringAsFixed(2)}  ──►  ${stats.newDupr.toStringAsFixed(2)}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDeltaPositive ? const Color(0xFF00E676).withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${isDeltaPositive ? '+' : ''}${stats.duprDelta.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isDeltaPositive ? const Color(0xFF00E676) : Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Official Pickleball Performance Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    _statComparisonRow('Kitchen Dinks Struck', '${stats.totalDinks}'),
                    const Divider(color: Colors.white10, height: 12),
                    _statComparisonRow('Overhead Smashes', '${stats.overheadSmashes}'),
                    const Divider(color: Colors.white10, height: 12),
                    _statComparisonRow('Kitchen Faults (NVZ)', '${stats.kitchenFaults}', isNegative: stats.kitchenFaults > 0),
                    const Divider(color: Colors.white10, height: 12),
                    _statComparisonRow('Longest Rally Streak', '${stats.longestRally} Hits'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sportsmanship "Paddle Tap" Button
              if (!_tappedPaddles)
                BouncyButton(
                  onTap: () {
                    setState(() => _tappedPaddles = true);
                    widget.onPaddleTap?.call();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.mintAccent),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🤝 TAP PADDLES (+25 Coins)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.mintAccent)),
                      ],
                    ),
                  ),
                ),

              // Continue Button
              BouncyButton(
                onTap: widget.onDismiss,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.opticYellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 13, letterSpacing: 1.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statComparisonRow(String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isNegative ? AppColors.electricCoral : Colors.white),
        ),
      ],
    );
  }
}