// lib/screens/gameplay/gameplay_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_state.dart';
import '../../../services/lan_multiplayer_manager.dart';
import '../../../widgets/ambient_background.dart';
import '../../../widgets/asset_helpers.dart';
import 'physics/court_physics_engine.dart';
import 'physics/tactical_ai_controller.dart';
import 'widgets/gameplay_controls.dart';
import 'widgets/gameplay_hud.dart';
import 'rendering/perspective_court_painter.dart';

enum MatchPhase {
  intro,
  serveTossWait,
  serveBallInAir,
  activeRally,
  pointScored,
  gameOver,
}

enum ShotType { normal, smash, signatureBlitz, drive, lob }

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
  double _hitstopTimer = 0.0;

  final Map<String, ui.Image> _sprites = {};

  final LanMultiplayerManager _lan = LanMultiplayerManager.instance;
  StreamSubscription? _netSub;
  bool _aiTookOver = false;

  bool get _isMultiplayer => _lan.isConnected && !_aiTookOver;
  bool get _isHost => _lan.isHost;
  bool get _isGuest => _lan.isGuest;

  bool _isPaused = false;
  double _cameraTrauma = 0.0;
  Offset _shakeOffset = Offset.zero;

  final FocusNode _keyboardFocusNode = FocusNode();
  final Set<LogicalKeyboardKey> _activeKeys = {};

  Offset _joystickKnobOffset = Offset.zero;
  bool _isJoystickActive = false;
  double _joystickInputX = 0.0;
  double _joystickInputY = 0.0;
  static const double _joystickRadius = 46.0;
  static const double _joystickDeadzone = 0.06;

  MatchPhase _phase = MatchPhase.intro;
  double _phaseTimer = 0.0;
  bool _playerServing = true;

  double _serveTossZ = 0.65;
  double _serveTossVz = 0.0;
  double _reticleScale = 1.0;
  bool _sweetSpotAudioPlayed = false;
  static const double _tossApexZ = 1.55;
  static const double _tossGravity = 3.6;

  String _bannerTitle = '';
  String _bannerSubtitle = '';
  Color _bannerColor = AppColors.opticYellow;
  String _timingFeedback = '';
  Color _timingFeedbackColor = AppColors.opticYellow;
  double _timingFeedbackTimer = 0.0;

  double _playerBlitzEnergy = 0.0;
  double _aiBlitzEnergy = 0.0;
  bool _blitzActive = false;
  Color _blitzTrailColor = Colors.transparent;

  int _playerScore = 0;
  int _aiScore = 0;
  int _currentRally = 0;
  int _longestRally = 0;
  int _totalSmashes = 0;

  // Player Kinematics
  double _playerX = 0.0;
  double _playerY = 0.0;
  double _playerVelocityX = 0.0;
  double _playerVelocityY = 0.0;
  double _lastMoveDirX = 0.0;
  double _shoeSqueakCooldown = 0.0;

  double _playerSwingAngle = 0.0;
  bool _playerIsSwinging = false;
  SpriteAction _playerAction = SpriteAction.idle;
  ShotType _playerCurrentShot = ShotType.normal;
  bool _playerIsDiving = false;

  // Subsystem Controllers
  final CourtPhysicsEngine _physics = CourtPhysicsEngine();
  final TacticalAiController _ai = TacticalAiController();

  @override
  void initState() {
    super.initState();
    _preloadCharacterSprites();

    if (_lan.isConnected) {
      _netSub = _lan.packetStream.listen(_onNetworkPacket);
      _lan.addListener(_onLanConnectionStateChanged);
    }

    _startIntroSequence();
    _ticker = createTicker(_onGameTick)..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocusNode.requestFocus();
    });
  }

  Future<void> _preloadCharacterSprites() async {
    final paths = AppAssets.getAllSpritePaths();
    for (final path in paths) {
      if (AppAssetRegistry.hasAsset(path)) {
        try {
          final data = await rootBundle.load(path);
          final bytes = data.buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(bytes);
          final frameInfo = await codec.getNextFrame();
          if (mounted) {
            setState(() => _sprites[path] = frameInfo.image);
          }
        } catch (_) {}
      }
    }

    const ids = ['FEMALE', 'MALE', 'ELENA', 'JAX'];
    const frames = [
      'frame_0_ready',
      'frame_1_backswing',
      'frame_2_contact',
      'frame_3_followthrough',
    ];

    for (final id in ids) {
      for (final frame in frames) {
        final legacyPath = 'lib/assets/images/characters/$frame $id.png';
        if (AppAssetRegistry.hasAsset(legacyPath)) {
          try {
            final data = await rootBundle.load(legacyPath);
            final bytes = data.buffer.asUint8List();
            final codec = await ui.instantiateImageCodec(bytes);
            final frameInfo = await codec.getNextFrame();
            if (mounted) {
              setState(() => _sprites['${frame}_$id'] = frameInfo.image);
            }
          } catch (_) {}
        }
      }
    }
  }

  @override
  void dispose() {
    _netSub?.cancel();
    _ticker.dispose();
    _keyboardFocusNode.dispose();
    _lan.removeListener(_onLanConnectionStateChanged);

    if (_lan.isConnected) {
      _lan.disconnect();
    }
    super.dispose();
  }

  void _addTrauma(double amount) {
    if (!GameState.instance.screenShakeEnabled) return;
    setState(() {
      _cameraTrauma = (_cameraTrauma + amount).clamp(0.0, 1.0);
    });
  }

  void _togglePause() {
    if (_phase == MatchPhase.gameOver) return;

    if (_isMultiplayer) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          title: const Text('FORFEIT MATCH?', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          content: const Text('Leaving will forfeit the match.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('STAY')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricCoral),
              onPressed: () {
                Navigator.pop(ctx);
                _lan.disconnect();
                Navigator.pop(context);
              },
              child: const Text('FORFEIT', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) {
        _lastElapsed = Duration.zero;
      }
    });
    AppAudio.playFeatureSfx(AppAssets.sfxClick);
  }

  void _onLanConnectionStateChanged() {
    if (!mounted) return;
    if (_lan.status != LanStatus.connected && !_aiTookOver) {
      if (_isHost) {
        setState(() => _aiTookOver = true);
        AppAudio.playFeatureSfx(AppAssets.sfxFaultBuzzer);
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _onNetworkPacket(Map<String, dynamic> packet) {
    if (!mounted) return;
    if (_isHost) {
      if (packet['type'] == 'pos') {
        final gx = (packet['x'] as num).toDouble();
        final gy = (packet['y'] as num).toDouble();
        setState(() {
          _ai.x = -gx;
          _ai.y = 1.0 - gy;
          _ai.isSwinging = packet['swing'] == true;
          if (_ai.isSwinging) _ai.swingAngle = 0.2;
        });
      } else if (packet['type'] == 'hit') {
        setState(() {
          _physics.ballVx = -(packet['vx'] as num).toDouble();
          _physics.ballVy = -(packet['vy'] as num).toDouble();
          _physics.ballVz = (packet['vz'] as num).toDouble();
          _physics.ballCurve = -(packet['curve'] as num).toDouble();
          _triggerAiSwing(ShotType.normal);
          _currentRally++;
          if (_currentRally > _longestRally) _longestRally = _currentRally;
          if (packet['isSmash'] == true) _totalSmashes++;
        });

        _physics.spawnHitSparks(_physics.ballX, _physics.ballY, _physics.ballZ, AppColors.electricCoral);
        AppAudio.playFeatureSfx(packet['isSmash'] == true ? AppAssets.sfxPaddleSmash : AppAssets.sfxPaddleDrive);
      }
    } else if (_isGuest && packet['type'] == 'tick') {
      setState(() {
        _physics.ballX = -(packet['bx'] as num).toDouble();
        _physics.ballY = 1.0 - (packet['by'] as num).toDouble();
        _physics.ballZ = (packet['bz'] as num).toDouble();
        _physics.ballVx = -(packet['bvx'] as num).toDouble();
        _physics.ballVy = -(packet['bvy'] as num).toDouble();
        _physics.ballVz = (packet['bvz'] as num).toDouble();
        _physics.ballCurve = -(packet['curve'] as num).toDouble();

        _ai.x = -(packet['p1x'] as num).toDouble();
        _ai.y = 1.0 - (packet['p1y'] as num).toDouble();
        _ai.velocityX = -(packet['p1vx'] as num).toDouble();
        _ai.isSwinging = packet['p1swing'] == true;

        _playerScore = packet['score2'] as int;
        _aiScore = packet['score1'] as int;

        final phaseName = packet['phase'] as String;
        _phase = MatchPhase.values.firstWhere((p) => p.name == phaseName, orElse: () => MatchPhase.activeRally);
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.keyP) {
        _togglePause();
        return;
      }
      if (_isPaused || _phase == MatchPhase.gameOver) return;

      _activeKeys.add(event.logicalKey);

      if (_phase == MatchPhase.serveTossWait && _playerServing) {
        if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyT) {
          _executeManualServeToss();
          return;
        }
      } else if (_phase == MatchPhase.serveBallInAir && _playerServing) {
        if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyJ) {
          _strikeManualServe(ShotType.drive);
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          _strikeManualServe(ShotType.lob);
        }
        return;
      }

      if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyJ) {
        _triggerPlayerSwing(ShotType.normal);
      } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight ||
          event.logicalKey == LogicalKeyboardKey.keyK) {
        _triggerPlayerSwing(ShotType.smash);
      }
    } else if (event is KeyUpEvent) {
      _activeKeys.remove(event.logicalKey);
    }
  }

  void _startIntroSequence() {
    setState(() {
      _phase = MatchPhase.intro;
      _bannerTitle = _isMultiplayer ? '1v1 LAN DUEL' : 'PICKLEBALL 3.0';
      _bannerSubtitle = _getMatchSituationBanner();
      _bannerColor = AppColors.opticYellow;
      _phaseTimer = 1.4;
      _blitzActive = false;
      _playerIsDiving = false;
      _resetPositionsForServe();
    });
  }

  void _resetPositionsForServe() {
    _playerY = 0.0;
    _playerVelocityX = 0.0;
    _playerVelocityY = 0.0;
    _serveTossZ = 0.65;
    _serveTossVz = 0.0;
    _reticleScale = 1.0;
    _sweetSpotAudioPlayed = false;
    _playerIsDiving = false;

    _ai.reset();
    _physics.resetBall(
      playerServing: _playerServing,
      playerX: _playerX,
      playerY: _playerY,
      aiX: _ai.x,
      aiY: _ai.y,
    );
  }

  String _getMatchSituationBanner() {
    final target = GameState.instance.targetScore;
    if (_playerScore >= target - 1 && _aiScore >= target - 1) {
      if (_playerScore == _aiScore) return 'DEUCE (TIED AT $_playerScore)';
      return _playerScore > _aiScore ? 'ADVANTAGE: PLAYER' : 'ADVANTAGE: OPPONENT';
    }
    if (_playerScore >= target - 1 && _playerScore > _aiScore) return 'MATCH POINT: PLAYER!';
    if (_aiScore >= target - 1 && _aiScore > _playerScore) return 'MATCH POINT: OPPONENT!';
    return 'FIRST TO $target (WIN BY 2)';
  }

  void _executeManualServeToss() {
    if (_phase != MatchPhase.serveTossWait || !_playerServing) return;

    setState(() {
      _phase = MatchPhase.serveBallInAir;
      _serveTossZ = 0.70;
      _serveTossVz = math.sqrt(2 * _tossGravity * (_tossApexZ - 0.70));
      _physics.ballX = _playerX + 0.14;
      _physics.ballY = 0.06;
      _physics.ballZ = _serveTossZ;
      _physics.ballVx = 0;
      _physics.ballVy = 0;
      _physics.ballCurve = 0;
      _physics.ballSpinVertical = 0;
      _reticleScale = 1.0;
      _sweetSpotAudioPlayed = false;
      _playerAction = SpriteAction.serve;
    });

    AppAudio.playFeatureSfx(AppAssets.sfxServeToss);
    HapticFeedback.lightImpact();
  }

  void _strikeManualServe(ShotType shotType) {
    if (_phase != MatchPhase.serveBallInAir || !_playerServing) return;

    final state = GameState.instance;
    final char = state.selectedCharacter;
    final pace = state.gamePace;

    final contactDiff = (_physics.ballZ - 1.25).abs();
    final isSweetSpot = contactDiff < 0.22;

    setState(() {
      _phase = MatchPhase.activeRally;
      _bannerTitle = '';
      _bannerSubtitle = '';
      _playerAction = SpriteAction.hit;
      _playerCurrentShot = shotType;
      _playerIsSwinging = true;
      _playerSwingAngle = 0.1;

      final power = state.effectivePaddlePower * char.swingPower * pace;

      if (isSweetSpot) {
        _setTimingFeedback(shotType == ShotType.drive ? '⚡ PERFECT DRIVE SERVE!' : '🎯 PINPOINT LOB SERVE!', AppColors.opticYellow);
        _addTrauma(0.35);
      } else {
        _setTimingFeedback('GOOD SERVE', AppColors.mintAccent);
      }

      final targetX = (-_playerX * 0.45).clamp(-0.75, 0.75);

      if (shotType == ShotType.drive) {
        _physics.ballVy = (isSweetSpot ? 0.90 : 0.78) * power;
        _physics.ballVz = 1.75;
        _physics.ballVx = (targetX - _physics.ballX) * 0.55;
        _physics.ballCurve = (_playerX * 0.35) * state.effectivePaddleSpin;
        _physics.ballSpinVertical = 0.25;
        AppAudio.playFeatureSfx(AppAssets.sfxServeDrive);
      } else {
        _physics.ballVy = 0.62 * power;
        _physics.ballVz = 2.65;
        _physics.ballVx = (targetX - _physics.ballX) * 0.40;
        _physics.ballCurve = 0;
        _physics.ballSpinVertical = -0.15;
        AppAudio.playFeatureSfx(AppAssets.sfxServeLob);
      }

      _currentRally = 1;
      _physics.spawnHitSparks(_physics.ballX, _physics.ballY, _physics.ballZ, AppColors.opticYellow);
    });

    HapticFeedback.mediumImpact();
  }

  void _executeAiServe() {
    final state = GameState.instance;
    final aiChar = state.opponentCharacter;
    final pace = state.gamePace;
    final rng = math.Random();

    setState(() {
      _phase = MatchPhase.activeRally;
      _bannerTitle = '';
      _bannerSubtitle = '';
      _ai.action = SpriteAction.serve;

      final targetX = (-_ai.x * 0.55 + (rng.nextDouble() - 0.5) * 0.25).clamp(-0.75, 0.75);
      final isAggressive = rng.nextDouble() < 0.45;

      if (isAggressive) {
        _physics.ballVy = -0.80 * aiChar.swingPower * pace;
        _physics.ballVz = 1.95;
        _ai.currentShot = ShotType.drive;
        _physics.ballSpinVertical = 0.2;
        AppAudio.playFeatureSfx(AppAssets.sfxServeDrive);
      } else {
        _physics.ballVy = -0.66 * aiChar.swingPower * pace;
        _physics.ballVz = 2.45;
        _ai.currentShot = ShotType.lob;
        _physics.ballSpinVertical = -0.1;
        AppAudio.playFeatureSfx(AppAssets.sfxServeLob);
      }

      _physics.ballVx = (targetX - _ai.x) * 0.45;
      _physics.ballCurve = (rng.nextDouble() - 0.5) * 0.15;
      _triggerAiSwing(_ai.currentShot);
      _physics.spawnHitSparks(_physics.ballX, _physics.ballY, _physics.ballZ, aiChar.accentColor);
    });
  }

  void _setTimingFeedback(String message, Color color) {
    _timingFeedback = message;
    _timingFeedbackColor = color;
    _timingFeedbackTimer = 1.2;
  }

  void _onGameTick(Duration elapsed) {
    if (_isPaused) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    if (_hitstopTimer > 0) {
      _hitstopTimer -= dt;
      return;
    }

    _gameTime += dt;
    if (_shoeSqueakCooldown > 0) _shoeSqueakCooldown -= dt;

    setState(() {
      if (_timingFeedbackTimer > 0) {
        _timingFeedbackTimer -= dt;
        if (_timingFeedbackTimer <= 0) {
          _timingFeedback = '';
        }
      }

      if (_cameraTrauma > 0) {
        _cameraTrauma = math.max(0.0, _cameraTrauma - dt * 2.8);
        final intensity = _cameraTrauma * _cameraTrauma;
        final rng = math.Random();
        _shakeOffset = Offset(
          (rng.nextDouble() * 2 - 1) * 16.0 * intensity,
          (rng.nextDouble() * 2 - 1) * 16.0 * intensity,
        );
      } else {
        _shakeOffset = Offset.zero;
      }

      _physics.updateVisualParticles(dt);

      if (_phase == MatchPhase.intro) {
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          _phase = MatchPhase.serveTossWait;
          if (_playerServing) {
            _bannerTitle = 'YOUR SERVE';
            _bannerSubtitle = 'AIM POSITION & TAP [TOSS BALL]';
            _bannerColor = AppColors.cyberCyan;
          } else {
            _bannerTitle = 'OPPONENT SERVING';
            _bannerSubtitle = 'PREPARE FOR RETURN';
            _bannerColor = AppColors.opticYellow;

            final state = GameState.instance;
            final rng = math.Random();
            final serveDelayMs = state.difficulty == AIDifficulty.rookie
                ? 1400 + rng.nextInt(1000)
                : state.difficulty == AIDifficulty.pro
                    ? 900 + rng.nextInt(800)
                    : 600 + rng.nextInt(500);

            Future.delayed(Duration(milliseconds: serveDelayMs), () {
              if (mounted && _phase == MatchPhase.serveTossWait && !_playerServing) {
                _executeAiServe();
              }
            });
          }
        }
        return;
      }

      if (_phase == MatchPhase.serveTossWait && _playerServing) {
        _physics.ballX = _playerX + 0.14;
        _physics.ballY = _playerY + 0.05;
        _physics.ballZ = 0.65;
      }

      if (_phase == MatchPhase.serveBallInAir && _playerServing) {
        _serveTossVz -= _tossGravity * dt;
        _physics.ballZ += _serveTossVz * dt;

        final heightRatio = ((_physics.ballZ - 0.70) / (_tossApexZ - 0.70)).clamp(0.0, 1.0);
        _reticleScale = (1.0 - heightRatio).clamp(0.0, 1.0);

        if (_reticleScale < 0.25 && !_sweetSpotAudioPlayed) {
          _sweetSpotAudioPlayed = true;
          AppAudio.playFeatureSfx(AppAssets.sfxReticleLock);
        }

        if (_physics.ballZ <= 0.08) {
          AppAudio.playFeatureSfx(AppAssets.sfxFaultBuzzer);
          _pointEnded(false, 'SERVICE FAULT (Ball Dropped)');
          return;
        }
      }

      final state = GameState.instance;
      final character = state.selectedCharacter;

      double targetVelX = 0.0;
      double targetVelY = 0.0;

      if (_isJoystickActive && _phase != MatchPhase.gameOver && !_isPaused) {
        final maxSpeedX = 2.4 * character.moveSpeed;
        final maxSpeedY = 1.4 * character.moveSpeed;
        targetVelX = _joystickInputX * maxSpeedX;
        targetVelY = _joystickInputY * maxSpeedY;
      }

      if (_activeKeys.contains(LogicalKeyboardKey.keyA) || _activeKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        targetVelX -= 2.2 * character.moveSpeed;
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyD) || _activeKeys.contains(LogicalKeyboardKey.arrowRight)) {
        targetVelX += 2.2 * character.moveSpeed;
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyW) || _activeKeys.contains(LogicalKeyboardKey.arrowUp)) {
        targetVelY += 1.4 * character.moveSpeed;
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyS) || _activeKeys.contains(LogicalKeyboardKey.arrowDown)) {
        targetVelY -= 1.4 * character.moveSpeed;
      }

      if (targetVelX.abs() > 0.6 && _lastMoveDirX.abs() > 0.6 && (targetVelX.sign != _lastMoveDirX.sign)) {
        if (_shoeSqueakCooldown <= 0) {
          _shoeSqueakCooldown = 0.45;
          AppAudio.playFeatureSfx(AppAssets.sfxShoeSqueak);
        }
      }
      if (targetVelX.abs() > 0.3) {
        _lastMoveDirX = targetVelX.sign;
      }

      final accelRate = (targetVelX.abs() > 0.1) ? 14.0 : 18.0;
      _playerVelocityX += (targetVelX - _playerVelocityX) * math.min(1.0, accelRate * dt);
      _playerVelocityY += (targetVelY - _playerVelocityY) * math.min(1.0, accelRate * dt);

      _playerX = (_playerX + _playerVelocityX * dt).clamp(-0.95, 0.95);
      _playerY = (_playerY + _playerVelocityY * dt).clamp(-0.18, 0.34);

      if (_isMultiplayer && _isGuest) {
        _lan.sendPacket({
          'type': 'pos',
          'x': _playerX,
          'y': _playerY,
          'swing': _playerIsSwinging,
        });
      }

      if (_playerIsSwinging) {
        _playerAction = SpriteAction.hit;
      } else if (_phase == MatchPhase.serveTossWait || _phase == MatchPhase.serveBallInAir) {
        _playerAction = _phase == MatchPhase.serveBallInAir ? SpriteAction.serve : SpriteAction.idle;
      } else if (_playerY >= 0.28) {
        _playerAction = SpriteAction.defend;
      } else if (_playerVelocityX.abs() > 0.3 || _playerVelocityY.abs() > 0.3) {
        _playerAction = SpriteAction.walk;
      } else {
        _playerAction = SpriteAction.idle;
      }

      if (_playerIsSwinging) {
        _playerSwingAngle += 14.0 * dt;
        if (_playerSwingAngle >= math.pi) {
          _playerSwingAngle = 0.0;
          _playerIsSwinging = false;
          _playerIsDiving = false;
        }
      }
      if (_ai.isSwinging) {
        _ai.swingAngle += 14.0 * dt;
        if (_ai.swingAngle >= math.pi) {
          _ai.swingAngle = 0.0;
          _ai.isSwinging = false;
          _ai.isDiving = false;
        }
      }

      if (_phase != MatchPhase.activeRally) return;

      _physics.updateBallFlight(
        dt: dt,
        onPointEnded: (playerWon, reason) => _pointEnded(playerWon, reason),
        onBallBounce: () => AppAudio.playFeatureSfx(AppAssets.sfxBallBounce),
        onNetFault: () => AppAudio.playFeatureSfx(AppAssets.sfxNetCord),
        onOutOfBounds: () => AppAudio.playFeatureSfx(AppAssets.sfxOutOfBounds),
      );

      if (!_isMultiplayer || _aiTookOver) {
        final aiChar = state.opponentCharacter;

        _ai.updatePosition(
          dt: dt,
          ballX: _physics.ballX,
          ballY: _physics.ballY,
          ballZ: _physics.ballZ,
          ballVx: _physics.ballVx,
          ballVy: _physics.ballVy,
          aiChar: aiChar,
          difficulty: state.difficulty,
          currentRally: _currentRally,
        );

        final distY = (_physics.ballY - _ai.y).abs();
        final inAiStrikeZoneY = distY <= 0.18;
        final distToAiX = (_physics.ballX - _ai.x).abs();
        final inAiStrikeZoneX = distToAiX < (0.32 * aiChar.reachFactor);

        if (_physics.ballVy > 0 && inAiStrikeZoneY && inAiStrikeZoneX && _physics.ballZ > 0.05 && _physics.ballZ < 2.2) {
          _ai.isDiving = distToAiX > (0.24 * aiChar.reachFactor);
          if (_ai.isDiving) AppAudio.playFeatureSfx(AppAssets.sfxPlayerDive);

          _ai.executeTacticalShot(
            aiChar: aiChar,
            pace: state.gamePace,
            playerX: _playerX,
            playerY: _playerY,
            ballZ: _physics.ballZ,
            currentRally: _currentRally,
            onApplyShot: (vy, vz, vx, curve, spinZ, shot) {
              _physics.ballVy = vy;
              _physics.ballVz = vz;
              _physics.ballVx = vx;
              _physics.ballCurve = curve;
              _physics.ballSpinVertical = spinZ;
              _triggerAiSwing(shot);

              if (shot == ShotType.signatureBlitz) {
                _hitstopTimer = 0.05;
                _addTrauma(0.65);
                AppAudio.playFeatureSfx(AppAssets.sfxBlitzSuper);
              } else if (shot == ShotType.smash) {
                _hitstopTimer = 0.03;
                _addTrauma(0.45);
                AppAudio.playFeatureSfx(AppAssets.sfxPaddleSmash);
              } else {
                AppAudio.playFeatureSfx(AppAssets.sfxPaddleDrive);
              }
            },
          );

          _physics.spawnHitSparks(_physics.ballX, _physics.ballY, _physics.ballZ, aiChar.accentColor);
          _currentRally++;
          if (_currentRally > _longestRally) _longestRally = _currentRally;
          if (_currentRally >= 5 && _currentRally % 5 == 0) {
            AppAudio.playFeatureSfx(AppAssets.sfxRallyStreak);
          }
        }
      }
    });
  }

  void _triggerPlayerSwing(ShotType type) {
    if (_isPaused || _phase == MatchPhase.gameOver) return;

    final state = GameState.instance;
    final character = state.selectedCharacter;
    final pace = state.gamePace;

    final distY = (_physics.ballY - _playerY).abs();
    final inStrikeZoneY = distY <= 0.19;
    final distX = (_physics.ballX - _playerX).abs();
    final inStrikeZoneX = distX < (0.34 * character.reachFactor);
    final inAir = _physics.ballZ > 0.05 && _physics.ballZ < 2.4;

    _playerIsDiving = distX > (0.24 * character.reachFactor);
    if (_playerIsDiving) AppAudio.playFeatureSfx(AppAssets.sfxPlayerDive);

    _playerCurrentShot = type;
    _playerIsSwinging = true;
    _playerSwingAngle = 0.1;

    if (inStrikeZoneY && inStrikeZoneX && inAir && _physics.ballVy < 0) {
      if (_playerY >= 0.34 && _physics.ballZ < 0.8 && _currentRally > 0) {
        AppAudio.playFeatureSfx(AppAssets.sfxKitchenFault);
        _pointEnded(false, 'KITCHEN FAULT (Volleyed in NVZ!)');
        return;
      }

      final isSmash = type == ShotType.smash || type == ShotType.signatureBlitz;
      final isPerfect = distY < 0.06;

      _playerBlitzEnergy = (_playerBlitzEnergy + (isPerfect ? 0.35 : 0.20)).clamp(0.0, 1.0);

      if (state.hapticsEnabled) {
        HapticFeedback.heavyImpact();
      }

      if (type == ShotType.signatureBlitz || (_playerBlitzEnergy >= 1.0 && isSmash)) {
        _addTrauma(0.85);
        _hitstopTimer = 0.05;
        AppAudio.playFeatureSfx(AppAssets.sfxBlitzSuper);
      } else if (isSmash) {
        _addTrauma(0.55);
        _hitstopTimer = 0.03;
        AppAudio.playFeatureSfx(AppAssets.sfxPaddleSmash);
      } else {
        AppAudio.playFeatureSfx(AppAssets.sfxPaddleDrive);
      }

      if (isPerfect) {
        _setTimingFeedback(isSmash ? '⚡ PERFECT SMASH!' : '🔥 PERFECT CONTACT!', AppColors.opticYellow);
      } else {
        _setTimingFeedback('GOOD HIT', AppColors.mintAccent);
      }

      final powerMultiplier = state.effectivePaddlePower * character.swingPower * pace;
      final outVy = (isSmash ? 0.98 : 0.74) * powerMultiplier;
      final outVz = isSmash ? 1.35 : 2.15;

      final offsetFromCenter = (_physics.ballX - _playerX).clamp(-0.25, 0.25);
      double targetX;
      if (isSmash) {
        targetX = (-_ai.x * 0.65 + (offsetFromCenter * 0.7)).clamp(-0.80, 0.80);
      } else {
        targetX = (-_playerX * 0.45 + (offsetFromCenter * 1.0)).clamp(-0.80, 0.80);
      }

      final outVx = (targetX - _physics.ballX) * 0.48;
      final outCurve = ((_physics.ballX - _playerX) / 0.3) * state.effectivePaddleSpin * 0.22;
      final outSpinZ = isSmash ? 0.35 : (isPerfect ? 0.20 : 0.0);

      _physics.spawnHitSparks(_physics.ballX, _physics.ballY, _physics.ballZ, isSmash ? AppColors.electricCoral : AppColors.opticYellow);

      _blitzActive = false;
      if (isSmash) _totalSmashes++;
      _physics.ballVy = outVy;
      _physics.ballVz = outVz;
      _physics.ballVx = outVx;
      _physics.ballCurve = outCurve;
      _physics.ballSpinVertical = outSpinZ;

      _currentRally++;
      if (_currentRally > _longestRally) _longestRally = _currentRally;
      if (_currentRally >= 5 && _currentRally % 5 == 0) {
        AppAudio.playFeatureSfx(AppAssets.sfxRallyStreak);
      }
    }
  }

  void _triggerAiSwing(ShotType type) {
    _ai.currentShot = type;
    _ai.isSwinging = true;
    _ai.swingAngle = 0.1;
  }

  void _pointEnded(bool playerWonPoint, String reason) {
    final target = GameState.instance.targetScore;

    setState(() {
      _phase = MatchPhase.pointScored;
      _playerAction = playerWonPoint ? SpriteAction.idle : SpriteAction.loss;
      _ai.action = playerWonPoint ? SpriteAction.loss : SpriteAction.idle;
      _playerIsDiving = false;
      _ai.isDiving = false;

      if (playerWonPoint) {
        _playerScore++;
        _playerServing = true;
        _bannerTitle = 'POINT: YOU!';
        _bannerSubtitle = reason;
        _bannerColor = AppColors.mintAccent;
        AppAudio.playFeatureSfx(AppAssets.sfxPointCheer);
      } else {
        _aiScore++;
        _playerServing = false;
        _bannerTitle = 'POINT: OPPONENT!';
        _bannerSubtitle = reason;
        _bannerColor = AppColors.electricCoral;
        AppAudio.playFeatureSfx(AppAssets.sfxRoundLose);
      }
      _currentRally = 0;
      _blitzActive = false;
    });

    final playerWonMatch = _playerScore >= target && (_playerScore - _aiScore) >= 2;
    final aiWonMatch = _aiScore >= target && (_aiScore - _playerScore) >= 2;

    if (playerWonMatch || aiWonMatch) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _bannerTitle = playerWonMatch ? 'CHAMPIONSHIP POINT!' : 'MATCH POINT CONVERTED';
          _bannerSubtitle = playerWonMatch ? 'MATCH CONVERTED!' : 'DEFEAT CONCEDED';
          _bannerColor = playerWonMatch ? AppColors.opticYellow : AppColors.electricCoral;
        });
      });

      Future.delayed(const Duration(milliseconds: 2900), () {
        if (!mounted) return;
        GameState.instance.addMatchExperience(
          wonMatch: playerWonMatch,
          rallyHits: _longestRally,
          smashes: _totalSmashes,
        );
        setState(() => _phase = MatchPhase.gameOver);
        AppAudio.playFeatureSfx(playerWonMatch ? AppAssets.sfxMatchWinner : AppAssets.sfxMatchLose);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        _startIntroSequence();
      });
    }
  }

  void _resetFullMatch() {
    setState(() {
      _isPaused = false;
      _playerScore = 0;
      _aiScore = 0;
      _currentRally = 0;
      _longestRally = 0;
      _totalSmashes = 0;
      _playerBlitzEnergy = 0.0;
      _aiBlitzEnergy = 0.0;
      _playerServing = true;
      _phase = MatchPhase.intro;
      _startIntroSequence();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    final opponentChar = state.opponentCharacter;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: _phase == MatchPhase.gameOver || _isPaused,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _togglePause();
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: SafeArea(
          top: false,
          bottom: true,
          left: true,
          right: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

              return SelectionContainer.disabled(
                child: KeyboardListener(
                  focusNode: _keyboardFocusNode,
                  autofocus: true,
                  onKeyEvent: _handleKeyEvent,
                  child: GestureDetector(
                    onLongPress: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
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
                                aiColor: opponentChar.bodyColor,
                                aiAccent: opponentChar.accentColor,
                                aiCharId: opponentChar.id,
                                aiAction: _ai.action,
                                aiShotType: _ai.currentShot,
                                aiIsDiving: _ai.isDiving,
                                ballX: _physics.ballX,
                                ballY: _physics.ballY,
                                ballZ: _physics.ballZ,
                                ballVx: _physics.ballVx,
                                ballVy: _physics.ballVy,
                                ballVz: _physics.ballVz,
                                ballRotationAngle: _physics.ballRotationAngle,
                                ballTrail: _physics.ballTrail,
                                particles: _physics.particles,
                                shockwaves: _physics.shockwaves,
                                blitzActive: _blitzActive,
                                blitzColor: _blitzTrailColor,
                                equippedPaddle: state.selectedPaddle,
                                courtVenue: state.courtVenue,
                                sprites: _sprites,
                                isLandscape: isLandscape,
                                isServing: _phase == MatchPhase.serveBallInAir,
                                reticleScale: _reticleScale,
                                gameTime: _gameTime,
                              ),
                            ),
                          ),
                        ),

                        // Scoreboard
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 16,
                          right: 16,
                          child: GameplayScoreboard(
                            state: state,
                            opponentChar: opponentChar,
                            playerScore: _playerScore,
                            aiScore: _aiScore,
                            onPause: _togglePause,
                          ),
                        ),

                        // Center Banners
                        if (_bannerTitle.isNotEmpty)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _bannerTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                    color: _bannerColor,
                                    shadows: [
                                      Shadow(color: _bannerColor.withValues(alpha: 0.7), blurRadius: 20),
                                      const Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 3)),
                                    ],
                                  ),
                                ),
                                if (_bannerSubtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _bannerSubtitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                        // Timing Feedback
                        if (_timingFeedback.isNotEmpty)
                          Positioned(
                            bottom: isLandscape ? 90 : 130,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                _timingFeedback,
                                style: TextStyle(
                                  color: _timingFeedbackColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(color: _timingFeedbackColor.withValues(alpha: 0.8), blurRadius: 14),
                                    const Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        if (_phase != MatchPhase.gameOver && !_isPaused) ...[
                          Positioned(
                            bottom: 20,
                            left: 20,
                            child: VirtualJoystickWidget(
                              knobOffset: _joystickKnobOffset,
                              radius: _joystickRadius,
                              onStart: () {
                                setState(() {
                                  _isJoystickActive = true;
                                  _joystickKnobOffset = Offset.zero;
                                });
                              },
                              onUpdate: (delta) {
                                final localOffset = _joystickKnobOffset + delta;
                                final distance = localOffset.distance;
                                final clampedOffset = distance > _joystickRadius
                                    ? Offset.fromDirection(localOffset.direction, _joystickRadius)
                                    : localOffset;

                                final normalizedMag = clampedOffset.distance / _joystickRadius;
                                double curvedX = 0.0;
                                double curvedY = 0.0;

                                if (normalizedMag > _joystickDeadzone) {
                                  final remappedMag = ((normalizedMag - _joystickDeadzone) / (1.0 - _joystickDeadzone)).clamp(0.0, 1.0);
                                  final curvedMag = math.pow(remappedMag, 1.4).toDouble();
                                  final direction = clampedOffset.direction;
                                  curvedX = math.cos(direction) * curvedMag;
                                  curvedY = -math.sin(direction) * curvedMag;
                                }

                                setState(() {
                                  _joystickKnobOffset = clampedOffset;
                                  _joystickInputX = curvedX;
                                  _joystickInputY = curvedY;
                                });
                              },
                              onEnd: () {
                                setState(() {
                                  _isJoystickActive = false;
                                  _joystickKnobOffset = Offset.zero;
                                  _joystickInputX = 0.0;
                                  _joystickInputY = 0.0;
                                });
                              },
                            ),
                          ),

                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: GameplayActionCluster(
                              phase: _phase,
                              playerServing: _playerServing,
                              blitzEnergy: _playerBlitzEnergy,
                              isLandscape: isLandscape,
                              onToss: _executeManualServeToss,
                              onDriveServe: () => _strikeManualServe(ShotType.drive),
                              onLobServe: () => _strikeManualServe(ShotType.lob),
                              onSwing: (type) => _triggerPlayerSwing(type),
                            ),
                          ),
                        ],

                        if (_isPaused)
                          Positioned.fill(
                            child: PauseMenuOverlay(
                              onResume: _togglePause,
                              onForfeit: () => Navigator.pop(context),
                            ),
                          ),

                        if (_phase == MatchPhase.gameOver)
                          Positioned.fill(
                            child: AbsorbPointer(
                              absorbing: false,
                              child: GameOverModal(
                                playerWon: _playerScore > _aiScore,
                                playerScore: _playerScore,
                                aiScore: _aiScore,
                                onRematch: _resetFullMatch,
                                onReturn: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}