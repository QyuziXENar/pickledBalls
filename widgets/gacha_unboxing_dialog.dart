// lib/widgets/gacha_unboxing_dialog.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../models/game_state.dart';
import 'asset_helpers.dart';
import 'game_components.dart';

class GachaRewardItem {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const GachaRewardItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });
}

class GachaUnboxingDialog extends StatefulWidget {
  final String crateName;
  final Color crateAccent;
  final List<GachaRewardItem> rewards;
  final VoidCallback onClaimed;

  const GachaUnboxingDialog({
    super.key,
    required this.crateName,
    required this.crateAccent,
    required this.rewards,
    required this.onClaimed,
  });

  static Future<void> show({
    required BuildContext context,
    required String crateName,
    required Color crateAccent,
    required List<GachaRewardItem> rewards,
    required VoidCallback onClaimed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => GachaUnboxingDialog(
        crateName: crateName,
        crateAccent: crateAccent,
        rewards: rewards,
        onClaimed: onClaimed,
      ),
    );
  }

  @override
  State<GachaUnboxingDialog> createState() => _GachaUnboxingDialogState();
}

class _GachaUnboxingDialogState extends State<GachaUnboxingDialog>
    with TickerProviderStateMixin {
  late AnimationController _chestWobbleController;
  late AnimationController _raySpinController;
  late AnimationController _rewardRevealController;

  bool _isOpened = false;

  @override
  void initState() {
    super.initState();

    _chestWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _raySpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _rewardRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _chestWobbleController.dispose();
    _raySpinController.dispose();
    _rewardRevealController.dispose();
    super.dispose();
  }

  void _openCrate() {
    if (_isOpened) return;

    if (GameState.instance.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    AppAudio.playSfx(AppAssets.sfxSwipe);

    setState(() => _isOpened = true);
    _chestWobbleController.stop();
    _rewardRevealController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isOpened)
                AnimatedBuilder(
                  animation: _raySpinController,
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _raySpinController.value * 2 * math.pi,
                      child: Container(
                        width: 340,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.crateAccent.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: widget.crateAccent, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: widget.crateAccent.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.crateName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: widget.crateAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_isOpened) ...[
                      GestureDetector(
                        onTap: _openCrate,
                        child: AnimatedBuilder(
                          animation: _chestWobbleController,
                          builder: (context, child) {
                            final tilt = math.sin(_chestWobbleController.value * math.pi) * 0.08;
                            return Transform.rotate(
                              angle: tilt,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black45,
                              border: Border.all(color: widget.crateAccent, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.crateAccent.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: 64,
                              color: widget.crateAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      BouncyButton(
                        onTap: _openCrate,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: widget.crateAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'TAP TO UNLOCK!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _rewardRevealController,
                          curve: Curves.elasticOut,
                        ),
                        child: Column(
                          children: widget.rewards.map((r) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: r.color.withValues(alpha: 0.5), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: r.color.withValues(alpha: 0.2),
                                    child: Icon(r.icon, color: r.color, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      r.title,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    r.amount,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: r.color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      BouncyButton(
                        onTap: () {
                          widget.onClaimed();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.battleButtonGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'CLAIM ALL REWARDS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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