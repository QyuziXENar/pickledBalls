// lib/screens/character_selection_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/game_components.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final initial = kCharacters.indexWhere(
      (c) => c.id == GameState.instance.selectedCharacter.id,
    );
    _currentIndex = initial >= 0 ? initial : 0;
    _pageController = PageController(viewportFraction: 0.55, initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameState.instance,
      builder: (context, _) {
        final activeChar = kCharacters[_currentIndex];
        final isEquipped = GameState.instance.selectedCharacter.id == activeChar.id;

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
                        'ATHLETE ROSTER',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                              },
                            ),
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: kCharacters.length,
                              onPageChanged: (idx) {
                                setState(() => _currentIndex = idx);
                                if (GameState.instance.hapticsEnabled) {
                                  HapticFeedback.selectionClick();
                                }
                              },
                              itemBuilder: (ctx, i) {
                                final character = kCharacters[i];
                                final isSelected = i == _currentIndex;

                                return AnimatedScale(
                                  duration: const Duration(milliseconds: 250),
                                  scale: isSelected ? 1.0 : 0.78,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: isSelected ? 1.0 : 0.50,
                                    child: Center(
                                      child: _CharacterRigPreview(
                                        character: character,
                                        paddle: GameState.instance.selectedPaddle,
                                        glow: isSelected,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            left: 8,
                            child: BouncyButton(
                              onTap: () {
                                if (_currentIndex > 0) _goToPage(_currentIndex - 1);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  color: _currentIndex > 0 ? Colors.white : Colors.white24,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            child: BouncyButton(
                              onTap: () {
                                if (_currentIndex < kCharacters.length - 1) {
                                  _goToPage(_currentIndex + 1);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: _currentIndex < kCharacters.length - 1
                                      ? Colors.white
                                      : Colors.white24,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(kCharacters.length, (idx) {
                      final char = kCharacters[idx];
                      final isSelected = idx == _currentIndex;

                      return GestureDetector(
                        onTap: () => _goToPage(idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 12 : 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? char.bodyColor : AppColors.glassFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? char.accentColor : Colors.white12,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: isSelected ? Colors.white : char.bodyColor,
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Text(
                                  char.name.split(' ')[0],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            Column(
                              children: [
                                Text(
                                  '${activeChar.gender.toUpperCase()} • ${activeChar.archetype.toUpperCase()}',
                                  style: TextStyle(
                                    color: activeChar.accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activeChar.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activeChar.perkDescription,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                StatBar(
                                  label: 'Sprint Speed',
                                  value: (activeChar.moveSpeed / 1.5).clamp(0.0, 1.0),
                                  color: activeChar.accentColor,
                                ),
                                const SizedBox(height: 8),
                                StatBar(
                                  label: 'Swing Power',
                                  value: (activeChar.swingPower / 1.5).clamp(0.0, 1.0),
                                  color: activeChar.accentColor,
                                ),
                                const SizedBox(height: 8),
                                StatBar(
                                  label: 'Strike Reach',
                                  value: (activeChar.reachFactor / 1.4).clamp(0.0, 1.0),
                                  color: activeChar.accentColor,
                                ),
                              ],
                            ),
                            BouncyButton(
                              onTap: () {
                                GameState.instance.selectCharacter(activeChar);
                              },
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isEquipped
                                      ? AppColors.glassFill
                                      : activeChar.accentColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isEquipped
                                        ? AppColors.glassBorder
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    isEquipped ? 'CURRENTLY EQUIPPED' : 'EQUIP ATHLETE',
                                    style: TextStyle(
                                      color: isEquipped ? Colors.white70 : Colors.black,
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

class _CharacterRigPreview extends StatelessWidget {
  final CharacterModel character;
  final PaddleModel paddle;
  final bool glow;

  const _CharacterRigPreview({
    required this.character,
    required this.paddle,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 230,
      decoration: BoxDecoration(
        boxShadow: glow
            ? [
                BoxShadow(
                  color: character.bodyColor.withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 16,
            child: Container(
              width: 110,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
            ),
          ),
          Positioned(
            top: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: character.bodyColor,
                    border: Border.all(
                      color: character.accentColor,
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      character.name[0],
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1B16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: character.accentColor, width: 1.2),
                    ),
                    child: Text(
                      character.archetype.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: character.accentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 38,
            child: Transform.rotate(
              angle: 0.25,
              child: PaddleGraphic(
                paddle: paddle,
                width: 48,
                height: 68,
              ),
            ),
          ),
        ],
      ),
    );
  }
}