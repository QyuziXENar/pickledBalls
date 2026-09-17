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

  // Pickleball Rules & Stats
  int _bouncesThisRally = 0;
  bool _serveCompleted = false;
  int _playerScore = 0;
  int _aiScore = 0;
  int _currentRally = 0;
  int _longestRally = 0;
  int _totalSmashes = 0;

  // 3D Kinematics
  double _playerX = 0.0;
  double _playerTargetX = 0.0;
  double _playerVelocityX = 0.0;
  double _playerSwingAngle = 0.0;
  bool _playerIsSwinging = false;

  double _aiX = 0.0;
  double _aiVelocityX = 0.0;
  double _aiSwingAngle = 0.0;
  bool _aiIsSwinging = false;

  // Ball Coordinates
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
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startIntroSequence() {
    setState(() {
      _phase = MatchPhase.intro;
      _toastMessage = _getMatchSituationBanner();
      _phaseTimer = 1.4;
      _bouncesThisRally = 0;
      _serveCompleted = false;
      _blitzActive = false;
      _resetBallPosition();
    });
  }

  void _resetBallPosition() {
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
      _bouncesThisRally = 0;
      _serveCompleted = true;

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

      // Lateral Movement
      final oldPlayerX = _playerX;
      final responsiveness = 18.0 * character.moveSpeed;
      _playerX += (_playerTargetX - _playerX) * math.min(1.0, responsiveness * dt);
      _playerVelocityX = (_playerX - oldPlayerX) / dt;

      // Swing Decay
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

      // Ballistics with Magnus Lateral Curve
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
        _bouncesThisRally++;
      }

      // Net Check (Y = 0.50, Height Z = 0.42m)
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
          if (_serveCompleted && _bouncesThisRally < 1 && _playerServing) {
            _pointEnded(playerWonPoint: true, reason: 'TWO-BOUNCE FAULT (AI volleyed serve!)');
            return;
          }

          _triggerAiSwing();
          _executeTacticalAiShot(aiChar, state.gamePace);
          _currentRally++;
          if (_currentRally > _longestRally) _longestRally = _currentRally;
        }
      }

      // Missed Ball Check
      if (_ballY > 1.15) {
        _pointEnded(playerWonPoint: true, reason: 'WINNER');
      } else if (_ballY < -0.12) {
        _pointEnded(playerWonPoint: false, reason: 'MISSED BALL');
      }
    });
  }

  void _executeTacticalAiShot(CharacterModel aiChar, double pace) {
    final rng = math.Random();
    _aiBlitzEnergy = (_aiBlitzEnergy + 0.22).clamp(0.0, 1.0);

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
    } else if (rng.nextDouble() < 0.28 && _currentRally > 2) {
      _blitzActive = false;
      _ballVy = -0.52 * pace;
      _ballVz = 1.6;
      _ballVx = (rng.nextDouble() - 0.5) * 0.35;
      _timingFeedback = '🎯 AI KITCHEN DINK!';
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

    final inStrikeZoneY = _ballY >= -0.05 && _ballY <= 0.22;
    final distToPaddle = (_ballX - _playerX).abs();
    final inStrikeZoneX = distToPaddle < (0.32 * character.reachFactor);
    final inAir = _ballZ > 0.08 && _ballZ < 2.3;

    if (inStrikeZoneY && inStrikeZoneX && inAir && _ballVy < 0) {
      if (_serveCompleted && _bouncesThisRally < 1 && !_playerServing) {
        _pointEnded(playerWonPoint: false, reason: 'TWO-BOUNCE FAULT (Must bounce on return!)');
        return;
      }
      if (_ballY >= 0.34 && _ballZ > 0.15 && _bouncesThisRally == 0) {
        _pointEnded(playerWonPoint: false, reason: 'KITCHEN FAULT (Volleyed in NVZ!)');
        return;
      }

      final isRightClick = type == ShotType.smash;
      final timingOffset = (_ballY - 0.08).abs();
      final isPerfect = timingOffset < 0.04;

      _playerBlitzEnergy = (_playerBlitzEnergy + (isPerfect ? 0.35 : 0.20)).clamp(0.0, 1.0);

      if (isRightClick && _playerBlitzEnergy >= 1.0) {
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
        if (isRightClick) _totalSmashes++;

        if (isPerfect) {
          _timingFeedback = isRightClick ? '⚡ PERFECT SMASH!' : '🔥 PERFECT DRIVE!';
          _timingFeedbackColor = AppTheme.opticYellow;
        } else if (_ballY > 0.08) {
          _timingFeedback = 'EARLY CONTACT';
          _timingFeedbackColor = AppTheme.mintAccent;
        } else {
          _timingFeedback = 'LATE CONTACT';
          _timingFeedbackColor = Colors.orangeAccent;
        }

        final combinedPower = character.swingPower * paddle.power * pace;
        _ballVy = (isRightClick ? 0.96 : 0.72) * combinedPower;
        _ballVz = isRightClick ? 1.35 : 2.2;
        _ballVx = (_ballX - _playerX) * 1.25 + ((math.Random().nextDouble() - 0.5) * 0.25);
        _ballCurve = ((_ballX - _playerX) / 0.3) * paddle.spin * 0.6;
      }

      _currentRally++;
      if (_currentRally > _longestRally) _longestRally = _currentRally;

      if (state.hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
    } else if (_phase == MatchPhase.activeRally && _ballVy < 0 && _ballY < 0.3) {
      _timingFeedback = 'WHIFF!';
      _timingFeedbackColor = const Color(0xFFFF5252);
    }
  }

  void _triggerAiSwing() {
    _aiIsSwinging = true;
    _aiSwingAngle = 0.1;
  }

  // DYNAMIC TARGET SCORE MATCH LOOP WITH XP AWARD
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
        // ====================================================================
        // XP AWARD & CAMPAIGN PROGRESSION HOOK
        // ====================================================================
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
    final courtCenterX = screenSize.width / 2;
    final halfCourtWidth = math.min(screenSize.width * 0.44, 280.0);
    final normalizedX = ((event.localPosition.dx - courtCenterX) / halfCourtWidth).clamp(-1.0, 1.0);
    setState(() => _playerTargetX = normalizedX);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_phase != MatchPhase.activeRally && _phase != MatchPhase.countdown) return;
    final isRightClick = event.buttons == kSecondaryMouseButton;
    _triggerPlayerSwing(isRightClick ? ShotType.smash : ShotType.normal);
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF07110D),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                Positioned.fill(
                  child: Listener(
                    onPointerDown: _onPointerDown,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.none,
                      onHover: (e) => _onPointerHover(e, screenSize),
                      child: GestureDetector(
                        onHorizontalDragUpdate: (e) {
                          final courtCenterX = screenSize.width / 2;
                          final halfCourtWidth = math.min(screenSize.width * 0.44, 280.0);
                          setState(() {
                            _playerTargetX = ((e.localPosition.dx - courtCenterX) / halfCourtWidth).clamp(-1.0, 1.0);
                          });
                        },
                        child: CustomPaint(
                          size: screenSize,
                          painter: PerspectiveCourtPainter(
                            playerX: _playerX,
                            playerVelocityX: _playerVelocityX,
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
                            blitzActive: _blitzActive,
                            blitzColor: _blitzTrailColor,
                            equippedPaddle: state.selectedPaddle,
                            courtVenue: state.courtVenue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Match Scoreboard
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

                // BLITZ ENERGY GAUGE HUD
                Positioned(
                  bottom: 54,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _playerBlitzEnergy >= 1.0 ? AppTheme.opticYellow : Colors.white12,
                          width: _playerBlitzEnergy >= 1.0 ? 2.0 : 1.0,
                        ),
                        boxShadow: _playerBlitzEnergy >= 1.0
                            ? [BoxShadow(color: AppTheme.opticYellow.withValues(alpha: 0.4), blurRadius: 16)]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 18,
                            color: _playerBlitzEnergy >= 1.0 ? AppTheme.opticYellow : Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _playerBlitzEnergy >= 1.0 ? 'BLITZ READY!' : 'BLITZ GAUGE',
                                      style: TextStyle(
                                        color: _playerBlitzEnergy >= 1.0 ? AppTheme.opticYellow : Colors.white70,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      '${(_playerBlitzEnergy * 100).toInt()}%',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _playerBlitzEnergy,
                                    minHeight: 5,
                                    backgroundColor: Colors.white12,
                                    valueColor: AlwaysStoppedAnimation(
                                      _playerBlitzEnergy >= 1.0 ? AppTheme.opticYellow : state.selectedCharacter.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Timing Feedback
                if (_timingFeedback.isNotEmpty)
                  Positioned(
                    bottom: 110,
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

                // Toast Banner
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

                // Countdown Numbers
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

                // Tournament Game Over Modal
                if (_phase == MatchPhase.gameOver)
                  _buildGameOverStatsModal(
                    playerWon: _playerScore > _aiScore,
                    state: state,
                  ),

                // Venue & Match Rules Footer
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'VENUE: ${state.courtVenue.toUpperCase()} • PACE: ${state.gamePace}x • FIRST TO ${state.targetScore}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            );
          },
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
// ELEVATED 3D COURT PAINTER
// ============================================================================

class PerspectiveCourtPainter extends CustomPainter {
  final double playerX;
  final double playerVelocityX;
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
  final bool blitzActive;
  final Color blitzColor;
  final PaddleModel equippedPaddle;
  final String courtVenue;

  PerspectiveCourtPainter({
    required this.playerX,
    required this.playerVelocityX,
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
    required this.blitzActive,
    required this.blitzColor,
    required this.equippedPaddle,
    required this.courtVenue,
  });

  Offset project3D(double x, double y, double z, Size size) {
    final centerX = size.width / 2;
    final nearY = size.height * 0.86;
    final farY = size.height * 0.22;
    final nearWidth = math.min(size.width * 0.88, 540.0);
    final farWidth = nearWidth * 0.52;

    final depth = y.clamp(0.0, 1.0);
    final courtWidthAtY = nearWidth + (farWidth - nearWidth) * depth;
    final groundY = nearY + (farY - nearY) * depth;

    final screenX = centerX + (x * (courtWidthAtY / 2));
    final depthScale = 1.0 - (depth * 0.48);
    final screenY = groundY - (z * 135.0 * depthScale);

    return Offset(screenX, screenY);
  }

  double getScale(double y) {
    return 1.0 - (y.clamp(0.0, 1.0) * 0.48);
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
      courtColor = const Color(0xFF0F1722);
      kitchenColor = const Color(0xFF162130);
      lineCol = const Color(0xFF00E5FF);
      hasNeonGlow = true;
    } else if (courtVenue == 'Sunlit Beach') {
      apronColor = const Color(0xFFD4A373);
      courtColor = const Color(0xFF2A9D8F);
      kitchenColor = const Color(0xFF264653);
      lineCol = const Color(0xFFFAEDCD);
    } else {
      apronColor = const Color(0xFF102840);
      courtColor = const Color(0xFF1F598C);
      kitchenColor = const Color(0xFF173E63);
      lineCol = Colors.white;
    }

    // 1. Apron
    final apronPath = Path()
      ..moveTo(project3D(-1.35, 0.0, 0, size).dx, project3D(-1.35, 0.0, 0, size).dy + 20)
      ..lineTo(project3D(1.35, 0.0, 0, size).dx, project3D(1.35, 0.0, 0, size).dy + 20)
      ..lineTo(project3D(1.40, 1.05, 0, size).dx, project3D(1.40, 1.05, 0, size).dy - 10)
      ..lineTo(project3D(-1.40, 1.05, 0, size).dx, project3D(-1.40, 1.05, 0, size).dy - 10)
      ..close();
    canvas.drawPath(apronPath, Paint()..color = apronColor);

    // 2. Playable Court
    final courtPath = Path()
      ..moveTo(project3D(-1.0, 0.0, 0, size).dx, project3D(-1.0, 0.0, 0, size).dy)
      ..lineTo(project3D(1.0, 0.0, 0, size).dx, project3D(1.0, 0.0, 0, size).dy)
      ..lineTo(project3D(1.0, 1.0, 0, size).dx, project3D(1.0, 1.0, 0, size).dy)
      ..lineTo(project3D(-1.0, 1.0, 0, size).dx, project3D(-1.0, 1.0, 0, size).dy)
      ..close();
    canvas.drawPath(courtPath, Paint()..color = courtColor);

    // 3. Kitchen (NVZ)
    final kitchenPath = Path()
      ..moveTo(project3D(-1.0, 0.34, 0, size).dx, project3D(-1.0, 0.34, 0, size).dy)
      ..lineTo(project3D(1.0, 0.34, 0, size).dx, project3D(1.0, 0.34, 0, size).dy)
      ..lineTo(project3D(1.0, 0.66, 0, size).dx, project3D(1.0, 0.66, 0, size).dy)
      ..lineTo(project3D(-1.0, 0.66, 0, size).dx, project3D(-1.0, 0.66, 0, size).dy)
      ..close();
    canvas.drawPath(kitchenPath, Paint()..color = kitchenColor);

    // 4. White Lines
    final linePaint = Paint()
      ..color = lineCol.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    if (hasNeonGlow) {
      canvas.drawPath(
        courtPath,
        Paint()
          ..color = lineCol.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawPath(courtPath, linePaint);
    canvas.drawLine(project3D(-1.0, 0.34, 0, size), project3D(1.0, 0.34, 0, size), linePaint);
    canvas.drawLine(project3D(-1.0, 0.66, 0, size), project3D(1.0, 0.66, 0, size), linePaint);
    canvas.drawLine(project3D(0.0, 0.0, 0, size), project3D(0.0, 0.34, 0, size), linePaint);
    canvas.drawLine(project3D(0.0, 0.66, 0, size), project3D(0.0, 1.0, 0, size), linePaint);

    // 5. Opponent Rig
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

    // 6. Net Structure
    _drawPerspectiveNet(canvas, size, lineCol);

    // 7. Ball & Shadow
    _drawBallAndShadow(canvas, size);

    // 8. Player Rig
    _drawAnimatedCharacter(
      canvas: canvas,
      size: size,
      x: playerX,
      y: 0.0,
      velocityX: playerVelocityX,
      swingAngle: playerSwingAngle,
      isSwinging: playerIsSwinging,
      bodyColor: playerColor,
      paddlePrimary: equippedPaddle.primaryColor,
      paddleAccent: equippedPaddle.accentColor,
      isOpponent: false,
    );
  }

  void _drawPerspectiveNet(Canvas canvas, Size size, Color cordColor) {
    const netHeightZ = 0.44;
    final leftBase = project3D(-1.08, 0.5, 0.0, size);
    final leftTop = project3D(-1.08, 0.5, netHeightZ, size);
    final rightBase = project3D(1.08, 0.5, 0.0, size);
    final rightTop = project3D(1.08, 0.5, netHeightZ, size);

    final meshPath = Path()
      ..moveTo(leftBase.dx, leftBase.dy)
      ..lineTo(rightBase.dx, rightBase.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..lineTo(leftTop.dx, leftTop.dy)
      ..close();
    canvas.drawPath(meshPath, Paint()..color = cordColor.withValues(alpha: 0.28));
    canvas.drawLine(leftTop, rightTop, Paint()..color = cordColor..strokeWidth = 3.5);
    final postPaint = Paint()..color = cordColor.withValues(alpha: 0.7)..strokeWidth = 4.0;
    canvas.drawLine(leftBase, leftTop, postPaint);
    canvas.drawLine(rightBase, rightTop, postPaint);
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