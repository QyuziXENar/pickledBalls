import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../widgets/ambient_background.dart';
import '../widgets/game_components.dart';

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
        final isUnlocked = state.playerLevel >= activePaddle.unlockLevel;

        return Scaffold(
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
                            color: AppTheme.glassFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.glassBorder),
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
                      // Player Level Tag
                      Text(
                        'PLAYER LV. ${state.playerLevel}',
                        style: const TextStyle(
                          color: AppTheme.opticYellow,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
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
                      if (GameState.instance.hapticsEnabled) {
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
                              // Lock Overlay
                              if (state.playerLevel < paddle.unlockLevel)
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
                                        'UNLOCKS AT LV. ${paddle.unlockLevel}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          color: AppTheme.opticYellow,
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
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1B16),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  activePaddle.brand,
                                  style: TextStyle(
                                    color: activePaddle.accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activePaddle.name,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                StatBar(label: 'Power', value: activePaddle.power, color: activePaddle.accentColor),
                                const SizedBox(height: 8),
                                StatBar(label: 'Control', value: activePaddle.control, color: activePaddle.accentColor),
                                const SizedBox(height: 8),
                                StatBar(label: 'Spin', value: activePaddle.spin, color: activePaddle.accentColor),
                              ],
                            ),
                            BouncyButton(
                              onTap: isUnlocked ? () => state.selectPaddle(activePaddle) : () {},
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: !isUnlocked
                                      ? Colors.white12
                                      : isEquipped
                                          ? AppTheme.glassFill
                                          : activePaddle.accentColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isEquipped ? AppTheme.glassBorder : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    !isUnlocked
                                        ? 'LOCKED (REQUIRES LEVEL ${activePaddle.unlockLevel})'
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
}