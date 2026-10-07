// lib/screens/gameplay/gameplay_screen.dart

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../widgets/asset_helpers.dart';
import '../multiplayer/widgets/post_match_summary_overlay.dart';
import '../multiplayer/widgets/quick_chat_overlay.dart';
import 'gameplay_controller.dart';
import 'gameplay_intro_overlay.dart';
import 'gameplay_models.dart';
import 'physics/court_physics_engine.dart';
import 'physics/tactical_ai_controller.dart';
import 'rendering/perspective_court_painter.dart';
import 'widgets/gameplay_controls.dart';
import 'widgets/gameplay_hud.dart';
import 'widgets/pc_controller_override.dart';

export 'gameplay_models.dart';

class CourtGameplayScreen extends StatefulWidget {
  const CourtGameplayScreen({super.key});

  @override
  State<CourtGameplayScreen> createState() => _CourtGameplayScreenState();
}

class _CourtGameplayScreenState extends State<CourtGameplayScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _gameTime = 0.0;
  double _cameraTrauma = 0.0;
  Offset _shakeOffset = Offset.zero;

  bool _isPaused = false;
  final FocusNode _keyboardFocusNode = FocusNode();
  final Set<LogicalKeyboardKey> _activeKeys = {};

  final CourtPhysicsEngine _physics = CourtPhysicsEngine();
  final TacticalAiController _ai = TacticalAiController();
  late final GameplayController _ctrl;
  final Map<String, ui.Image> _sprites = {};

  Offset _joystickKnobOffset = Offset.zero;
  bool _isJoystickActive = false;
  double _joystickInputX = 0.0;
  double _joystickInputY = 0.0;
  static const double _joystickRadius = 46.0;

  double _playerX = 0.38;
  double _playerY = 0.0;
  double _playerVelocityX = 0.0;
  double _playerVelocityY = 0.0;
  double _playerSwingAngle = 0.0;
  bool _playerIsSwinging = false;
  SpriteAction _playerAction = SpriteAction.idle;
  ShotType _playerCurrentShot = ShotType.normal;
  bool _playerIsDiving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = GameplayController(physics: _physics, ai: _ai);
    _ctrl.startMatchIntro();

    _preloadSprites();
    _ticker = createTicker(_onGameTick)..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocusNode.requestFocus();
    });
  }

  Future<void> _preloadSprites() async {
    for (final path in AppAssets.getAllSpritePaths()) {
      if (AppAssetRegistry.hasAsset(path)) {
        try {
          final data = await rootBundle.load(path);
          final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
          final frameInfo = await codec.getNextFrame();
          if (mounted) setState(() => _sprites[path] = frameInfo.image);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _keyboardFocusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _addTrauma(double amount) {
    if (!GameState.instance.screenShakeEnabled) return;
    setState(() => _cameraTrauma = (_cameraTrauma + amount).clamp(0.0, 1.0));
  }

  void _openQuickChatPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickChatPickerSheet(
        onSend: (call) => _ctrl.showQuickChat(call.text),
      ),
    );
  }

  // ==========================================================================
  // PURE KEYBOARD CONTROLS (J, K, L, U) — ZERO MOUSE REQUIRED
  // ==========================================================================
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.keyP) {
        setState(() => _isPaused = !_isPaused);
        return;
      }
      if (_isPaused || _ctrl.phase == MatchPhase.gameOver) return;

      _activeKeys.add(event.logicalKey);

      // Serve Stages (J or Space to Toss/Drive, L to Lob)
      if (_ctrl.phase == MatchPhase.serveTossWait && _ctrl.playerServing) {
        if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyJ) {
          _ctrl.executePlayerToss(playerX: _playerX);
          return;
        }
      } else if (_ctrl.phase == MatchPhase.serveBallInAir && _ctrl.playerServing) {
        if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyJ) {
          _ctrl.strikePlayerServe(
            shotType: ShotType.drive,
            playerX: _playerX,
            joystickX: _joystickInputX,
            onTrauma: _addTrauma,
            onPointEnd: (won, reason) => _ctrl.resolvePoint(
              playerWonRally: won,
              reason: reason,
              onMatchEnd: () => setState(() {}),
              onStartRepositioning: (px, py) => setState(() {}),
            ),
          );
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          _ctrl.strikePlayerServe(
            shotType: ShotType.lob,
            playerX: _playerX,
            joystickX: _joystickInputX,
            onTrauma: _addTrauma,
            onPointEnd: (won, reason) => _ctrl.resolvePoint(
              playerWonRally: won,
              reason: reason,
              onMatchEnd: () => setState(() {}),
              onStartRepositioning: (px, py) => setState(() {}),
            ),
          );
        }
        return;
      }

      // Rally Hits (J = Drive, K = Smash, L = Lob, U/Q = Blitz)
      if (event.logicalKey == LogicalKeyboardKey.keyJ || event.logicalKey == LogicalKeyboardKey.space) {
        _handlePlayerSwing(ShotType.normal);
      } else if (event.logicalKey == LogicalKeyboardKey.keyK || event.logicalKey == LogicalKeyboardKey.shiftLeft) {
        _handlePlayerSwing(ShotType.smash);
      } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        _handlePlayerSwing(ShotType.lob);
      } else if ((event.logicalKey == LogicalKeyboardKey.keyU || event.logicalKey == LogicalKeyboardKey.keyQ) &&
          _ctrl.playerBlitzEnergy >= 1.0) {
        _handlePlayerSwing(ShotType.signatureBlitz);
      }
    } else if (event is KeyUpEvent) {
      _activeKeys.remove(event.logicalKey);
    }
  }

  void _onGameTick(Duration elapsed) {
    if (_isPaused) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    _gameTime += dt;

    setState(() {
      // 1. Cinematic & Countdown Phase Timers
      if (_ctrl.phase == MatchPhase.cinematicSplash) {
        _ctrl.phaseTimer -= dt;
        if (_ctrl.phaseTimer <= 0) {
          _ctrl.phase = MatchPhase.countdown;
          _ctrl.countdownNumber = 3;
          _ctrl.phaseTimer = 0.85;
        }
        return;
      }

      if (_ctrl.phase == MatchPhase.countdown) {
        _ctrl.phaseTimer -= dt;
        if (_ctrl.phaseTimer <= 0) {
          _ctrl.countdownNumber--;
          if (_ctrl.countdownNumber > 0) {
            _ctrl.phaseTimer = 0.85;
          } else {
            _ctrl.completeRepositioning(playerX: _playerX, playerY: _playerY);
          }
        }
        return;
      }

      // 2. Automated Re-Positioning Glide
      if (_ctrl.phase == MatchPhase.repositioning) {
        _ctrl.phaseTimer -= dt;
        _playerX += (_ctrl.targetPlayerBoxX - _playerX) * math.min(1.0, 10.0 * dt);
        _playerY += (0.0 - _playerY) * math.min(1.0, 10.0 * dt);
        _ai.x += (_ctrl.targetAiBoxX - _ai.x) * math.min(1.0, 10.0 * dt);
        _ai.y += (0.92 - _ai.y) * math.min(1.0, 10.0 * dt);

        if (_ctrl.phaseTimer <= 0) {
          _ctrl.completeRepositioning(playerX: _playerX, playerY: _playerY);
        }
        return;
      }

      // 3. Match Timers
      if (_ctrl.phase == MatchPhase.activeRally) {
        _ctrl.matchTimeRemaining = math.max(0.0, _ctrl.matchTimeRemaining - dt);
      }
      if (_ctrl.driveCooldown > 0) _ctrl.driveCooldown = math.max(0.0, _ctrl.driveCooldown - dt);
      if (_ctrl.smashCooldown > 0) _ctrl.smashCooldown = math.max(0.0, _ctrl.smashCooldown - dt);
      if (_ctrl.lobCooldown > 0) _ctrl.lobCooldown = math.max(0.0, _ctrl.lobCooldown - dt);
      if (_ctrl.feedbackTimer > 0) _ctrl.feedbackTimer -= dt;
      if (_ctrl.pointToastTimer > 0) _ctrl.pointToastTimer -= dt;
      if (_ctrl.quickChatTimer > 0) {
        _ctrl.quickChatTimer -= dt;
        if (_ctrl.quickChatTimer <= 0) _ctrl.activeQuickChat = null;
      }

      if (_cameraTrauma > 0) {
        _cameraTrauma = math.max(0.0, _cameraTrauma - dt * 2.8);
        final intensity = _cameraTrauma * _cameraTrauma;
        final rng = math.Random();
        _shakeOffset = Offset((rng.nextDouble() * 2 - 1) * 14 * intensity, (rng.nextDouble() * 2 - 1) * 14 * intensity);
      } else {
        _shakeOffset = Offset.zero;
      }

      _physics.updateVisualParticles(dt);

      // 4. Ball Position in Serve States
      if (_ctrl.phase == MatchPhase.serveTossWait) {
        if (_ctrl.playerServing) {
          _physics.ballX = _playerX + 0.10;
          _physics.ballY = _playerY + 0.04;
          _physics.ballZ = 0.65;
        }
      } else if (_ctrl.phase == MatchPhase.serveBallInAir && _ctrl.playerServing) {
        _ctrl.serveTossVz -= 3.6 * dt;
        _physics.ballZ += _ctrl.serveTossVz * dt;
        final ratio = ((_physics.ballZ - 0.70) / (1.55 - 0.70)).clamp(0.0, 1.0);
        _ctrl.reticleScale = (1.0 - ratio).clamp(0.0, 1.0);

        if (_ctrl.reticleScale < 0.25 && !_ctrl.sweetSpotAudioPlayed) {
          _ctrl.sweetSpotAudioPlayed = true;
          AppAudio.playFeatureSfx(AppAssets.sfxReticleLock);
        }
        if (_physics.ballZ <= 0.08) {
          _ctrl.resolvePoint(
            playerWonRally: false,
            reason: 'SERVICE FAULT',
            onMatchEnd: () => setState(() {}),
            onStartRepositioning: (px, py) => setState(() {}),
          );
          return;
        }
      }

      // 5. Zero-Drift Instant-Braking Movement
      double targetVelX = 0.0;
      double targetVelY = 0.0;
      bool hasInput = false;

      if (_isJoystickActive && _ctrl.phase != MatchPhase.gameOver && !_isPaused) {
        targetVelX = _joystickInputX * 1.65;
        targetVelY = _joystickInputY * 1.05;
        hasInput = true;
      }

      if (_activeKeys.contains(LogicalKeyboardKey.keyA) || _activeKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        targetVelX -= 1.60;
        hasInput = true;
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyD) || _activeKeys.contains(LogicalKeyboardKey.arrowRight)) {
        targetVelX += 1.60;
        hasInput = true;
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyW) || _activeKeys.contains(LogicalKeyboardKey.arrowUp)) {
        targetVelY += 1.05;
        hasInput = true;
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyS) || _activeKeys.contains(LogicalKeyboardKey.arrowDown)) {
        targetVelY -= 1.05;
        hasInput = true;
      }

      if (hasInput) {
        _playerVelocityX += (targetVelX - _playerVelocityX) * math.min(1.0, 14.0 * dt);
        _playerVelocityY += (targetVelY - _playerVelocityY) * math.min(1.0, 14.0 * dt);
      } else {
        _playerVelocityX = 0.0;
        _playerVelocityY = 0.0;
      }

      _playerX = (_playerX + _playerVelocityX * dt).clamp(-0.95, 0.95);
      _playerY = (_playerY + _playerVelocityY * dt).clamp(-0.18, 0.34);

      if (_playerIsSwinging) {
        _playerSwingAngle += 14.0 * dt;
        if (_playerSwingAngle >= math.pi) {
          _playerSwingAngle = 0.0;
          _playerIsSwinging = false;
          _playerIsDiving = false;
        }
      }

      if (_playerIsSwinging) {
        _playerAction = SpriteAction.hit;
      } else if (_ctrl.phase == MatchPhase.serveTossWait || _ctrl.phase == MatchPhase.serveBallInAir) {
        _playerAction = _ctrl.phase == MatchPhase.serveBallInAir ? SpriteAction.serve : SpriteAction.idle;
      } else if (_playerY >= 0.28) {
        _playerAction = SpriteAction.defend;
      } else if (_playerVelocityX.abs() > 0.2 || _playerVelocityY.abs() > 0.2) {
        _playerAction = SpriteAction.walk;
      } else {
        _playerAction = SpriteAction.idle;
      }

      if (_ctrl.phase != MatchPhase.activeRally) return;

      // 6. Ball Flight Simulation
      _physics.updateBallFlight(
        dt: dt,
        currentTime: _gameTime,
        onPointEnded: (playerWon, reason) => _ctrl.resolvePoint(
          playerWonRally: playerWon,
          reason: reason,
          onMatchEnd: () => setState(() {}),
          onStartRepositioning: (px, py) => setState(() {}),
        ),
        onBallBounce: () => AppAudio.playFeatureSfx(AppAssets.sfxBallBounce),
        onNetFault: () => AppAudio.playFeatureSfx(AppAssets.sfxNetCord),
        onOutOfBounds: () => AppAudio.playFeatureSfx(AppAssets.sfxOutOfBounds),
      );

      // 7. Tactical AI Loop (Reliable Intercept & Return)
      _ai.updatePosition(
        dt: dt,
        ballX: _physics.ballX,
        ballY: _physics.ballY,
        ballZ: _physics.ballZ,
        ballVx: _physics.ballVx,
        ballVy: _physics.ballVy,
        aiChar: GameState.instance.opponentCharacter,
        difficulty: GameState.instance.difficulty,
        currentRally: _ctrl.currentRally,
        playerY: _playerY,
      );

      final bool aiWaitingServe = _ctrl.playerServing && _physics.bouncesThisRally < 1;
      if (!aiWaitingServe) {
        final distToAiX = (_physics.ballX - _ai.x).abs();
        final inReachX = distToAiX <= (0.30 * GameState.instance.opponentCharacter.reachFactor);
        final inReachY = (_physics.ballY >= _ai.y - 0.18) && (_physics.ballY <= _ai.y + 0.12);
        final inReachZ = _physics.ballZ >= 0.05 && _physics.ballZ <= 2.10;

        if (_physics.ballVy > 0 && inReachX && inReachY && inReachZ) {
          _ctrl.executeAiReturn(
            onTrauma: _addTrauma,
            onAiSwing: () {
              _ai.isSwinging = true;
              _ai.swingAngle = 0.1;
            },
          );
        }
      }
    });
  }

  // ==========================================================================
  // FAIR, CALIBRATED PLAYER HITBOX (NATURAL HUMAN TIMING)
  // ==========================================================================
  void _handlePlayerSwing(ShotType type) {
    if (_isPaused || _ctrl.phase == MatchPhase.gameOver) return;

    if (type == ShotType.normal && _ctrl.driveCooldown > 0) return;
    if (type == ShotType.smash && _ctrl.smashCooldown > 0) return;
    if (type == ShotType.lob && _ctrl.lobCooldown > 0) return;

    if (type == ShotType.normal) _ctrl.driveCooldown = GameplayController.kMaxDriveCooldown;
    if (type == ShotType.smash) _ctrl.smashCooldown = GameplayController.kMaxSmashCooldown;
    if (type == ShotType.lob) _ctrl.lobCooldown = GameplayController.kMaxLobCooldown;

    final char = GameState.instance.selectedCharacter;
    final isForehand = _physics.ballX >= _playerX;
    final paddleX = _playerX + (isForehand ? 0.09 : -0.09);
    final paddleY = _playerY + 0.03;

    // Calibrated natural reach boundaries
    final distX = (_physics.ballX - paddleX).abs();
    final inReachX = distX <= (0.24 * char.reachFactor);
    final distY = (_physics.ballY - paddleY).abs();
    final inReachY = distY <= 0.16; // Generous 16cm timing window
    final inHeight = _physics.ballZ >= 0.05 && _physics.ballZ <= 1.95;

    _playerCurrentShot = type;
    _playerIsSwinging = true;
    _playerSwingAngle = 0.1;

    if (inReachX && inReachY && inHeight && _physics.ballVy < 0) {
      if (!_ctrl.playerServing && _physics.bouncesThisRally < 1 && _physics.ballZ > 0.25) {
        _ctrl.resolvePoint(
          playerWonRally: false,
          reason: 'TWO-BOUNCE FAULT',
          onMatchEnd: () => setState(() {}),
          onStartRepositioning: (px, py) => setState(() {}),
        );
        return;
      }

      final isSmash = type == ShotType.smash || type == ShotType.signatureBlitz;
      _ctrl.playerBlitzEnergy = (_ctrl.playerBlitzEnergy + 0.22).clamp(0.0, 1.0);

      if (_physics.ballY >= 0.25) _ctrl.totalDinks++;

      _physics.ballVy = (isSmash ? 0.95 : 0.74) * GameState.instance.effectivePaddlePower;
      _physics.ballVz = math.max(1.80, (0.58 - _physics.ballZ + 0.5 * 4.15 * 0.2) / 0.45);
      _physics.ballVx = (_joystickInputX.abs() > 0.18 ? _joystickInputX * 0.70 : 0.0) - (_physics.ballX * 0.4);

      _physics.spawnHitSparks(paddleX, paddleY, _physics.ballZ, isSmash ? AppColors.electricCoral : AppColors.opticYellow);
      _ctrl.currentRally++;
      if (_ctrl.currentRally > _ctrl.longestRally) _ctrl.longestRally = _ctrl.currentRally;
      _ai.onPlayerHitBall(difficulty: GameState.instance.difficulty, ballVx: _physics.ballVx);
      AppAudio.playFeatureSfx(isSmash ? AppAssets.sfxPaddleSmash : AppAssets.sfxPaddleDrive);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        top: false,
        bottom: true,
        left: true,
        right: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

            return KeyboardListener(
              focusNode: _keyboardFocusNode,
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. 2.5D Court Projection Engine
                  Positioned.fill(
                    child: Transform.translate(
                      offset: _shakeOffset,
                      child: CustomPaint(
                        size: screenSize,
                        painter: PerspectiveCourtPainter(
                          playerX: _playerX,
                          playerY: _playerY,
                          playerVelocityX: _playerVelocityX,
                          playerVelocityY: _playerVelocityY,
                          playerSwingAngle: _playerSwingAngle,
                          playerIsSwinging: _playerIsSwinging,
                          playerColor: state.selectedCharacter.bodyColor,
                          playerAccent: state.selectedCharacter.accentColor,
                          playerCharId: state.selectedCharacter.id,
                          playerAction: _playerAction,
                          playerShotType: _playerCurrentShot,
                          playerIsDiving: _playerIsDiving,
                          aiX: _ai.x,
                          aiY: _ai.y,
                          aiVelocityX: _ai.velocityX,
                          aiVelocityY: _ai.velocityY,
                          aiSwingAngle: _ai.swingAngle,
                          aiIsSwinging: _ai.isSwinging,
                          aiColor: state.opponentCharacter.bodyColor,
                          aiAccent: state.opponentCharacter.accentColor,
                          aiCharId: state.opponentCharacter.id,
                          aiAction: _ai.action,
                          aiShotType: _ai.currentShot,
                          aiIsDiving: false,
                          ballX: _physics.ballX,
                          ballY: _physics.ballY,
                          ballZ: _physics.ballZ,
                          ballVx: _physics.ballVx,
                          ballVy: _physics.ballVy,
                          ballVz: _physics.ballVz,
                          ballCurve: _physics.ballCurve,
                          ballRotationAngle: _physics.ballRotationAngle,
                          smoothTrail: _physics.smoothTrail,
                          physics: _physics,
                          particles: _physics.particles,
                          shockwaves: _physics.shockwaves,
                          blitzActive: _ctrl.blitzActive,
                          blitzColor: AppColors.opticYellow,
                          equippedPaddle: state.selectedPaddle,
                          courtVenue: state.courtVenue,
                          sprites: _sprites,
                          isLandscape: isLandscape,
                          isServing: _ctrl.phase == MatchPhase.serveBallInAir,
                          reticleScale: _ctrl.reticleScale,
                          gameTime: _gameTime,
                        ),
                      ),
                    ),
                  ),

                  // 2. Scoreboard & Quick-Chat Button
                  if (_ctrl.phase != MatchPhase.cinematicSplash)
                    Positioned(
                      top: 8,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: GameplayScoreboard(
                            state: state,
                            opponentChar: state.opponentCharacter,
                            playerScore: _ctrl.playerScore,
                            aiScore: _ctrl.aiScore,
                            matchTimeRemaining: _ctrl.matchTimeRemaining,
                            onPause: () => setState(() => _isPaused = !_isPaused),
                            onOpenChat: () => _openQuickChatPicker(context),
                          ),
                        ),
                      ),
                    ),

                  // 3. Floating Quick-Chat Speech Bubble
                  if (_ctrl.activeQuickChat != null)
                    Positioned(
                      bottom: isLandscape ? 120 : 180,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: QuickChatBubble(text: _ctrl.activeQuickChat!),
                      ),
                    ),

                  // 4. Fast Non-Intrusive Point Toast
                  if (_ctrl.pointToastTimer > 0)
                    Positioned(
                      top: 64,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1B26),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.opticYellow, width: 1.5),
                          ),
                          child: Text(
                            _ctrl.pointToastText,
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.opticYellow, fontSize: 12),
                          ),
                        ),
                      ),
                    ),

                  // 5. Responsive Controls: Mobile Touch vs. Pure-Keyboard PC
                  if (_ctrl.phase != MatchPhase.cinematicSplash && _ctrl.phase != MatchPhase.countdown) ...[
                    if (PlatformInputManager.shouldShowTouchControls) ...[
                      Positioned(
                        bottom: 18,
                        left: 20,
                        child: VirtualJoystickWidget(
                          knobOffset: _joystickKnobOffset,
                          radius: _joystickRadius,
                          onStart: () => setState(() => _isJoystickActive = true),
                          onUpdate: (delta) {
                            final local = _joystickKnobOffset + delta;
                            final clamped = local.distance > _joystickRadius
                                ? Offset.fromDirection(local.direction, _joystickRadius)
                                : local;
                            setState(() {
                              _joystickKnobOffset = clamped;
                              _joystickInputX = math.cos(clamped.direction) * (clamped.distance / _joystickRadius);
                              _joystickInputY = -math.sin(clamped.direction) * (clamped.distance / _joystickRadius);
                            });
                          },
                          onEnd: () => setState(() {
                            _isJoystickActive = false;
                            _joystickKnobOffset = Offset.zero;
                            _joystickInputX = 0;
                            _joystickInputY = 0;
                          }),
                        ),
                      ),
                      Positioned(
                        bottom: 18,
                        right: 20,
                        child: GameplayActionCluster(
                          phase: _ctrl.phase,
                          playerServing: _ctrl.playerServing,
                          blitzEnergy: _ctrl.playerBlitzEnergy,
                          driveCooldown: _ctrl.driveCooldown / GameplayController.kMaxDriveCooldown,
                          smashCooldown: _ctrl.smashCooldown / GameplayController.kMaxSmashCooldown,
                          lobCooldown: _ctrl.lobCooldown / GameplayController.kMaxLobCooldown,
                          isLandscape: isLandscape,
                          onToss: () => _ctrl.executePlayerToss(playerX: _playerX),
                          onDriveServe: () => _ctrl.strikePlayerServe(
                            shotType: ShotType.drive,
                            playerX: _playerX,
                            joystickX: _joystickInputX,
                            onTrauma: _addTrauma,
                            onPointEnd: (won, reason) => _ctrl.resolvePoint(
                              playerWonRally: won,
                              reason: reason,
                              onMatchEnd: () => setState(() {}),
                              onStartRepositioning: (px, py) => setState(() {}),
                            ),
                          ),
                          onLobServe: () => _ctrl.strikePlayerServe(
                            shotType: ShotType.lob,
                            playerX: _playerX,
                            joystickX: _joystickInputX,
                            onTrauma: _addTrauma,
                            onPointEnd: (won, reason) => _ctrl.resolvePoint(
                              playerWonRally: won,
                              reason: reason,
                              onMatchEnd: () => setState(() {}),
                              onStartRepositioning: (px, py) => setState(() {}),
                            ),
                          ),
                          onSwing: _handlePlayerSwing,
                          onBlitzNotReady: () => _ctrl.setFeedback('⚡ BLITZ CHARGING...', AppColors.opticYellow),
                        ),
                      ),
                    ] else ...[
                      // PURE KEYBOARD PC HUD (NO MOUSE RIGHT CLICK)
                      PcKeyHintsOverlay(
                        phase: _ctrl.phase,
                        playerServing: _ctrl.playerServing,
                        blitzEnergy: _ctrl.playerBlitzEnergy,
                      ),
                    ],
                  ],

                  // 6. Cinematic Intro & 3-2-1 Countdown Overlay
                  if (_ctrl.phase == MatchPhase.cinematicSplash || _ctrl.phase == MatchPhase.countdown)
                    Positioned.fill(
                      child: GameplayIntroOverlay(
                        phase: _ctrl.phase,
                        countdownNumber: _ctrl.countdownNumber,
                        playerChar: state.selectedCharacter,
                        opponentChar: state.opponentCharacter,
                        venueName: state.courtVenue,
                        difficulty: state.difficulty,
                      ),
                    ),

                  if (_isPaused)
                    Positioned.fill(
                      child: PauseMenuOverlay(
                        onResume: () => setState(() => _isPaused = false),
                        onForfeit: () => Navigator.pop(context),
                      ),
                    ),

                  if (_ctrl.phase == MatchPhase.gameOver && _ctrl.matchSummaryStats != null)
                    Positioned.fill(
                      child: PostMatchSummaryOverlay(
                        stats: _ctrl.matchSummaryStats!,
                        onDismiss: () => Navigator.pop(context),
                        onPaddleTap: () {
                          GameState.instance.addGoldCoins(25);
                          AppAudio.playFeatureSfx(AppAssets.sfxPointCheer);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}