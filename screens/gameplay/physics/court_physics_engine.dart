// lib/screens/gameplay/physics/court_physics_engine.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

class BounceShockwave {
  final double x;
  final double y;
  double radius;
  double opacity;
  final Color color;

  BounceShockwave({
    required this.x,
    required this.y,
    this.radius = 2.0,
    this.opacity = 0.85,
    required this.color,
  });
}

class CourtParticle {
  double x;
  double y;
  double z;
  double vx;
  double vy;
  double vz;
  double life;
  final Color color;

  CourtParticle({
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.life,
    required this.color,
  });
}

class CourtPhysicsEngine {
  double ballX = 0.0;
  double ballY = 0.05;
  double ballZ = 0.65;
  double ballVx = 0.0;
  double ballVy = 0.0;
  double ballVz = 0.0;
  double ballCurve = 0.0;
  double ballSpinVertical = 0.0;
  double ballRotationAngle = 0.0;

  final List<Offset> ballTrail = [];
  final List<CourtParticle> particles = [];
  final List<BounceShockwave> shockwaves = [];

  static const double gravity = 4.4;

  void resetBall({
    required bool playerServing,
    required double playerX,
    required double playerY,
    required double aiX,
    required double aiY,
  }) {
    ballTrail.clear();
    particles.clear();
    shockwaves.clear();

    ballX = playerServing ? (playerX + 0.14) : aiX;
    ballY = playerServing ? 0.05 : aiY;
    ballZ = 0.65;
    ballVx = 0;
    ballVy = 0;
    ballVz = 0;
    ballCurve = 0;
    ballSpinVertical = 0;
  }

  void spawnHitSparks(double x, double y, double z, Color color) {
    final rng = math.Random();
    for (int i = 0; i < 14; i++) {
      particles.add(
        CourtParticle(
          x: x,
          y: y,
          z: z,
          vx: (rng.nextDouble() - 0.5) * 2.0,
          vy: (rng.nextDouble() - 0.5) * 2.0,
          vz: (rng.nextDouble() * 1.6) + 0.4,
          life: 0.32 + rng.nextDouble() * 0.22,
          color: color,
        ),
      );
    }
  }

  void spawnBounceShockwave(double x, double y, Color color) {
    shockwaves.add(
      BounceShockwave(
        x: x,
        y: y,
        radius: 2.0,
        opacity: 0.85,
        color: color,
      ),
    );
  }

  void updateVisualParticles(double dt) {
    for (int i = shockwaves.length - 1; i >= 0; i--) {
      final sw = shockwaves[i];
      sw.radius += dt * 45.0;
      sw.opacity -= dt * 1.8;
      if (sw.opacity <= 0) {
        shockwaves.removeAt(i);
      }
    }

    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.life -= dt;
      if (p.life <= 0) {
        particles.removeAt(i);
      } else {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.z += p.vz * dt;
        p.vz -= 3.5 * dt;
      }
    }
  }

  void updateBallFlight({
    required double dt,
    required Function(bool playerWon, String reason) onPointEnded,
    required VoidCallback onBallBounce,
    required VoidCallback onNetFault,
    required VoidCallback onOutOfBounds,
  }) {
    // 1. Wiffle-ball aerodynamic drag
    final speed = math.sqrt(ballVx * ballVx + ballVy * ballVy);
    final drag = 1.0 - (0.16 * dt * (1.0 + speed * 0.35));
    ballVx *= drag;
    ballVy *= drag;

    // 2. Decaying lateral Magnus spin & topspin dip
    ballVx += ballCurve * dt * 2.2;
    ballVz -= (gravity + (ballSpinVertical * 1.8)) * dt;

    ballCurve *= math.max(0.0, 1.0 - 1.4 * dt);
    ballSpinVertical *= math.max(0.0, 1.0 - 1.2 * dt);
    ballRotationAngle += (speed * 14.0) * dt;

    ballX += ballVx * dt;
    ballY += ballVy * dt;
    ballZ += ballVz * dt;

    ballTrail.add(Offset(ballX, ballY));
    if (ballTrail.length > 7) ballTrail.removeAt(0);

    // 3. Floor bounce & Out-of-bounds detection
    if (ballZ <= 0.0) {
      ballZ = 0.0;
      final isOut = ballX.abs() > 1.0 || ballY < -0.05 || ballY > 1.05;

      if (isOut) {
        spawnHitSparks(ballX, ballY, 0.0, const Color(0xFFFF5252));
        spawnBounceShockwave(ballX, ballY, const Color(0xFFFF5252));
        onOutOfBounds();
        onPointEnded(ballVy < 0, 'OUT OF BOUNDS');
        return;
      } else {
        if (ballVz.abs() > 0.40) {
          onBallBounce();
          spawnHitSparks(ballX, ballY, 0.0, const Color(0xFFD6F800));
          spawnBounceShockwave(ballX, ballY, const Color(0xFFD6F800));
        }
        ballVz = -ballVz * 0.72;
      }
    }

    // 4. Net collision (Y = 0.50, Height Z = 0.42m)
    if ((ballY - 0.50).abs() < 0.03 && ballZ < 0.42) {
      spawnHitSparks(ballX, 0.50, ballZ, Colors.white);
      onNetFault();
      onPointEnded(ballVy < 0, 'NET FAULT');
      return;
    }

    // 5. Deep missed ball checks
    if (ballY > 1.25) {
      onPointEnded(true, 'WINNER');
    } else if (ballY < -0.30) {
      onPointEnded(false, 'MISSED BALL');
    }
  }
}