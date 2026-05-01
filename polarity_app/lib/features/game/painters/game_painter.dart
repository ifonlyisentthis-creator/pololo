import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:polarity/core/constants.dart';
import 'package:polarity/features/game/engine/game_engine.dart';
import 'package:polarity/features/game/visual/theme_renderer.dart';
import 'package:polarity/features/game/visual/visual_theme.dart';
import 'package:polarity/features/game/troll/troll_system.dart';

class GamePainter extends CustomPainter {
  static const List<Offset> _trollCloneOffsets = <Offset>[
    Offset(-30, -20),
    Offset(30, -10),
    Offset(0, 30),
  ];

  final GameEngine engine;
  final bool isDarkTheme;

  // Reusable paint objects — avoids per-draw allocation
  final Paint _fillPaint = Paint();
  final Paint _glowPaint = Paint();

  // V6: Pre-allocated reusable Paint objects to eliminate per-frame allocations
  final Paint _p = Paint();
  final Paint _p2 = Paint();
  final Paint _shaderP = Paint();
  final Paint _linePaint = Paint();
  final Path _linePath = Path();
  final Path _shapePath = Path();
  final Path _shapePath2 = Path();
  final List<Color> _obstacleGradientColors = [Colors.black, Colors.black];
  final List<Color> _magnetGradientColors = [Colors.white, Colors.white];
  final List<Color> _gradient2 = [Colors.white, Colors.white];
  final List<Color> _gradient3 = [Colors.white, Colors.white, Colors.white];
  final Paint _alphaLayerPaint = Paint();
  final Paint _fxStrokePaint = Paint();
  final Paint _fxFillPaint = Paint();

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

