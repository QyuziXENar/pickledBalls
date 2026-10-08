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
import '../../models/online_profile_models.dart';
import '../../services/lan_multiplayer_manager.dart';
import '../../services/online_multiplayer_manager.dart';
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
  final MatchMode matchMode;
  final bool isHost;

  const CourtGameplayScreen({
    super.key,
    this.matchMode = MatchMode.vsAi,
    this.isHost = true,
  });

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

  final LanMultiplayerManager _lan = LanMultiplayerManager.instance;
  final OnlineMultiplayerManager _online = OnlineMultiplayerManager.instance;
  StreamSubscription? _networkSub;

  double _networkTickAccumulator = 0.0;
  double _ballSyncAccumulator = 0.0;

  late CharacterModel _opponentCharacter;

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
    _ctrl = GameplayController(
      physics: _physics,
      ai: _ai,
      matchMode: widget.matchMode,
    );

    if (widget.matchMode != MatchMode.vsAi) {
      _ctrl.playerServing = widget.isHost;
    }

    _resolveOpponentLoadout();
    _initNetworkStream();

    _ctrl.startMatchIntro();
    _preloadSprites();
    _ticker = createTicker(_onGameTick)..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocusNode.requestFocus();
    });
  }

  void _resolveOpponentLoadout() {
    final state = GameState.instance;

    if (widget.matchMode == MatchMode.lanPvp) {
      _opponentCharacter = kCharacters.firstWhere(
        (c) => c.id == _lan.opponentAthleteId,
        orElse: () => state.opponentCharacter,
      );
    } else if (widget.matchMode == MatchMode.onlinePvp) {
      _opponentCharacter = kCharacters.firstWhere(
        (c) => c.id == _online.opponentAthleteId,
        orElse: () => state.opponentCharacter,
      );
    } else {
      _opponentCharacter = state.opponentCharacter;
    }
  }

  void _initNetworkStream() {
    if (widget.matchMode == MatchMode.lanPvp) {
      _networkSub = _lan.packetStream.listen(_onNetworkPacketReceived);
    } else if (widget.matchMode == MatchMode.onlinePvp) {
      _networkSub = _online.packetStream.listen(_onNetworkPacketReceived);
    }
  }

  void _sendNetworkPacket(Map<String, dynamic> packet) {
    if (widget.matchMode == MatchMode.lanPvp) {
      _lan.sendPacket(packet);
    } else if (widget.matchMode == MatchMode.onlinePvp) {
      _online.sendPacket(packet);
    }
  }

  void _onNetworkPacketReceived(Map<String, dynamic> packet) {
    if (!mounted) return;
    final type = packet['type'];

    // 1. Live Remote Player Position & Animation Sync (Flipped coordinates)
    if (type == 'pos') {
      final double remoteX = -(packet['x'] as num).toDouble();
      final double remoteY = 1.0 - (packet['y'] as num).toDouble();
      final double remoteVx = -(packet['vx'] as num).toDouble();
      final double remoteVy = -(packet['vy'] as num).toDouble();

      setState(() {
        _ai.x = remoteX;
        _ai.y = remoteY;
        _ai.velocityX = remoteVx;
        _ai.velocityY = remoteVy;
        _ai.swingAngle = (packet['swingAngle'] as num).toDouble();
        _ai.isSwinging = packet['isSwinging'] == true;
        _ai.action = SpriteAction.values[(packet['action'] as num).toInt()];
        _ai.currentShot = ShotType.values[(packet['shotType'] as num).toInt()];
      });
    }

    // 2. Ball Telemetry Sync (Sent by Host, received by Guest)
    else if (type == 'ball_sync' && !widget.isHost) {
      final double bx = -(packet['bx'] as num).toDouble();
      final double by = 1.0 - (packet['by'] as num).toDouble();
      final double bz = (packet['bz'] as num).toDouble();
      final double bvx = -(packet['bvx'] as num).toDouble();
      final double bvy = -(packet['bvy'] as num).toDouble();
      final double bvz = (packet['bvz'] as num).toDouble();

      setState(() {
        _physics.ballX = bx;
        _physics.ballY = by;
        _physics.ballZ = bz;
        _physics.ballVx = bvx;
        _physics.ballVy = bvy;
        _physics.ballVz = bvz;
        _physics.ballCurve = -(packet['curve'] as num).toDouble();
        _physics.ballSpinVertical = (packet['spinZ'] as num).toDouble();
        _physics.ballRotationAngle = (packet['rot'] as num).toDouble();
        _ctrl.currentRally = (packet['rally'] as num).toInt();
      });
    }

    // 3. Remote Serve Toss
    else if (type == 'serve_toss') {
      final double remoteX = -(packet['x'] as num).toDouble();
      setState(() {
        _ai.x = remoteX;
        _ai.isSwinging = false;
        _ctrl.phase = MatchPhase.serveBallInAir;
        _physics.ballX = remoteX - 0.10;
        _physics.ballY = 0.96;
        _physics.ballZ = 0.70;
        _physics.ballVx = 0;
        _physics.ballVy = 0;
        _physics.ballVz = math.sqrt(2 * 3.6 * (1.55 - 0.70));
        AppAudio.playFeatureSfx(AppAssets.sfxServeToss);
      });
    }

    // 4. Remote Serve Strike
    else if (type == 'serve_strike') {
      final shotType = ShotType.values[(packet['shot'] as num).toInt()];
      final double vx = -(packet['vx'] as num).toDouble();
      final double vy = -(packet['vy'] as num).toDouble();
      final double vz = (packet['vz'] as num).toDouble();
      final double curve = -(packet['curve'] as num).toDouble();
      final double spinZ = (packet['spinZ'] as num).toDouble();

      setState(() {
        _ctrl.phase = MatchPhase.activeRally;
        _physics.ballVx = vx;
        _physics.ballVy = vy;
        _physics.ballVz = vz;
        _physics.ballCurve = curve;
        _physics.ballSpinVertical = spinZ;

        _ai.isSwinging = true;
        _ai.swingAngle = 0.1;
        _ai.currentShot = shotType;
        _ctrl.currentRally = 1;

        _physics.spawnHitSparks(_ai.x, _ai.y, _physics.ballZ, _opponentCharacter.accentColor);
        AppAudio.playFeatureSfx(shotType == ShotType.drive ? AppAssets.sfxServeDrive : AppAssets.sfxServeLob);
      });
    }

    // 5. Remote Ball Strike (During Active Rally)
    else if (type == 'ball_hit') {
      final shotType = ShotType.values[(packet['shot'] as num).toInt()];
      final double vx = -(packet['vx'] as num).toDouble();
      final double vy = -(packet['vy'] as num).toDouble();
      final double vz = (packet['vz'] as num).toDouble();
      final double curve = -(packet['curve'] as num).toDouble();
      final double spinZ = (packet['spinZ'] as num).toDouble();

      setState(() {
        _physics.ballVx = vx;
        _physics.ballVy = vy;
        _physics.ballVz = vz;
        _physics.ballCurve = curve;
        _physics.ballSpinVertical = spinZ;

        _ai.isSwinging = true;
        _ai.swingAngle = 0.1;
        _ai.currentShot = shotType;

        _ctrl.currentRally = (packet['rally'] as num?)?.toInt() ?? (_ctrl.currentRally + 1);
        if (_ctrl.currentRally > _ctrl.longestRally) _ctrl.longestRally = _ctrl.currentRally;

        _physics.spawnHitSparks(_ai.x, _ai.y, _physics.ballZ, _opponentCharacter.accentColor);

        if (shotType == ShotType.smash) {
          _addTrauma(0.40);
          AppAudio.playFeatureSfx(AppAssets.sfxPaddleSmash);
        } else {
          AppAudio.playFeatureSfx(AppAssets.sfxPaddleDrive);
        }
      });
    }

    // 6. Host-Authoritative Point Resolution (Received by Guest)
    else if (type == 'point_resolved' && !widget.isHost) {
      final bool hostWon = packet['hostWon'] == true;
      final String reason = packet['reason'] ?? '';
      final int hostScore = (packet['hostScore'] as num).toInt();
      final int guestScore = (packet['guestScore'] as num).toInt();
      final bool hostServing = packet['hostServing'] == true;
      final bool matchOver = packet['matchOver'] == true;

      setState(() {
        _ctrl.playerScore = guestScore;
        _ctrl.aiScore = hostScore;
        _ctrl.playerServing = !hostServing;
        _ctrl.pointToastText = hostWon ? 'POINT: OPPONENT ($reason)' : 'POINT: YOU ($reason)';
        _ctrl.pointToastTimer = 1.0;
        _ctrl.currentRally = 0;
        _ctrl.blitzActive = false;

        if (matchOver) {
          _ctrl.phase = MatchPhase.gameOver;
          final bool iWon = guestScore > hostScore;
          _ctrl.matchSummaryStats = MatchPerformanceStats(
            playerScore: guestScore,
            opponentScore: hostScore,
            totalDinks: _ctrl.totalDinks,
            overheadSmashes: _ctrl.totalSmashes,
            kitchenFaults: _ctrl.kitchenFaults,
            longestRally: _ctrl.longestRally,
            won: iWon,
            previousDupr: 3.42,
            duprDelta: iWon ? 0.25 : -0.20,
            xpEarned: iWon ? 150 : 50,
            coinsEarned: iWon ? 200 : 75,
          );
          AppAudio.playFeatureSfx(iWon ? AppAssets.sfxMatchWinner : AppAssets.sfxMatchLose);
        } else {
          _ctrl.phase = MatchPhase.pointScored;
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _ctrl.beginAutomatedRepositioning(onReady: () {});
          });
        }
      });
    }

    // 7. Courtside Quick Chat
    else if (type == 'chat') {
      _ctrl.showQuickChat(packet['text'] ?? '');
    }
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
    _networkSub?.cancel();
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
        onSend: (call) {
          _ctrl.showQuickChat(call.text);
          _sendNetworkPacket({'type': 'chat', 'text': call.text});
        },
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.keyP) {
        setState(() => _isPaused = !_isPaused);
        return;
      }
      if (_isPaused || _ctrl.phase == MatchPhase.gameOver) return;

      _activeKeys.add(event.logicalKey);

      if (_ctrl.phase == MatchPhase.serveTossWait && _ctrl.playerServing) {
        if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyJ) {
          _onTriggerToss();
          return;
        }
      } else if (_ctrl.phase == MatchPhase.serveBallInAir && _ctrl.playerServing) {
        if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyJ) {
          _onTriggerServeStrike(ShotType.drive);
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          _onTriggerServeStrike(ShotType.lob);
        }
        return;
      }

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

  void _onTriggerToss() {
    _ctrl.executePlayerToss(playerX: _playerX);
    if (widget.matchMode != MatchMode.vsAi) {
      _sendNetworkPacket({'type': 'serve_toss', 'x': _playerX});
    }
  }

  void _onTriggerServeStrike(ShotType shotType) {
    _ctrl.strikePlayerServe(
      shotType: shotType,
      playerX: _playerX,
      joystickX: _joystickInputX,
      onTrauma: _addTrauma,
      onPointEnd: _handlePointEndCallback,
    );

    if (widget.matchMode != MatchMode.vsAi) {
      _sendNetworkPacket({
        'type': 'serve_strike',
        'shot': shotType.index,
        'vx': _physics.ballVx,
        'vy': _physics.ballVy,
        'vz': _physics.ballVz,
        'curve': _physics.ballCurve,
        'spinZ': _physics.ballSpinVertical,
      });
    }
  }

  void _handlePointEndCallback(bool won, String reason) {
    _ctrl.resolvePoint(
      playerWonRally: won,
      reason: reason,
      onMatchEnd: () => setState(() {}),
      onStartRepositioning: (px, py) => setState(() {}),
    );

    if (widget.matchMode != MatchMode.vsAi && widget.isHost) {
      final bool matchOver = _ctrl.phase == MatchPhase.gameOver;
      _sendNetworkPacket({
        'type': 'point_resolved',
        'hostWon': won,
        'reason': reason,
        'hostScore': _ctrl.playerScore,
        'guestScore': _ctrl.aiScore,
        'hostServing': _ctrl.playerServing,
        'matchOver': matchOver,
      });
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

      // 3. Match Timers & Trauma
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
          _handlePointEndCallback(false, 'SERVICE FAULT');
          return;
        }
      }

      // 5. Calibrated Grounded Kinematics
      double targetVelX = 0.0;
      double targetVelY = 0.0;
      bool hasInput = false;

      if (_isJoystickActive && _ctrl.phase != MatchPhase.gameOver && !_isPaused) {
        targetVelX = _joystickInputX * 1.50;
        targetVelY = _joystickInputY * 0.42;
        hasInput = true;
      }

      if (_activeKeys.contains(LogicalKeyboardKey.keyA) || _activeKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        targetVelX -= 1.50;
        hasInput = true;
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyD) || _activeKeys.contains(LogicalKeyboardKey.arrowRight)) {
        targetVelX += 1.50;
        hasInput = true;
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyW) || _activeKeys.contains(LogicalKeyboardKey.arrowUp)) {
        targetVelY += 0.42;
        hasInput = true;
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyS) || _activeKeys.contains(LogicalKeyboardKey.arrowDown)) {
        targetVelY -= 0.42;
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
      } else if (_playerVelocityX.abs() > 0.2 || _playerVelocityY.abs() > 0.08) {
        _playerAction = SpriteAction.walk;
      } else {
        _playerAction = SpriteAction.idle;
      }

      // 6. Real-Time Telemetry Broadcast (~20 Hz)
      if (widget.matchMode != MatchMode.vsAi) {
        _networkTickAccumulator += dt;
        if (_networkTickAccumulator >= 0.045) {
          _networkTickAccumulator = 0.0;
          _sendNetworkPacket({
            'type': 'pos',
            'x': _playerX,
            'y': _playerY,
            'vx': _playerVelocityX,
            'vy': _playerVelocityY,
            'swingAngle': _playerSwingAngle,
            'isSwinging': _playerIsSwinging,
            'action': _playerAction.index,
            'shotType': _playerCurrentShot.index,
          });
        }

        // Host authoritative ball broadcast
        if (widget.isHost && _ctrl.phase == MatchPhase.activeRally) {
          _ballSyncAccumulator += dt;
          if (_ballSyncAccumulator >= 0.05) {
            _ballSyncAccumulator = 0.0;
            _sendNetworkPacket({
              'type': 'ball_sync',
              'bx': _physics.ballX,
              'by': _physics.ballY,
              'bz': _physics.ballZ,
              'bvx': _physics.ballVx,
              'bvy': _physics.ballVy,
              'bvz': _physics.ballVz,
              'curve': _physics.ballCurve,
              'spinZ': _physics.ballSpinVertical,
              'rot': _physics.ballRotationAngle,
              'rally': _ctrl.currentRally,
            });
          }
        }
      }

      if (_ctrl.phase != MatchPhase.activeRally) return;

      // 7. Ball Flight Simulation
      _physics.updateBallFlight(
        dt: dt,
        currentTime: _gameTime,
        onPointEnded: (playerWon, reason) {
          if (widget.matchMode == MatchMode.vsAi || widget.isHost) {
            _handlePointEndCallback(playerWon, reason);
          }
        },
        onBallBounce: () => AppAudio.playFeatureSfx(AppAssets.sfxBallBounce),
        onNetFault: () => AppAudio.playFeatureSfx(AppAssets.sfxNetCord),
        onOutOfBounds: () => AppAudio.playFeatureSfx(AppAssets.sfxOutOfBounds),
      );

      // 8. Single-Player Tactical AI Loop (DISABLED in PvP)
      if (widget.matchMode == MatchMode.vsAi) {
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
      }
    });
  }

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

    final distX = (_physics.ballX - paddleX).abs();
    final inReachX = distX <= (0.24 * char.reachFactor);
    final distY = (_physics.ballY - paddleY).abs();
    final inReachY = distY <= 0.16;
    final inHeight = _physics.ballZ >= 0.05 && _physics.ballZ <= 1.95;

    _playerCurrentShot = type;
    _playerIsSwinging = true;
    _playerSwingAngle = 0.1;

    if (inReachX && inReachY && inHeight && _physics.ballVy < 0) {
      if (!_ctrl.playerServing && _physics.bouncesThisRally < 1 && _physics.ballZ > 0.25) {
        _handlePointEndCallback(false, 'TWO-BOUNCE FAULT');
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

      AppAudio.playFeatureSfx(isSmash ? AppAssets.sfxPaddleSmash : AppAssets.sfxPaddleDrive);

      if (widget.matchMode == MatchMode.vsAi) {
        _ai.onPlayerHitBall(difficulty: GameState.instance.difficulty, ballVx: _physics.ballVx);
      } else {
        _sendNetworkPacket({
          'type': 'ball_hit',
          'shot': type.index,
          'vx': _physics.ballVx,
          'vy': _physics.ballVy,
          'vz': _physics.ballVz,
          'curve': _physics.ballCurve,
          'spinZ': _physics.ballSpinVertical,
          'rally': _ctrl.currentRally,
        });
      }
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
                          aiColor: _opponentCharacter.bodyColor,
                          aiAccent: _opponentCharacter.accentColor,
                          aiCharId: _opponentCharacter.id,
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
                            opponentChar: _opponentCharacter,
                            playerScore: _ctrl.playerScore,
                            aiScore: _ctrl.aiScore,
                            matchTimeRemaining: _ctrl.matchTimeRemaining,
                            onPause: () => setState(() => _isPaused = !_isPaused),
                            onOpenChat: () => _openQuickChatPicker(context),
                          ),
                        ),
                      ),
                    ),

                  if (_ctrl.activeQuickChat != null)
                    Positioned(
                      bottom: isLandscape ? 120 : 180,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: QuickChatBubble(text: _ctrl.activeQuickChat!),
                      ),
                    ),

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
                          onToss: _onTriggerToss,
                          onDriveServe: () => _onTriggerServeStrike(ShotType.drive),
                          onLobServe: () => _onTriggerServeStrike(ShotType.lob),
                          onSwing: _handlePlayerSwing,
                          onBlitzNotReady: () => _ctrl.setFeedback('⚡ BLITZ CHARGING...', AppColors.opticYellow),
                        ),
                      ),
                    ] else ...[
                      PcKeyHintsOverlay(
                        phase: _ctrl.phase,
                        playerServing: _ctrl.playerServing,
                        blitzEnergy: _ctrl.playerBlitzEnergy,
                      ),
                    ],
                  ],

                  if (_ctrl.phase == MatchPhase.cinematicSplash || _ctrl.phase == MatchPhase.countdown)
                    Positioned.fill(
                      child: GameplayIntroOverlay(
                        phase: _ctrl.phase,
                        countdownNumber: _ctrl.countdownNumber,
                        playerChar: state.selectedCharacter,
                        opponentChar: _opponentCharacter,
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