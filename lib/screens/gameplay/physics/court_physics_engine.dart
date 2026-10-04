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

class TrailNode {
  final double x;
  final double y;
  final double z;
  final double time;

  const TrailNode({
    required this.x,
    required this.y,
    required this.z,
    required this.time,
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

  // Strict Court Ownership & Official Rulebook Tracking
  int lastBounceHalf = 0; // 0 = none, 1 = player half (Y < 0.5), 2 = opponent half (Y > 0.5)
  int bouncesThisRally = 0;
  bool isServeBall = false;
  bool serveFromRight = true;

  // Smooth Jitter-Free Ribbon Trail
  final List<TrailNode> smoothTrail = [];
  final List<CourtParticle> particles = [];
  final List<BounceShockwave> shockwaves = [];

  static const double gravity = 4.15; // Tuned for authentic parabolic hang time

  void resetBall({
    required bool playerServing,
    required double playerX,
    required double playerY,
    required double aiX,
    required double aiY,
  }) {
    smoothTrail.clear();
    particles.clear();
    shockwaves.clear();

    lastBounceHalf = 0;
    bouncesThisRally = 0;
    isServeBall = true;
    serveFromRight = playerServing ? (playerX >= 0) : (aiX >= 0);

    ballX = playerServing ? (playerX + 0.14) : aiX;
    ballY = playerServing ? 0.05 : aiY;
    ballZ = 0.65;
    ballVx = 0;
    ballVy = 0;
    ballVz = 0;
    ballCurve = 0;
    ballSpinVertical = 0;
    ballRotationAngle = 0;
  }

  void spawnHitSparks(double x, double y, double z, Color color) {
    final rng = math.Random();
    for (int i = 0; i < 16; i++) {
      particles.add(
        CourtParticle(
          x: x,
          y: y,
          z: z,
          vx: (rng.nextDouble() - 0.5) * 2.2,
          vy: (rng.nextDouble() - 0.5) * 2.2,
          vz: (rng.nextDouble() * 1.8) + 0.5,
          life: 0.35 + rng.nextDouble() * 0.20,
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
        radius: 3.0,
        opacity: 0.90,
        color: color,
      ),
    );
  }

  void updateVisualParticles(double dt) {
    for (int i = shockwaves.length - 1; i >= 0; i--) {
      final sw = shockwaves[i];
      sw.radius += dt * 42.0;
      sw.opacity -= dt * 2.1;
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
        p.vz -= 3.2 * dt;
      }
    }
  }

  // ==========================================================================
  // JITTER-FREE BALL FLIGHT SIMULATION WITH NET CLEARANCE
  // ==========================================================================
  void updateBallFlight({
    required double dt,
    required double currentTime,
    required Function(bool playerWon, String reason) onPointEnded,
    required VoidCallback onBallBounce,
    required VoidCallback onNetFault,
    required VoidCallback onOutOfBounds,
  }) {
    // 1. Aerodynamic wiffle drag (smooth deceleration without hitching)
    final speed = math.sqrt(ballVx * ballVx + ballVy * ballVy);
    final drag = 1.0 - (0.13 * dt * (1.0 + speed * 0.28));
    ballVx *= drag;
    ballVy *= drag;

    // 2. Lateral spin drift and vertical topspin/backspin loft
    ballVx += ballCurve * dt * 2.0;
    ballVz -= (gravity + (ballSpinVertical * 1.6)) * dt;

    ballCurve *= math.max(0.0, 1.0 - 1.2 * dt);
    ballSpinVertical *= math.max(0.0, 1.0 - 1.1 * dt);
    ballRotationAngle += (speed * 12.0) * dt;

    ballX += ballVx * dt;
    ballY += ballVy * dt;
    ballZ += ballVz * dt;

    // Jitter-free trail recording: distance-gated sampling
    if (smoothTrail.isEmpty) {
      smoothTrail.add(TrailNode(x: ballX, y: ballY, z: ballZ, time: currentTime));
    } else {
      final last = smoothTrail.last;
      final distSq = (ballX - last.x) * (ballX - last.x) +
          (ballY - last.y) * (ballY - last.y) +
          (ballZ - last.z) * (ballZ - last.z);

      if (distSq > 0.0016) { // Adds node only after 4cm of smooth travel
        smoothTrail.add(TrailNode(x: ballX, y: ballY, z: ballZ, time: currentTime));
      }
    }

    // Age-based trail culling (smooth 0.28s tail lifetime)
    smoothTrail.removeWhere((node) => (currentTime - node.time) > 0.28);
    if (smoothTrail.length > 18) smoothTrail.removeAt(0);

    // 3. Floor Bounce & Increased Restitution
    if (ballZ <= 0.0) {
      ballZ = 0.0;
      final currentHalf = (ballY < 0.50) ? 1 : 2;

      // Out of bounds check
      final isOut = ballX.abs() > 1.0 || ballY < -0.05 || ballY > 1.05;

      if (isOut) {
        spawnHitSparks(ballX, ballY, 0.0, const Color(0xFFFF5252));
        spawnBounceShockwave(ballX, ballY, const Color(0xFFFF5252));
        onOutOfBounds();
        onPointEnded(ballVy < 0, 'OUT OF BOUNDS');
        return;
      }

      // First serve bounce check in NVZ kitchen
      if (isServeBall && bouncesThisRally == 0) {
        isServeBall = false;
        if (ballY >= 0.34 && ballY <= 0.66) {
          spawnHitSparks(ballX, ballY, 0.0, const Color(0xFFFF5252));
          onPointEnded(ballVy < 0, 'SERVICE FAULT (Landed in Kitchen)');
          return;
        }
      }

      // Double bounce on same half
      if (lastBounceHalf == currentHalf) {
        spawnHitSparks(ballX, ballY, 0.0, const Color(0xFFFF5252));
        spawnBounceShockwave(ballX, ballY, const Color(0xFFFF5252));
        onPointEnded(currentHalf == 2, 'DOUBLE BOUNCE FAULT');
        return;
      }

      lastBounceHalf = currentHalf;
      bouncesThisRally++;

      // Energetic floor bounce restitution (No dying balls)
      if (ballVz.abs() > 0.35) {
        onBallBounce();
        spawnHitSparks(ballX, ballY, 0.0, const Color(0xFFD6F800));
        spawnBounceShockwave(ballX, ballY, const Color(0xFFD6F800));
      }

      // Restitution: 78% retention + minimum playable apex
      ballVz = -ballVz * 0.78;
      if (ballVz.abs() < 1.1 && ballVz.abs() > 0.2) {
        ballVz = 1.1; // Ensures ball rises back to waist height
      }
    }

    // 4. Net Collision (Y = 0.50, Height Z = 0.44m)
    if ((ballY - 0.50).abs() < 0.035 && ballZ < 0.44) {
      spawnHitSparks(ballX, 0.50, ballZ, Colors.white);
      onNetFault();
      onPointEnded(ballVy < 0, 'NET FAULT');
      return;
    }

    // 5. Baseline Out Checks
    if (ballY > 1.25) {
      onPointEnded(lastBounceHalf == 2, lastBounceHalf == 2 ? 'WINNER' : 'OUT OF BOUNDS');
    } else if (ballY < -0.30) {
      onPointEnded(lastBounceHalf != 1, lastBounceHalf == 1 ? 'MISSED BALL' : 'OUT OF BOUNDS');
    }
  }

  // ==========================================================================
  // ANALYTIC TRAJECTORY PREDICTOR (HOLOGRAPHIC PIPREVIEW)
  // ==========================================================================
  List<Vector3D> computePredictedTrajectory({int samples = 20}) {
    final List<Vector3D> points = [];
    if (ballVy == 0) return points;

    // Simulate forward parabola up to next floor contact (Z = 0)
    double t = 0.0;
    const double dtStep = 0.045;

    double simX = ballX;
    double simY = ballY;
    double simZ = ballZ;
    double simVx = ballVx;
    double simVy = ballVy;
    double simVz = ballVz;

    for (int i = 0; i < samples; i++) {
      points.add(Vector3D(simX, simY, simZ));

      simVx += ballCurve * dtStep * 2.0;
      simVz -= (gravity + (ballSpinVertical * 1.6)) * dtStep;
      simX += simVx * dtStep;
      simY += simVy * dtStep;
      simZ += simVz * dtStep;
      t += dtStep;

      // Stop once trajectory reaches floor or out of playable bounds
      if (simZ <= 0.0 || simY < -0.35 || simY > 1.35) {
        points.add(Vector3D(simX, simY, 0.0));
        break;
      }
    }

    return points;
  }
}

class Vector3D {
  final double x;
  final double y;
  final double z;

  const Vector3D(this.x, this.y, this.z);
}