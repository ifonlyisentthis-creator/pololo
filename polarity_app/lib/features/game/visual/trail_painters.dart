import 'dart:math';
import 'package:flutter/material.dart';
import 'visual_theme.dart';
import '../models/particle.dart';

class TrailPainters {
  TrailPainters._();

  static final Paint _fillPaint = Paint();
  static final Paint _fillPaint2 = Paint();
  static final Paint _strokePaint = Paint();
  static final Path _pathA = Path();
  static final Path _pathB = Path();

  /// Draw a single trail particle with the given style.
  /// [alpha] = p.life / p.maxLife (1.0 = fresh, fading toward 0 as it dies).
  static void draw(TrailStyle style, Canvas canvas, Particle p, double alpha) {
    switch (style) {
      case TrailStyle.dots:
        _drawDot(canvas, p, alpha);
      case TrailStyle.streaks:
        _drawStreak(canvas, p, alpha);
      case TrailStyle.flames:
        _drawFlame(canvas, p, alpha);
      case TrailStyle.sparkles:
        _drawSparkle(canvas, p, alpha);
      case TrailStyle.ribbons:
        _drawRibbon(canvas, p, alpha);
      case TrailStyle.bubbles:
        _drawBubble(canvas, p, alpha);
      case TrailStyle.embers:
        _drawEmber(canvas, p, alpha);
      case TrailStyle.crystals:
        _drawCrystal(canvas, p, alpha);
      case TrailStyle.lightning:
        _drawLightning(canvas, p, alpha);
      case TrailStyle.shadows:
        _drawShadow(canvas, p, alpha);
      case TrailStyle.waves:
        _drawWave(canvas, p, alpha);
      case TrailStyle.droplets:
        _drawDroplet(canvas, p, alpha);
      case TrailStyle.code:
        _drawCode(canvas, p, alpha);
      case TrailStyle.feathers:
        _drawFeather(canvas, p, alpha);
      case TrailStyle.shards:
        _drawShard(canvas, p, alpha);
    }
  }

  // ── dots ───────────────────────────────────────────────────────────────────
  /// Simple soft circle at the particle position.
  static void _drawDot(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;
    _fillPaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(Offset(p.x, p.y), r, _fillPaint);
  }

