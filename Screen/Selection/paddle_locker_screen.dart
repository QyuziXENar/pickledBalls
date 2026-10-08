// lib/Screen/Selection/paddle_locker_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/asset_helpers.dart';
import '../../widgets/game_components.dart';

class PaddleLockerScreen extends StatefulWidget {
  const PaddleLockerScreen({super.key});

  @override
  State<PaddleLockerScreen> createState() => _PaddleLockerScreenState();
}

class _PaddleLockerScreenState extends State<PaddleLockerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final initial = kPaddles.indexWhere((p) => p.id == GameState.instance.selectedPaddle.id);
    _currentIndex = initial >= 0 ? initial : 0;
    _pageController = PageController(viewportFraction: 0.72, initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameState.instance,
      builder: (context, _) {
        final state = GameState.instance;
        final activePaddle = kPaddles[_currentIndex];
        final isEquipped = state.selectedPaddle.id == activePaddle.id;
        final isUnlocked = state.playerLevel >= activePaddle.unlockLevel && !activePaddle.isPrototype;
        final alloc = state.getAllocation(activePaddle.id);

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
                        'PADDLE LOCKER',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.upgradePoint.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.upgradePoint.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 15, color: AppColors.upgradePoint),
                            const SizedBox(width: 4),
                            Text(
                              '${state.upgradePoints} UP',
                              style: const TextStyle(
                                color: AppColors.upgradePoint,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: kPaddles.length,
                    onPageChanged: (idx) {
                      setState(() => _currentIndex = idx);
                      AppAudio.playFeatureSfx(AppAssets.sfxCardTap);
                      if (state.hapticsEnabled) {
                        HapticFeedback.selectionClick();
                      }
                    },
                    itemBuilder: (ctx, i) {
                      final paddle = kPaddles[i];
                      final isSelected = i == _currentIndex;

                      return AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: isSelected ? 1.0 : 0.85,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PaddleGraphic(
                                paddle: paddle,
                                width: 190,
                                height: 270,
                                glow: isSelected && isUnlocked,
                              ),
                              if (!isUnlocked)
                                Container(
                                  width: 190,
                                  height: 270,
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.lock_rounded, size: 36, color: Colors.white70),
                                      const SizedBox(height: 6),
                                      Text(
                                        paddle.isPrototype ? 'COMING IN v3.1' : 'UNLOCKS AT LV. ${paddle.unlockLevel}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          color: AppColors.opticYellow,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activePaddle.brand,
                                      style: TextStyle(
                                        color: activePaddle.accentColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    Text(
                                      activePaddle.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                if (alloc.totalAllocated > 0 && !activePaddle.isPrototype)
                                  BouncyButton(
                                    onTap: () {
                                      state.resetPaddleAllocations(activePaddle.id);
                                      AppAudio.playFeatureSfx(AppAssets.sfxClick);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.refresh_rounded, size: 14, color: Colors.redAccent),
                                          SizedBox(width: 4),
                                          Text('REFUND UP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Column(
                              children: [
                                _statRowWithBoost('POWER', activePaddle.basePower, alloc.power, activePaddle.accentColor, () {
                                  state.allocateUpgradePoint(activePaddle.id, 'power');
                                }),
                                const SizedBox(height: 6),
                                _statRowWithBoost('CONTROL', activePaddle.baseControl, alloc.control, activePaddle.accentColor, () {
                                  state.allocateUpgradePoint(activePaddle.id, 'control');
                                }),
                                const SizedBox(height: 6),
                                _statRowWithBoost('SPIN', activePaddle.baseSpin, alloc.spin, activePaddle.accentColor, () {
                                  state.allocateUpgradePoint(activePaddle.id, 'spin');
                                }),
                                const SizedBox(height: 6),
                                _statRowWithBoost('AGILITY', activePaddle.baseAgility, alloc.agility, activePaddle.accentColor, () {
                                  state.allocateUpgradePoint(activePaddle.id, 'agility');
                                }),
                              ],
                            ),
                            BouncyButton(
                              onTap: isUnlocked
                                  ? () {
                                      state.selectPaddle(activePaddle);
                                      AppAudio.playFeatureSfx(AppAssets.sfxPaddleEquip);
                                      if (state.hapticsEnabled) {
                                        HapticFeedback.mediumImpact();
                                      }
                                    }
                                  : () {},
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: !isUnlocked
                                      ? Colors.white12
                                      : isEquipped
                                          ? AppColors.glassFill
                                          : activePaddle.accentColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isEquipped ? AppColors.glassBorder : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    !isUnlocked
                                        ? activePaddle.isPrototype
                                            ? 'PROTOTYPE (COMING SOON)'
                                            : 'LOCKED (REQUIRES LEVEL ${activePaddle.unlockLevel})'
                                        : isEquipped
                                            ? 'CURRENTLY EQUIPPED'
                                            : 'EQUIP PADDLE',
                                    style: TextStyle(
                                      color: !isUnlocked
                                          ? Colors.white38
                                          : isEquipped
                                              ? Colors.white70
                                              : Colors.black,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
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

  Widget _statRowWithBoost(String label, int base, int bonus, Color color, VoidCallback onBoost) {
    final total = base + bonus;
    final fill = (total / 30.0).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(height: 8, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
              FractionallySizedBox(
                widthFactor: fill,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '$total',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: bonus > 0 ? AppColors.mintAccent : Colors.white,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            onBoost();
            AppAudio.playFeatureSfx(AppAssets.sfxClick);
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: AppColors.upgradePoint, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 12, color: Colors.black),
          ),
        ),
      ],
    );
  }
}