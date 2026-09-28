// lib/screens/lobby/tabs/athlete_roster_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_state.dart';
import '../../../widgets/ambient_background.dart';
import '../../../widgets/asset_helpers.dart';
import '../../../widgets/game_components.dart';

class AthleteRosterTab extends StatefulWidget {
  final GameState state;

  const AthleteRosterTab({super.key, required this.state});

  @override
  State<AthleteRosterTab> createState() => _AthleteRosterTabState();
}

class _AthleteRosterTabState extends State<AthleteRosterTab> {
  late PageController _athletePageController;
  int _currentAthleteIndex = 0;

  @override
  void initState() {
    super.initState();
    final initialCharIdx = kCharacters.indexWhere(
      (c) => c.id == widget.state.selectedCharacter.id,
    );
    _currentAthleteIndex = initialCharIdx >= 0 ? initialCharIdx : 0;
    _athletePageController = PageController(
      viewportFraction: 0.55,
      initialPage: _currentAthleteIndex,
    );
  }

  @override
  void dispose() {
    _athletePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final activeChar = kCharacters[_currentAthleteIndex];
    final isEquipped = state.selectedCharacter.id == activeChar.id;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ATHLETE ROSTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  Text('${_currentAthleteIndex + 1} OF ${kCharacters.length}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _athletePageController,
                    itemCount: kCharacters.length,
                    onPageChanged: (idx) {
                      setState(() => _currentAthleteIndex = idx);
                      AppAudio.play(context, AppAssets.sfxSwipe, 'Athlete Slide');
                      if (state.hapticsEnabled) {
                        HapticFeedback.selectionClick();
                      }
                    },
                    itemBuilder: (ctx, i) {
                      final character = kCharacters[i];
                      final isSelected = i == _currentAthleteIndex;

                      return AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: isSelected ? 1.0 : 0.78,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: isSelected ? 1.0 : 0.45,
                          child: Center(
                            child: _buildAthletePreviewRig(character, state.selectedPaddle, isSelected),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 4,
                    child: GestureDetector(
                      onTap: () {
                        if (_currentAthleteIndex > 0) {
                          _athletePageController.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                        child: Icon(Icons.chevron_left_rounded, color: _currentAthleteIndex > 0 ? Colors.white : Colors.white24, size: 24),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        if (_currentAthleteIndex < kCharacters.length - 1) {
                          _athletePageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                        child: Icon(Icons.chevron_right_rounded, color: _currentAthleteIndex < kCharacters.length - 1 ? Colors.white : Colors.white24, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(kCharacters.length, (idx) {
                  final char = kCharacters[idx];
                  final isSelected = idx == _currentAthleteIndex;

                  return GestureDetector(
                    onTap: () {
                      _athletePageController.animateToPage(idx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: EdgeInsets.symmetric(horizontal: isSelected ? 10 : 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? char.bodyColor : AppColors.glassFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? char.accentColor : Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 3.5, backgroundColor: isSelected ? Colors.white : char.bodyColor),
                          if (isSelected) ...[
                            const SizedBox(width: 5),
                            Text(char.name.split(' ')[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
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
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1B16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${activeChar.gender.toUpperCase()} • ${activeChar.archetype.toUpperCase()}',
                          style: TextStyle(color: activeChar.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.8),
                        ),
                        const SizedBox(height: 2),
                        Text(activeChar.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        Text(activeChar.perkDescription, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    Column(
                      children: [
                        StatBar(label: 'Sprint Speed', value: (activeChar.moveSpeed / 1.5).clamp(0.0, 1.0), color: activeChar.accentColor),
                        const SizedBox(height: 5),
                        StatBar(label: 'Swing Power', value: (activeChar.swingPower / 1.5).clamp(0.0, 1.0), color: activeChar.accentColor),
                        const SizedBox(height: 5),
                        StatBar(label: 'Strike Reach', value: (activeChar.reachFactor / 1.4).clamp(0.0, 1.0), color: activeChar.accentColor),
                      ],
                    ),
                    BouncyButton(
                      onTap: () {
                        state.selectCharacter(activeChar);
                        AppAudio.play(context, AppAssets.sfxCharacterSelect, 'Athlete Chosen');
                      },
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isEquipped ? AppColors.glassFill : activeChar.accentColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isEquipped ? AppColors.glassBorder : Colors.transparent),
                        ),
                        child: Center(
                          child: Text(
                            isEquipped ? 'CURRENTLY EQUIPPED' : 'EQUIP ATHLETE',
                            style: TextStyle(color: isEquipped ? Colors.white70 : Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthletePreviewRig(CharacterModel character, PaddleModel paddle, bool glow) {
    return Container(
      width: 150,
      height: 200,
      decoration: BoxDecoration(
        boxShadow: glow
            ? [BoxShadow(color: character.bodyColor.withValues(alpha: 0.35), blurRadius: 32, spreadRadius: 3)]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 14,
            child: Container(
              width: 90,
              height: 20,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
            ),
          ),
          Positioned(
            top: 15,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildAthleteVisual(character),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1B16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: character.accentColor, width: 1.0),
                    ),
                    child: Text(character.archetype.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: character.accentColor)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 4,
            bottom: 30,
            child: Transform.rotate(
              angle: 0.25,
              child: PaddleGraphic(paddle: paddle, width: 44, height: 62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteVisual(CharacterModel character) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: character.bodyColor,
        border: Border.all(color: character.accentColor, width: 3),
      ),
      child: Center(
        child: Text(
          character.name[0],
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}