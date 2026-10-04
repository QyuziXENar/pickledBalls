// lib/screens/gameplay/gameplay_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../services/lan_multiplayer_manager.dart';
import '../../widgets/asset_helpers.dart';
import 'gameplay_logic.dart';
import 'gameplay_models.dart';
import 'physics/court_physics_engine.dart';
import 'physics/tactical_ai_controller.dart';
import 'rendering/perspective_court_painter.dart';
import 'widgets/gameplay_controls.dart';
import 'widgets/gameplay_hud.dart';
import 'widgets/pc_controller_override.dart';

// Re-export models so existing callers have full access
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
  late final GameplayLogic _logic;

  final Map<String, ui.Image> _sprites = {};
  
  // LAN Multiplayer Sync
  final LanMultiplayerManager _lan = LanMultiplayerManager.instance;
  StreamSubscription? _netSub;

  Offset _joystickKnobOffset = Offset.zero;
  bool _isJoystickActive = false;
  double _joystickInputX = 0.0;
  double _joystickInputY = 0.0;
  static const double _joystickRadius = 46.0;
  static const double _joystickDeadzone = 0.06;

  double _playerX = 0.0;
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
    _logic = GameplayLogic(physics: _physics, ai: _ai);
    _logic.startServeSequence(playerX: _playerX, playerY: _playerY);

    if (_lan.isConnected) {
      _netSub = _lan.packetStream.listen(_onNetworkPacket);
      _lan.addListener(_onLanConnectionStateChanged);
    }

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
    _netSub?.cancel();
    _lan.removeListener(_onLanConnectionStateChanged);
    super.dispose();
  }

  void _addTrauma(double amount) {
    if (!GameState.instance.screenShakeEnabled) return;
    setState(() => _cameraTrauma = (_cameraTrauma + amount).clamp(0.0, 1.0));
  }

  // ==========================================================================
  // MULTIPLAYER PACKET HANDLERS
  // ==========================================================================
  void _onLanConnectionStateChanged() {
    if (!mounted) return;
    if (_lan.status != LanStatus.connected) {
      if (_lan.isHost) {
        AppAudio.playFeatureSfx(AppAssets.sfxFaultBuzzer);
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _onNetworkPacket(Map<String, dynamic> packet) {
    if (!mounted) return;
    if (_lan.isHost) {
      if (packet['type'] == 'pos') {
        setState(() {
          _ai.x = -(packet['x'] as num).toDouble();
          _ai.y = 1.0 - (packet['y'] as num).toDouble();
          _ai.isSwinging = packet['swing'] == true;
          if (_ai.isSwinging) _ai.swingAngle = 0.2;
        });
      } else if (packet['type'] == 'hit') {
        setState(() {
          _physics.ballVx = -(packet['vx'] as num).toDouble();
          _physics.ballVy = -(packet['vy'] as num).toDouble();
          _physics.ballVz = (packet['vz'] as num).toDouble();
          _physics.ballCurve = -(packet['curve'] as num).toDouble();
          _ai.currentShot = ShotType.normal;
          _ai.isSwinging = true;
          _ai.swingAngle = 0.1;
        });
        AppAudio.playFeatureSfx(packet['isSmash'] == true ? AppAssets.sfxPaddleSmash : AppAssets.sfxPaddleDrive);
      }
    } else if (_lan.isGuest && packet['type'] == 'tick') {
      setState(() {
        _physics.ballX = -(packet['bx'] as num).toDouble();
        _physics.ballY = 1.0 - (packet['by'] as num).toDouble();
        _physics.ballZ = (packet['bz'] as num).toDouble();
        _physics.ballVx = -(packet['bvx'] as num).toDouble();
        _physics.ballVy = -(packet['bvy'] as num).toDouble();
        _physics.ballVz = (packet['bvz'] as num).toDouble();

        _ai.x = -(packet['p1x'] as num).toDouble();
        _ai.y = 1.0 - (packet['p1y'] as num).toDouble();
        _ai.velocityX = -(packet['p1vx'] as num).toDouble();
        _ai.isSwinging = packet['p1swing'] == true;

        _logic.playerScore = packet['score2'] as int;
        _logic.aiScore = packet['score1'] as int;
        _logic.matchTimeRemaining = (packet['time'] as num?)?.toDouble() ?? _logic.matchTimeRemaining;
      });
    }
  }

  // ==========================================================================
  // TICK ENGINE
  // ==========================================================================
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
      // 1. Tick Cooldowns & Timers
      if (_logic.phase == MatchPhase.activeRally) {
        _logic.matchTimeRemaining = math.max(0.0, _logic.matchTimeRemaining - dt);
      }
      if (_logic.driveCooldown > 0) _logic.driveCooldown = math.max(0.0, _logic.driveCooldown - dt);
      if (_logic.smashCooldown > 0) _logic.smashCooldown = math.max(0.0, _logic.smashCooldown - dt);
      if (_logic.lobCooldown > 0) _logic.lobCooldown = math.max(0.0, _logic.lobCooldown - dt);
      if (_logic.feedbackTimer > 0) _logic.feedbackTimer -= dt;
      if (_logic.pointToastTimer > 0) _logic.pointToastTimer -= dt;

      // 2. Camera Trauma Shake
      if (_cameraTrauma > 0) {
        _cameraTrauma = math.max(0.0, _cameraTrauma - dt * 2.8);
        final intensity = _cameraTrauma * _cameraTrauma;
        final rng = math.Random();
        _shakeOffset = Offset((rng.nextDouble() * 2 - 1) * 14 * intensity, (rng.nextDouble() * 2 - 1) * 14 * intensity);
      } else {
        _shakeOffset = Offset.zero;
      }

      _physics.updateVisualParticles(dt);

      // 3. Serve Sequence Tossing Mechanics
      if (_logic.phase == MatchPhase.serveTossWait && _logic.playerServing) {
        _physics.ballX = _playerX + 0.10;
        _physics.ballY = _playerY + 0.04;
        _physics.ballZ = 0.65;
      } else if (_logic.phase == MatchPhase.serveBallInAir && _logic.playerServing) {
        _logic.serveTossVz -= 3.6 * dt;
        _physics.ballZ += _logic.serveTossVz * dt;
        final ratio = ((_physics.ballZ - 0.70) / (1.55 - 0.70)).clamp(0.0, 1.0);
        _logic.reticleScale = (1.0 - ratio).clamp(0.0, 1.0);

        if (_logic.reticleScale < 0.25 && !_logic.sweetSpotAudioPlayed) {
          _logic.sweetSpotAudioPlayed = true;
          AppAudio.playFeatureSfx(AppAssets.sfxReticleLock);
        }
        if (_physics.ballZ <= 0.08) {
          _logic.resolvePoint(
            playerWonRally: false,
            reason: 'SERVICE FAULT',
            onMatchEnd: () => setState(() {}),
            onQuickReset: () => setState(() => _logic.startServeSequence(playerX: _playerX, playerY: _playerY)),
          );
          return;
        }
      }

      // 4. Instant-Brake Player Footwork
      double targetVelX = 0.0;
      double targetVelY = 0.0;
      bool hasInput = false;

      if (_isJoystickActive && _logic.phase != MatchPhase.gameOver && !_isPaused) {
        targetVelX = _joystickInputX * 1.65;
        targetVelY = _joystickInputY * 1.05;
        hasInput = true;
      }

      if (_activeKeys.contains(LogicalKeyboardKey.keyA)) { targetVelX -= 1.6; hasInput = true; }
      if (_activeKeys.contains(LogicalKeyboardKey.keyD)) { targetVelX += 1.6; hasInput = true; }
      if (_activeKeys.contains(LogicalKeyboardKey.keyW)) { targetVelY += 1.1; hasInput = true; }
      if (_activeKeys.contains(LogicalKeyboardKey.keyS)) { targetVelY -= 1.1; hasInput = true; }

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

      // Sprite Action Resolution
      if (_playerIsSwinging) {
        _playerAction = SpriteAction.hit;
      } else if (_logic.phase == MatchPhase.serveTossWait || _logic.phase == MatchPhase.serveBallInAir) {
        _playerAction = _logic.phase == MatchPhase.serveBallInAir ? SpriteAction.serve : SpriteAction.idle;
      } else if (_playerY >= 0.28) {
        _playerAction = SpriteAction.defend;
      } else if (_playerVelocityX.abs() > 0.2 || _playerVelocityY.abs() > 0.2) {
        _playerAction = SpriteAction.walk;
      } else {
        _playerAction = SpriteAction.idle;
      }

      // LAN Sync Broadcasting
      if (_lan.isConnected) {
        if (_lan.isGuest) {
          _lan.sendPacket({
            'type': 'pos',
            'x': _playerX,
            'y': _playerY,
            'swing': _playerIsSwinging,
          });
        } else if (_lan.isHost) {
          _lan.sendPacket({
            'type': 'tick',
            'bx': _physics.ballX,
            'by': _physics.ballY,
            'bz': _physics.ballZ,
            'bvx': _physics.ballVx,
            'bvy': _physics.ballVy,
            'bvz': _physics.ballVz,
            'p1x': _playerX,
            'p1y': _playerY,
            'p1vx': _playerVelocityX,
            'p1swing': _playerIsSwinging,
            'score1': _logic.playerScore,
            'score2': _logic.aiScore,
            'time': _logic.matchTimeRemaining,
            'phase': _logic.phase.name,
          });
        }
      }

      if (_logic.phase != MatchPhase.activeRally) return;

      // 5. Ballistics Flight Loop
      _physics.updateBallFlight(
        dt: dt,
        currentTime: _gameTime,
        onPointEnded: (playerWon, reason) => _logic.resolvePoint(
          playerWonRally: playerWon,
          reason: reason,
          onMatchEnd: () => setState(() {}),
          onQuickReset: () => setState(() => _logic.startServeSequence(playerX: _playerX, playerY: _playerY)),
        ),
        onBallBounce: () => AppAudio.playFeatureSfx(AppAssets.sfxBallBounce),
        onNetFault: () => AppAudio.playFeatureSfx(AppAssets.sfxNetCord),
        onOutOfBounds: () => AppAudio.playFeatureSfx(AppAssets.sfxOutOfBounds),
      );

      // 6. Balanced AI Decision Loop
      if (!_lan.isConnected || _lan.isHost) {
        _ai.updatePosition(
          dt: dt,
          ballX: _physics.ballX,
          ballY: _physics.ballY,
          ballZ: _physics.ballZ,
          ballVx: _physics.ballVx,
          ballVy: _physics.ballVy,
          aiChar: GameState.instance.opponentCharacter,
          difficulty: GameState.instance.difficulty,
          currentRally: _logic.currentRally,
          playerY: _playerY,
        );

        final bool aiWaitingServe = _logic.playerServing && _physics.bouncesThisRally < 1;
        if (!aiWaitingServe) {
          final distToAiX = (_physics.ballX - _ai.x).abs();
          final inReachX = distToAiX <= (0.28 * GameState.instance.opponentCharacter.reachFactor);
          final inReachY = (_physics.ballY >= _ai.y - 0.16) && (_physics.ballY <= _ai.y + 0.12);

          if (_physics.ballVy > 0 && inReachX && inReachY && _physics.ballZ > 0.05 && _physics.ballZ < 2.1) {
            _logic.executeAiReturn(
              onTrauma: _addTrauma,
              onAiSwing: () {
                _ai.isSwinging = true;
                _ai.swingAngle = 0.1;
              },
            );
          }
        }
      }
    });
  }

  void _handlePlayerSwing(ShotType type) {
    if (_isPaused || _logic.phase == MatchPhase.gameOver) return;

    if (type == ShotType.normal && _logic.driveCooldown > 0) return;
    if (type == ShotType.smash && _logic.smashCooldown > 0) return;
    if (type == ShotType.lob && _logic.lobCooldown > 0) return;

    if (type == ShotType.normal) _logic.driveCooldown = GameplayLogic.kMaxDriveCooldown;
    if (type == ShotType.smash) _logic.smashCooldown = GameplayLogic.kMaxSmashCooldown;
    if (type == ShotType.lob) _logic.lobCooldown = GameplayLogic.kMaxLobCooldown;

    final char = GameState.instance.selectedCharacter;
    final isForehand = _physics.ballX >= _playerX;
    final paddleX = _playerX + (isForehand ? 0.09 : -0.09);
    final paddleY = _playerY + 0.03;

    final distX = (_physics.ballX - paddleX).abs();
    final inReachX = distX <= (0.16 * char.reachFactor);
    final distY = (_physics.ballY - paddleY).abs();
    final inReachY = distY <= 0.11;
    final inHeight = _physics.ballZ >= 0.08 && _physics.ballZ <= 2.1;

    _playerCurrentShot = type;
    _playerIsSwinging = true;
    _playerSwingAngle = 0.1;

    if (inReachX && inReachY && inHeight && _physics.ballVy < 0) {
      if (!_logic.playerServing && _physics.bouncesThisRally < 1 && _physics.ballZ > 0.25) {
        _logic.resolvePoint(
          playerWonRally: false,
          reason: 'TWO-BOUNCE FAULT',
          onMatchEnd: () => setState(() {}),
          onQuickReset: () => setState(() => _logic.startServeSequence(playerX: _playerX, playerY: _playerY)),
        );
        return;
      }

      final isSmash = type == ShotType.smash || type == ShotType.signatureBlitz;
      _logic.playerBlitzEnergy = (_logic.playerBlitzEnergy + 0.22).clamp(0.0, 1.0);

      _physics.ballVy = (isSmash ? 0.95 : 0.74) * GameState.instance.effectivePaddlePower;
      _physics.ballVz = math.max(1.80, (0.58 - _physics.ballZ + 0.5 * 4.15 * 0.2) / 0.45);
      _physics.ballVx = (_joystickInputX.abs() > 0.18 ? _joystickInputX * 0.70 : 0.0) - (_physics.ballX * 0.4);

      _physics.spawnHitSparks(paddleX, paddleY, _physics.ballZ, isSmash ? AppColors.electricCoral : AppColors.opticYellow);
      _logic.currentRally++;
      if (_logic.currentRally > _logic.longestRally) _logic.longestRally = _logic.currentRally;
      
      _ai.onPlayerHitBall(difficulty: GameState.instance.difficulty, ballVx: _physics.ballVx);
      
      if (_lan.isConnected && _lan.isGuest) {
        _lan.sendPacket({
          'type': 'hit',
          'isSmash': isSmash,
          'vx': _physics.ballVx,
          'vy': _physics.ballVy,
          'vz': _physics.ballVz,
          'curve': _physics.ballCurve,
        });
      }
      
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
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
                        blitzActive: _logic.blitzActive,
                        blitzColor: AppColors.opticYellow,
                        equippedPaddle: state.selectedPaddle,
                        courtVenue: state.courtVenue,
                        sprites: _sprites,
                        isLandscape: isLandscape,
                        isServing: _logic.phase == MatchPhase.serveBallInAir,
                        reticleScale: _logic.reticleScale,
                        gameTime: _gameTime,
                      ),
                    ),
                  ),
                ),

                // 2. Scoreboard & 3:00 Round Timer
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
                        playerScore: _logic.playerScore,
                        aiScore: _logic.aiScore,
                        matchTimeRemaining: _logic.matchTimeRemaining,
                        onPause: () => setState(() => _isPaused = !_isPaused),
                      ),
                    ),
                  ),
                ),

                // 3. Fast Non-Intrusive Point Toast (No More Frozen Dead-Air!)
                if (_logic.pointToastTimer > 0)
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
                          _logic.pointToastText,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.opticYellow, fontSize: 12),
                        ),
                      ),
                    ),
                  ),

                // 4. On-Screen Controls
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
                          if (clamped.distance > _joystickDeadzone * _joystickRadius) {
                            _joystickInputX = math.cos(clamped.direction) * (clamped.distance / _joystickRadius);
                            _joystickInputY = -math.sin(clamped.direction) * (clamped.distance / _joystickRadius);
                          } else {
                            _joystickInputX = 0;
                            _joystickInputY = 0;
                          }
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
                      phase: _logic.phase,
                      playerServing: _logic.playerServing,
                      blitzEnergy: _logic.playerBlitzEnergy,
                      driveCooldown: _logic.driveCooldown / GameplayLogic.kMaxDriveCooldown,
                      smashCooldown: _logic.smashCooldown / GameplayLogic.kMaxSmashCooldown,
                      lobCooldown: _logic.lobCooldown / GameplayLogic.kMaxLobCooldown,
                      isLandscape: isLandscape,
                      onToss: () => _logic.executePlayerToss(playerX: _playerX),
                      onDriveServe: () => _logic.strikePlayerServe(
                        shotType: ShotType.drive,
                        playerX: _playerX,
                        joystickX: _joystickInputX,
                        onTrauma: _addTrauma,
                      ),
                      onLobServe: () => _logic.strikePlayerServe(
                        shotType: ShotType.lob,
                        playerX: _playerX,
                        joystickX: _joystickInputX,
                        onTrauma: _addTrauma,
                      ),
                      onSwing: _handlePlayerSwing,
                      onBlitzNotReady: () => _logic.setFeedback('⚡ BLITZ CHARGING...', AppColors.opticYellow),
                    ),
                  ),
                ] else ...[
                  PcKeyHintsOverlay(
                    phase: _logic.phase,
                    playerServing: _logic.playerServing,
                    blitzEnergy: _logic.playerBlitzEnergy,
                  ),
                ],

                if (_isPaused)
                  Positioned.fill(
                    child: PauseMenuOverlay(
                      onResume: () => setState(() => _isPaused = false),
                      onForfeit: () => Navigator.pop(context),
                    ),
                  ),

                if (_logic.phase == MatchPhase.gameOver)
                  Positioned.fill(
                    child: GameOverModal(
                      playerWon: _logic.playerScore > _logic.aiScore,
                      playerScore: _logic.playerScore,
                      aiScore: _logic.aiScore,
                      onRematch: () => setState(() => _logic.resetMatch()),
                      onReturn: () => Navigator.pop(context),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}