  GamePainter({required this.engine, required this.isDarkTheme, super.repaint});

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
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _p);

    // Pre-resolve effective theme once per frame (cached, no allocation)
    final theme = engine.effectiveTheme;

    // Screen shake wrapping — everything inside shakes
    canvas.save();
    if (engine.screenShakeIntensity > 0.5) {
      canvas.translate(engine.screenShakeX, engine.screenShakeY);
    }

    _drawAmbientParticles(canvas, size, theme);
    _drawObstacles(canvas, size, theme);
    _drawTrailParticles(canvas, size, theme);
    _drawMagnetAura(canvas, size);

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
    if (theme != null && engine.themeTransitionTimer > 0) {
      ThemeRenderer.drawThemeTransition(
        canvas,
        size,
        engine.player.x,
        engine.player.y,
        engine.themeTransitionTimer,
        theme,
      );
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
      ThemeRenderer.drawAmbientParticles(
        canvas,
        engine.ambientParticles,
        theme,
      );
      return;
    }
    final particles = engine.ambientParticles;
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
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
      ThemeRenderer.drawObstacles(
        canvas,
        size,
        engine.obstacles,
        theme,
        fgColor,
        engine.gameTime,
      );
      return;
    }
    // Hoist gradient colors outside loop (avoids per-obstacle List allocation)
    _obstacleGradientColors[0] = fgColor;
    _obstacleGradientColors[1] = fgColor.withValues(alpha: 0.6);
    const obstacleStops = [0.0, 1.0];
    final obstacles = engine.obstacles;
    for (int i = 0; i < obstacles.length; i++) {
      final obs = obstacles[i];
      if (obs.worldY < -50 || obs.worldY > size.height + 50) continue;

      final halfT = obs.thickness / 2;
      Rect rect;
      RRect rrect;
      if (obs.fromLeft) {
        rect = Rect.fromLTWH(0, obs.worldY - halfT, obs.width, obs.thickness);
        // Round only the exposed tip end
        rrect = RRect.fromRectAndCorners(
          rect,
          topRight: Radius.circular(halfT),
          bottomRight: Radius.circular(halfT),
        );
      } else {
        rect = Rect.fromLTWH(
          size.width - obs.width,
          obs.worldY - halfT,
          obs.width,
          obs.thickness,
        );
        rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(halfT),
          bottomLeft: Radius.circular(halfT),
        );
      }

      // Subtle gradient: solid fgColor fading slightly toward the wall anchor
      final gradStart = obs.fromLeft ? rect.right : rect.left;
      final gradEnd = obs.fromLeft ? rect.left : rect.right;
      _shaderP.shader = ui.Gradient.linear(
        Offset(gradStart, obs.worldY),
        Offset(gradEnd, obs.worldY),
        _obstacleGradientColors,
        obstacleStops,
      );
      _shaderP.maskFilter = null;
      _shaderP.style = PaintingStyle.fill;
      canvas.drawRRect(rrect, _shaderP);
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

    // Invincibility smooth alpha pulse (always visible, premium phasing)
    double invincAlpha = 1.0;
    if (engine.isInvincible) {
      invincAlpha = 0.35 + 0.65 * ((sin(glow * 8) + 1) / 2);
    }

    // V3: Use theme renderer if theme is active
    if (theme != null) {
      if (invincAlpha < 1.0) {
        _alphaLayerPaint.color = Color.fromRGBO(0, 0, 0, invincAlpha);
        canvas.saveLayer(null, _alphaLayerPaint);
      }
      ThemeRenderer.drawBall(
        canvas,
        px,
        py,
        pr,
        theme,
        glow,
        intensity,
        stretch,
      );
      if (invincAlpha < 1.0) canvas.restore();
      return;
    }

    if (invincAlpha < 1.0) {
      _alphaLayerPaint.color = Color.fromRGBO(0, 0, 0, invincAlpha);
      canvas.saveLayer(null, _alphaLayerPaint);
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

    if (invincAlpha < 1.0) canvas.restore();
  }

  // Phase 1: Glowing Sphere
  void _drawPhase1Sphere(
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    final glowR = pr + 8 + sin(glow) * 3 * intensity;
    // Glow aura
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.25 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..shader = null;
    canvas.drawCircle(Offset.zero, glowR, _fxFillPaint);

    // Gradient sphere
    _gradient3[0] = Colors.white;
    _gradient3[1] = accent;
    _gradient3[2] = accent.withValues(alpha: 0.5);
    _shaderP
      ..shader = ui.Gradient.radial(
        Offset(-pr * 0.3, -pr * 0.3),
        pr * 1.2,
        _gradient3,
        const [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    canvas.drawCircle(Offset.zero, pr, _shaderP);

    // Specular highlight
    _fxFillPaint
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset(-pr * 0.25, -pr * 0.25), pr * 0.35, _fxFillPaint);
  }

  // Phase 2: Hollow Ring with orbital dust
  void _drawPhase2Ring(
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    // Outer glow
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.2 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr + 6, _fxFillPaint);

    // Ring stroke
    _fxStrokePaint
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr, _fxStrokePaint);

    // Inner hollow
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr * 0.4, _fxFillPaint);

    // Orbital dust particles (3 orbiting dots)
    for (int i = 0; i < 3; i++) {
      final angle = glow * 2.5 + i * (pi * 2 / 3);
      final ox = cos(angle) * (pr + 4);
      final oy = sin(angle) * (pr + 4);
      _fxFillPaint
        ..color = accent.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill
        ..strokeWidth = 0
        ..maskFilter = null
        ..shader = null;
      canvas.drawCircle(
        Offset(ox, oy),
        1.5 + sin(glow * 3 + i) * 0.5,
        _fxFillPaint,
      );
    }
  }

  // Phase 3: Pulsating Diamond
  void _drawPhase3Diamond(
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    final pulse = 1.0 + sin(glow * 3) * 0.12 * intensity;
    final r = pr * pulse;
    // Glow
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.2 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..shader = null;
    canvas.drawCircle(Offset.zero, r + 8, _fxFillPaint);

    // Diamond shape
    final path = _shapePath
      ..reset()
      ..moveTo(0, -r * 1.2)
      ..lineTo(r * 0.9, 0)
      ..lineTo(0, r * 1.2)
      ..lineTo(-r * 0.9, 0)
      ..close();

    // Gradient fill
    _gradient2[0] = Colors.white;
    _gradient2[1] = accent;
    _shaderP
      ..shader = ui.Gradient.radial(Offset.zero, r * 1.2, _gradient2, const [
        0.0,
        1.0,
      ])
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    canvas.drawPath(path, _shaderP);

    // Stroke outline
    _fxStrokePaint
      ..color = accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = null
      ..shader = null;
    canvas.drawPath(path, _fxStrokePaint);
  }

  // Phase 4: Searing Horizontal Slit
  void _drawPhase4Slit(
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    final flicker = 1.0 + sin(glow * 6) * 0.15 * intensity;
    final slitW = pr * 2.2 * flicker;
    final slitH = pr * 0.35;
    // Wide glow
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.2 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..shader = null;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: slitW + 16,
        height: slitH + 12,
      ),
      _fxFillPaint,
    );

    // Core slit
    final slitRect = Rect.fromCenter(
      center: Offset.zero,
      width: slitW,
      height: slitH,
    );
    final slitEdge = accent.withValues(alpha: 0.3);
    _gradient3[0] = slitEdge;
    _gradient3[1] = Colors.white;
    _gradient3[2] = slitEdge;
    _shaderP
      ..shader = ui.Gradient.linear(
        Offset(-slitW / 2, 0),
        Offset(slitW / 2, 0),
        _gradient3,
        const [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    canvas.drawRRect(
      RRect.fromRectAndRadius(slitRect, const Radius.circular(2)),
      _shaderP,
    );

    // Bright center dot
    _fxFillPaint
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset.zero, 2.0, _fxFillPaint);
  }

  // Phase 5: Pitch-black Singularity with contrasting aura
  void _drawPhase5Singularity(
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    // Aura color must contrast with background (white bg in phase 5)
    final auraColor = fgColor;
    final auraR = pr + 10 + sin(glow * 2) * 3 * intensity;
    // Aura
    _fxFillPaint
      ..color = auraColor.withValues(alpha: 0.35 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..shader = null;
    canvas.drawCircle(Offset.zero, auraR, _fxFillPaint);

    // Contrasting ring
    _fxStrokePaint
      ..color = auraColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr + 3, _fxStrokePaint);

    // Pitch black core
    _fxFillPaint
      ..color = Colors.black
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr, _fxFillPaint);

    // Subtle dark gradient
    _gradient2[0] = const Color(0xFF111111);
    _gradient2[1] = Colors.black;
    _shaderP
      ..shader = ui.Gradient.radial(Offset.zero, pr * 0.6, _gradient2, const [
        0.0,
        1.0,
      ])
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    canvas.drawCircle(Offset.zero, pr * 0.6, _shaderP);
  }

  // ── Elite Player Variants ──
  void _drawElitePlayer(
    Canvas canvas,
    double pr,
    int phase,
    double glow,
    Color accent,
    double intensity,
  ) {
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
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    // Larger glow aura
    final glowR = pr + 12 + sin(glow) * 4 * intensity;
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.3 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..shader = null;
    canvas.drawCircle(Offset.zero, glowR, _fxFillPaint);

    // Core sphere
    _gradient3[0] = Colors.white;
    _gradient3[1] = accent;
    _gradient3[2] = accent.withValues(alpha: 0.5);
    _shaderP
      ..shader = ui.Gradient.radial(
        Offset(-pr * 0.3, -pr * 0.3),
        pr * 1.2,
        _gradient3,
        const [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    canvas.drawCircle(Offset.zero, pr, _shaderP);

    // Specular highlight
    _fxFillPaint
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset(-pr * 0.25, -pr * 0.25), pr * 0.35, _fxFillPaint);

    // Rotating prismatic/rainbow ring (HSV hue cycling)
    final ringR = pr + 6;
    for (int i = 0; i < 36; i++) {
      final angle = glow * 2 + i * (pi * 2 / 36);
      final hue = ((glow * 60 + i * 10) % 360).toDouble();
      final ox = cos(angle) * ringR;
      final oy = sin(angle) * ringR;
      _fxFillPaint
        ..color = HSVColor.fromAHSV(0.8, hue, 1.0, 1.0).toColor()
        ..style = PaintingStyle.fill
        ..strokeWidth = 0
        ..maskFilter = null
        ..shader = null;
      canvas.drawCircle(Offset(ox, oy), 1.5, _fxFillPaint);
    }
  }

  // Elite Phase 1: Double nested rings + 5 orbital dots
  void _drawEliteRing(
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    // Larger glow aura
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.25 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr + 10, _fxFillPaint);

    // Outer ring rotating clockwise
    canvas.save();
    canvas.rotate(glow * 1.5);
    _fxStrokePaint
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr + 2, _fxStrokePaint);
    canvas.restore();

    // Inner ring rotating counter-clockwise
    canvas.save();
    canvas.rotate(-glow * 2.0);
    _fxStrokePaint
      ..color = accent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr * 0.6, _fxStrokePaint);
    canvas.restore();

    // Inner hollow glow
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr * 0.3, _fxFillPaint);

    // 5 orbital dots
    for (int i = 0; i < 5; i++) {
      final angle = glow * 3 + i * (pi * 2 / 5);
      final ox = cos(angle) * (pr + 5);
      final oy = sin(angle) * (pr + 5);
      _fxFillPaint
        ..color = accent.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill
        ..strokeWidth = 0
        ..maskFilter = null
        ..shader = null;
      canvas.drawCircle(
        Offset(ox, oy),
        2.0 + sin(glow * 4 + i) * 0.8,
        _fxFillPaint,
      );
    }
  }

  // Elite Phase 2: Diamond with inner rotating equilateral triangle
  void _drawEliteDiamond(
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    final pulse = 1.0 + sin(glow * 3) * 0.12 * intensity;
    final r = pr * pulse;
    // Larger glow
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.25 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..shader = null;
    canvas.drawCircle(Offset.zero, r + 12, _fxFillPaint);

    // Diamond shape
    final path = _shapePath
      ..reset()
      ..moveTo(0, -r * 1.2)
      ..lineTo(r * 0.9, 0)
      ..lineTo(0, r * 1.2)
      ..lineTo(-r * 0.9, 0)
      ..close();

    // Gradient fill
    _gradient2[0] = Colors.white;
    _gradient2[1] = accent;
    _shaderP
      ..shader = ui.Gradient.radial(Offset.zero, r * 1.2, _gradient2, const [
        0.0,
        1.0,
      ])
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    canvas.drawPath(path, _shaderP);

    // Stroke outline
    _fxStrokePaint
      ..color = accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = null
      ..shader = null;
    canvas.drawPath(path, _fxStrokePaint);

    // Inner rotating equilateral triangle
    canvas.save();
    canvas.rotate(glow * 2);
    final triR = r * 0.5;
    final triPath = _shapePath2..reset();
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
    _fxStrokePaint
      ..color = accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = null
      ..shader = null;
    canvas.drawPath(triPath, _fxStrokePaint);
    canvas.restore();
  }

  // Elite Phase 3: Slit with pulsing energy dots at endpoints
  void _drawEliteSlit(
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    final flicker = 1.0 + sin(glow * 6) * 0.15 * intensity;
    final slitW = pr * 2.2 * flicker;
    final slitH = pr * 0.35;
    // Larger glow
    _fxFillPaint
      ..color = accent.withValues(alpha: 0.25 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..shader = null;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: slitW + 20,
        height: slitH + 16,
      ),
      _fxFillPaint,
    );

    // Core slit
    final slitRect = Rect.fromCenter(
      center: Offset.zero,
      width: slitW,
      height: slitH,
    );
    final slitEdge = accent.withValues(alpha: 0.3);
    _gradient3[0] = slitEdge;
    _gradient3[1] = Colors.white;
    _gradient3[2] = slitEdge;
    _shaderP
      ..shader = ui.Gradient.linear(
        Offset(-slitW / 2, 0),
        Offset(slitW / 2, 0),
        _gradient3,
        const [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    canvas.drawRRect(
      RRect.fromRectAndRadius(slitRect, const Radius.circular(2)),
      _shaderP,
    );

    // Bright center dot
    _fxFillPaint
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset.zero, 2.0, _fxFillPaint);

    // Pulsing energy dots at each endpoint
    final dotPulse = 3.0 + sin(glow * 5) * 1.5;
    final dotAlpha = (0.6 + sin(glow * 4) * 0.3).clamp(0.0, 1.0);
    _fxFillPaint
      ..color = accent.withValues(alpha: dotAlpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = null;
    canvas.drawCircle(Offset(-slitW / 2, 0), dotPulse, _fxFillPaint);
    canvas.drawCircle(Offset(slitW / 2, 0), dotPulse, _fxFillPaint);
  }

  // Elite Phase 4: Singularity with orbiting accretion disk
  void _drawEliteSingularity(
    Canvas canvas,
    double pr,
    double glow,
    Color accent,
    double intensity,
  ) {
    // Aura color must contrast with background (white bg in phase 5)
    final auraColor = fgColor;
    // Larger contrasting aura
    final auraR = pr + 14 + sin(glow * 2) * 4 * intensity;
    _fxFillPaint
      ..color = auraColor.withValues(alpha: 0.4 * intensity)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22)
      ..shader = null;
    canvas.drawCircle(Offset.zero, auraR, _fxFillPaint);

    // Contrasting ring
    _fxStrokePaint
      ..color = auraColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr + 3, _fxStrokePaint);

    // Pitch black core
    _fxFillPaint
      ..color = Colors.black
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset.zero, pr, _fxFillPaint);

    // Subtle dark gradient
    _gradient2[0] = const Color(0xFF111111);
    _gradient2[1] = Colors.black;
    _shaderP
      ..shader = ui.Gradient.radial(Offset.zero, pr * 0.6, _gradient2, const [
        0.0,
        1.0,
      ])
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    canvas.drawCircle(Offset.zero, pr * 0.6, _shaderP);

    // Orbiting accretion disk (elliptical orbit)
    final diskR = pr + 8;
    for (int i = 0; i < 24; i++) {
      final angle = glow * 1.5 + i * (pi * 2 / 24);
      final ox = cos(angle) * diskR;
      final oy = sin(angle) * diskR * 0.4;
      final alpha = (0.5 + sin(angle) * 0.3).clamp(0.0, 1.0);
      _fxFillPaint
        ..color = auraColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill
        ..strokeWidth = 0
        ..maskFilter = null
        ..shader = null;
      canvas.drawCircle(
        Offset(ox, oy),
        1.2 + sin(glow * 3 + i) * 0.4,
        _fxFillPaint,
      );
    }
  }

  // ── Milestone Celebration Glow ──
  void _drawMilestoneGlow(Canvas canvas, Size size) {
    if (engine.milestoneGlowTimer <= 0) return;
    final progress = 1.0 - engine.milestoneGlowTimer / 0.6;
    final radius = progress * 150.0;
    final alpha = (1.0 - progress) * 0.4;
    _fxFillPaint
      ..color = engine.milestoneGlowColor.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..shader = null;
    canvas.drawCircle(
      Offset(engine.player.x, engine.player.y),
      radius,
      _fxFillPaint,
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
    _fxStrokePaint
      ..color = gold.withValues(alpha: ringAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringStroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..shader = null;
    canvas.drawCircle(
      Offset(engine.player.x, engine.player.y),
      ringRadius,
      _fxStrokePaint,
    );
    // Subtle screen-wide golden wash
    final washAlpha = (1.0 - progress) * 0.06;
    _fxFillPaint
      ..color = gold.withValues(alpha: washAlpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = null
      ..shader = null;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _fxFillPaint);
  }

  // ── Near High Score Edge Glow (simplified — no gradient shader) ──
  void _drawNearHighScoreEdge(Canvas canvas, Size size) {
    // Disabled to keep side walls visually clean during progression.
    return;
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
    _fxFillPaint
      ..color = visibleAccent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..shader = null;
    canvas.drawCircle(Offset(px, py), shieldR, _fxFillPaint);
    // Shield stroke ring
    _fxStrokePaint
      ..color = visibleAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = null
      ..shader = null;
    canvas.drawCircle(Offset(px, py), shieldR, _fxStrokePaint);
    // Shield icon
    if (engine.eliteUnlocked) {
      // 3 orbiting star shapes
      for (int i = 0; i < 3; i++) {
        final angle = glow * 2 + i * (pi * 2 / 3);
        final starX = px + cos(angle) * shieldR;
        final starY = py + sin(angle) * shieldR;
        final starPath = _shapePath..reset();
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
        _fxFillPaint
          ..color = visibleAccent
          ..style = PaintingStyle.fill
          ..strokeWidth = 0
          ..maskFilter = null
          ..shader = null;
        canvas.drawPath(starPath, _fxFillPaint);
      }
    } else {
      // Small diamond at top
      final iconY = py - shieldR + 2;
      final iconPath = _shapePath2
        ..reset()
        ..moveTo(px, iconY - 4)
        ..lineTo(px + 3, iconY)
        ..lineTo(px, iconY + 4)
        ..lineTo(px - 3, iconY)
        ..close();
      _fxFillPaint
        ..color = visibleAccent
        ..style = PaintingStyle.fill
        ..strokeWidth = 0
        ..maskFilter = null
        ..shader = null;
      canvas.drawPath(iconPath, _fxFillPaint);
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
    _fxStrokePaint
      ..color = engine.phaseRingColor.withValues(alpha: ringAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = null;
    canvas.drawCircle(
      Offset(engine.player.x, engine.player.y),
      radius,
      _fxStrokePaint,
    );

    // Brief screen-wide color wash
    final washAlpha = (1.0 - progress) * 0.08;
    _fxFillPaint
      ..color = engine.phaseRingColor.withValues(alpha: washAlpha)
      ..style = PaintingStyle.fill
      ..strokeWidth = 0
      ..maskFilter = null
      ..shader = null;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _fxFillPaint);
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
    canvas.drawCircle(Offset(engine.shockwaveX, engine.shockwaveY), radius, _p);
  }

  // ── Magnet Lines ──
  void _drawMagnetLines(Canvas canvas, Size size, VisualTheme? theme) {
    // V3: Use theme renderer if theme is active
    if (theme != null) {
      ThemeRenderer.drawMagnetEffect(
        canvas,
        size,
        engine.player.x,
        engine.player.y,
        engine.isTouching,
        theme,
        engine.gameTime,
      );
      return;
    }
    final px = engine.player.x;
    final py = engine.player.y;
    final phase = engine.magnetPhase;

    // Position-based: nearest wall
    final half = size.width / 2;
    final nearLeft = px < half;
    final wallX = nearLeft ? 0.0 : size.width;
    final distToWall = nearLeft ? px : size.width - px;
    final proximity = (1.0 - distToWall / half).clamp(0.0, 1.0);
    if (proximity < 0.15) return;

    for (int i = 0; i < 2; i++) {
      final p = phase + i * 1.8;
      final ySpread = (i == 0 ? 1.0 : -1.0) * 14.0;
      final yOff = sin(p) * (25.0 + sin(p * 0.7) * 10.0);
      final midX = (wallX + px) / 2;
      final midY = py + yOff + ySpread;
      final baseAlpha =
          (0.14 + sin(phase * 3.0 + i * 1.5).abs() * 0.10) * proximity;

      _linePath
        ..reset()
        ..moveTo(wallX, py + ySpread)
        ..quadraticBezierTo(midX, midY, px, py);

      // Glow
      _linePaint
        ..color = visibleAccent.withValues(alpha: 0.08 * proximity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
        ..shader = null;
      canvas.drawPath(_linePath, _linePaint);

      // Core with gradient
      _magnetGradientColors[0] = visibleAccent.withValues(alpha: 0.0);
      _magnetGradientColors[1] = visibleAccent.withValues(alpha: baseAlpha);
      _linePaint
        ..shader = ui.Gradient.linear(
          Offset(wallX, py),
          Offset(px, py),
          _magnetGradientColors,
          [0.0, 1.0],
        )
        ..strokeWidth = 2.0
        ..maskFilter = null;
      canvas.drawPath(_linePath, _linePaint);
      _linePaint.shader = null;
    }
  }

  // ── Trail Particles (enhanced with glow) ──
  void _drawTrailParticles(Canvas canvas, Size size, VisualTheme? theme) {
    // V3: Use theme renderer if theme is active
    if (theme != null) {
      ThemeRenderer.drawTrailParticles(
        canvas,
        size,
        engine.trailParticles,
        theme,
      );
      return;
    }

    const margin = 40.0;
    final minX = -margin;
    final maxX = size.width + margin;
    final minY = -margin;
    final maxY = size.height + margin;

    final particles = engine.trailParticles;
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      if (p.isDead) continue;
      if (p.x < minX || p.x > maxX || p.y < minY || p.y > maxY) continue;
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

  // ── Magnet Aura (wall-anchored suction glow + inward-drifting arcs) ──
  void _drawMagnetAura(Canvas canvas, Size size) {
    // When theme is active, ThemeRenderer.drawMagnetEffect handles this
    if (engine.effectiveTheme != null) return;

    final px = engine.player.x;
    final py = engine.player.y;
    final half = size.width / 2;
    final nearLeft = px < half;
    final wallX = nearLeft ? 0.0 : size.width;
    final distToWall = nearLeft ? px : size.width - px;
    final proximity = (1.0 - distToWall / half).clamp(0.0, 1.0);
    if (proximity < 0.15) return;

    final phase = engine.magnetPhase;

    // Concentric pull arcs — only on left wall (right wall has tendrils only)
    if (nearLeft) {
      _linePaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = null
        ..shader = null;
      const pi = 3.14159265;
      for (int i = 0; i < 4; i++) {
        final cycle = (phase * 0.8 + i * 0.785) % pi;
        final arcRadius = 60.0 * (1.0 - cycle / pi);
        final arcAlpha = sin(cycle) * 0.25 * proximity;
        if (arcAlpha < 0.01 || arcRadius < 2.0) continue;
        _linePaint.color = visibleAccent.withValues(alpha: arcAlpha);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(wallX, py), radius: arcRadius),
          -pi / 2,
          -pi,
          false,
          _linePaint,
        );
      }
    }
  }

  // ── Death Particles ──
  void _drawDeathParticles(Canvas canvas, Size size, VisualTheme? theme) {
    // V3: Use theme renderer if theme is active
    if (theme != null) {
      ThemeRenderer.drawDeathParticles(canvas, size, engine.particles, theme);
      return;
    }

    const margin = 56.0;
    final minX = -margin;
    final maxX = size.width + margin;
    final minY = -margin;
    final maxY = size.height + margin;

    int rendered = 0;
    final particles = engine.particles;
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      if (p.isDead) continue;
      if (rendered >= 100) break; // V5: cap classic death particles
      rendered++;
      if (p.x < minX || p.x > maxX || p.y < minY || p.y > maxY) continue;
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
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _p);
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
      _p.color = accent.withValues(alpha: troll.alpha * 0.2);
      for (int i = 0; i < _trollCloneOffsets.length; i++) {
        final o = _trollCloneOffsets[i];
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
    canvas.drawCircle(Offset(troll.x, troll.y), troll.radius * 1.8, _p2);
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
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _p);
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
      Offset(
        (size.width - _cachedCountdownPainter!.width) / 2,
        (size.height - _cachedCountdownPainter!.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) =>
      oldDelegate.isDarkTheme != isDarkTheme;
}
