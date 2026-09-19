import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../widgets/ambient_background.dart';
import '../widgets/game_components.dart';

enum MatchPhase { intro, serveReady, countdown, activeRally, pointScored, gameOver }
enum ShotType { normal, smash, signatureBlitz }

class CourtGameplayScreen extends StatefulWidget {
  const CourtGameplayScreen({super.key});

  @override
  State<CourtGameplayScreen> createState() => _CourtGameplayScreenState();
}

class _CourtGameplayScreenState extends State<CourtGameplayScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Keyboard Controller
  final FocusNode _keyboardFocusNode = FocusNode();
  final Set<LogicalKeyboardKey> _activeKeys = {};

  // Mobile Virtual Joystick State (Full 360 Degree Control)
  Offset _joystickKnobOffset = Offset.zero;
  bool _isJoystickActive = false;
  double _joystickInputX = 0.0;
  double _joystickInputY = 0.0;
  static const double _joystickRadius = 45.0;

  // Match State
  MatchPhase _phase = MatchPhase.intro;
  double _phaseTimer = 0.0;
  int _countdownNumber = 3;
  bool _playerServing = true;
  String _toastMessage = 'MATCH START';
  String _timingFeedback = '';
  Color _timingFeedbackColor = AppTheme.opticYellow;

  // Kinetic Blitz Meter (0.0 to 1.0)
  double _playerBlitzEnergy = 0.0;
  double _aiBlitzEnergy = 0.0;
  bool _blitzActive = false;
  Color _blitzTrailColor = Colors.transparent;

  // Match Stats
  int _playerScore = 0;
  int _aiScore = 0;
  int _currentRally = 0;
  int _longestRally = 0;
  int _totalSmashes = 0;

  // 3D Player Positioning
  double _playerX = 0.0;
  double _playerTargetX = 0.0;
  double _playerVelocityX = 0.0;

  double _playerY = 0.0;
  double _playerTargetY = 0.0;
  double _playerVelocityY = 0.0;

  double _playerSwingAngle = 0.0;
  bool _playerIsSwinging = false;

  // AI State
  double _aiX = 0.0;
  double _aiVelocityX = 0.0;
  double _aiSwingAngle = 0.0;
  bool _aiIsSwinging = false;

  // Ball Coordinates & Velocities
  double _ballX = 0.0;
  double _ballY = 0.05;
  double _ballZ = 0.6;
  double _ballVx = 0.0;
  double _ballVy = 0.0;
  double _ballVz = 0.0;
  double _ballCurve = 0.0;

  static const double _gravity = 4.6;

  @override
  void initState() {
    super.initState();
    _startIntroSequence();
    _ticker = createTicker(_onGameTick)..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _activeKeys.add(event.logicalKey);

      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.keyJ) {
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
      _toastMessage = _getMatchSituationBanner();
      _phaseTimer = 1.4;
      _blitzActive = false;
      _resetBallPosition();
    });
  }

  void _resetBallPosition() {
    _playerY = 0.0;
    _playerTargetY = 0.0;
    _ballX = _playerServing ? _playerX : _aiX;
    _ballY = _playerServing ? 0.08 : 0.92;
    _ballZ = 0.65;
    _ballVx = 0;
    _ballVy = 0;
    _ballVz = 0;
    _ballCurve = 0;
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

  void _triggerServe() {
    final state = GameState.instance;
    final rng = math.Random();
    final char = state.selectedCharacter;
    final paddle = state.selectedPaddle;
    final pace = state.gamePace;

    setState(() {
      _phase = MatchPhase.activeRally;
      _toastMessage = '';
      _timingFeedback = '';

      if (_playerServing) {
        _ballVy = 0.76 * char.swingPower * paddle.power * pace;
        _ballVz = 2.1;
        _ballVx = (rng.nextDouble() - 0.5) * 0.42;
        _triggerPlayerSwing(ShotType.normal);
      } else {
        _ballVy = -0.76 * state.opponentCharacter.swingPower * pace;
        _ballVz = 2.1;
        _ballVx = (rng.nextDouble() - 0.5) * 0.42;
        _triggerAiSwing();
      }
    });
  }

  void _onGameTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    setState(() {
      if (_phase == MatchPhase.intro) {
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          _phase = MatchPhase.serveReady;
          _toastMessage = _playerServing ? 'PLAYER 1 TO SERVE' : 'OPPONENT TO SERVE';
          _phaseTimer = 1.0;
        }
        return;
      }

      if (_phase == MatchPhase.serveReady) {
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          _phase = MatchPhase.countdown;
          _countdownNumber = 3;
          _phaseTimer = 0.85;
        }
        return;
      }

      if (_phase == MatchPhase.countdown) {
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          _countdownNumber--;
          if (_countdownNumber > 0) {
            _phaseTimer = 0.85;
          } else {
            _triggerServe();
          }
        }
        return;
      }

      if (_phase != MatchPhase.activeRally) return;

      final state = GameState.instance;
      final character = state.selectedCharacter;

      // 1. Mobile Virtual Joystick 360 Movement (X & Y Depth)
      if (_isJoystickActive) {
        final joySpeedX = 2.6 * character.moveSpeed;
        final joySpeedY = 1.5 * character.moveSpeed;

        if (_joystickInputX.abs() > 0.04) {
          _playerTargetX = (_playerTargetX + _joystickInputX * joySpeedX * dt).clamp(-0.92, 0.92);
        }
        if (_joystickInputY.abs() > 0.04) {
          _playerTargetY = (_playerTargetY + _joystickInputY * joySpeedY * dt).clamp(-0.18, 0.34);
        }
      }

      // 2. Keyboard 2D Movement (WASD / Arrow Keys)
      final keySpeedX = 2.4 * character.moveSpeed;
      final keySpeedY = 1.4 * character.moveSpeed;

      // Lateral
      if (_activeKeys.contains(LogicalKeyboardKey.keyA) ||
          _activeKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        _playerTargetX = (_playerTargetX - keySpeedX * dt).clamp(-0.92, 0.92);
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyD) ||
          _activeKeys.contains(LogicalKeyboardKey.arrowRight)) {
        _playerTargetX = (_playerTargetX + keySpeedX * dt).clamp(-0.92, 0.92);
      }
      // Depth
      if (_activeKeys.contains(LogicalKeyboardKey.keyW) ||
          _activeKeys.contains(LogicalKeyboardKey.arrowUp)) {
        _playerTargetY = (_playerTargetY + keySpeedY * dt).clamp(-0.18, 0.34);
      }
      if (_activeKeys.contains(LogicalKeyboardKey.keyS) ||
          _activeKeys.contains(LogicalKeyboardKey.arrowDown)) {
        _playerTargetY = (_playerTargetY - keySpeedY * dt).clamp(-0.18, 0.34);
      }

      // Smooth Position Interpolation
      final oldPlayerX = _playerX;
      final oldPlayerY = _playerY;
      final responsiveness = 18.0 * character.moveSpeed;

      _playerX += (_playerTargetX - _playerX) * math.min(1.0, responsiveness * dt);
      _playerY += (_playerTargetY - _playerY) * math.min(1.0, responsiveness * dt);

      _playerVelocityX = (_playerX - oldPlayerX) / dt;
      _playerVelocityY = (_playerY - oldPlayerY) / dt;

      // 3. Swing Decay
      if (_playerIsSwinging) {
        _playerSwingAngle += 14.0 * dt;
        if (_playerSwingAngle >= math.pi) {
          _playerSwingAngle = 0.0;
          _playerIsSwinging = false;
        }
      }
      if (_aiIsSwinging) {
        _aiSwingAngle += 14.0 * dt;
        if (_aiSwingAngle >= math.pi) {
          _aiSwingAngle = 0.0;
          _aiIsSwinging = false;
        }
      }

      // 4. Ball Physics
      _ballVx += _ballCurve * dt * 48.0;
      _ballX += _ballVx * dt;
      _ballY += _ballVy * dt;
      _ballZ += _ballVz * dt;
      _ballVz -= _gravity * dt;

      // Sideline In-bounds Rebound
      if (_ballX <= -0.92) {
        _ballX = -0.92;
        _ballVx = -_ballVx * 0.92;
        _ballCurve *= -0.5;
      } else if (_ballX >= 0.92) {
        _ballX = 0.92;
        _ballVx = -_ballVx * 0.92;
        _ballCurve *= -0.5;
      }

      // Floor Bounce
      if (_ballZ <= 0.0) {
        _ballZ = 0.0;
        _ballVz = -_ballVz * 0.78;
      }

      // Net Collision Check (Y = 0.50, Height Z = 0.42m)
      if ((_ballY - 0.50).abs() < 0.03 && _ballZ < 0.42) {
        _pointEnded(playerWonPoint: _ballVy < 0, reason: 'NET FAULT');
        return;
      }

      // Tactical AI Engine
      final aiChar = state.opponentCharacter;
      final aiMultiplier = state.difficulty.speedMultiplier;
      final oldAiX = _aiX;
      _aiX += (_ballX - _aiX) * math.min(1.0, (5.2 * aiChar.moveSpeed * aiMultiplier) * dt);
      _aiX = _aiX.clamp(-0.85, 0.85);
      _aiVelocityX = (_aiX - oldAiX) / dt;

      // AI Active Shot Execution
      if (_ballVy > 0 && _ballY >= 0.88 && _ballY <= 1.05) {
        final distToAi = (_ballX - _aiX).abs();
        if (distToAi < (0.28 * aiChar.reachFactor) && _ballZ > 0.05) {
          _triggerAiSwing();
          _executeTacticalAiShot(aiChar, state.gamePace);
          _currentRally++;
          if (_currentRally > _longestRally) _longestRally = _currentRally;
        }
      }

      // Out of bounds / Missed Ball Check
      if (_ballY > 1.15) {
        _pointEnded(playerWonPoint: true, reason: 'WINNER');
      } else if (_ballY < -0.22) {
        _pointEnded(playerWonPoint: false, reason: 'MISSED BALL');
      }
    });
  }

  void _executeTacticalAiShot(CharacterModel aiChar, double pace) {
    final rng = math.Random();
    _aiBlitzEnergy = (_aiBlitzEnergy + 0.22).clamp(0.0, 1.0);

    final playerIsDeep = _playerY < 0.05;

    if (_aiBlitzEnergy >= 1.0) {
      _aiBlitzEnergy = 0.0;
      _blitzActive = true;
      _blitzTrailColor = aiChar.bodyColor;
      _ballVy = -1.15 * aiChar.swingPower * pace;
      _ballVz = 1.35;
      _ballVx = (_playerX > 0 ? -0.65 : 0.65);
      _timingFeedback = '⚠️ AI UNLEASHED ${aiChar.abilityName.toUpperCase()}!';
      _timingFeedbackColor = aiChar.accentColor;
    } else if (_ballZ > 1.15) {
      _blitzActive = false;
      _ballVy = -0.96 * aiChar.swingPower * pace;
      _ballVz = 1.35;
      _ballVx = (_playerX > 0 ? -0.55 : 0.55) + (rng.nextDouble() - 0.5) * 0.2;
      _timingFeedback = '⚡ AI OVERHEAD SMASH!';
      _timingFeedbackColor = const Color(0xFFFF5252);
    } else if (playerIsDeep && rng.nextDouble() < 0.38 && _currentRally > 1) {
      _blitzActive = false;
      _ballVy = -0.48 * pace;
      _ballVz = 1.5;
      _ballVx = (rng.nextDouble() - 0.5) * 0.35;
      _timingFeedback = '🎯 AI TACTICAL DINK!';
      _timingFeedbackColor = AppTheme.mintAccent;
    } else {
      _blitzActive = false;
      _ballVy = -0.74 * aiChar.swingPower * pace;
      _ballVz = 2.1;
      _ballVx = (_playerX > 0 ? -0.45 : 0.45) + (rng.nextDouble() - 0.5) * 0.25;
    }
  }

  void _triggerPlayerSwing(ShotType type) {
    _playerIsSwinging = true;
    _playerSwingAngle = 0.1;

    final state = GameState.instance;
    final character = state.selectedCharacter;
    final paddle = state.selectedPaddle;
    final pace = state.gamePace;

    final distY = (_ballY - _playerY).abs();
    final inStrikeZoneY = distY <= 0.19;
    final distX = (_ballX - _playerX).abs();
    final inStrikeZoneX = distX < (0.34 * character.reachFactor);
    final inAir = _ballZ > 0.05 && _ballZ < 2.4;

    if (inStrikeZoneY && inStrikeZoneX && inAir && _ballVy < 0) {
      final isSmash = type == ShotType.smash || type == ShotType.signatureBlitz;
      final isPerfect = distY < 0.06;

      _playerBlitzEnergy = (_playerBlitzEnergy + (isPerfect ? 0.35 : 0.20)).clamp(0.0, 1.0);

      if ((isSmash || type == ShotType.signatureBlitz) && _playerBlitzEnergy >= 1.0) {
        _playerBlitzEnergy = 0.0;
        _blitzActive = true;
        _blitzTrailColor = character.accentColor;
        _totalSmashes++;

        if (character.id == 'aria') {
          _ballVy = 1.25 * paddle.power * pace;
          _ballVz = 1.3;
          _ballVx = (_ballX - _playerX) * 1.5;
          _ballCurve = 0;
        } else if (character.id == 'marcus') {
          _ballVy = 1.15 * paddle.power * pace;
          _ballVz = 1.0;
          _ballVx = (_ballX - _playerX) * 1.2;
          _ballCurve = 0;
        } else if (character.id == 'elena') {
          _ballVy = 0.95 * paddle.power * pace;
          _ballVz = 1.6;
          _ballVx = (_ballX - _playerX) * 0.8;
          _ballCurve = (_playerX > 0 ? -1.8 : 1.8) * paddle.spin;
        } else {
          _ballVy = 1.08 * paddle.power * pace;
          _ballVz = 1.4;
          _ballVx = (_ballX - _playerX) * 1.3;
          _ballCurve = 0;
        }

        _timingFeedback = '🌟 SIGNATURE ${character.abilityName.toUpperCase()}!';
        _timingFeedbackColor = character.accentColor;
      } else {
        _blitzActive = false;
        if (isSmash) _totalSmashes++;

        if (isPerfect) {
          _timingFeedback = isSmash ? '⚡ PERFECT SMASH!' : '🔥 PERFECT DRIVE!';
          _timingFeedbackColor = AppTheme.opticYellow;
        } else if (_ballY > _playerY + 0.06) {
          _timingFeedback = 'EARLY CONTACT';
          _timingFeedbackColor = AppTheme.mintAccent;
        } else {
          _timingFeedback = 'LATE CONTACT';
          _timingFeedbackColor = Colors.orangeAccent;
        }

        final combinedPower = character.swingPower * paddle.power * pace;
        _ballVy = (isSmash ? 0.96 : 0.72) * combinedPower;
        _ballVz = isSmash ? 1.35 : 2.2;
        _ballVx = (_ballX - _playerX) * 1.25 + ((math.Random().nextDouble() - 0.5) * 0.25);
        _ballCurve = ((_ballX - _playerX) / 0.3) * paddle.spin * 0.6;
      }

      _currentRally++;
      if (_currentRally > _longestRally) _longestRally = _currentRally;

      if (state.hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
    } else if (_phase == MatchPhase.activeRally && _ballVy < 0 && distY < 0.3) {
      _timingFeedback = 'WHIFF!';
      _timingFeedbackColor = const Color(0xFFFF5252);
    }
  }

  void _triggerAiSwing() {
    _aiIsSwinging = true;
    _aiSwingAngle = 0.1;
  }

  void _pointEnded({required bool playerWonPoint, required String reason}) {
    final target = GameState.instance.targetScore;

    setState(() {
      _phase = MatchPhase.pointScored;
      _toastMessage = playerWonPoint ? 'POINT: YOU ($reason)' : 'POINT: OPPONENT ($reason)';
      if (playerWonPoint) {
        _playerScore++;
        _playerServing = true;
      } else {
        _aiScore++;
        _playerServing = false;
      }
      _currentRally = 0;
      _blitzActive = false;
    });

    final playerWonMatch = _playerScore >= target && (_playerScore - _aiScore) >= 2;
    final aiWonMatch = _aiScore >= target && (_aiScore - _playerScore) >= 2;

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (playerWonMatch || aiWonMatch) {
        GameState.instance.addMatchExperience(
          wonMatch: playerWonMatch,
          rallyHits: _longestRally,
          smashes: _totalSmashes,
        );

        setState(() => _phase = MatchPhase.gameOver);
      } else {
        _startIntroSequence();
      }
    });
  }

  void _resetFullMatch() {
    setState(() {
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

  void _onPointerHover(PointerHoverEvent event, Size screenSize) {
    if (_isJoystickActive) return;
    final courtCenterX = screenSize.width / 2;
    final halfCourtWidth = math.min(screenSize.width * 0.44, 280.0);
    final normalizedX = ((event.localPosition.dx - courtCenterX) / halfCourtWidth).clamp(-0.92, 0.92);
    setState(() => _playerTargetX = normalizedX);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (_phase != MatchPhase.activeRally && _phase != MatchPhase.countdown) return;
      final isRightClick = event.buttons == kSecondaryMouseButton;
      _triggerPlayerSwing(isRightClick ? ShotType.smash : ShotType.normal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF070B09),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

            return KeyboardListener(
              focusNode: _keyboardFocusNode,
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: Stack(
                children: [
                  // 1. Perspective 3D Court Canvas
                  Positioned.fill(
                    child: Listener(
                      onPointerDown: _onPointerDown,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.none,
                        onHover: (e) => _onPointerHover(e, screenSize),
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
                            aiX: _aiX,
                            aiVelocityX: _aiVelocityX,
                            aiSwingAngle: _aiSwingAngle,
                            aiIsSwinging: _aiIsSwinging,
                            aiColor: state.opponentCharacter.bodyColor,
                            aiAccent: state.opponentCharacter.accentColor,
                            ballX: _ballX,
                            ballY: _ballY,
                            ballZ: _ballZ,
                            ballVx: _ballVx,
                            ballVy: _ballVy,
                            ballVz: _ballVz,
                            blitzActive: _blitzActive,
                            blitzColor: _blitzTrailColor,
                            equippedPaddle: state.selectedPaddle,
                            courtVenue: state.courtVenue,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Top Match Scoreboard
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: AppTheme.glassFill),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Text('${state.selectedCharacter.name.split(" ")[0].toUpperCase()}: $_playerScore',
                                  style: TextStyle(color: state.selectedCharacter.bodyColor, fontWeight: FontWeight.w900, fontSize: 13)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('•', style: TextStyle(color: Colors.white30)),
                              ),
                              Text('${state.opponentCharacter.name.split(" ")[0].toUpperCase()}: $_aiScore',
                                  style: TextStyle(color: state.opponentCharacter.bodyColor, fontWeight: FontWeight.w900, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.glassFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'FIRST TO ${state.targetScore}',
                            style: const TextStyle(color: AppTheme.mintAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Central Blitz Energy Gauge
                  Positioned(
                    top: 68,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _playerBlitzEnergy >= 1.0 ? AppTheme.opticYellow : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 16, color: _playerBlitzEnergy >= 1.0 ? AppTheme.opticYellow : Colors.white38),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 110,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _playerBlitzEnergy,
                                  minHeight: 4,
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation(
                                    _playerBlitzEnergy >= 1.0 ? AppTheme.opticYellow : state.selectedCharacter.accentColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. Timing Feedback
                  if (_timingFeedback.isNotEmpty)
                    Positioned(
                      bottom: 120,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.80),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _timingFeedbackColor.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            _timingFeedback,
                            style: TextStyle(
                              color: _timingFeedbackColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 5. Toast Banner
                  if (_phase == MatchPhase.intro ||
                      _phase == MatchPhase.serveReady ||
                      _phase == MatchPhase.pointScored)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1B16).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.opticYellow.withValues(alpha: 0.4)),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
                        ),
                        child: Text(
                          _toastMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                  // 6. Countdown Numbers
                  if (_phase == MatchPhase.countdown)
                    Center(
                      child: Text(
                        '$_countdownNumber',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.opticYellow,
                          shadows: [Shadow(color: Colors.black, blurRadius: 20)],
                        ),
                      ),
                    ),

                  // 7. VIRTUAL CONTROLS
                  // A. LEFT THUMB: 360 DEGREE VIRTUAL JOYSTICK
                  Positioned(
                    bottom: 24,
                    left: 20,
                    child: GestureDetector(
                      onPanStart: (_) {
                        setState(() {
                          _isJoystickActive = true;
                          _joystickKnobOffset = Offset.zero;
                        });
                      },
                      onPanUpdate: (details) {
                        final localOffset = _joystickKnobOffset + details.delta;
                        final distance = localOffset.distance;
                        final clampedOffset = distance > _joystickRadius
                            ? Offset.fromDirection(localOffset.direction, _joystickRadius)
                            : localOffset;

                        setState(() {
                          _joystickKnobOffset = clampedOffset;
                          _joystickInputX = clampedOffset.dx / _joystickRadius;
                          _joystickInputY = -clampedOffset.dy / _joystickRadius;
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _isJoystickActive = false;
                          _joystickKnobOffset = Offset.zero;
                          _joystickInputX = 0.0;
                          _joystickInputY = 0.0;
                        });
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Center(
                          child: Transform.translate(
                            offset: _joystickKnobOffset,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.opticYellow.withValues(alpha: 0.85),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.opticYellow.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.control_camera_rounded, size: 18, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // B. RIGHT THUMB: ACTION BUTTON CLUSTER
                  Positioned(
                    bottom: 20,
                    right: 18,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _mobileActionButton(
                          label: 'BLITZ',
                          icon: Icons.bolt,
                          size: 50,
                          color: _playerBlitzEnergy >= 1.0 ? AppTheme.opticYellow : Colors.white12,
                          textColor: _playerBlitzEnergy >= 1.0 ? Colors.black : Colors.white38,
                          glow: _playerBlitzEnergy >= 1.0,
                          onTap: () {
                            if (_playerBlitzEnergy >= 1.0) {
                              _triggerPlayerSwing(ShotType.signatureBlitz);
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        _mobileActionButton(
                          label: 'SMASH',
                          icon: Icons.flash_on_rounded,
                          size: 58,
                          color: const Color(0xFFFF7043),
                          textColor: Colors.white,
                          onTap: () => _triggerPlayerSwing(ShotType.smash),
                        ),
                        const SizedBox(width: 10),
                        _mobileActionButton(
                          label: 'DRIVE',
                          icon: Icons.sports_tennis,
                          size: 68,
                          color: AppTheme.mintAccent,
                          textColor: Colors.black,
                          onTap: () => _triggerPlayerSwing(ShotType.normal),
                        ),
                      ],
                    ),
                  ),

                  // 8. Game Over Modal
                  if (_phase == MatchPhase.gameOver)
                    _buildGameOverStatsModal(
                      playerWon: _playerScore > _aiScore,
                      state: state,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _mobileActionButton({
    required String label,
    required IconData icon,
    required double size,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    bool glow = false,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        if (GameState.instance.hapticsEnabled) {
          HapticFeedback.lightImpact();
        }
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.85),
          border: Border.all(color: Colors.white38, width: 2),
          boxShadow: glow
              ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 18, spreadRadius: 2)]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size * 0.38, color: textColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverStatsModal({
    required bool playerWon,
    required GameState state,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          borderColor: playerWon ? AppTheme.opticYellow : const Color(0xFFFF4D4D),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                playerWon ? Icons.emoji_events_rounded : Icons.highlight_off_rounded,
                size: 58,
                color: playerWon ? AppTheme.opticYellow : const Color(0xFFFF4D4D),
              ),
              const SizedBox(height: 12),
              Text(
                playerWon ? 'CHAMPIONSHIP VICTORY!' : 'MATCH DEFEAT',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                'Final Score: $_playerScore - $_aiScore',
                style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _modalStatRow('Longest Rally Streak', '$_longestRally hits'),
                    const Divider(color: Colors.white12, height: 16),
                    _modalStatRow('Kinetic Smashes Hit', '$_totalSmashes'),
                    const Divider(color: Colors.white12, height: 16),
                    _modalStatRow('Target Played', '${state.targetScore} Points'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              BouncyButton(
                onTap: _resetFullMatch,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.opticYellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('PLAY REMATCH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              BouncyButton(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.glassFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: const Center(
                    child: Text('RETURN TO LOBBY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
      ],
    );
  }
}

// ============================================================================
// ELEVATED 3D COURT PAINTER WITH NON-LINEAR PERSPECTIVE DEPTH
// ============================================================================

class PerspectiveCourtPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final double playerVelocityX;
  final double playerVelocityY;
  final double playerSwingAngle;
  final bool playerIsSwinging;
  final Color playerColor;
  final Color playerAccent;

  final double aiX;
  final double aiVelocityX;
  final double aiSwingAngle;
  final bool aiIsSwinging;
  final Color aiColor;
  final Color aiAccent;

  final double ballX;
  final double ballY;
  final double ballZ;
  final double ballVx;
  final double ballVy;
  final double ballVz;
  final bool blitzActive;
  final Color blitzColor;
  final PaddleModel equippedPaddle;
  final String courtVenue;

  PerspectiveCourtPainter({
    required this.playerX,
    required this.playerY,
    required this.playerVelocityX,
    required this.playerVelocityY,
    required this.playerSwingAngle,
    required this.playerIsSwinging,
    required this.playerColor,
    required this.playerAccent,
    required this.aiX,
    required this.aiVelocityX,
    required this.aiSwingAngle,
    required this.aiIsSwinging,
    required this.aiColor,
    required this.aiAccent,
    required this.ballX,
    required this.ballY,
    required this.ballZ,
    required this.ballVx,
    required this.ballVy,
    required this.ballVz,
    required this.blitzActive,
    required this.blitzColor,
    required this.equippedPaddle,
    required this.courtVenue,
  });

  // NON-LINEAR PINHOLE PERSPECTIVE CURVE
  // Pushes the net to ~62% of vertical court pixels to match human visual perception!
  double _perspectiveDepth(double y) {
    final clampedY = y.clamp(-0.25, 1.05);
    if (clampedY >= 0) {
      return (clampedY * 1.65) / (1.0 + 0.65 * clampedY);
    } else {
      return clampedY * 1.65;
    }
  }

  Offset project3D(double x, double y, double z, Size size) {
    final centerX = size.width / 2;
    final nearY = size.height * 0.81;
    final farY = size.height * 0.22;
    final nearWidth = math.min(size.width * 0.90, 540.0);
    final farWidth = nearWidth * 0.48;

    final t = _perspectiveDepth(y);
    final courtWidthAtY = nearWidth + (farWidth - nearWidth) * t;
    final groundY = nearY + (farY - nearY) * t;

    final screenX = centerX + (x * (courtWidthAtY / 2));
    final depthScale = (1.0 - (t.clamp(0.0, 1.0) * 0.50)).clamp(0.25, 1.0);
    final screenY = groundY - (z * 135.0 * depthScale);

    return Offset(screenX, screenY);
  }

  double getScale(double y) {
    final t = _perspectiveDepth(y);
    return (1.0 - (t.clamp(0.0, 1.0) * 0.48)).clamp(0.40, 1.15);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Color apronColor;
    Color courtColor;
    Color kitchenColor;
    Color lineCol;
    bool hasNeonGlow = false;

    if (courtVenue == 'Midnight Stadium') {
      apronColor = const Color(0xFF070B10);
      courtColor = const Color(0xFF0D1826);
      kitchenColor = const Color(0xFF142438);
      lineCol = const Color(0xFF00E5FF);
      hasNeonGlow = true;
    } else if (courtVenue == 'Sunlit Beach') {
      apronColor = const Color(0xFFD4A373);
      courtColor = const Color(0xFF2A9D8F);
      kitchenColor = const Color(0xFF264653);
      lineCol = const Color(0xFFFFF7E6);
    } else {
      apronColor = const Color(0xFF102840);
      courtColor = const Color(0xFF1C5382);
      kitchenColor = const Color(0xFF163E63);
      lineCol = Colors.white;
    }

    // 0. STADIUM SURROUNDING & LED HOARDING BACKDROP
    _drawStadiumAtmosphere(canvas, size, lineCol);

    // 1. 3D SLAB DROP SHADOW & ELEVATION BEVEL
    _draw3DCourtSlab(canvas, size, apronColor);

    // 2. PLAYABLE COURT
    final courtPath = Path()
      ..moveTo(project3D(-1.0, 0.0, 0, size).dx, project3D(-1.0, 0.0, 0, size).dy)
      ..lineTo(project3D(1.0, 0.0, 0, size).dx, project3D(1.0, 0.0, 0, size).dy)
      ..lineTo(project3D(1.0, 1.0, 0, size).dx, project3D(1.0, 1.0, 0, size).dy)
      ..lineTo(project3D(-1.0, 1.0, 0, size).dx, project3D(-1.0, 1.0, 0, size).dy)
      ..close();

    final courtBounds = courtPath.getBounds();
    final courtPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          courtColor.withValues(alpha: 0.90),
          courtColor,
          courtColor.withValues(alpha: 0.85),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(courtBounds);
    canvas.drawPath(courtPath, courtPaint);

    // 3. KITCHEN (NON-VOLLEY ZONE)
    final kitchenPath = Path()
      ..moveTo(project3D(-1.0, 0.34, 0, size).dx, project3D(-1.0, 0.34, 0, size).dy)
      ..lineTo(project3D(1.0, 0.34, 0, size).dx, project3D(1.0, 0.34, 0, size).dy)
      ..lineTo(project3D(1.0, 0.66, 0, size).dx, project3D(1.0, 0.66, 0, size).dy)
      ..lineTo(project3D(-1.0, 0.66, 0, size).dx, project3D(-1.0, 0.66, 0, size).dy)
      ..close();
    canvas.drawPath(kitchenPath, Paint()..color = kitchenColor);

    // 4. CRISP REGULATION COURT LINES
    final linePaint = Paint()
      ..color = lineCol.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    if (hasNeonGlow) {
      final glowPaint = Paint()
        ..color = lineCol.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(courtPath, glowPaint);
    }

    canvas.drawPath(courtPath, linePaint);

    // Buffer Baseline behind player
    final bufferLinePaint = Paint()
      ..color = lineCol.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawLine(project3D(-1.0, -0.18, 0, size), project3D(1.0, -0.18, 0, size), bufferLinePaint);

    // Kitchen & Center Service Lines
    canvas.drawLine(project3D(-1.0, 0.34, 0, size), project3D(1.0, 0.34, 0, size), linePaint);
    canvas.drawLine(project3D(-1.0, 0.66, 0, size), project3D(1.0, 0.66, 0, size), linePaint);
    canvas.drawLine(project3D(0.0, 0.0, 0, size), project3D(0.0, 0.34, 0, size), linePaint);
    canvas.drawLine(project3D(0.0, 0.66, 0, size), project3D(0.0, 1.0, 0, size), linePaint);

    // 5. OPPONENT RIG
    _drawAnimatedCharacter(
      canvas: canvas,
      size: size,
      x: aiX,
      y: 1.0,
      velocityX: aiVelocityX,
      swingAngle: aiSwingAngle,
      isSwinging: aiIsSwinging,
      bodyColor: aiColor,
      paddlePrimary: const Color(0xFF222222),
      paddleAccent: aiAccent,
      isOpponent: true,
    );

    // 6. 3D NET WITH CENTER SAG & FLOOR SHADOW
    _draw3DPickleballNet(canvas, size, lineCol);

    // 7. BALL LANDING RETICLE
    _drawLandingReticle(canvas, size);

    // 8. BALL & 3D GROUND SHADOW
    _drawBallAndShadow(canvas, size);

    // 9. PLAYER RIG
    _drawAnimatedCharacter(
      canvas: canvas,
      size: size,
      x: playerX,
      y: playerY,
      velocityX: playerVelocityX,
      swingAngle: playerSwingAngle,
      isSwinging: playerIsSwinging,
      bodyColor: playerColor,
      paddlePrimary: equippedPaddle.primaryColor,
      paddleAccent: equippedPaddle.accentColor,
      isOpponent: false,
    );
  }

  void _drawStadiumAtmosphere(Canvas canvas, Size size, Color accentColor) {
    // Top stadium LED ribbon hoarding behind far baseline
    final pLeft = project3D(-1.40, 1.06, 0, size);
    final pRight = project3D(1.40, 1.06, 0, size);

    final hoardingHeight = 22.0;
    final hoardingPath = Path()
      ..moveTo(pLeft.dx, pLeft.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..lineTo(pRight.dx, pRight.dy - hoardingHeight)
      ..lineTo(pLeft.dx, pLeft.dy - hoardingHeight)
      ..close();

    canvas.drawPath(
      hoardingPath,
      Paint()..color = const Color(0xFF05080C),
    );

    // Neon trim along ribbon top
    canvas.drawLine(
      Offset(pLeft.dx, pLeft.dy - hoardingHeight),
      Offset(pRight.dx, pRight.dy - hoardingHeight),
      Paint()
        ..color = accentColor.withValues(alpha: 0.7)
        ..strokeWidth = 2.0,
    );
  }

  void _draw3DCourtSlab(Canvas canvas, Size size, Color apronColor) {
    const bevelDrop = 10.0;

    final pTopLeft = project3D(-1.35, 1.05, 0, size);
    final pTopRight = project3D(1.40, 1.05, 0, size);
    final pBottomRight = project3D(1.35, -0.22, 0, size);
    final pBottomLeft = project3D(-1.35, -0.22, 0, size);

    // Ambient drop shadow beneath the slab
    final shadowPath = Path()
      ..moveTo(pBottomLeft.dx, pBottomLeft.dy + bevelDrop + 6)
      ..lineTo(pBottomRight.dx, pBottomRight.dy + bevelDrop + 6)
      ..lineTo(pTopRight.dx, pTopRight.dy + 8)
      ..lineTo(pTopLeft.dx, pTopLeft.dy + 8)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Front Thickness Bevel
    final frontBevelPath = Path()
      ..moveTo(pBottomLeft.dx, pBottomLeft.dy)
      ..lineTo(pBottomRight.dx, pBottomRight.dy)
      ..lineTo(pBottomRight.dx, pBottomRight.dy + bevelDrop)
      ..lineTo(pBottomLeft.dx, pBottomLeft.dy + bevelDrop)
      ..close();
    canvas.drawPath(
      frontBevelPath,
      Paint()..color = apronColor.withValues(alpha: 0.65),
    );

    // Right Side Thickness Bevel
    final sideBevelPath = Path()
      ..moveTo(pBottomRight.dx, pBottomRight.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy + bevelDrop * 0.4)
      ..lineTo(pBottomRight.dx, pBottomRight.dy + bevelDrop)
      ..close();
    canvas.drawPath(
      sideBevelPath,
      Paint()..color = apronColor.withValues(alpha: 0.45),
    );

    // Main Apron Floor Surface
    final apronPath = Path()
      ..moveTo(pBottomLeft.dx, pBottomLeft.dy)
      ..lineTo(pBottomRight.dx, pBottomRight.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pTopLeft.dx, pTopLeft.dy)
      ..close();
    canvas.drawPath(apronPath, Paint()..color = apronColor);
  }

  void _draw3DPickleballNet(Canvas canvas, Size size, Color cordColor) {
    const postHeightZ = 0.44; // 36 inches at posts
    const centerDipZ = 0.40;  // 34 inches at center strap

    final leftBase = project3D(-1.08, 0.5, 0.0, size);
    final leftTop = project3D(-1.08, 0.5, postHeightZ, size);

    final rightBase = project3D(1.08, 0.5, 0.0, size);
    final rightTop = project3D(1.08, 0.5, postHeightZ, size);

    final centerTop = project3D(0.0, 0.5, centerDipZ, size);
    final centerBase = project3D(0.0, 0.5, 0.0, size);

    // 1. Net Translucent Floor Shadow on Kitchen
    final shadowFloorPath = Path()
      ..moveTo(leftBase.dx, leftBase.dy - 3)
      ..lineTo(rightBase.dx, rightBase.dy - 3)
      ..lineTo(rightBase.dx, rightBase.dy + 8)
      ..lineTo(leftBase.dx, leftBase.dy + 8)
      ..close();
    canvas.drawPath(
      shadowFloorPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 2. Net Mesh Surface (With subtle Sag Bézier Curve)
    final meshPath = Path()
      ..moveTo(leftBase.dx, leftBase.dy)
      ..lineTo(rightBase.dx, rightBase.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..quadraticBezierTo(centerTop.dx, centerTop.dy, leftTop.dx, leftTop.dy)
      ..close();

    canvas.drawPath(
      meshPath,
      Paint()..color = cordColor.withValues(alpha: 0.30),
    );

    // 3. Top White Vinyl Net Tape (Bézier Sag)
    final tapePath = Path()
      ..moveTo(leftTop.dx, leftTop.dy)
      ..quadraticBezierTo(centerTop.dx, centerTop.dy, rightTop.dx, rightTop.dy);

    canvas.drawPath(
      tapePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6,
    );

    // 4. Center Strap (Regulation 2-inch vertical white band)
    canvas.drawLine(
      centerTop,
      centerBase,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.90)
        ..strokeWidth = 2.4,
    );

    // 5. 3D Metal Net Posts with Top Caps
    final postPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final capPaint = Paint()
      ..color = AppTheme.opticYellow
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(leftBase, leftTop, postPaint);
    canvas.drawLine(rightBase, rightTop, postPaint);
    canvas.drawCircle(leftTop, 3.5, capPaint);
    canvas.drawCircle(rightTop, 3.5, capPaint);
  }

  void _drawLandingReticle(Canvas canvas, Size size) {
    if (ballZ <= 0.04 || ballVy >= 0) return;

    const g = 4.6;
    final discriminant = (ballVz * ballVz) + (2 * g * ballZ);
    if (discriminant < 0) return;

    final timeToFloor = (ballVz + math.sqrt(discriminant)) / g;
    if (timeToFloor <= 0.02 || timeToFloor > 1.8) return;

    final landingX = (ballX + (ballVx * timeToFloor)).clamp(-0.95, 0.95);
    final landingY = (ballY + (ballVy * timeToFloor));

    if (landingY < -0.22 || landingY > 0.55) return;

    final targetPos = project3D(landingX, landingY, 0.0, size);
    final scale = getScale(landingY);

    final outerRadius = 24.0 * scale;
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawOval(
      Rect.fromCenter(center: targetPos, width: outerRadius * 2, height: outerRadius * 0.9),
      ringPaint,
    );

    final progress = (ballZ / 1.6).clamp(0.0, 1.0);
    final innerRadius = outerRadius * progress;
    if (innerRadius > 1.5) {
      final innerPaint = Paint()
        ..color = AppTheme.opticYellow.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawOval(
        Rect.fromCenter(center: targetPos, width: innerRadius * 2, height: innerRadius * 0.9),
        innerPaint,
      );
    }

    canvas.drawCircle(targetPos, 3.0 * scale, Paint()..color = AppTheme.opticYellow);

    final currentShadowPos = project3D(ballX, ballY, 0.0, size);
    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(currentShadowPos, targetPos, pathPaint);
  }

  void _drawBallAndShadow(Canvas canvas, Size size) {
    final floorPos = project3D(ballX, ballY, 0.0, size);
    final ballPos = project3D(ballX, ballY, ballZ, size);
    final scale = getScale(ballY);

    final shadowSize = (1.0 + ballZ * 0.65) * scale;
    final shadowOpacity = (0.50 / (1.0 + ballZ * 0.8)).clamp(0.12, 0.50);

    canvas.drawOval(
      Rect.fromCenter(center: floorPos, width: 20 * shadowSize, height: 9 * shadowSize),
      Paint()..color = Colors.black.withValues(alpha: shadowOpacity),
    );

    final radius = (10.0 * scale).clamp(4.5, 14.0);

    if (blitzActive) {
      canvas.drawCircle(
        ballPos,
        radius * 2.2,
        Paint()
          ..color = blitzColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0),
      );
    }

    final ballPaint = Paint()..color = AppTheme.opticYellow;
    canvas.drawCircle(ballPos, radius, ballPaint);

    final dimplePaint = Paint()..color = const Color(0xFF9EBF00);
    canvas.drawCircle(ballPos, radius * 0.22, dimplePaint);
    canvas.drawCircle(ballPos + Offset(-radius * 0.35, -radius * 0.2), radius * 0.15, dimplePaint);
    canvas.drawCircle(ballPos + Offset(radius * 0.35, radius * 0.2), radius * 0.15, dimplePaint);
  }

  void _drawAnimatedCharacter({
    required Canvas canvas,
    required Size size,
    required double x,
    required double y,
    required double velocityX,
    required double swingAngle,
    required bool isSwinging,
    required Color bodyColor,
    required Color paddlePrimary,
    required Color paddleAccent,
    required bool isOpponent,
  }) {
    final basePos = project3D(x, y, 0.0, size);
    final scale = getScale(y);
    final tiltAngle = (velocityX * 0.07).clamp(-0.25, 0.25);

    canvas.drawOval(
      Rect.fromCenter(center: basePos, width: 42 * scale, height: 16 * scale),
      Paint()..color = Colors.black45,
    );

    canvas.save();
    canvas.translate(basePos.dx, basePos.dy - (32 * scale));
    canvas.rotate(tiltAngle);

    final bodyRadius = 23 * scale;
    canvas.drawCircle(Offset.zero, bodyRadius, Paint()..color = bodyColor);
    canvas.drawCircle(
      Offset.zero,
      bodyRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale,
    );

    final paddleArmOffset = Offset(24 * scale, 4 * scale);
    canvas.save();
    canvas.translate(paddleArmOffset.dx, paddleArmOffset.dy);

    final baseRotation = isOpponent ? -0.3 : 0.3;
    final activeRotation = isSwinging ? (isOpponent ? swingAngle : -swingAngle) : 0.0;
    canvas.rotate(baseRotation + activeRotation);

    final paddleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 22 * scale, height: 32 * scale),
      Radius.circular(6 * scale),
    );
    canvas.drawRRect(paddleRect, Paint()..color = paddlePrimary);
    canvas.drawRRect(
      paddleRect,
      Paint()
        ..color = paddleAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale,
    );
    canvas.drawRect(
      Rect.fromLTWH(-3 * scale, 16 * scale, 6 * scale, 10 * scale),
      Paint()..color = const Color(0xFF111111),
    );

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PerspectiveCourtPainter oldDelegate) => true;
}