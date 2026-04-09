import 'dart:math';
import 'package:flutter/material.dart';
import 'package:polarity/features/game/models/particle.dart';
import 'package:polarity/features/game/visual/visual_theme.dart';
import 'package:polarity/features/game/visual/ball_painters.dart';
import 'package:polarity/features/game/visual/trail_painters.dart';

/// Master dispatch that GamePainter calls.
/// Delegates to the specialised trail, explosion, and ball painters so that
/// the game renderer only needs a single entry-point per visual element.
class ThemeRenderer {
  ThemeRenderer._();

  // ── Ball ─────────────────────────────────────────────────────────────────

  /// Draw the player ball with theme visuals.
  /// [theme] should already be the effective theme (inverted if Phase 5).
  static void drawBall(Canvas canvas, double px, double py, double pr,
      VisualTheme theme, double glowPhase, double intensity, double stretch) {
    final colors = theme.ballColors;

    canvas.save();
    canvas.translate(px, py);
    canvas.scale(stretch, 1.0 / stretch);

    // Apply ball effect transform.
    _applyBallEffect(canvas, theme, glowPhase);

    // Draw glow aura.
    final glowR = pr + theme.ballGlowRadius + sin(glowPhase) * 3 * intensity;
    canvas.drawCircle(
      Offset.zero,
      glowR,
      Paint()
        ..color = colors.first
            .withValues(alpha: theme.ballGlowIntensity * intensity)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, theme.ballGlowRadius),
    );

    // Draw shape via specialised ball painter.
    BallPainters.draw(theme.ballShape, canvas, pr, colors, glowPhase, intensity);

