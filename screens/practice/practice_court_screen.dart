// lib/screens/practice/practice_court_screen.dart

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_state.dart';
import '../../widgets/asset_helpers.dart';
import '../../widgets/game_components.dart';
import '../gameplay/gameplay_screen.dart';
import '../gameplay/physics/court_physics_engine.dart';
import '../gameplay/physics/tactical_ai_controller.dart';
import '../gameplay/rendering/perspective_court_painter.dart';
import '../gameplay/widgets/gameplay_controls.dart';

class PracticeCourtScreen extends StatefulWidget {
  const PracticeCourtScreen({super.key});

  @override
  State<PracticeCourtScreen> createState() => _PracticeCourtScreenState();
}

class _PracticeCourtScreenState extends State<PracticeCourtScreen>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _gameTime = 0.0;

  // --------------------------------------------------------------------------
  // SCRIPTED LESSON STATE
  // --------------------------------------------------------------------------
  int _currentStep = 1; // 1 to 9
  bool _isFreePlayMode = false;
  bool _stepActionSatisfied = false;
  String _stepBannerFeedback = '';
  Color _stepBannerColor = AppColors.opticYellow;
  double _bannerDecayTimer = 0.0;
  int _freePlayRallyStreak = 0;

  late AnimationController _arrowBobController;
  late AnimationController _pulseController;

  // Target Waypoint for Step 1
  static const Offset _step1Waypoint = Offset(-0.45, 0.10);

  // Ball State
  double _ballX = 0.0;
  double _ballY = 0.05;
  double _ballZ = 0.65;
  double _ballVx = 0.0;
  double _ballVy = 0.0;
  double _ballVz = 0.0;
  double _reticleScale = 1.0;
  int _bouncesThisRally = 0;

  // Player Kinematics
  double _playerX = 0.0;
  double _playerY = 0.0;
  double _playerVelocityX = 0.0;
  double _playerVelocityY = 0.0;
  double _playerSwingAngle = 0.0;
  bool _playerIsSwinging = false;
  SpriteAction _playerAction = SpriteAction.idle;
  ShotType _playerCurrentShot = ShotType.normal;

  // Coach Boomer Kinematics
  double _boomerX = 0.0;
  double _boomerY = 0.90;
  double _boomerVelocityX = 0.0;
  double _boomerVelocityY = 0.0;
  double _boomerSwingAngle = 0.0;
  bool _boomerIsSwinging = false;
  SpriteAction _boomerAction = SpriteAction.idle;
  ShotType _boomerCurrentShot = ShotType.normal;

  // Virtual Joystick
  Offset _joystickKnobOffset = Offset.zero;
  bool _isJoystickActive = false;
  double _joystickInputX = 0.0;
  double _joystickInputY = 0.0;
  static const double _joystickRadius = 46.0;

  // FX & Visuals
  final Map<String, ui.Image> _sprites = {};
  final List<TrailNode> _smoothTrail = [];
  final List<CourtParticle> _particles = [];
  final List<BounceShockwave> _shockwaves = [];
  double _cameraTrauma = 0.0;
  Offset _shakeOffset = Offset.zero;

  // Physics & AI Engine
  final CourtPhysicsEngine _physics = CourtPhysicsEngine();
  final TacticalAiController _freePlayAi = TacticalAiController();

  // 9 Scripted Lessons
  final List<Map<String, dynamic>> _lessons = [
    {
      'step': 1,
      'title': '1. FOOTWORK & MOVEMENT',
      'dialogue': 'Welcome to my academy, rookie! I am Coach Boomer. Drag the virtual joystick on the bottom-left to slide your athlete across the baseline.',
      'actionPrompt': 'Move your player inside the glowing floor ring.',
      'targetType': 'waypoint',
    },
    {
      'step': 2,
      'title': '2. THE MANUAL SERVE: TOSS',
      'dialogue': 'Every rally begins with an active serve. Tap [TOSS BALL] to throw the ball upward toward apex.',
      'actionPrompt': 'Tap the green [TOSS BALL] button.',
      'targetType': 'toss_button',
    },
    {
      'step': 3,
      'title': '3. THE MANUAL SERVE: STRIKE',
      'dialogue': 'Watch the timing reticle contract as the ball drops. Tap [DRIVE SERVE] inside the green sweet spot!',
      'actionPrompt': 'Tap [DRIVE SERVE] as the ring turns green!',
      'targetType': 'drive_button',
    },
    {
      'step': 4,
      'title': '4. THE TWO-BOUNCE RULE',
      'dialogue': 'Official Rule #1: The serve must bounce, and the return must bounce! NEVER volley out of the air early.',
      'actionPrompt': 'Wait for the ball to bounce on your court before swinging!',
      'targetType': 'court_bounce',
    },
    {
      'step': 5,
      'title': '5. FOREHAND TOPSPIN DRIVE',
      'dialogue': 'Tap [DRIVE] (Button 1) when the ball is at waist height to execute a crisp topspin drive with maximum pace!',
      'actionPrompt': 'Hit Button 1 (DRIVE) on the return.',
      'targetType': 'button_1',
    },
    {
      'step': 6,
      'title': '6. THE KITCHEN (NVZ LINE)',
      'dialogue': 'Official Rule #2: You CANNOT volley out of the air while inside the Kitchen (Y >= 0.34). Always let it bounce first!',
      'actionPrompt': 'Stay behind the kitchen line or let it bounce.',
      'targetType': 'kitchen_line',
    },
    {
      'step': 7,
      'title': '7. OVERHEAD SMASH SPIKE',
      'dialogue': 'When I float a high ball over the net, tap [SMASH] (Button 2) to jump off the deck and spike downward violently!',
      'actionPrompt': 'Hit Button 2 (SMASH) on high floaters.',
      'targetType': 'button_2',
    },
    {
      'step': 8,
      'title': '8. DEFENSIVE LOB',
      'dialogue': 'Under heavy pressure? Tap [LOB] (Button 3) to scoop the ball deep over my head and buy time to reset court position!',
      'actionPrompt': 'Hit Button 3 (LOB) to scoop the ball high.',
      'targetType': 'button_3',
    },
    {
      'step': 9,
      'title': '9. BLITZ SUPER KINETIC STRIKE',
      'dialogue': 'Rallies charge your Blitz Gauge. When it hits 100%, Button 4 unlocks glowing Optic Yellow. Tap it to unleash your finisher!',
      'actionPrompt': 'Tap Button 4 (BLITZ) to unleash your finisher!',
      'targetType': 'button_4',
    },
  ];

  @override
  void initState() {
    super.initState();
    _arrowBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _setupLessonStep(1);
    _ticker = createTicker(_onGameTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _arrowBobController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // 3D PERSPECTIVE PROJECTION
  // ==========================================================================
  Offset _project3D(double x, double y, double z, Size size) {
    final centerX = size.width / 2;
    final nearY = size.height * 0.81;
    final farY = size.height * 0.24;
    final nearWidth = math.min(size.width * 0.90, 540.0);
    final farWidth = nearWidth * 0.48;

    final clampedY = y.clamp(-0.25, 1.15);
    final t = (clampedY >= 0)
        ? (clampedY * 1.65) / (1.0 + 0.65 * clampedY)
        : clampedY * 1.65;

    final courtWidthAtY = nearWidth + (farWidth - nearWidth) * t;
    final groundY = nearY + (farY - nearY) * t;

    final screenX = centerX + (x * (courtWidthAtY / 2));
    final depthScale = (1.0 - (t.clamp(0.0, 1.0) * 0.50)).clamp(0.25, 1.0);
    final screenY = groundY - (z * 135.0 * depthScale);

    return Offset(screenX, screenY);
  }

  // ==========================================================================
  // SCRIPTED LESSON SETUP
  // ==========================================================================
  void _setupLessonStep(int step) {
    setState(() {
      _currentStep = step;
      _stepActionSatisfied = false;
      _stepBannerFeedback = '';
      _bouncesThisRally = 0;
      _reticleScale = 1.0;
      _playerSwingAngle = 0.0;
      _playerIsSwinging = false;
      _boomerSwingAngle = 0.0;
      _boomerIsSwinging = false;
      _playerAction = SpriteAction.idle;
      _boomerAction = SpriteAction.idle;
      _smoothTrail.clear();

      switch (step) {
        case 1:
          _ballZ = -1.0;
          _playerX = 0.0;
          _playerY = 0.0;
          _boomerX = 0.0;
          _boomerY = 0.88;
          break;

        case 2:
          _playerX = 0.0;
          _playerY = 0.0;
          _boomerX = 0.0;
          _boomerY = 0.88;
          _ballX = _playerX + 0.14;
          _ballY = 0.05;
          _ballZ = 0.65;
          _ballVx = 0.0;
          _ballVy = 0.0;
          _ballVz = 0.0;
          break;

        case 3:
          _playerX = 0.0;
          _playerY = 0.0;
          _boomerX = 0.0;
          _boomerY = 0.88;
          _ballX = _playerX + 0.14;
          _ballY = 0.05;
          _ballZ = 1.55;
          _ballVx = 0.0;
          _ballVy = 0.0;
          _ballVz = -0.55;
          _reticleScale = 0.85;
          break;

        case 4:
          _playerX = 0.0;
          _playerY = 0.0;
          _boomerX = 0.0;
          _boomerY = 0.88;
          _ballX = 0.0;
          _ballY = 0.86;
          _ballZ = 0.70;
          _ballVx = 0.06;
          _ballVy = -0.48;
          _ballVz = 2.2;
          _triggerBoomerSwing(ShotType.lob);
          break;

        case 5:
          _playerX = 0.05;
          _playerY = 0.0;
          _boomerX = -0.05;
          _boomerY = 0.88;
          _ballX = -0.05;
          _ballY = 0.85;
          _ballZ = 0.65;
          _ballVx = 0.08;
          _ballVy = -0.62;
          _ballVz = 1.5;
          _triggerBoomerSwing(ShotType.drive);
          break;

        case 6:
          _playerX = 0.0;
          _playerY = 0.15;
          _boomerX = 0.0;
          _boomerY = 0.70;
          _ballX = 0.0;
          _ballY = 0.68;
          _ballZ = 0.50;
          _ballVx = 0.0;
          _ballVy = -0.38;
          _ballVz = 1.25;
          _triggerBoomerSwing(ShotType.drive);
          break;

        case 7:
          _playerX = 0.0;
          _playerY = 0.05;
          _boomerX = 0.0;
          _boomerY = 0.85;
          _ballX = 0.0;
          _ballY = 0.80;
          _ballZ = 0.60;
          _ballVx = 0.0;
          _ballVy = -0.42;
          _ballVz = 2.8;
          _triggerBoomerSwing(ShotType.lob);
          break;

        case 8:
          _playerX = 0.0;
          _playerY = 0.0;
          _boomerX = 0.15;
          _boomerY = 0.85;
          _ballX = 0.15;
          _ballY = 0.80;
          _ballZ = 0.60;
          _ballVx = -0.12;
          _ballVy = -0.75;
          _ballVz = 1.45;
          _triggerBoomerSwing(ShotType.smash);
          break;

        case 9:
          _playerX = 0.0;
          _playerY = 0.0;
          _boomerX = 0.0;
          _boomerY = 0.88;
          _ballX = 0.0;
          _ballY = 0.80;
          _ballZ = 0.60;
          _ballVx = 0.0;
          _ballVy = -0.55;
          _ballVz = 1.8;
          _triggerBoomerSwing(ShotType.drive);
          break;
      }
    });
  }

  void _triggerBoomerSwing(ShotType shot) {
    _boomerCurrentShot = shot;
    _boomerIsSwinging = true;
    _boomerSwingAngle = 0.1;
    _boomerAction = SpriteAction.hit;
  }

  void _completeStepWithSuccess(String feedback) {
    if (_stepActionSatisfied) return;
    _stepActionSatisfied = true;
    _stepBannerFeedback = feedback;
    _stepBannerColor = AppColors.mintAccent;
    _bannerDecayTimer = 1.4;

    AppAudio.playFeatureSfx(AppAssets.sfxPointCheer);
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_currentStep < 9) {
        _setupLessonStep(_currentStep + 1);
      } else {
        _showGraduationModal();
      }
    });
  }

  void _failStepWithReset(String reason) {
    _stepBannerFeedback = reason;
    _stepBannerColor = AppColors.electricCoral;
    _bannerDecayTimer = 1.3;

    AppAudio.playFeatureSfx(AppAssets.sfxFaultBuzzer);
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      _setupLessonStep(_currentStep);
    });
  }

  // ==========================================================================
  // TICK ENGINE
  // ==========================================================================
  void _onGameTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    _gameTime += dt;

    setState(() {
      if (_bannerDecayTimer > 0) {
        _bannerDecayTimer -= dt;
        if (_bannerDecayTimer <= 0) _stepBannerFeedback = '';
      }

      if (_cameraTrauma > 0) {
        _cameraTrauma = math.max(0.0, _cameraTrauma - dt * 2.8);
        final intensity = _cameraTrauma * _cameraTrauma;
        final rng = math.Random();
        _shakeOffset = Offset((rng.nextDouble() * 2 - 1) * 14 * intensity, (rng.nextDouble() * 2 - 1) * 14 * intensity);
      } else {
        _shakeOffset = Offset.zero;
      }

      // Player Movement - Active Joystick Check
      double targetVelX = 0.0;
      double targetVelY = 0.0;

      if (_isJoystickActive) {
        const maxSpeedX = 1.65;
        const maxSpeedY = 1.05;
        targetVelX = _joystickInputX * maxSpeedX;
        targetVelY = _joystickInputY * maxSpeedY;
      }

      _playerVelocityX += (targetVelX - _playerVelocityX) * math.min(1.0, 11.0 * dt);
      _playerVelocityY += (targetVelY - _playerVelocityY) * math.min(1.0, 11.0 * dt);

      _playerX = (_playerX + _playerVelocityX * dt).clamp(-0.95, 0.95);
      _playerY = (_playerY + _playerVelocityY * dt).clamp(-0.18, 0.34);

      if (_playerIsSwinging) {
        _playerSwingAngle += 14.0 * dt;
        if (_playerSwingAngle >= math.pi) {
          _playerSwingAngle = 0.0;
          _playerIsSwinging = false;
        }
      }
      if (_boomerIsSwinging) {
        _boomerSwingAngle += 14.0 * dt;
        if (_boomerSwingAngle >= math.pi) {
          _boomerSwingAngle = 0.0;
          _boomerIsSwinging = false;
        }
      }

      // ----------------------------------------------------------------------
      // STEP 1 CHECK: Footwork Target Waypoint
      // ----------------------------------------------------------------------
      if (_currentStep == 1 && !_stepActionSatisfied) {
        final dist = (Offset(_playerX, _playerY) - _step1Waypoint).distance;
        if (dist < 0.16) {
          _completeStepWithSuccess('🎯 WAYPOINT REACHED!');
        }
      }

      // ----------------------------------------------------------------------
      // STEP 2 & 3: Serve Toss & Strike
      // ----------------------------------------------------------------------
      if (_currentStep == 2 && !_stepActionSatisfied) {
        _ballX = _playerX + 0.14;
        _ballY = 0.05;
      } else if (_currentStep == 3 && !_stepActionSatisfied) {
        _ballVz -= 2.8 * dt;
        _ballZ += _ballVz * dt;

        final heightRatio = ((_ballZ - 0.50) / (1.55 - 0.50)).clamp(0.0, 1.0);
        _reticleScale = (1.0 - heightRatio).clamp(0.0, 1.0);

        if (_ballZ <= 0.08) {
          _failStepWithReset('TOO LATE! BALL DROPPED');
        }
      }

      // ----------------------------------------------------------------------
      // STEPS 4 THROUGH 9: Scripted Ball Flight & Bounce Rules
      // ----------------------------------------------------------------------
      if (_currentStep >= 4 && _ballZ >= 0.0 && !_isFreePlayMode) {
        _ballX += _ballVx * dt;
        _ballY += _ballVy * dt;
        _ballZ += _ballVz * dt;
        _ballVz -= 3.8 * dt;

        _smoothTrail.add(TrailNode(x: _ballX, y: _ballY, z: _ballZ, time: _gameTime));
        if (_smoothTrail.length > 7) _smoothTrail.removeAt(0);

        // Floor Bounce
        if (_ballZ <= 0.0) {
          _ballZ = 0.0;
          _bouncesThisRally++;
          _ballVz = -_ballVz * 0.70;
          AppAudio.playFeatureSfx(AppAssets.sfxBallBounce);

          if (_currentStep == 4 && _bouncesThisRally == 1) {
            _stepBannerFeedback = 'BALL BOUNCED! NOW HIT [DRIVE]!';
            _stepBannerColor = AppColors.opticYellow;
          }
        }

        // Net Check
        if ((_ballY - 0.50).abs() < 0.03 && _ballZ < 0.42) {
          _failStepWithReset('NET FAULT! TRY AGAIN');
        }

        // Deep Missed Ball Check
        if (_ballY < -0.28 && !_stepActionSatisfied) {
          _failStepWithReset('MISSED BALL! TRY AGAIN');
        }
      } else if (_isFreePlayMode) {
        // Free Play Rally Engine
        _ballX += _ballVx * dt;
        _ballY += _ballVy * dt;
        _ballZ += _ballVz * dt;
        _ballVz -= 4.2 * dt;

        _smoothTrail.add(TrailNode(x: _ballX, y: _ballY, z: _ballZ, time: _gameTime));
        if (_smoothTrail.length > 7) _smoothTrail.removeAt(0);

        if (_ballZ <= 0.0) {
          _ballZ = 0.0;
          _ballVz = -_ballVz * 0.72;
          AppAudio.playFeatureSfx(AppAssets.sfxBallBounce);
        }

        // AI positioning for Boomer
        final oldBoomerX = _boomerX;
        final oldBoomerY = _boomerY;

        final state = GameState.instance;
        _freePlayAi.updatePosition(
          dt: dt,
          ballX: _ballX,
          ballY: _ballY,
          ballZ: _ballZ,
          ballVx: _ballVx,
          ballVy: _ballVy,
          aiChar: state.selectedCharacter,
          difficulty: AIDifficulty.pro,
          currentRally: _freePlayRallyStreak,
          playerY: _playerY,
        );

        _boomerX = _freePlayAi.x;
        _boomerY = _freePlayAi.y;
        _boomerVelocityX = (_boomerX - oldBoomerX) / dt;
        _boomerVelocityY = (_boomerY - oldBoomerY) / dt;

        final distToBoomerY = (_ballY - _boomerY).abs();
        final distToBoomerX = (_ballX - _boomerX).abs();
        if (_ballVy > 0 && distToBoomerY <= 0.20 && distToBoomerX < 0.35 && _ballZ > 0.05 && _ballZ < 2.0) {
          _freePlayAi.executeTacticalShot(
            aiChar: state.selectedCharacter,
            pace: 1.0,
            playerX: _playerX,
            playerY: _playerY,
            ballZ: _ballZ,
            currentRally: _freePlayRallyStreak,
            difficulty: AIDifficulty.pro,
            isUnderPressure: false,
            onApplyShot: (vy, vz, vx, curve, spinZ, shot) {
              _ballVy = vy;
              _ballVz = vz;
              _ballVx = vx;
              _triggerBoomerSwing(shot);
              AppAudio.playFeatureSfx(AppAssets.sfxPaddleDrive);
            },
          );
        }

        if (_ballY < -0.30 || _ballY > 1.30) {
          _freePlayRallyStreak = 0;
          _setupLessonStep(5);
        }
      }

      // Synchronize physics engine representation for trajectory projection
      _physics.ballX = _ballX;
      _physics.ballY = _ballY;
      _physics.ballZ = _ballZ;
      _physics.ballVx = _ballVx;
      _physics.ballVy = _ballVy;
      _physics.ballVz = _ballVz;
      _physics.ballRotationAngle = _gameTime * 12.0;
    });
  }

  // ==========================================================================
  // SCRIPTED PLAYER ACTIONS
  // ==========================================================================
  void _onPlayerToss() {
    if (_currentStep != 2 || _stepActionSatisfied) return;
    AppAudio.playFeatureSfx(AppAssets.sfxServeToss);
    HapticFeedback.lightImpact();
    _completeStepWithSuccess('PERFECT TOSS TO APEX!');
  }

  void _onPlayerSwing(ShotType shot) {
    _playerCurrentShot = shot;
    _playerIsSwinging = true;
    _playerSwingAngle = 0.1;

    // STEP 3: Serve Strike
    if (_currentStep == 3 && !_stepActionSatisfied) {
      if (_ballZ > 0.35) {
        _ballVy = 0.86;
        _ballVz = 1.70;
        _ballVx = 0.05;
        _triggerBoomerSwing(ShotType.drive);
        AppAudio.playFeatureSfx(AppAssets.sfxServeDrive);
        _completeStepWithSuccess('⚡ SWEET SPOT SERVE CONVERTED!');
      } else {
        _failStepWithReset('MISTIMED SWING! HIT IN GREEN RETICLE');
      }
      return;
    }

    final distY = (_ballY - _playerY).abs();
    final distX = (_ballX - _playerX).abs();
    final inStrikeZone = distY <= 0.32 && distX < 0.48 && _ballZ > 0.02;

    if (!inStrikeZone) return;

    if (_isFreePlayMode) {
      _ballVy = 0.82;
      _ballVz = 1.65;
      _ballVx = (_joystickInputX.abs() > 0.15) ? (_joystickInputX * 0.6) : 0.0;
      _freePlayRallyStreak++;
      AppAudio.playFeatureSfx(AppAssets.sfxPaddleDrive);
      return;
    }

    if (_stepActionSatisfied) return;

    // STEP 4: Two-Bounce Check
    if (_currentStep == 4) {
      if (_bouncesThisRally < 1) {
        _failStepWithReset('FAULT! YOU VOLLEYED BEFORE BOUNCE!');
        return;
      }
      _ballVy = 0.82;
      _ballVz = 1.60;
      AppAudio.playFeatureSfx(AppAssets.sfxPaddleDrive);
      _completeStepWithSuccess('🎯 TWO-BOUNCE RULE SATISFIED!');
      return;
    }

    // STEP 5: Forehand Topspin Drive
    if (_currentStep == 5) {
      if (shot == ShotType.normal || shot == ShotType.drive) {
        _ballVy = 0.90;
        _ballVz = 1.35;
        AppAudio.playFeatureSfx(AppAssets.sfxPaddleDrive);
        _completeStepWithSuccess('🔥 CRISP TOPSPIN DRIVE!');
      } else {
        _failStepWithReset('USE BUTTON 1 (DRIVE)!');
      }
      return;
    }

    // STEP 6: Kitchen NVZ Check
    if (_currentStep == 6) {
      if (_playerY >= 0.34 && _bouncesThisRally < 1) {
        _failStepWithReset('KITCHEN FAULT! VOLLEYED IN NVZ!');
        return;
      }
      _ballVy = 0.50;
      _ballVz = 1.40;
      AppAudio.playFeatureSfx(AppAssets.sfxDinkPop);
      _completeStepWithSuccess('🎯 PERFECT KITCHEN DINK!');
      return;
    }

    // STEP 7: Overhead Smash Spike
    if (_currentStep == 7) {
      if (shot == ShotType.smash) {
        _ballVy = 1.10;
        _ballVz = 0.95;
        _addTrauma(0.55);
        AppAudio.playFeatureSfx(AppAssets.sfxPaddleSmash);
        _completeStepWithSuccess('⚡ THUNDEROUS SMASH SPIKE!');
      } else {
        _failStepWithReset('USE BUTTON 2 (SMASH) ON FLOATERS!');
      }
      return;
    }

    // STEP 8: Defensive Lob
    if (_currentStep == 8) {
      if (shot == ShotType.lob) {
        _ballVy = 0.65;
        _ballVz = 2.70;
        AppAudio.playFeatureSfx(AppAssets.sfxPaddleDrive);
        _completeStepWithSuccess('🌟 HIGH DEFENSIVE LOB SCOOP!');
      } else {
        _failStepWithReset('USE BUTTON 3 (LOB) TO RESET!');
      }
      return;
    }

    // STEP 9: Blitz Super Release
    if (_currentStep == 9) {
      if (shot == ShotType.signatureBlitz) {
        _ballVy = 1.35;
        _ballVz = 1.20;
        _addTrauma(0.85);
        AppAudio.playFeatureSfx(AppAssets.sfxBlitzSuper);
        _completeStepWithSuccess('💥 SIGNATURE BLITZ UNLEASHED!');
      } else {
        _failStepWithReset('TAP BUTTON 4 (BLITZ)!');
      }
      return;
    }
  }

  void _addTrauma(double amount) {
    setState(() => _cameraTrauma = (_cameraTrauma + amount).clamp(0.0, 1.0));
  }

  void _showGraduationModal() {
    final state = GameState.instance;
    state.addGoldCoins(500);
    state.addUpgradePoints(3);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.opticYellow, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.military_tech_rounded, color: AppColors.opticYellow, size: 28),
            SizedBox(width: 8),
            Text('TRAINING COMPLETE!', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coach Boomer: "Outstanding execution, rookie! You mastered the two-bounce rule, kitchen positioning, and kinetic drives."',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(children: [Icon(Icons.monetization_on_rounded, size: 16, color: AppColors.coinGold), SizedBox(width: 4), Text('+500 Coins', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))]),
                  Row(children: [Icon(Icons.bolt_rounded, size: 16, color: AppColors.upgradePoint), SizedBox(width: 4), Text('+3 UP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))]),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('RETURN TO LOBBY', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.opticYellow, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isFreePlayMode = true;
                _setupLessonStep(5);
              });
            },
            child: const Text('FREE RALLY VS COACH', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    final lesson = _lessons[_currentStep - 1];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                // 1. Scripted 2.5D Court Painter
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
                        playerIsDiving: false,
                        aiX: _boomerX,
                        aiY: _boomerY,
                        aiVelocityX: _boomerVelocityX,
                        aiVelocityY: _boomerVelocityY,
                        aiSwingAngle: _boomerSwingAngle,
                        aiIsSwinging: _boomerIsSwinging,
                        aiColor: Colors.white,
                        aiAccent: AppColors.opticYellow,
                        aiCharId: 'coach_boomer',
                        aiAction: _boomerAction,
                        aiShotType: _boomerCurrentShot,
                        aiIsDiving: false,
                        ballX: _ballX,
                        ballY: _ballY,
                        ballZ: _ballZ,
                        ballVx: _ballVx,
                        ballVy: _ballVy,
                        ballVz: _ballVz,
                        ballRotationAngle: _gameTime * 12.0,
                        smoothTrail: _smoothTrail,
                        physics: _physics,
                        particles: _particles,
                        shockwaves: _shockwaves,
                        blitzActive: _currentStep == 9,
                        blitzColor: AppColors.opticYellow,
                        equippedPaddle: state.selectedPaddle,
                        courtVenue: 'Training Facility',
                        sprites: _sprites,
                        isLandscape: false,
                        isServing: _currentStep == 3,
                        reticleScale: _reticleScale,
                        gameTime: _gameTime,
                      ),
                    ),
                  ),
                ),

                // 2. STEP 1: Accurate 3D Floor Waypoint
                if (_currentStep == 1 && !_stepActionSatisfied && !_isFreePlayMode)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final scale = 1.0 + (_pulseController.value * 0.22);
                      final waypointPos = _project3D(_step1Waypoint.dx, _step1Waypoint.dy, 0.0, screenSize);

                      return Positioned(
                        left: waypointPos.dx - (28 * scale),
                        top: waypointPos.dy - (14 * scale),
                        child: IgnorePointer(
                          child: Container(
                            width: 56 * scale,
                            height: 28 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.opticYellow, width: 2.5),
                              boxShadow: [
                                BoxShadow(color: AppColors.opticYellow.withValues(alpha: 0.55), blurRadius: 16),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.my_location_rounded, size: 16, color: AppColors.opticYellow),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // 3. STEP 4: Accurate 3D Floor Bounce Target Marker
                if (_currentStep == 4 && _bouncesThisRally == 0 && !_isFreePlayMode)
                  Builder(
                    builder: (context) {
                      final bouncePos = _project3D(0.06, 0.14, 0.0, screenSize);
                      return Positioned(
                        left: bouncePos.dx - 40,
                        top: bouncePos.dy - 18,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.electricCoral, width: 2.0),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppColors.electricCoral, size: 16),
                                SizedBox(width: 4),
                                Text('LET IT BOUNCE!', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // 4. Feedback Banner
                if (_stepBannerFeedback.isNotEmpty)
                  Positioned(
                    bottom: 190,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _stepBannerColor, width: 2.0),
                          boxShadow: [BoxShadow(color: _stepBannerColor.withValues(alpha: 0.5), blurRadius: 14)],
                        ),
                        child: Text(
                          _stepBannerFeedback,
                          style: TextStyle(fontWeight: FontWeight.w900, color: _stepBannerColor, fontSize: 13, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ),

                // 5. Free Play Rally Header
                if (_isFreePlayMode)
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1B26),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.opticYellow),
                        ),
                        child: Text(
                          'FREE PRACTICE • RALLY STREAK: $_freePlayRallyStreak HITS',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.opticYellow, fontSize: 12),
                        ),
                      ),
                    ),
                  ),

                // 6. Controls Cluster
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: VirtualJoystickWidget(
                    knobOffset: _joystickKnobOffset,
                    radius: _joystickRadius,
                    onStart: () => setState(() => _isJoystickActive = true),
                    onUpdate: (delta) {
                      final localOffset = _joystickKnobOffset + delta;
                      final clamped = localOffset.distance > _joystickRadius
                          ? Offset.fromDirection(localOffset.direction, _joystickRadius)
                          : localOffset;
                      setState(() {
                        _joystickKnobOffset = clamped;
                        _joystickInputX = clamped.dx / _joystickRadius;
                        _joystickInputY = -clamped.dy / _joystickRadius;
                      });
                    },
                    onEnd: () {
                      setState(() {
                        _isJoystickActive = false;
                        _joystickKnobOffset = Offset.zero;
                        _joystickInputX = 0;
                        _joystickInputY = 0;
                      });
                    },
                  ),
                ),

                Positioned(
                  bottom: 20,
                  right: 20,
                  child: GameplayActionCluster(
                    phase: (_currentStep == 2 && !_isFreePlayMode)
                        ? MatchPhase.serveTossWait
                        : ((_currentStep == 3 && !_isFreePlayMode) ? MatchPhase.serveBallInAir : MatchPhase.activeRally),
                    playerServing: true,
                    blitzEnergy: (_currentStep == 9 || _isFreePlayMode) ? 1.0 : 0.0,
                    driveCooldown: 0.0,
                    smashCooldown: 0.0,
                    lobCooldown: 0.0,
                    isLandscape: false,
                    onToss: _onPlayerToss,
                    onDriveServe: () => _onPlayerSwing(ShotType.drive),
                    onLobServe: () => _onPlayerSwing(ShotType.lob),
                    onSwing: (shot) => _onPlayerSwing(shot),
                    onBlitzNotReady: () {},
                  ),
                ),

                // 7. Accurately Aligned Bouncing Arrow Pointer
                if (!_isFreePlayMode && !_stepActionSatisfied)
                  AnimatedBuilder(
                    animation: _arrowBobController,
                    builder: (context, _) {
                      final bob = _arrowBobController.value * 8;
                      final target = lesson['targetType'] as String;

                      Offset arrowPos = Offset.zero;

                      if (target == 'waypoint') {
                        final wp = _project3D(_step1Waypoint.dx, _step1Waypoint.dy, 0.0, screenSize);
                        arrowPos = Offset(wp.dx, wp.dy - 34 - bob);
                      } else if (target == 'toss_button') {
                        arrowPos = Offset(screenSize.width - 90, screenSize.height - 85 - bob);
                      } else if (target == 'drive_button') {
                        arrowPos = Offset(screenSize.width - 75, screenSize.height - 85 - bob);
                      } else if (target == 'button_1') {
                        arrowPos = Offset(screenSize.width - 60, screenSize.height - 80 - bob);
                      } else if (target == 'button_2') {
                        arrowPos = Offset(screenSize.width - 66, screenSize.height - 150 - bob);
                      } else if (target == 'button_3') {
                        arrowPos = Offset(screenSize.width - 135, screenSize.height - 145 - bob);
                      } else if (target == 'button_4') {
                        arrowPos = Offset(screenSize.width - 155, screenSize.height - 65 - bob);
                      } else if (target == 'court_bounce') {
                        final bp = _project3D(0.06, 0.14, 0.0, screenSize);
                        arrowPos = Offset(bp.dx, bp.dy - 40 - bob);
                      } else if (target == 'kitchen_line') {
                        final kp = _project3D(0.0, 0.34, 0.0, screenSize);
                        arrowPos = Offset(kp.dx, kp.dy - 36 - bob);
                      }

                      return Positioned(
                        left: arrowPos.dx - 16,
                        top: arrowPos.dy,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.opticYellow,
                              boxShadow: [
                                BoxShadow(color: AppColors.opticYellow.withValues(alpha: 0.7), blurRadius: 14, spreadRadius: 2),
                              ],
                            ),
                            child: const Icon(Icons.arrow_downward_rounded, size: 20, color: Colors.black),
                          ),
                        ),
                      );
                    },
                  ),

                // 8. Top Coach Boomer Dialogue Box
                if (!_isFreePlayMode)
                  Positioned(
                    top: 10,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1B26).withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.opticYellow, width: 1.8),
                        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xFF37474F),
                                    child: Icon(Icons.sports_rounded, color: AppColors.opticYellow, size: 16),
                                  ),
                                  SizedBox(width: 8),
                                  Text('COACH BOOMER', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.opticYellow, fontSize: 11)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  'LESSON $_currentStep / 9',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9.5, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(lesson['dialogue']!, style: const TextStyle(fontSize: 11, color: Colors.white, height: 1.35)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '🎯 ${lesson['actionPrompt']}',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.mintAccent),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.opticYellow,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: const Size(60, 28),
                                ),
                                onPressed: () => _setupLessonStep(_currentStep < 9 ? _currentStep + 1 : 9),
                                child: Text(
                                  _currentStep == 9 ? 'GRADUATE' : 'SKIP >>',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // 9. Back to Lobby Button
                Positioned(
                  top: 12,
                  left: 12,
                  child: BouncyButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.glassFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
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
}