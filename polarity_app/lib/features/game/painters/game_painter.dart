import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:polarity/core/constants.dart';
import 'package:polarity/features/game/engine/game_engine.dart';
import 'package:polarity/features/game/visual/theme_renderer.dart';
import 'package:polarity/features/game/visual/visual_theme.dart';
import 'package:polarity/features/game/troll/troll_system.dart';

class GamePainter extends CustomPainter {
  final GameEngine engine;
  final bool isDarkTheme;

  // Reusable paint objects — avoids per-draw allocation
  final Paint _fillPaint = Paint();
  final Paint _glowPaint = Paint();

  // V6: Pre-allocated reusable Paint objects to eliminate per-frame allocations
  final Paint _p = Paint();
  final Paint _p2 = Paint();
  final Paint _shaderP = Paint();

  // Cached vignette — only rebuilt when inversion or size changes
  bool? _cachedVignetteInverted;
  Size? _cachedVignetteSize;
  Paint? _cachedVignettePaint;

  // Cached countdown text — only rebuilt when countdownValue changes
  int _cachedCountdownValue = -1;
  TextPainter? _cachedCountdownPainter;
  Color? _cachedCountdownColor;

  // Cached tutorial opacity bucket — avoids per-frame setState upstream
  int lastTutorialOpacityBucket = -1;

  GamePainter({
    required this.engine,
    required this.isDarkTheme,
    super.repaint,
  });

  // Phase 5 inverts the theme regardless of user setting
  bool get _inverted => engine.isPhase5Inverted;
  Color get bgColor =>
      _inverted ? Colors.white : (isDarkTheme ? Colors.black : Colors.white);
  Color get fgColor =>
      _inverted ? Colors.black : (isDarkTheme ? Colors.white : Colors.black);

  /// Accent color guaranteed to be visible against the current background.
  /// Phase 1 white is invisible on white bg → use fgColor instead.
  /// Phase 5 black is invisible on black bg → use fgColor instead.
  Color get visibleAccent {
    // V3: When theme is active, use the pre-resolved effective theme's primary color
    final theme = engine.effectiveTheme;
    if (theme != null) {
      return theme.ballColors.first;
    }
    final raw = engine.accentColor;
    final bg = bgColor;
    // If accent is too close to background, substitute fgColor
    final dr = ((raw.r - bg.r) * 255).abs();
    final dg = ((raw.g - bg.g) * 255).abs();
    final db = ((raw.b - bg.b) * 255).abs();
    final contrast = dr + dg + db;
    if (contrast < 80) return fgColor;
    return raw;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Solid background
    _p.color = bgColor;
    _p.style = PaintingStyle.fill;
    _p.shader = null;
    _p.maskFilter = null;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _p,
    );

    // Pre-resolve effective theme once per frame (cached, no allocation)
    final theme = engine.effectiveTheme;

    // Screen shake wrapping — everything inside shakes
    canvas.save();
    if (engine.screenShakeIntensity > 0.5) {
      canvas.translate(engine.screenShakeX, engine.screenShakeY);
    }

    _drawAmbientParticles(canvas, size, theme);
    // V3: Draw themed walls before obstacles
    if (theme != null) {
      ThemeRenderer.drawWalls(canvas, size, theme, engine.gameTime);
    }
    _drawObstacles(canvas, size, theme);
    _drawTrailParticles(canvas, size, theme);
    _drawMagnetParticles(canvas, size);

    if (engine.player.isAlive) {
      _drawMagnetLines(canvas, size, theme);
      _drawPlayer(canvas, size, theme);
      if (engine.hasShield) _drawShield(canvas, size);
    }

    // V4: Draw troll ball (ghost-like, translucent)
    _drawTrollBall(canvas, size);

    _drawPhaseTransition(canvas, size);
    _drawMilestoneGlow(canvas, size);
    _drawEliteUnlockFlash(canvas, size);
    // V3: Theme transition VFX
    if (engine.activeTheme != null && engine.themeTransitionTimer > 0) {
      ThemeRenderer.drawThemeTransition(canvas, size, engine.player.x,
          engine.player.y, engine.themeTransitionTimer, engine.activeTheme!);
    }
    _drawShockwave(canvas, size);
    _drawDeathParticles(canvas, size, theme);

    if (engine.state == GameState.countdown) {
      _drawCountdown(canvas, size);
    }

    canvas.restore();