    canvas.restore();
  }

  static void _applyBallEffect(
      Canvas canvas, VisualTheme theme, double glowPhase) {
    final speed = theme.ballEffectSpeed;
    switch (theme.ballEffect) {
      case BallEffect.pulse:
        final s = 1.0 + sin(glowPhase * 3 * speed) * 0.12;
        canvas.scale(s, s);
      case BallEffect.spin:
        canvas.rotate(glowPhase * 2 * speed);
      case BallEffect.flicker:
        // Alpha handled elsewhere; slight scale flicker here.
        final s = 1.0 + sin(glowPhase * 6 * speed) * 0.05;
        canvas.scale(s, s);
      case BallEffect.breathe:
        final s = 1.0 + sin(glowPhase * 1.5 * speed) * 0.08;
        canvas.scale(s, s);
      case BallEffect.prismatic:
        // Colour shifting handled in colours; gentle spin.
        canvas.rotate(glowPhase * 0.3 * speed);
      case BallEffect.orbit:
        // Orbit dots drawn after shape — no transform needed.
        break;
      case BallEffect.phase:
        // Blink in/out — handled in alpha.
        break;
      case BallEffect.morph:
        final sx = 1.0 + sin(glowPhase * 2 * speed) * 0.06;
        final sy = 1.0 + cos(glowPhase * 2 * speed) * 0.06;
        canvas.scale(sx, sy);
      case BallEffect.corona:
        // Corona spikes drawn after shape.
        break;
      case BallEffect.ripple:
        // Concentric rings drawn after shape.
        break;
      case BallEffect.none:
        break;
    }
  }

  // ── Trail particles ──────────────────────────────────────────────────────

  /// Draw trail particles with theme style.
  /// [theme] should already be the effective theme (inverted if Phase 5).
  static void drawTrailParticles(Canvas canvas, List<Particle> trailParticles,
      VisualTheme theme) {
    int rendered = 0;
    for (final p in trailParticles) {
      if (p.isDead) continue;
      if (rendered >= 150) break;
      rendered++;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      TrailPainters.draw(theme.trailStyle, canvas, p, alpha);
    }
  }

  // ── Death particles ──────────────────────────────────────────────────────

  /// Draw death explosion particles with theme style.
  /// [theme] should already be the effective theme (inverted if Phase 5).
  static void drawDeathParticles(Canvas canvas, List<Particle> particles,
      VisualTheme theme) {
    // Cap rendered particles for performance
    int rendered = 0;
    for (final p in particles) {
      if (p.isDead) continue;
      if (rendered >= 60) break;
      rendered++;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      TrailPainters.draw(theme.trailStyle, canvas, p, alpha);
    }
  }

  // ── Obstacles ────────────────────────────────────────────────────────────

  /// Draw obstacles with theme style.
  /// [theme] should already be the effective theme (inverted if Phase 5).
  static void drawObstacles(Canvas canvas, Size size, List<dynamic> obstacles,
      VisualTheme theme, Color fgColor, double gameTime) {
    final colors = theme.obstacleColors;
    final primary =
        colors.isNotEmpty ? colors.first : fgColor;
    final secondary =
        colors.length > 1 ? colors[1] : primary.withValues(alpha: 0.6);

    // Ensure obstacles are visible on dark backgrounds
    Color effectivePrimary = primary;
    Color effectiveSecondary = secondary;
    if (primary.computeLuminance() < 0.05 && secondary.computeLuminance() < 0.05) {
      // Both colors nearly invisible — boost to minimum visibility
      effectivePrimary = Color.lerp(primary, const Color(0xFF404040), 0.6)!;
      effectiveSecondary = Color.lerp(secondary, const Color(0xFF303030), 0.6)!;
    }

    for (final obs in obstacles) {
      final double worldY = obs.worldY;
      if (worldY < -50 || worldY > size.height + 50) continue;

      final double obsWidth = obs.width;
      final bool fromLeft = obs.fromLeft;
      final double thickness = obs.thickness;
      final halfT = thickness / 2;

      final left = fromLeft ? 0.0 : size.width - obsWidth;
      final top = worldY - halfT;
      final rect = Rect.fromLTWH(left, top, obsWidth, thickness);

      // Base obstacle body with rounded end.
      final rrect = fromLeft
          ? RRect.fromRectAndCorners(rect,
              topRight: Radius.circular(halfT),
              bottomRight: Radius.circular(halfT))
          : RRect.fromRectAndCorners(rect,
              topLeft: Radius.circular(halfT),
              bottomLeft: Radius.circular(halfT));

      final tipX = fromLeft ? obsWidth : size.width - obsWidth;
      final gradStart = fromLeft
          ? Offset(obsWidth, worldY)
          : Offset(size.width - obsWidth, worldY);
      final gradEnd =
          fromLeft ? Offset(0, worldY) : Offset(size.width, worldY);

      final gradient = LinearGradient(colors: [effectivePrimary, effectiveSecondary]);
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = gradient.createShader(Rect.fromPoints(gradStart, gradEnd)),
      );

      // Tip glow based on obstacle style.
      _drawObstacleTip(canvas, theme.obstacleStyle, tipX, worldY,
          halfT, primary, theme.obstacleGlowIntensity, gameTime);
    }
  }

  static void _drawObstacleTip(Canvas canvas, ObstacleStyle style,
      double tipX, double tipY, double halfT, Color color, double intensity,
      double gameTime) {
    final glowAlpha =
        (0.15 + sin(gameTime * 4 + tipY * 0.02).abs() * 0.3) * intensity;
    final effectiveGlowAlpha = glowAlpha.clamp(0.04, 1.0);
    final glowR = halfT * (0.5 + sin(gameTime * 3).abs() * 0.15);
    final blurSigma = 6 + sin(gameTime * 3) * 6;

    // Helper: GPU-blurred glow at obstacle tip
    void tipGlow(double cx, double cy, double r, double a) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withValues(alpha: a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma),
      );
    }

    switch (style) {
      case ObstacleStyle.solid:
      case ObstacleStyle.glow:
        tipGlow(tipX, tipY, glowR, effectiveGlowAlpha);
      case ObstacleStyle.pulse:
        final pulseScale = 1.0 + sin(gameTime * 5) * 0.3;
        tipGlow(tipX, tipY, glowR * pulseScale, effectiveGlowAlpha * 0.8);
      case ObstacleStyle.flame:
        for (int i = 0; i < 3; i++) {
          final offset = sin(gameTime * 8 + i * 1.5) * 3;
          final h = halfT * (1.0 + sin(gameTime * 6 + i) * 0.3);
          tipGlow(tipX + offset, tipY - h * 0.5 * i, 3.0,
              effectiveGlowAlpha * (1.0 - i * 0.3));
        }
      case ObstacleStyle.frost:
        tipGlow(tipX, tipY, glowR * 0.8, effectiveGlowAlpha);
      case ObstacleStyle.electric:
        final sparkAlpha = (sin(gameTime * 12 + tipY) > 0.5)
            ? effectiveGlowAlpha * 1.5
            : effectiveGlowAlpha * 0.3;
        tipGlow(tipX, tipY, glowR * 0.6, sparkAlpha.clamp(0.0, 1.0));
      case ObstacleStyle.stripe:
        tipGlow(tipX, tipY, glowR, effectiveGlowAlpha * 0.6);
      case ObstacleStyle.cracked:
        tipGlow(tipX, tipY, glowR * 1.2, effectiveGlowAlpha * 0.5);
      case ObstacleStyle.shadow:
        tipGlow(tipX, tipY, glowR * 1.5, effectiveGlowAlpha * 0.4);
    }
  }

  // ── Magnet effect ────────────────────────────────────────────────────────

  /// Draw magnet lines/particles with theme style.
  /// [theme] should already be the effective theme (inverted if Phase 5).
  static void drawMagnetEffect(Canvas canvas, Size size, double playerX,
      double playerY, bool isTouching, VisualTheme theme, double gameTime) {
    final color = theme.magnetColors.isNotEmpty
        ? theme.magnetColors.first
        : theme.ballColors.first;
    final wallX = isTouching ? size.width : 0.0;

    // Draw 3 curved lines from wall to player.
    for (int i = 0; i < 3; i++) {
      final yOffset = sin(gameTime * 3 + i * 2.0) * 30;
      final midX = (wallX + playerX) / 2;
      final midY = playerY + yOffset;

      final path = Path()
        ..moveTo(wallX, playerY + (i - 1) * 20)
        ..quadraticBezierTo(midX, midY, playerX, playerY);

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(
              alpha: 0.06 + sin(gameTime * 4 + i).abs() * 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  // ── Ambient particles ────────────────────────────────────────────────────

  /// Draw ambient particles with theme style.
  /// [theme] should already be the effective theme (inverted if Phase 5).
  static void drawAmbientParticles(Canvas canvas,
      List<Particle> ambientParticles, VisualTheme theme) {
    final color = theme.ambientColors.isNotEmpty
        ? theme.ambientColors.first
        : theme.ballColors.first;

    for (final p in ambientParticles) {
      if (p.isDead) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0) * 0.08;
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  // ── Walls ────────────────────────────────────────────────────────────────

  /// Draw wall accents with theme style.
  /// [theme] should already be the effective theme (inverted if Phase 5).
  static void drawWalls(Canvas canvas, Size size, VisualTheme theme,
      double gameTime) {
    if (theme.wallStyle == WallStyle.clean) return;

    final color = theme.wallAccentColor;
    final intensity = theme.wallGlowIntensity;
    if (intensity <= 0) return;

    final baseAlpha = intensity * 0.3;

    switch (theme.wallStyle) {
      case WallStyle.glow:
        // Subtle gradient strips along edges.
        _drawWallGlow(canvas, size, color, baseAlpha);
      case WallStyle.pulse:
        final pulseAlpha =
            baseAlpha * (0.5 + sin(gameTime * 3).abs() * 0.5);
        _drawWallGlow(canvas, size, color, pulseAlpha);
      case WallStyle.drip:
        _drawWallGlow(canvas, size, color, baseAlpha * 0.7);
      case WallStyle.crack:
        _drawWallGlow(canvas, size, color, baseAlpha * 0.5);
      case WallStyle.electric:
        final sparkAlpha =
            baseAlpha * (sin(gameTime * 8) > 0.3 ? 1.0 : 0.2);
        _drawWallGlow(canvas, size, color, sparkAlpha);
      case WallStyle.frost:
        _drawWallGlow(canvas, size, color, baseAlpha * 0.8);
      case WallStyle.flame:
        final flameAlpha =
            baseAlpha * (0.6 + sin(gameTime * 5).abs() * 0.4);
        _drawWallGlow(canvas, size, color, flameAlpha);
      case WallStyle.clean:
        break;
    }
  }

  static void _drawWallGlow(
      Canvas canvas, Size size, Color color, double alpha) {
    final a = (alpha * 0.7).clamp(0.0, 1.0);
    // Gradient strips along left and right edges
    final leftGradient = LinearGradient(
      colors: [color.withValues(alpha: a), color.withValues(alpha: 0.0)],
    );
    final rightGradient = LinearGradient(
      colors: [color.withValues(alpha: 0.0), color.withValues(alpha: a)],
    );
    final leftRect = Rect.fromLTWH(0, 0, 20, size.height);
    final rightRect = Rect.fromLTWH(size.width - 20, 0, 20, size.height);
    canvas.drawRect(leftRect,
      Paint()..shader = leftGradient.createShader(leftRect),
    );
    canvas.drawRect(rightRect,
      Paint()..shader = rightGradient.createShader(rightRect),
    );
  }

  // ── Theme transition VFX ─────────────────────────────────────────────────

  /// Draw theme transition VFX (expanding ring + screen wash).
  static void drawThemeTransition(Canvas canvas, Size size, double playerX,
      double playerY, double timer, VisualTheme theme) {
    if (timer <= 0) return;
    final progress = 1.0 - timer; // 0 to 1
    final radius = progress * 400.0;
    final alpha = (1.0 - progress) * 0.6;
    final color = theme.ballColors.first;

    // Expanding ring.
    canvas.drawCircle(
      Offset(playerX, playerY),
      radius,
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 - progress * 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Screen wash.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = color.withValues(alpha: (1.0 - progress) * 0.1),
    );
  }
}
