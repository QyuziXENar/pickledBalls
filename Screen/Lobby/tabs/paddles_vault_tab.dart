// lib/Screen/Lobby/tabs/paddles_vault_tab.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_state.dart';
import '../../../widgets/asset_helpers.dart';
import '../../../widgets/game_components.dart';

class PaddlesVaultTab extends StatefulWidget {
  final GameState state;

  const PaddlesVaultTab({super.key, required this.state});

  @override
  State<PaddlesVaultTab> createState() => _PaddlesVaultTabState();
}

class _PaddlesVaultTabState extends State<PaddlesVaultTab> {
  PaddleModel? _previewPaddle;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final activePaddle = _previewPaddle ?? state.selectedPaddle;
    final isEquipped = state.selectedPaddle.id == activePaddle.id;
    final isUnlocked = state.playerLevel >= activePaddle.unlockLevel && !activePaddle.isPrototype;
    final alloc = state.getAllocation(activePaddle.id);

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
                  child: SingleChildScrollView(child: _buildInspectorCard(state, activePaddle, isEquipped, isUnlocked, alloc)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCollectionHeader(),
                      const SizedBox(height: 6),
                      Expanded(child: _buildPaddlesGrid(state, activePaddle)),
                    ],
                  ),
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
            _buildInspectorCard(state, activePaddle, isEquipped, isUnlocked, alloc),
            _buildCollectionHeader(),
            Expanded(child: _buildPaddlesGrid(state, activePaddle)),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectorCard(GameState state, PaddleModel activePaddle, bool isEquipped, bool isUnlocked, PaddleStatAllocation alloc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1829),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: activePaddle.isPrototype ? Colors.white24 : activePaddle.accentColor.withValues(alpha: 0.7),
          width: 1.8,
        ),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activePaddle.isPrototype ? Colors.white10 : activePaddle.primaryColor.withValues(alpha: 0.25),
                          ),
                        ),
                        PaddleGraphic(paddle: activePaddle, width: 48, height: 72, glow: isUnlocked),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(activePaddle.isPrototype ? 'v3.1 TECH' : 'LVL. ${activePaddle.level}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activePaddle.name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text(activePaddle.brand, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: activePaddle.accentColor)),
                    const SizedBox(height: 3),
                    _compactStatRow('SPIN', activePaddle.statSpin + alloc.spin, 30, () => state.allocateUpgradePoint(activePaddle.id, 'spin')),
                    _compactStatRow('SWING', activePaddle.statSwing + alloc.power, 30, () => state.allocateUpgradePoint(activePaddle.id, 'power')),
                    _compactStatRow('AGILITY', activePaddle.statAgility + alloc.agility, 30, () => state.allocateUpgradePoint(activePaddle.id, 'agility')),
                    _compactStatRow('ACCURACY', activePaddle.statAccuracy + alloc.control, 30, () => state.allocateUpgradePoint(activePaddle.id, 'control')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isUnlocked
                      ? () {
                          state.selectPaddle(activePaddle);
                          AppAudio.playFeatureSfx(AppAssets.sfxPaddleEquip);
                          setState(() {});
                        }
                      : null,
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: !isUnlocked ? Colors.white12 : isEquipped ? AppColors.glassFill : AppColors.opticYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isEquipped ? AppColors.glassBorder : Colors.transparent),
                    ),
                    child: Center(
                      child: Text(
                        activePaddle.isPrototype ? 'PROTOTYPE' : !isUnlocked ? 'LOCKED (LV. ${activePaddle.unlockLevel})' : isEquipped ? 'EQUIPPED' : 'EQUIP PADDLE',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: !isUnlocked ? Colors.white38 : isEquipped ? Colors.white70 : Colors.black),
                      ),
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

  Widget _buildCollectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('PADDLE COLLECTION (${kPaddles.length})', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0)),
          const Text('TAP TO INSPECT', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildPaddlesGrid(GameState state, PaddleModel activePaddle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.80,
        ),
        itemCount: kPaddles.length,
        itemBuilder: (context, index) {
          final paddle = kPaddles[index];
          final isEq = state.selectedPaddle.id == paddle.id;
          final isInspected = activePaddle.id == paddle.id;

          return GestureDetector(
            onTap: () {
              AppAudio.playFeatureSfx(AppAssets.sfxCardTap);
              setState(() => _previewPaddle = paddle);
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131B26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isEq ? AppColors.opticYellow : isInspected ? Colors.white : Colors.white12, width: isEq || isInspected ? 1.8 : 1.0),
              ),
              child: Center(child: PaddleGraphic(paddle: paddle, width: 42, height: 64)),
            ),
          );
        },
      ),
    );
  }

  Widget _compactStatRow(String label, int value, int max, VoidCallback? onBoost) {
    final fill = (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text(label, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white70))),
          Expanded(
            child: Stack(
              children: [
                Container(height: 4, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(2))),
                FractionallySizedBox(widthFactor: fill, child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(2)))),
              ],
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(width: 12, child: Text('$value', textAlign: TextAlign.end, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white))),
          if (onBoost != null) ...[
            const SizedBox(width: 3),
            GestureDetector(
              onTap: onBoost,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(color: AppColors.upgradePoint, shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 8, color: Colors.black),
              ),
            ),
          ],
        ],
      ),
    );
  }
}