    // These draw OUTSIDE the shake — stable overlays
    _drawDeathFlash(canvas, size);
    _drawFakeDeathFlash(canvas, size);
    _drawVignette(canvas, size);
    _drawNearHighScoreEdge(canvas, size);
  }

  // ── Ambient Background Particles ──
  void _drawAmbientParticles(Canvas canvas, Size size, VisualTheme? theme) {
    // V3: Use theme renderer if theme is active
    if (theme != null) {
      ThemeRenderer.drawAmbientParticles(canvas, engine.ambientParticles, theme);
      return;
    }
    for (final p in engine.ambientParticles) {
      if (p.isDead) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      _fillPaint.color = visibleAccent.withValues(alpha: alpha * 0.08);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, _fillPaint);
    }
  }

  // ── Obstacles ──
  void _drawObstacles(Canvas canvas, Size size, VisualTheme? theme) {
    // V3: Use theme renderer if theme is active
    if (theme != null) {
      ThemeRenderer.drawObstacles(canvas, size, engine.obstacles,
          theme, fgColor, engine.gameTime);
      return;
    }
    // Hoist gradient colors outside loop (avoids per-obstacle List allocation)
    final obstacleColors = [fgColor, fgColor.withValues(alpha: 0.6)];
    const obstacleStops = [0.0, 1.0];
    for (final obs in engine.obstacles) {
      if (obs.worldY < -50 || obs.worldY > size.height + 50) continue;

      final halfT = obs.thickness / 2;
      Rect rect;
      RRect rrect;
      if (obs.fromLeft) {
        rect = Rect.fromLTWH(0, obs.worldY - halfT, obs.width, obs.thickness);
        // Round only the exposed tip end
        rrect = RRect.fromRectAndCorners(rect,
            topRight: Radius.circular(halfT),
            bottomRight: Radius.circular(halfT));
      } else {
        rect = Rect.fromLTWH(
            size.width - obs.width, obs.worldY - halfT, obs.width, obs.thickness);
        rrect = RRect.fromRectAndCorners(rect,
            topLeft: Radius.circular(halfT),
            bottomLeft: Radius.circular(halfT));
      }

      // Subtle gradient: solid fgColor fading slightly toward the wall anchor
      final gradStart = obs.fromLeft ? rect.right : rect.left;
      final gradEnd = obs.fromLeft ? rect.left : rect.right;
      _shaderP.shader = ui.Gradient.linear(
        Offset(gradStart, obs.worldY),
        Offset(gradEnd, obs.worldY),
        obstacleColors,
        obstacleStops,
      );
      _shaderP.maskFilter = null;
      _shaderP.style = PaintingStyle.fill;
      canvas.drawRRect(rrect, _shaderP);

      // Pulsing accent glow at exposed tip (no GPU blur — double-draw fake glow)
      final tipX = obs.fromLeft ? rect.right : rect.left;
      final pulsePhase = engine.gameTime * 4.0 + obs.worldY * 0.02;
      final glowAlpha = (0.25 + 0.15 * sin(pulsePhase)).clamp(0.0, 1.0);
      final glowRadius = halfT * (0.5 + 0.15 * sin(pulsePhase));
      // Outer soft glow
      _glowPaint.color = visibleAccent.withValues(alpha: glowAlpha * 0.25);
      canvas.drawCircle(Offset(tipX, obs.worldY), glowRadius * 2.5, _glowPaint);
      // Core
      _fillPaint.color = visibleAccent.withValues(alpha: glowAlpha);
      canvas.drawCircle(Offset(tipX, obs.worldY), glowRadius, _fillPaint);
    }
  }

  // ── Phase-Specific Player Cores ──
  void _drawPlayer(Canvas canvas, Size size, VisualTheme? theme) {
    final px = engine.player.x;
    final py = engine.player.y;
    final pr = GameConstants.playerRadius;
    final phase = engine.currentPhase;
    final glow = engine.player.glowPhase;
    final stretch = engine.squashStretch;
    final accent = visibleAccent;
    final intensity = engine.glowIntensitySeed;

    // Invincibility rapid blink
    if (engine.isInvincible) {
      final blink = (sin(glow * 15) + 1) / 2;
      if (blink < 0.3) return;
    }

    // V3: Use theme renderer if theme is active
    if (theme != null) {
      ThemeRenderer.drawBall(canvas, px, py, pr, theme,
          glow, intensity, stretch);
      return;
    }

    canvas.save();
    canvas.translate(px, py);
    // Squash/stretch: stretch horizontally, compress vertically
    canvas.scale(stretch, 1.0 / stretch);

    if (engine.eliteUnlocked) {
      _drawElitePlayer(canvas, pr, phase, glow, accent, intensity);
    } else {
      switch (phase) {
        case 0:
          _drawPhase1Sphere(canvas, pr, glow, accent, intensity);
          break;
        case 1:
          _drawPhase2Ring(canvas, pr, glow, accent, intensity);
          break;
        case 2:
          _drawPhase3Diamond(canvas, pr, glow, accent, intensity);
          break;
        case 3:
          _drawPhase4Slit(canvas, pr, glow, accent, intensity);
          break;
        default:
          _drawPhase5Singularity(canvas, pr, glow, accent, intensity);
          break;
      }
    }

    canvas.restore();
  }

  // Phase 1: Glowing Sphere
  void _drawPhase1Sphere(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    final glowR = pr + 8 + sin(glow) * 3 * intensity;
    // Glow aura
    canvas.drawCircle(Offset.zero, glowR, Paint()
      ..color = accent.withValues(alpha: 0.25 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    // Gradient sphere
    canvas.drawCircle(Offset.zero, pr, Paint()
      ..shader = ui.Gradient.radial(
        Offset(-pr * 0.3, -pr * 0.3),
        pr * 1.2,
        [Colors.white, accent, accent.withValues(alpha: 0.5)],
        [0.0, 0.5, 1.0],
      ),
    );
    // Specular highlight
    canvas.drawCircle(Offset(-pr * 0.25, -pr * 0.25), pr * 0.35, Paint()
      ..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  // Phase 2: Hollow Ring with orbital dust
  void _drawPhase2Ring(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    // Outer glow
    canvas.drawCircle(Offset.zero, pr + 6, Paint()
      ..color = accent.withValues(alpha: 0.2 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Ring stroke
    canvas.drawCircle(Offset.zero, pr, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
    );
    // Inner hollow
    canvas.drawCircle(Offset.zero, pr * 0.4, Paint()
      ..color = accent.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Orbital dust particles (3 orbiting dots)
    for (int i = 0; i < 3; i++) {
      final angle = glow * 2.5 + i * (pi * 2 / 3);
      final ox = cos(angle) * (pr + 4);
      final oy = sin(angle) * (pr + 4);
      canvas.drawCircle(Offset(ox, oy), 1.5 + sin(glow * 3 + i) * 0.5, Paint()
        ..color = accent.withValues(alpha: 0.6),
      );
    }
  }

  // Phase 3: Pulsating Diamond
  void _drawPhase3Diamond(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    final pulse = 1.0 + sin(glow * 3) * 0.12 * intensity;
    final r = pr * pulse;
    // Glow
    canvas.drawCircle(Offset.zero, r + 8, Paint()
      ..color = accent.withValues(alpha: 0.2 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Diamond shape
    final path = Path()
      ..moveTo(0, -r * 1.2)
      ..lineTo(r * 0.9, 0)
      ..lineTo(0, r * 1.2)
      ..lineTo(-r * 0.9, 0)
      ..close();
    // Gradient fill
    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        r * 1.2,
        [Colors.white, accent],
        [0.0, 1.0],
      ),
    );
    // Stroke outline
    canvas.drawPath(path, Paint()
      ..color = accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
    );
  }

  // Phase 4: Searing Horizontal Slit
  void _drawPhase4Slit(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    final flicker = 1.0 + sin(glow * 6) * 0.15 * intensity;
    final slitW = pr * 2.2 * flicker;
    final slitH = pr * 0.35;
    // Wide glow
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: slitW + 16, height: slitH + 12),
      Paint()
        ..color = accent.withValues(alpha: 0.2 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Core slit
    final slitRect =
        Rect.fromCenter(center: Offset.zero, width: slitW, height: slitH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slitRect, const Radius.circular(2)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-slitW / 2, 0),
          Offset(slitW / 2, 0),
          [accent.withValues(alpha: 0.3), Colors.white, accent.withValues(alpha: 0.3)],
          [0.0, 0.5, 1.0],
        ),
    );
    // Bright center dot
    canvas.drawCircle(Offset.zero, 2.0, Paint()
      ..color = Colors.white,
    );
  }

  // Phase 5: Pitch-black Singularity with contrasting aura
  void _drawPhase5Singularity(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    // Aura color must contrast with background (white bg in phase 5)
    final auraColor = fgColor;
    final auraR = pr + 10 + sin(glow * 2) * 3 * intensity;
    // Aura
    canvas.drawCircle(Offset.zero, auraR, Paint()
      ..color = auraColor.withValues(alpha: 0.35 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Contrasting ring
    canvas.drawCircle(Offset.zero, pr + 3, Paint()
      ..color = auraColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
    );
    // Pitch black core
    canvas.drawCircle(Offset.zero, pr, Paint()
      ..color = Colors.black,
    );
    // Subtle dark gradient
    canvas.drawCircle(Offset.zero, pr * 0.6, Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        pr * 0.6,
        [const Color(0xFF111111), Colors.black],
        [0.0, 1.0],
      ),
    );
  }

  // ── Elite Player Variants ──
  void _drawElitePlayer(
      Canvas canvas, double pr, int phase, double glow, Color accent, double intensity) {
    switch (phase) {
      case 0:
        _drawEliteSphere(canvas, pr, glow, accent, intensity);
        break;
      case 1:
        _drawEliteRing(canvas, pr, glow, accent, intensity);
        break;
      case 2:
        _drawEliteDiamond(canvas, pr, glow, accent, intensity);
        break;
      case 3:
        _drawEliteSlit(canvas, pr, glow, accent, intensity);
        break;
      default:
        _drawEliteSingularity(canvas, pr, glow, accent, intensity);
        break;
    }
  }

  // Elite Phase 0: Sphere with rotating prismatic ring
  void _drawEliteSphere(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    // Larger glow aura
    final glowR = pr + 12 + sin(glow) * 4 * intensity;
    canvas.drawCircle(Offset.zero, glowR, Paint()
      ..color = accent.withValues(alpha: 0.3 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Core sphere
    canvas.drawCircle(Offset.zero, pr, Paint()
      ..shader = ui.Gradient.radial(
        Offset(-pr * 0.3, -pr * 0.3),
        pr * 1.2,
        [Colors.white, accent, accent.withValues(alpha: 0.5)],
        [0.0, 0.5, 1.0],
      ),
    );
    // Specular highlight
    canvas.drawCircle(Offset(-pr * 0.25, -pr * 0.25), pr * 0.35, Paint()
      ..color = Colors.white.withValues(alpha: 0.7),
    );
    // Rotating prismatic/rainbow ring (HSV hue cycling)
    final ringR = pr + 6;
    for (int i = 0; i < 36; i++) {
      final angle = glow * 2 + i * (pi * 2 / 36);
      final hue = ((glow * 60 + i * 10) % 360).toDouble();
      final ox = cos(angle) * ringR;
      final oy = sin(angle) * ringR;
      canvas.drawCircle(Offset(ox, oy), 1.5, Paint()
        ..color = HSVColor.fromAHSV(0.8, hue, 1.0, 1.0).toColor(),
      );
    }
  }

  // Elite Phase 1: Double nested rings + 5 orbital dots
  void _drawEliteRing(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    // Larger glow aura
    canvas.drawCircle(Offset.zero, pr + 10, Paint()
      ..color = accent.withValues(alpha: 0.25 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    // Outer ring rotating clockwise
    canvas.save();
    canvas.rotate(glow * 1.5);
    canvas.drawCircle(Offset.zero, pr + 2, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0,
    );
    canvas.restore();
    // Inner ring rotating counter-clockwise
    canvas.save();
    canvas.rotate(-glow * 2.0);
    canvas.drawCircle(Offset.zero, pr * 0.6, Paint()
      ..color = accent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
    );
    canvas.restore();
    // Inner hollow glow
    canvas.drawCircle(Offset.zero, pr * 0.3, Paint()
      ..color = accent.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // 5 orbital dots
    for (int i = 0; i < 5; i++) {
      final angle = glow * 3 + i * (pi * 2 / 5);
      final ox = cos(angle) * (pr + 5);
      final oy = sin(angle) * (pr + 5);
      canvas.drawCircle(Offset(ox, oy), 2.0 + sin(glow * 4 + i) * 0.8, Paint()
        ..color = accent.withValues(alpha: 0.8),
      );
    }
  }

  // Elite Phase 2: Diamond with inner rotating equilateral triangle
  void _drawEliteDiamond(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    final pulse = 1.0 + sin(glow * 3) * 0.12 * intensity;
    final r = pr * pulse;
    // Larger glow
    canvas.drawCircle(Offset.zero, r + 12, Paint()
      ..color = accent.withValues(alpha: 0.25 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    // Diamond shape
    final path = Path()
      ..moveTo(0, -r * 1.2)
      ..lineTo(r * 0.9, 0)
      ..lineTo(0, r * 1.2)
      ..lineTo(-r * 0.9, 0)
      ..close();
    // Gradient fill
    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        r * 1.2,
        [Colors.white, accent],
        [0.0, 1.0],
      ),
    );
    // Stroke outline
    canvas.drawPath(path, Paint()
      ..color = accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
    );
    // Inner rotating equilateral triangle
    canvas.save();
    canvas.rotate(glow * 2);
    final triR = r * 0.5;
    final triPath = Path();
    for (int i = 0; i < 3; i++) {
      final a = -pi / 2 + i * (pi * 2 / 3);
      final tx = cos(a) * triR;
      final ty = sin(a) * triR;
      if (i == 0) {
        triPath.moveTo(tx, ty);
      } else {
        triPath.lineTo(tx, ty);
      }
    }
    triPath.close();
    canvas.drawPath(triPath, Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  // Elite Phase 3: Slit with pulsing energy dots at endpoints
  void _drawEliteSlit(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    final flicker = 1.0 + sin(glow * 6) * 0.15 * intensity;
    final slitW = pr * 2.2 * flicker;
    final slitH = pr * 0.35;
    // Larger glow
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: slitW + 20, height: slitH + 16),
      Paint()
        ..color = accent.withValues(alpha: 0.25 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Core slit
    final slitRect =
        Rect.fromCenter(center: Offset.zero, width: slitW, height: slitH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slitRect, const Radius.circular(2)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-slitW / 2, 0),
          Offset(slitW / 2, 0),
          [accent.withValues(alpha: 0.3), Colors.white, accent.withValues(alpha: 0.3)],
          [0.0, 0.5, 1.0],
        ),
    );
    // Bright center dot
    canvas.drawCircle(Offset.zero, 2.0, Paint()
      ..color = Colors.white,
    );
    // Pulsing energy dots at each endpoint
    final dotPulse = 3.0 + sin(glow * 5) * 1.5;
    final dotAlpha = (0.6 + sin(glow * 4) * 0.3).clamp(0.0, 1.0);
    final dotPaint = Paint()
      ..color = accent.withValues(alpha: dotAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(-slitW / 2, 0), dotPulse, dotPaint);
    canvas.drawCircle(Offset(slitW / 2, 0), dotPulse, dotPaint);
  }

  // Elite Phase 4: Singularity with orbiting accretion disk
  void _drawEliteSingularity(
      Canvas canvas, double pr, double glow, Color accent, double intensity) {
    // Aura color must contrast with background (white bg in phase 5)
    final auraColor = fgColor;
    // Larger contrasting aura
    final auraR = pr + 14 + sin(glow * 2) * 4 * intensity;
    canvas.drawCircle(Offset.zero, auraR, Paint()
      ..color = auraColor.withValues(alpha: 0.4 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    // Contrasting ring
    canvas.drawCircle(Offset.zero, pr + 3, Paint()
      ..color = auraColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
    );
    // Pitch black core
    canvas.drawCircle(Offset.zero, pr, Paint()
      ..color = Colors.black,
    );
    // Subtle dark gradient
    canvas.drawCircle(Offset.zero, pr * 0.6, Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        pr * 0.6,
        [const Color(0xFF111111), Colors.black],
        [0.0, 1.0],
      ),
    );
    // Orbiting accretion disk (elliptical orbit)
    final diskR = pr + 8;
    for (int i = 0; i < 24; i++) {
      final angle = glow * 1.5 + i * (pi * 2 / 24);
      final ox = cos(angle) * diskR;
      final oy = sin(angle) * diskR * 0.4;
      final alpha = (0.5 + sin(angle) * 0.3).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(ox, oy), 1.2 + sin(glow * 3 + i) * 0.4, Paint()
        ..color = auraColor.withValues(alpha: alpha),
      );
    }
  }

  // ── Milestone Celebration Glow ──
  void _drawMilestoneGlow(Canvas canvas, Size size) {
    if (engine.milestoneGlowTimer <= 0) return;
    final progress = 1.0 - engine.milestoneGlowTimer / 0.6;
    final radius = progress * 150.0;
    final alpha = (1.0 - progress) * 0.4;
    canvas.drawCircle(Offset(engine.player.x, engine.player.y), radius, Paint()
      ..color = engine.milestoneGlowColor.withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  // ── Elite Unlock Flash ──
  void _drawEliteUnlockFlash(Canvas canvas, Size size) {
    if (engine.eliteUnlockTimer <= 0) return;
    final progress = 1.0 - engine.eliteUnlockTimer / 1.5;
    const gold = Color(0xFFFFD700);
    // Expanding golden ring
    final ringRadius = progress * 400.0;
    final ringAlpha = (1.0 - progress) * 0.6;
    final ringStroke = 6.0 - progress * 5.0;
    canvas.drawCircle(Offset(engine.player.x, engine.player.y), ringRadius, Paint()
      ..color = gold.withValues(alpha: ringAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringStroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Subtle screen-wide golden wash
    final washAlpha = (1.0 - progress) * 0.06;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()
      ..color = gold.withValues(alpha: washAlpha),
    );
  }

  // ── Near High Score Edge Glow (simplified — no gradient shader) ──
  void _drawNearHighScoreEdge(Canvas canvas, Size size) {
    if (!engine.isNearHighScore) return;
    final accent = visibleAccent;
    final pulse = (sin(engine.gameTime * 4) + 1) / 2;
    final baseAlpha = engine.isInRecordTerritory ? 0.25 : 0.12;
    final alpha = baseAlpha + pulse * (engine.isInRecordTerritory ? 0.15 : 0.08);
    final edgeWidth = engine.isInRecordTerritory ? 12.0 : 6.0;
    _fillPaint.color = accent.withValues(alpha: alpha * 0.6);
    // Left edge
    canvas.drawRect(
      Rect.fromLTWH(0, 0, edgeWidth, size.height),
      _fillPaint,
    );
    // Right edge
    canvas.drawRect(
      Rect.fromLTWH(size.width - edgeWidth, 0, edgeWidth, size.height),
      _fillPaint,
    );
  }

  // ── Shield Visual ──
  void _drawShield(Canvas canvas, Size size) {
    final px = engine.player.x;
    final py = engine.player.y;
    final pr = GameConstants.playerRadius;
    final glow = engine.player.glowPhase;

    // Pickup pulse: expand shield ring during pickup animation
    final pickupExtra = engine.shieldPickupTimer > 0
        ? (engine.shieldPickupTimer / 0.3) * 10.0
        : 0.0;
    final shieldR = pr + 14 + sin(glow * 2) * 2 + pickupExtra;

    // Shield glow circle
    canvas.drawCircle(Offset(px, py), shieldR, Paint()
      ..color = visibleAccent.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Shield stroke ring
    canvas.drawCircle(Offset(px, py), shieldR, Paint()
      ..color = visibleAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
    );
    // Shield icon
    if (engine.eliteUnlocked) {
      // 3 orbiting star shapes
      for (int i = 0; i < 3; i++) {
        final angle = glow * 2 + i * (pi * 2 / 3);
        final starX = px + cos(angle) * shieldR;
        final starY = py + sin(angle) * shieldR;
        final starPath = Path();
        for (int j = 0; j < 10; j++) {
          final a = -pi / 2 + j * (pi / 5);
          final r = (j % 2 == 0) ? 4.0 : 2.0;
          final sx = starX + cos(a) * r;
          final sy = starY + sin(a) * r;
          if (j == 0) {
            starPath.moveTo(sx, sy);
          } else {
            starPath.lineTo(sx, sy);
          }
        }
        starPath.close();
        canvas.drawPath(starPath, Paint()
          ..color = visibleAccent,
        );
      }
    } else {
      // Small diamond at top
      final iconY = py - shieldR + 2;
      final iconPath = Path()
        ..moveTo(px, iconY - 4)
        ..lineTo(px + 3, iconY)
        ..lineTo(px, iconY + 4)
        ..lineTo(px - 3, iconY)
        ..close();
      canvas.drawPath(iconPath, Paint()
        ..color = visibleAccent,
      );
    }
  }

  // ── Phase Transition Ring ──
  void _drawPhaseTransition(Canvas canvas, Size size) {
    if (engine.phaseRingTimer <= 0) return;
    final progress = (1.0 - engine.phaseRingTimer / 0.6).clamp(0.0, 1.0);

    // Expanding ring from player
    final radius = progress * 300.0;
    final ringAlpha = (1.0 - progress) * 0.5;
    final strokeWidth = 4.0 - progress * 3.0;
    canvas.drawCircle(Offset(engine.player.x, engine.player.y), radius, Paint()
      ..color = engine.phaseRingColor.withValues(alpha: ringAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Brief screen-wide color wash
    final washAlpha = (1.0 - progress) * 0.08;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()
      ..color = engine.phaseRingColor.withValues(alpha: washAlpha),
    );
  }

  // ── Shockwave Ring (death) ──
  void _drawShockwave(Canvas canvas, Size size) {
    if (engine.shockwaveTimer <= 0) return;
    final progress = (1.0 - engine.shockwaveTimer / 0.5).clamp(0.0, 1.0);

    final radius = progress * 200.0;
    final alpha = (1.0 - progress) * 0.8;
    final strokeWidth = 8.0 - progress * 7.0;
    _p.color = visibleAccent.withValues(alpha: alpha);
    _p.style = PaintingStyle.stroke;
    _p.strokeWidth = strokeWidth;
    _p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    _p.shader = null;
    canvas.drawCircle(
      Offset(engine.shockwaveX, engine.shockwaveY),
      radius,
      _p,
    );
  }

  // ── Magnet Lines ──
  void _drawMagnetLines(Canvas canvas, Size size, VisualTheme? theme) {
    // V3: Use theme renderer if theme is active
    if (theme != null) {
      ThemeRenderer.drawMagnetEffect(canvas, size, engine.player.x,
          engine.player.y, engine.isTouching, theme, engine.gameTime);
      return;
    }
    final px = engine.player.x;
    final py = engine.player.y;
    final phase = engine.magnetPhase;
    final wallX = engine.isTouching ? size.width : 0.0;

    for (int i = 0; i < 3; i++) {
      final offset = (phase + i * 2.1) % (pi * 2);
      final yOff = sin(offset) * 30;
      final alpha = (0.08 + sin(offset) * 0.04).clamp(0.0, 1.0);

      final path = Path()..moveTo(wallX, py + yOff);
      path.quadraticBezierTo(
          (wallX + px) / 2, py + yOff + cos(offset) * 15, px, py);

      canvas.drawPath(path, Paint()
        ..color = visibleAccent.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
      );
    }
  }

  // ── Trail Particles (enhanced with glow) ──
  void _drawTrailParticles(Canvas canvas, Size size, VisualTheme? theme) {
    // V3: Use theme renderer if theme is active
    if (theme != null) {
      ThemeRenderer.drawTrailParticles(canvas, engine.trailParticles, theme);
      return;
    }
    for (final p in engine.trailParticles) {
      if (p.isDead) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final r = p.radius * alpha;
      if (r <= 0) continue;
      // Outer "glow" — larger, dimmer, no GPU blur
      _glowPaint.color = p.color.withValues(alpha: alpha * 0.2);
      canvas.drawCircle(Offset(p.x, p.y), r * 2.0, _glowPaint);
      // Core
      _fillPaint.color = p.color.withValues(alpha: alpha * 0.7);
      canvas.drawCircle(Offset(p.x, p.y), r, _fillPaint);
    }
  }

  // ── Magnet Particles (glow without GPU blur) ──
  void _drawMagnetParticles(Canvas canvas, Size size) {
    for (final p in engine.magnetParticles) {
      if (p.isDead) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final r = p.radius * alpha;
      if (r <= 0) continue;
      _glowPaint.color = p.color.withValues(alpha: alpha * 0.15);
      canvas.drawCircle(Offset(p.x, p.y), r * 2.5, _glowPaint);
      _fillPaint.color = p.color.withValues(alpha: alpha * 0.7);
      canvas.drawCircle(Offset(p.x, p.y), r, _fillPaint);
    }
  }

  // ── Death Particles ──
  void _drawDeathParticles(Canvas canvas, Size size, VisualTheme? theme) {
    // V3: Use theme renderer if theme is active
    if (theme != null) {
      ThemeRenderer.drawDeathParticles(canvas, engine.particles, theme);
      return;
    }
    int rendered = 0;
    for (final p in engine.particles) {
      if (p.isDead) continue;
      if (rendered >= 100) break; // V5: cap classic death particles
      rendered++;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final r = p.radius * alpha;
      if (r <= 0) continue;
      // Outer glow (no GPU blur)
      _glowPaint.color = p.color.withValues(alpha: alpha * 0.2);
      canvas.drawCircle(Offset(p.x, p.y), r * 2.0, _glowPaint);
      // Core
      _fillPaint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(p.x, p.y), r, _fillPaint);
    }
  }

  // ── Death Flash Overlay ──
  void _drawDeathFlash(Canvas canvas, Size size) {
    if (engine.deathFlashTimer <= 0) return;
    final progress = (1.0 - engine.deathFlashTimer / 0.15).clamp(0.0, 1.0);
    final alpha = pow(1.0 - progress, 2) * 0.6;
    final flashColor = _inverted ? Colors.black : Colors.white;
    _p.color = flashColor.withValues(alpha: alpha.toDouble());
    _p.style = PaintingStyle.fill;
    _p.shader = null;
    _p.maskFilter = null;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _p,
    );
  }

  // ── V4: Troll Ghost Ball ──
  void _drawTrollBall(Canvas canvas, Size size) {
    final troll = engine.trollSystem.activeTroll;
    if (troll == null || !engine.trollSystem.shouldRenderTroll) return;

    final accent = visibleAccent;
    _p.style = PaintingStyle.fill;
    _p.shader = null;
    _p.maskFilter = null;

    // Shadow clones: draw 3 offset copies first
    if (troll.behaviour == TrollBehaviour.shadowClone) {
      const offsets = [
        Offset(-30, -20),
        Offset(30, -10),
        Offset(0, 30),
      ];
      _p.color = accent.withValues(alpha: troll.alpha * 0.2);
      for (final o in offsets) {
        canvas.drawCircle(
          Offset(troll.x + o.dx, troll.y + o.dy),
          troll.radius,
          _p,
        );
      }
    }

    // Main troll ball: translucent ghost circle with soft glow
    _p.color = accent.withValues(alpha: troll.alpha);
    canvas.drawCircle(Offset(troll.x, troll.y), troll.radius, _p);

    // Outer glow ring
    _p2.color = accent.withValues(alpha: troll.alpha * 0.15);
    _p2.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    _p2.style = PaintingStyle.fill;
    _p2.shader = null;
    canvas.drawCircle(
      Offset(troll.x, troll.y),
      troll.radius * 1.8,
      _p2,
    );
  }

  // ── V4: Fake Death Flash (troll) ──
  void _drawFakeDeathFlash(Canvas canvas, Size size) {
    if (engine.fakeDeathFlashTimer <= 0) return;
    // V5: Suppress fake flash during real death to avoid stacking
    if (engine.deathFlashTimer > 0) return;
    final progress = (1.0 - engine.fakeDeathFlashTimer / 0.3).clamp(0.0, 1.0);
    final alpha = pow(1.0 - progress, 3) * 0.5;
    final flashColor = _inverted ? Colors.black : Colors.white;
    _p.color = flashColor.withValues(alpha: alpha.toDouble());
    _p.style = PaintingStyle.fill;
    _p.shader = null;
    _p.maskFilter = null;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _p,
    );
  }

  // ── Vignette Overlay (cached — only rebuilt on inversion/size change) ──
  void _drawVignette(Canvas canvas, Size size) {
    if (_cachedVignettePaint == null ||
        _cachedVignetteInverted != _inverted ||
        _cachedVignetteSize != size) {
      _cachedVignetteInverted = _inverted;
      _cachedVignetteSize = size;
      final center = Offset(size.width / 2, size.height / 2);
      final radius = size.height * 0.7;
      final vignetteColor = _inverted ? Colors.white : Colors.black;
      _cachedVignettePaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            vignetteColor.withValues(alpha: 0.0),
            vignetteColor.withValues(alpha: 0.0),
            vignetteColor.withValues(alpha: 0.15),
          ],
          [0.0, 0.5, 1.0],
        );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _cachedVignettePaint!,
    );
  }

  // ── Countdown (cached TextPainter — only rebuilt when value changes) ──
  void _drawCountdown(Canvas canvas, Size size) {
    final color = visibleAccent.withValues(alpha: 0.6);
    if (_cachedCountdownValue != engine.countdownValue ||
        _cachedCountdownColor != color) {
      _cachedCountdownValue = engine.countdownValue;
      _cachedCountdownColor = color;
      _cachedCountdownPainter = TextPainter(
        text: TextSpan(
          text: '${engine.countdownValue}',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 120,
            fontWeight: FontWeight.w100,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    _cachedCountdownPainter!.paint(
      canvas,
      Offset((size.width - _cachedCountdownPainter!.width) / 2,
          (size.height - _cachedCountdownPainter!.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) =>
      oldDelegate.isDarkTheme != isDarkTheme;
}
