import 'dart:math';
import 'package:flutter/material.dart';
import '../models/particle.dart';
import 'visual_theme.dart';

class ExplosionSpawner {
  ExplosionSpawner._();

  /// Spawn death-explosion particles into [particles] using the given [pattern].
  ///
  /// [particles] is cleared first. [count] particles are created at ([x],[y])
  /// with colors cycling through [colors], a lifespan around [life], and the
  /// supplied [gravity].
  static void spawn(
    ExplosionPattern pattern,
    List<Particle> particles,
    double x,
    double y,
    List<Color> colors,
    int count,
    double life,
    double gravity,
    Random rng,
  ) {
    particles.clear();
    switch (pattern) {
      case ExplosionPattern.burst:
        _spawnBurst(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.spiral:
        _spawnSpiral(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.ring:
        _spawnRing(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.fountain:
        _spawnFountain(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.vortex:
        _spawnVortex(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.shatter:
        _spawnShatter(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.bloom:
        _spawnBloom(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.lightning:
        _spawnLightning(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.cascade:
        _spawnCascade(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.implosion:
        _spawnImplosion(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.nova:
        _spawnNova(particles, x, y, colors, count, life, gravity, rng);
      case ExplosionPattern.fractal:
        _spawnFractal(particles, x, y, colors, count, life, gravity, rng);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static double _randRange(Random rng, double lo, double hi) =>
      lo + rng.nextDouble() * (hi - lo);

  static double _lifeJitter(Random rng, double base) =>
      base * (0.7 + rng.nextDouble() * 0.6);

  // ── burst ──────────────────────────────────────────────────────────────────
  /// Random radial blast — angles random, speeds 80-450, radii 2-7.
  static void _spawnBurst(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = _randRange(rng, 80, 450);
      particles.add(Particle(
        x: x,
        y: y,
        velocityX: cos(angle) * speed,
        velocityY: sin(angle) * speed,
        life: _lifeJitter(rng, life),
        radius: _randRange(rng, 2, 7),
        color: colors[i % colors.length],
        gravity: gravity,
      ));
    }
  }

  // ── spiral ─────────────────────────────────────────────────────────────────
  /// Golden-ratio spiral — 137.5 degree increments, sqrt(i) * 8 radius.
  static void _spawnSpiral(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    const goldenAngle = 137.5 * pi / 180;
    for (int i = 0; i < count; i++) {
      final angle = i * goldenAngle;
      final dist = sqrt(i.toDouble()) * 8;
      final speed = 100 + dist * 3;
      particles.add(Particle(
        x: x,
        y: y,
        velocityX: cos(angle) * speed,
        velocityY: sin(angle) * speed,
        life: _lifeJitter(rng, life),
        radius: _randRange(rng, 2, 5),
        color: colors[i % colors.length],
        gravity: gravity,
      ));
    }
  }

  // ── ring ───────────────────────────────────────────────────────────────────
  /// Concentric rings — 3 rings at different speeds, evenly spaced angles.
  static void _spawnRing(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    const ringCount = 3;
    final perRing = count ~/ ringCount;
    const speeds = [150.0, 280.0, 400.0];

    for (int r = 0; r < ringCount; r++) {
      final n = (r == ringCount - 1) ? count - perRing * r : perRing;
      for (int i = 0; i < n; i++) {
        final angle = (i / n) * 2 * pi + r * 0.3;
        final speed = speeds[r] + rng.nextDouble() * 30;
        particles.add(Particle(
          x: x,
          y: y,
          velocityX: cos(angle) * speed,
          velocityY: sin(angle) * speed,
          life: _lifeJitter(rng, life * (1.0 + r * 0.15)),
          radius: _randRange(rng, 2, 5),
          color: colors[(perRing * r + i) % colors.length],
          gravity: gravity,
        ));
      }
    }
  }

  // ── fountain ───────────────────────────────────────────────────────────────
  /// Upward velocity (-200 to -500 Y) with high gravity (120+).
  static void _spawnFountain(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    final effectiveGravity = max(gravity, 120.0);
    for (int i = 0; i < count; i++) {
      final vy = _randRange(rng, -500, -200);
      final vx = _randRange(rng, -80, 80);
      particles.add(Particle(
        x: x + _randRange(rng, -5, 5),
        y: y,
        velocityX: vx,
        velocityY: vy,
        life: _lifeJitter(rng, life * 1.2),
        radius: _randRange(rng, 2, 6),
        color: colors[i % colors.length],
        gravity: effectiveGravity,
      ));
    }
  }

  // ── vortex ─────────────────────────────────────────────────────────────────
  /// Tangential velocity (perpendicular to radial) creating a spiral outflow.
  static void _spawnVortex(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final radialSpeed = _randRange(rng, 60, 200);
      final tangentialSpeed = _randRange(rng, 150, 350);
      // Radial + tangential components.
      final vx =
          cos(angle) * radialSpeed + cos(angle + pi / 2) * tangentialSpeed;
      final vy =
          sin(angle) * radialSpeed + sin(angle + pi / 2) * tangentialSpeed;
      particles.add(Particle(
        x: x,
        y: y,
        velocityX: vx,
        velocityY: vy,
        life: _lifeJitter(rng, life),
        radius: _randRange(rng, 2, 5),
        color: colors[i % colors.length],
        gravity: gravity * 0.3,
      ));
    }
  }

  // ── shatter ────────────────────────────────────────────────────────────────
  /// Angular quadrant-based fragments with low gravity.
  static void _spawnShatter(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    for (int i = 0; i < count; i++) {
      final quadrant = i % 4;
      final baseAngle = quadrant * pi / 2;
      final angle = baseAngle + _randRange(rng, -0.4, 0.4);
      final speed = _randRange(rng, 100, 400);
      particles.add(Particle(
        x: x,
        y: y,
        velocityX: cos(angle) * speed,
        velocityY: sin(angle) * speed,
        life: _lifeJitter(rng, life),
        radius: _randRange(rng, 3, 7),
        color: colors[i % colors.length],
        gravity: gravity * 0.2,
      ));
    }
  }

  // ── bloom ──────────────────────────────────────────────────────────────────
  /// Petal curves — r = cos(n*theta) for a petal pattern (n = 5).
  static void _spawnBloom(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    const petalN = 5;
    for (int i = 0; i < count; i++) {
      final theta = (i / count) * 2 * pi;
      final petalR = cos(petalN * theta).abs();
      final speed = 80 + petalR * 320 + rng.nextDouble() * 40;
      particles.add(Particle(
        x: x,
        y: y,
        velocityX: cos(theta) * speed,
        velocityY: sin(theta) * speed,
        life: _lifeJitter(rng, life),
        radius: _randRange(rng, 2, 5),
        color: colors[i % colors.length],
        gravity: gravity * 0.5,
      ));
    }
  }

  // ── lightning ──────────────────────────────────────────────────────────────
  /// Tree branching: main trunk upward + random branches at various angles.
  static void _spawnLightning(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    // Main trunk particles (30 %) go mostly upward.
    final trunkCount = (count * 0.3).round();
    for (int i = 0; i < trunkCount; i++) {
      final progress = i / trunkCount;
      final vx = _randRange(rng, -30, 30);
      final vy = -200 - progress * 300;
      particles.add(Particle(
        x: x + _randRange(rng, -3, 3),
        y: y,
        velocityX: vx,
        velocityY: vy,
        life: _lifeJitter(rng, life * 0.8),
        radius: _randRange(rng, 1.5, 4),
        color: colors[i % colors.length],
        gravity: gravity * 0.3,
      ));
    }
    // Branch particles (70 %) spray outward at varied angles.
    final branchCount = count - trunkCount;
    for (int i = 0; i < branchCount; i++) {
      final baseAngle = _randRange(rng, -pi, pi);
      final angle = baseAngle + _randRange(rng, -0.5, 0.5);
      final speed = _randRange(rng, 80, 350);
      particles.add(Particle(
        x: x,
        y: y,
        velocityX: cos(angle) * speed,
        velocityY: sin(angle) * speed,
        life: _lifeJitter(rng, life * 0.6),
        radius: _randRange(rng, 1, 3),
        color: colors[(trunkCount + i) % colors.length],
        gravity: gravity * 0.2,
      ));
    }
  }

  // ── cascade ────────────────────────────────────────────────────────────────
  /// Downward waterfall: start at x with horizontal spread, velocities mostly
  /// downward.
  static void _spawnCascade(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    for (int i = 0; i < count; i++) {
      final vx = _randRange(rng, -120, 120);
      final vy = _randRange(rng, 50, 350);
      particles.add(Particle(
        x: x + _randRange(rng, -20, 20),
        y: y,
        velocityX: vx,
        velocityY: vy,
        life: _lifeJitter(rng, life * 1.1),
        radius: _randRange(rng, 2, 6),
        color: colors[i % colors.length],
        gravity: gravity,
      ));
    }
  }

  // ── implosion ──────────────────────────────────────────────────────────────
  /// Particles start at a large radius and converge inward (negative radial
  /// velocity).
  static void _spawnImplosion(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final startDist = _randRange(rng, 80, 200);
      final speed = _randRange(rng, -350, -120); // negative = inward

      particles.add(Particle(
        x: x + cos(angle) * startDist,
        y: y + sin(angle) * startDist,
        velocityX: cos(angle) * speed,
        velocityY: sin(angle) * speed,
        life: _lifeJitter(rng, life * 0.9),
        radius: _randRange(rng, 2, 6),
        color: colors[i % colors.length],
        gravity: gravity * 0.1,
      ));
    }
  }

  // ── nova ───────────────────────────────────────────────────────────────────
  /// Two-phase: inner ring of fast particles + outer ring of slow particles.
  static void _spawnNova(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    final innerCount = count ~/ 2;
    final outerCount = count - innerCount;

    // Inner ring — fast, short-lived.
    for (int i = 0; i < innerCount; i++) {
      final angle = (i / innerCount) * 2 * pi + rng.nextDouble() * 0.2;
      final speed = _randRange(rng, 300, 500);
      particles.add(Particle(
        x: x,
        y: y,
        velocityX: cos(angle) * speed,
        velocityY: sin(angle) * speed,
        life: _lifeJitter(rng, life * 0.6),
        radius: _randRange(rng, 2, 4),
        color: colors[i % colors.length],
        gravity: gravity * 0.4,
      ));
    }

    // Outer ring — slow, long-lived.
    for (int i = 0; i < outerCount; i++) {
      final angle = (i / outerCount) * 2 * pi + rng.nextDouble() * 0.15;
      final speed = _randRange(rng, 60, 160);
      particles.add(Particle(
        x: x,
        y: y,
        velocityX: cos(angle) * speed,
        velocityY: sin(angle) * speed,
        life: _lifeJitter(rng, life * 1.4),
        radius: _randRange(rng, 3, 7),
        color: colors[(innerCount + i) % colors.length],
        gravity: gravity * 0.6,
      ));
    }
  }

  // ── fractal ────────────────────────────────────────────────────────────────
  /// Tree branching with recursive angle subdivision. 4 levels of branching:
  /// each level doubles the number of directions, particles distributed across
  /// levels.
  static void _spawnFractal(List<Particle> particles, double x, double y,
      List<Color> colors, int count, double life, double gravity, Random rng) {
    const levels = 4;
    final perLevel = count ~/ levels;

    // Start with one direction, each level splits into two.
    List<double> angles = [_randRange(rng, -pi, pi)];

    for (int level = 0; level < levels; level++) {
      final n = (level == levels - 1) ? count - perLevel * level : perLevel;
      final speed = 350 - level * 70.0; // decreasing speed per level
      final lifeScale = 1.0 + level * 0.15;

      for (int i = 0; i < n; i++) {
        final baseAngle = angles[i % angles.length];
        final jitter = _randRange(rng, -0.3, 0.3);
        final angle = baseAngle + jitter;
        final s = speed + rng.nextDouble() * 60;

        particles.add(Particle(
          x: x,
          y: y,
          velocityX: cos(angle) * s,
          velocityY: sin(angle) * s,
          life: _lifeJitter(rng, life * lifeScale),
          radius: _randRange(rng, 1.5, 5),
          color: colors[(perLevel * level + i) % colors.length],
          gravity: gravity * (0.3 + level * 0.15),
        ));
      }

      // Split each angle into two for the next level.
      final newAngles = <double>[];
      for (final a in angles) {
        newAngles.add(a + _randRange(rng, 0.3, 0.8));
        newAngles.add(a - _randRange(rng, 0.3, 0.8));
      }
      angles = newAngles;
    }
  }
}
