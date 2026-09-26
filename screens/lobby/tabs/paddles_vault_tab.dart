// lib/screens/lobby/tabs/paddles_vault_tab.dart

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
    final activePaddle = _previewPaddle ?? state.selectedPaddle;
    final isEquipped = state.selectedPaddle.id == activePaddle.id;
    final isUnlocked = state.playerLevel >= activePaddle.unlockLevel && !activePaddle.isPrototype;
    final alloc = state.getAllocation(activePaddle.id);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1829),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activePaddle.isPrototype
                      ? Colors.white24
                      : activePaddle.accentColor.withValues(alpha: 0.7),
                  width: 2.0,
                ),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
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
                                  width: 75,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: activePaddle.isPrototype
                                        ? Colors.white10
                                        : activePaddle.primaryColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                PaddleGraphic(paddle: activePaddle, width: 56, height: 82, glow: isUnlocked),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activePaddle.isPrototype ? 'v3.1 TECH' : 'LVL. ${activePaddle.level}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: activePaddle.isPrototype ? Colors.white12 : const Color(0xFF0277BD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                activePaddle.isPrototype ? 'CLASSIFIED' : '${activePaddle.cardsCollected}/${activePaddle.cardsNeeded}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: activePaddle.isPrototype
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activePaddle.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white60),
                                  ),
                                  const Text(
                                    'CLASSIFIED PROTOTYPE',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.opticYellow),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.lock_clock_rounded, size: 14, color: AppColors.opticYellow),
                                            SizedBox(width: 6),
                                            Text(
                                              'COMING SOON IN v3.1',
                                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Experimental aero-core blade currently in development at Blitz Labs.',
                                          style: TextStyle(fontSize: 8.5, color: AppColors.textMuted, height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activePaddle.name.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                  Text(
                                    activePaddle.brand,
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: activePaddle.accentColor),
                                  ),
                                  const SizedBox(height: 4),
                                  _compactStatRow('SPIN', activePaddle.statSpin + alloc.spin, 30, () {
                                    state.allocateUpgradePoint(activePaddle.id, 'spin');
                                  }),
                                  _compactStatRow('SWING', activePaddle.statSwing + alloc.power, 30, () {
                                    state.allocateUpgradePoint(activePaddle.id, 'power');
                                  }),
                                  _compactStatRow('AGILITY', activePaddle.statAgility + alloc.agility, 30, () {
                                    state.allocateUpgradePoint(activePaddle.id, 'agility');
                                  }),
                                  _compactStatRow('ACCURACY', activePaddle.statAccuracy + alloc.control, 30, () {
                                    state.allocateUpgradePoint(activePaddle.id, 'control');
                                  }),
                                  _compactStatRow('STAMINA', activePaddle.statStamina, 25, null),
                                  _compactStatRow('POWER', activePaddle.statPower + alloc.power, 30, null),
                                  _compactStatRow('SPEED', activePaddle.statSpeed + alloc.agility, 30, null),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: isUnlocked
                              ? () {
                                  state.selectPaddle(activePaddle);
                                  AppAudio.play(context, AppAssets.sfxPaddleEquip, 'Paddle Equipped Sound');
                                  setState(() {});
                                }
                              : null,
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: !isUnlocked
                                  ? Colors.white12
                                  : isEquipped
                                      ? AppColors.glassFill
                                      : AppColors.opticYellow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isEquipped ? AppColors.glassBorder : Colors.transparent),
                            ),
                            child: Center(
                              child: Text(
                                activePaddle.isPrototype
                                    ? 'PROTOTYPE (COMING SOON IN v3.1)'
                                    : !isUnlocked
                                        ? 'LOCKED (REQUIRES LEVEL ${activePaddle.unlockLevel})'
                                        : isEquipped
                                            ? 'CURRENTLY EQUIPPED'
                                            : 'EQUIP THIS PADDLE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: !isUnlocked
                                      ? Colors.white38
                                      : isEquipped
                                          ? Colors.white70
                                          : Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (alloc.totalAllocated > 0 && !activePaddle.isPrototype) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                          onPressed: () => state.resetPaddleAllocations(activePaddle.id),
                          tooltip: 'Refund UP',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PADDLE COLLECTION (${kPaddles.length})',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.2),
                  ),
                  const Text(
                    'TAP TO INSPECT',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white38),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: kPaddles.length,
                  itemBuilder: (context, index) {
                    final paddle = kPaddles[index];
                    final isEq = state.selectedPaddle.id == paddle.id;
                    final isInspected = activePaddle.id == paddle.id;
                    final isUnl = state.playerLevel >= paddle.unlockLevel && !paddle.isPrototype;

                    return GestureDetector(
                      onTap: () {
                        AppAudio.play(context, AppAssets.sfxCardTap, 'Card Select');
                        setState(() => _previewPaddle = paddle);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: paddle.isPrototype ? const Color(0xFF0A0F14) : const Color(0xFF131B26),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEq
                                ? AppColors.opticYellow
                                : isInspected
                                    ? Colors.white
                                    : paddle.isPrototype
                                        ? Colors.white12
                                        : isUnl
                                            ? const Color(0xFF7B1FA2)
                                            : Colors.white12,
                            width: isEq || isInspected ? 2.2 : 1.2,
                          ),
                          boxShadow: isEq
                              ? [BoxShadow(color: AppColors.opticYellow.withValues(alpha: 0.35), blurRadius: 8)]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: paddle.isPrototype
                                  ? Opacity(
                                      opacity: 0.35,
                                      child: PaddleGraphic(paddle: paddle, width: 48, height: 70),
                                    )
                                  : PaddleGraphic(paddle: paddle, width: 50, height: 74),
                            ),
                            if (isEq)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.opticYellow,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text('USED', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.black)),
                                ),
                              ),
                            if (!isUnl)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        paddle.isPrototype ? Icons.science_rounded : Icons.lock_rounded,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        paddle.isPrototype ? 'v3.1 TECH' : 'LV. ${paddle.unlockLevel}',
                                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppColors.opticYellow),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactStatRow(String label, int value, int max, VoidCallback? onBoost) {
    final fill = (value / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white70)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(height: 5, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: fill,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 14,
            child: Text('$value', textAlign: TextAlign.end, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          if (onBoost != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onBoost,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: AppColors.upgradePoint, shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 9, color: Colors.black),
              ),
            ),
          ],
        ],
      ),
    );
  }
}