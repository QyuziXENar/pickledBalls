// lib/Screen/Lobby/tabs/athlete_roster_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_state.dart';
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
    final initialCharIdx = kCharacters.indexWhere((c) => c.id == widget.state.selectedCharacter.id);
    _currentAthleteIndex = initialCharIdx >= 0 ? initialCharIdx : 0;
    _athletePageController = PageController(viewportFraction: 0.55, initialPage: _currentAthleteIndex);
  }

  @override
  void dispose() {
    _athletePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final activeChar = kCharacters[_currentAthleteIndex];
    final isEquipped = state.selectedCharacter.id == activeChar.id;

    if (isLandscape) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildHeaderRow(),
                      Expanded(child: _buildAthleteCarousel(state)),
                      _buildDotsRow(),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(child: _buildStatsCard(activeChar, isEquipped, state)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            _buildHeaderRow(),
            Expanded(flex: 5, child: _buildAthleteCarousel(state)),
            _buildDotsRow(),
            Expanded(flex: 4, child: _buildStatsCard(activeChar, isEquipped, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('ATHLETE ROSTER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          Text('${_currentAthleteIndex + 1} OF ${kCharacters.length}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAthleteCarousel(GameState state) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          controller: _athletePageController,
          itemCount: kCharacters.length,
          onPageChanged: (idx) {
            setState(() => _currentAthleteIndex = idx);
            AppAudio.playFeatureSfx(AppAssets.sfxSwipe);
            if (state.hapticsEnabled) HapticFeedback.selectionClick();
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
              if (_currentAthleteIndex > 0) _athletePageController.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
              child: Icon(Icons.chevron_left_rounded, color: _currentAthleteIndex > 0 ? Colors.white : Colors.white24, size: 22),
            ),
          ),
        ),
        Positioned(
          right: 4,
          child: GestureDetector(
            onTap: () {
              if (_currentAthleteIndex < kCharacters.length - 1) _athletePageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
              child: Icon(Icons.chevron_right_rounded, color: _currentAthleteIndex < kCharacters.length - 1 ? Colors.white : Colors.white24, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDotsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(kCharacters.length, (idx) {
          final char = kCharacters[idx];
          final isSelected = idx == _currentAthleteIndex;

          return GestureDetector(
            onTap: () => _athletePageController.animateToPage(idx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 8 : 5, vertical: 2.5),
              decoration: BoxDecoration(
                color: isSelected ? char.bodyColor : AppColors.glassFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? char.accentColor : Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3, backgroundColor: isSelected ? Colors.white : char.bodyColor),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    Text(char.name.split(' ')[0], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsCard(CharacterModel activeChar, bool isEquipped, GameState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF0F1B16), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.glassBorder)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${activeChar.gender.toUpperCase()} • ${activeChar.archetype.toUpperCase()}', style: TextStyle(color: activeChar.accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 2),
          Text(activeChar.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          Text(activeChar.perkDescription, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          StatBar(label: 'Sprint Speed', value: (activeChar.moveSpeed / 1.5).clamp(0.0, 1.0), color: activeChar.accentColor),
          const SizedBox(height: 4),
          StatBar(label: 'Swing Power', value: (activeChar.swingPower / 1.5).clamp(0.0, 1.0), color: activeChar.accentColor),
          const SizedBox(height: 4),
          StatBar(label: 'Strike Reach', value: (activeChar.reachFactor / 1.4).clamp(0.0, 1.0), color: activeChar.accentColor),
          const SizedBox(height: 8),
          BouncyButton(
            onTap: () {
              state.selectCharacter(activeChar);
              AppAudio.playFeatureSfx(AppAssets.sfxCharacterSelect);
            },
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: isEquipped ? AppColors.glassFill : activeChar.accentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isEquipped ? AppColors.glassBorder : Colors.transparent),
              ),
              child: Center(
                child: Text(
                  isEquipped ? 'CURRENTLY EQUIPPED' : 'EQUIP ATHLETE',
                  style: TextStyle(color: isEquipped ? Colors.white70 : Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthletePreviewRig(CharacterModel character, PaddleModel paddle, bool glow) {
    return Container(
      width: 140,
      height: 180,
      decoration: BoxDecoration(
        boxShadow: glow ? [BoxShadow(color: character.bodyColor.withValues(alpha: 0.35), blurRadius: 28, spreadRadius: 2)] : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 12,
            child: Container(width: 80, height: 18, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54)),
          ),
          Positioned(
            top: 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: character.bodyColor, border: Border.all(color: character.accentColor, width: 2.5)),
                  child: Center(child: Text(character.name[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(color: const Color(0xFF0F1B16), borderRadius: BorderRadius.circular(6), border: Border.all(color: character.accentColor, width: 1.0)),
                    child: Text(character.archetype.toUpperCase(), style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: character.accentColor)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 4,
            bottom: 24,
            child: Transform.rotate(angle: 0.25, child: PaddleGraphic(paddle: paddle, width: 38, height: 54)),
          ),
        ],
      ),
    );
  }
}