  // ── streaks ────────────────────────────────────────────────────────────────
  /// Elongated ellipse oriented along the velocity vector, length proportional
  /// to speed so faster particles leave longer trails.
  static void _drawStreak(Canvas canvas, Particle p, double alpha) {
    final speed = sqrt(p.velocityX * p.velocityX + p.velocityY * p.velocityY);
    final length = (speed * 0.04 + 1.0) * p.radius * alpha;
    final width = p.radius * alpha * 0.5;
    if (length <= 0 || width <= 0) return;

    final angle = atan2(p.velocityY, p.velocityX);

    _fillPaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;

    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: length * 2, height: width * 2),
      _fillPaint,
    );
    canvas.restore();
  }

  // ── flames ─────────────────────────────────────────────────────────────────
  /// Upward-pointing triangle (opposite to velocity) with flickering alpha.
  static void _drawFlame(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;

    final flickerAlpha = (alpha * (0.6 + sin(p.life * 18) * 0.4)).clamp(0.0, 1.0);
    final angle = atan2(p.velocityY, p.velocityX);
    final tipAngle = angle + pi;
    final baseAngle1 = angle + pi * 0.7;
    final baseAngle2 = angle - pi * 0.7;
    final tipLen = r * 2.5;
    final baseLen = r * 1.2;

    final path = _pathA
      ..reset()
      ..moveTo(p.x + cos(tipAngle) * tipLen, p.y + sin(tipAngle) * tipLen)
      ..lineTo(p.x + cos(baseAngle1) * baseLen, p.y + sin(baseAngle1) * baseLen)
      ..lineTo(p.x + cos(baseAngle2) * baseLen, p.y + sin(baseAngle2) * baseLen)
      ..close();

    // Glow layer (no GPU blur — fake glow via larger translucent draw)
    _fillPaint
      ..color = p.color.withValues(alpha: flickerAlpha * 0.25)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.scale(1.4);
    canvas.translate(-p.x, -p.y);
    canvas.drawPath(path, _fillPaint);
    canvas.restore();
    // Core
    _fillPaint
      ..color = p.color.withValues(alpha: flickerAlpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawPath(path, _fillPaint);
  }

  // ── sparkles ───────────────────────────────────────────────────────────────
  /// 4-pointed star: two thin diamonds rotated 45 degrees from each other.
  static void _drawSparkle(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;

    _fillPaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;

    final longR = r * 2.0;
    final shortR = r * 0.4;

    // First diamond (vertical / horizontal)
    final path = _pathA
      ..reset()
      ..moveTo(p.x, p.y - longR)
      ..lineTo(p.x + shortR, p.y)
      ..lineTo(p.x, p.y + longR)
      ..lineTo(p.x - shortR, p.y)
      ..close();
    canvas.drawPath(path, _fillPaint);

    // Second diamond rotated 45 degrees
    final diag = longR * 0.707; // cos(45) ≈ 0.707
    final diagS = shortR * 0.707;
    final path2 = _pathB
      ..reset()
      ..moveTo(p.x - diag, p.y - diag)
      ..lineTo(p.x + diagS, p.y - diagS)
      ..lineTo(p.x + diag, p.y + diag)
      ..lineTo(p.x - diagS, p.y + diagS)
      ..close();
    canvas.drawPath(path2, _fillPaint);
  }

  // ── ribbons ────────────────────────────────────────────────────────────────
  /// Elongated curved arc, wider at center, tapered at ends.
  static void _drawRibbon(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;

    final angle = atan2(p.velocityY, p.velocityX);
    final length = r * 3.0;
    final midWidth = r * 0.8;

    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(angle);

    final path = _pathA
      ..reset()
      ..moveTo(-length, 0)
      ..quadraticBezierTo(0, -midWidth, length, 0)
      ..quadraticBezierTo(0, midWidth, -length, 0)
      ..close();

    _fillPaint
      ..color = p.color.withValues(alpha: alpha * 0.8)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawPath(path, _fillPaint);
    canvas.restore();
  }

  // ── bubbles ────────────────────────────────────────────────────────────────
  /// Stroked (hollow) circle — a simple ring.
  static void _drawBubble(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha * 1.5;
    if (r <= 0) return;

    _strokePaint
      ..color = p.color.withValues(alpha: alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.25).clamp(0.5, 2.0)
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(Offset(p.x, p.y), r, _strokePaint);
  }

  // ── embers ─────────────────────────────────────────────────────────────────
  /// Circle with a warm glow, slightly larger blur. Gravity-oriented drift.
  static void _drawEmber(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;

    // Inner core
    _fillPaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(Offset(p.x, p.y), r, _fillPaint);
    // Outer glow
    _fillPaint2
      ..color = p.color.withValues(alpha: alpha * 0.3)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(Offset(p.x, p.y), r * 2.0, _fillPaint2);
  }

  // ── crystals ───────────────────────────────────────────────────────────────
  /// Small angular polygon (4 vertices at fixed offset angles), slowly rotating.
  static void _drawCrystal(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha * 1.3;
    if (r <= 0) return;

    // Deterministic "random" rotation based on particle position hash.
    final baseAngle = (p.x * 3.7 + p.y * 2.3) % (2 * pi);
    final rotation = baseAngle + p.life * 2.0;

    // 4 vertices at uneven angular offsets for a crystalline look.
    const offsets = [0.0, 1.3, 2.9, 4.6];
    final path = _pathA..reset();
    for (int i = 0; i < offsets.length; i++) {
      final a = rotation + offsets[i];
      final vx = p.x + cos(a) * r;
      final vy = p.y + sin(a) * r;
      if (i == 0) {
        path.moveTo(vx, vy);
      } else {
        path.lineTo(vx, vy);
      }
    }
    path.close();

    _fillPaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawPath(path, _fillPaint);
  }

  // ── lightning ──────────────────────────────────────────────────────────────
  /// Short jagged line segment (3-4 points) along the velocity direction.
  static void _drawLightning(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;

    final angle = atan2(p.velocityY, p.velocityX);
    final perpX = -sin(angle);
    final perpY = cos(angle);
    final segLen = r * 1.5;

    // Build a jagged path with 4 points.
    final path = _pathA
      ..reset()
      ..moveTo(p.x, p.y);
    double cx = p.x, cy = p.y;
    // Deterministic jags based on life value.
    final jags = [0.6, -0.8, 0.4];
    for (int i = 0; i < 3; i++) {
      cx += cos(angle) * segLen;
      cy += sin(angle) * segLen;
      final jag = jags[i] * r * 2;
      path.lineTo(cx + perpX * jag, cy + perpY * jag);
    }

    _strokePaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.4).clamp(0.5, 2.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, _strokePaint);
  }

  // ── shadows ────────────────────────────────────────────────────────────────
  /// Very faint, large blur circle — ghostly afterimage.
  static void _drawShadow(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha * 2.0;
    if (r <= 0) return;

    _fillPaint
      ..color = p.color.withValues(alpha: alpha * 0.3)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(Offset(p.x, p.y), r, _fillPaint);
  }

  // ── waves ──────────────────────────────────────────────────────────────────
  /// Circle with position offset by a sine wave for a floating effect.
  static void _drawWave(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;

    final waveOffset = sin(p.life * 10 + p.x * 0.05) * r * 3;

    _fillPaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(Offset(p.x + waveOffset, p.y), r, _fillPaint);
  }

  // ── droplets ───────────────────────────────────────────────────────────────
  /// Teardrop: circle at the base, point toward velocity direction.
  static void _drawDroplet(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;

    final angle = atan2(p.velocityY, p.velocityX);
    final tipLen = r * 3.0;

    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(angle);

    // Teardrop: two curves from the tip converging at a circle.
    final path = _pathA
      ..reset()
      ..moveTo(tipLen, 0)
      ..quadraticBezierTo(0, -r, -r * 0.3, 0)
      ..quadraticBezierTo(0, r, tipLen, 0)
      ..close();

    _fillPaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawPath(path, _fillPaint);
    canvas.restore();
  }

  // ── code ───────────────────────────────────────────────────────────────────
  /// Small filled rectangle (3x6 pixels) — a tiny monospace glyph block.
  static void _drawCode(Canvas canvas, Particle p, double alpha) {
    _fillPaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(p.x, p.y), width: 3, height: 6),
      _fillPaint,
    );
  }

  // ── feathers ───────────────────────────────────────────────────────────────
  /// Thin curved arc stroke — a wispy feather shape.
  static void _drawFeather(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;

    final angle = atan2(p.velocityY, p.velocityX);

    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(angle);

    final arcRect = Rect.fromCenter(
      center: Offset.zero,
      width: r * 4,
      height: r * 2,
    );
    _strokePaint
      ..color = p.color.withValues(alpha: alpha * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.35).clamp(0.4, 1.5)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -pi * 0.3, pi * 0.6, false, _strokePaint);
    canvas.restore();
  }

  // ── shards ─────────────────────────────────────────────────────────────────
  /// Sharp triangle fragment oriented along the velocity direction.
  static void _drawShard(Canvas canvas, Particle p, double alpha) {
    final r = p.radius * alpha;
    if (r <= 0) return;

    final angle = atan2(p.velocityY, p.velocityX);
    final tipLen = r * 2.5;
    final halfBase = r * 0.6;

    // Triangle: tip along velocity, base perpendicular behind.
    final tipX = p.x + cos(angle) * tipLen;
    final tipY = p.y + sin(angle) * tipLen;
    final perpX = -sin(angle);
    final perpY = cos(angle);
    final baseX1 = p.x + perpX * halfBase;
    final baseY1 = p.y + perpY * halfBase;
    final baseX2 = p.x - perpX * halfBase;
    final baseY2 = p.y - perpY * halfBase;

    final path = _pathA
      ..reset()
      ..moveTo(tipX, tipY)
      ..lineTo(baseX1, baseY1)
      ..lineTo(baseX2, baseY2)
      ..close();

    _fillPaint
      ..color = p.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;
    canvas.drawPath(path, _fillPaint);
  }
}
