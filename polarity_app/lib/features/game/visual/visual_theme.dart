import 'package:flutter/material.dart';

// ── Ball Shapes ──
enum BallShape {
  circle,
  hexagon,
  star5,
  star6,
  pentagon,
  diamond,
  gear,
  crescent,
  crown,
  cross,
  cube,
  spiral,
  eye,
  snowflake,
  bolt,
  prism,
  leaf,
  ring,
  slit,
  singularity,
  doubleRing,
  helix,
  tesseract,
}

// ── Ball Effects ──
enum BallEffect {
  none,
  pulse,
  spin,
  flicker,
  breathe,
  prismatic,
  orbit,
  phase,
  morph,
  corona,
  ripple,
}

// ── Trail Styles ──
enum TrailStyle {
  dots,
  streaks,
  flames,
  sparkles,
  ribbons,
  bubbles,
  embers,
  crystals,
  lightning,
  shadows,
  waves,
  droplets,
  code,
  feathers,
  shards,
}

// ── Explosion Patterns ──
enum ExplosionPattern {
  burst,
  spiral,
  ring,
  fountain,
  vortex,
  shatter,
  bloom,
  lightning,
  cascade,
  implosion,
  nova,
  fractal,
}

// ── Magnet Styles ──
enum MagnetStyle {
  lines,
  particles,
  waves,
  arcs,
  tendrils,
  chains,
  pulses,
  electric,
}

// ── Obstacle Styles ──
enum ObstacleStyle {
  solid,
  glow,
  pulse,
  stripe,
  cracked,
  flame,
  frost,
  electric,
  shadow,
}

// ── Ambient Styles ──
enum AmbientStyle {
  dust,
  sparkle,
  rain,
  snow,
  embers,
  bubbles,
  stars,
  leaves,
  fireflies,
  ash,
}

// ── Wall Styles ──
enum WallStyle {
  clean,
  glow,
  pulse,
  drip,
  crack,
  electric,
  frost,
  flame,
}

/// Immutable data class describing a complete visual theme.
/// The rendering system reads these fields to parameterize all draw calls.
class VisualTheme {
  final String id;
  final String displayName;
  final int tier; // 1-5 (or 6+ for DFA)
  final int variation; // 0-9 within tier

  // Ball
  final BallShape ballShape;
  final List<Color> ballColors;
  final double ballGlowRadius;
  final double ballGlowIntensity;
  final BallEffect ballEffect;
  final double ballEffectSpeed;

  // Trail
  final TrailStyle trailStyle;
  final List<Color> trailColors;
  final double trailWidth;
  final double trailLife;
  final int trailDensity;

  // Obstacle
  final ObstacleStyle obstacleStyle;
  final List<Color> obstacleColors;
  final double obstacleGlowIntensity;

  // Death explosion
  final ExplosionPattern explosionPattern;
  final List<Color> explosionColors;
  final int explosionParticleCount;
  final double explosionLife;
  final double explosionGravity;

  // Magnet/pull
  final MagnetStyle magnetStyle;
  final List<Color> magnetColors;

  // Ambient particles
  final AmbientStyle ambientStyle;
  final List<Color> ambientColors;
  final int ambientCount;

  // Wall accent
  final WallStyle wallStyle;
  final Color wallAccentColor;
  final double wallGlowIntensity;

  // Phase 5 inversion overrides (null = auto-invert)
  final List<Color>? invertedBallColors;
  final List<Color>? invertedTrailColors;
  final List<Color>? invertedObstacleColors;

  const VisualTheme({
    required this.id,
    required this.displayName,
    required this.tier,
    required this.variation,
    required this.ballShape,
    required this.ballColors,
    this.ballGlowRadius = 8.0,
    this.ballGlowIntensity = 0.25,
    this.ballEffect = BallEffect.none,
    this.ballEffectSpeed = 1.0,
    required this.trailStyle,
    required this.trailColors,
    this.trailWidth = 1.0,
    this.trailLife = 1.0,
    this.trailDensity = 1,
    this.obstacleStyle = ObstacleStyle.solid,
    required this.obstacleColors,
    this.obstacleGlowIntensity = 0.25,
    required this.explosionPattern,
    required this.explosionColors,
    this.explosionParticleCount = 100,
    this.explosionLife = 1.2,
    this.explosionGravity = 70.0,
    this.magnetStyle = MagnetStyle.lines,
    required this.magnetColors,
    this.ambientStyle = AmbientStyle.dust,
    required this.ambientColors,
    this.ambientCount = 25,
    this.wallStyle = WallStyle.clean,
    this.wallAccentColor = const Color(0x00000000),
    this.wallGlowIntensity = 0.0,
    this.invertedBallColors,
    this.invertedTrailColors,
    this.invertedObstacleColors,
  });

  /// Auto-invert colors for Phase 5 white background.
  /// Returns a copy with colors adjusted for contrast on white.
  VisualTheme withInversion() {
    return VisualTheme(
      id: id,
      displayName: displayName,
      tier: tier,
      variation: variation,
      ballShape: ballShape,
      ballColors: invertedBallColors ?? ballColors.map(_ensureContrastOnWhite).toList(),
      ballGlowRadius: ballGlowRadius,
      ballGlowIntensity: ballGlowIntensity,
      ballEffect: ballEffect,
      ballEffectSpeed: ballEffectSpeed,
      trailStyle: trailStyle,
      trailColors: invertedTrailColors ?? trailColors.map(_ensureContrastOnWhite).toList(),
      trailWidth: trailWidth,
      trailLife: trailLife,
      trailDensity: trailDensity,
      obstacleStyle: obstacleStyle,
      obstacleColors: invertedObstacleColors ?? obstacleColors.map(_ensureContrastOnWhite).toList(),
      obstacleGlowIntensity: obstacleGlowIntensity,
      explosionPattern: explosionPattern,
      explosionColors: explosionColors.map(_ensureContrastOnWhite).toList(),
      explosionParticleCount: explosionParticleCount,
      explosionLife: explosionLife,
      explosionGravity: explosionGravity,
      magnetStyle: magnetStyle,
      magnetColors: magnetColors.map(_ensureContrastOnWhite).toList(),
      ambientStyle: ambientStyle,
      ambientColors: ambientColors.map(_ensureContrastOnWhite).toList(),
      ambientCount: ambientCount,
      wallStyle: wallStyle,
      wallAccentColor: _ensureContrastOnWhite(wallAccentColor),
      wallGlowIntensity: wallGlowIntensity,
    );
  }

  /// Copy theme with component overrides (used by DFA compositing).
  VisualTheme copyWith({
    String? id,
    String? displayName,
    int? tier,
    int? variation,
    BallShape? ballShape,
    List<Color>? ballColors,
    double? ballGlowRadius,
    double? ballGlowIntensity,
    BallEffect? ballEffect,
    double? ballEffectSpeed,
    TrailStyle? trailStyle,
    List<Color>? trailColors,
    double? trailWidth,
    double? trailLife,
    int? trailDensity,
    ObstacleStyle? obstacleStyle,
    List<Color>? obstacleColors,
    double? obstacleGlowIntensity,
    ExplosionPattern? explosionPattern,
    List<Color>? explosionColors,
    int? explosionParticleCount,
    double? explosionLife,
    double? explosionGravity,
    MagnetStyle? magnetStyle,
    List<Color>? magnetColors,
    AmbientStyle? ambientStyle,
    List<Color>? ambientColors,
    int? ambientCount,
    WallStyle? wallStyle,
    Color? wallAccentColor,
    double? wallGlowIntensity,
    List<Color>? invertedBallColors,
    List<Color>? invertedTrailColors,
    List<Color>? invertedObstacleColors,
  }) {
    return VisualTheme(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      tier: tier ?? this.tier,
      variation: variation ?? this.variation,
      ballShape: ballShape ?? this.ballShape,
      ballColors: ballColors ?? this.ballColors,
      ballGlowRadius: ballGlowRadius ?? this.ballGlowRadius,
      ballGlowIntensity: ballGlowIntensity ?? this.ballGlowIntensity,
      ballEffect: ballEffect ?? this.ballEffect,
      ballEffectSpeed: ballEffectSpeed ?? this.ballEffectSpeed,
      trailStyle: trailStyle ?? this.trailStyle,
      trailColors: trailColors ?? this.trailColors,
      trailWidth: trailWidth ?? this.trailWidth,
      trailLife: trailLife ?? this.trailLife,
      trailDensity: trailDensity ?? this.trailDensity,
      obstacleStyle: obstacleStyle ?? this.obstacleStyle,
      obstacleColors: obstacleColors ?? this.obstacleColors,
      obstacleGlowIntensity: obstacleGlowIntensity ?? this.obstacleGlowIntensity,
      explosionPattern: explosionPattern ?? this.explosionPattern,
      explosionColors: explosionColors ?? this.explosionColors,
      explosionParticleCount: explosionParticleCount ?? this.explosionParticleCount,
      explosionLife: explosionLife ?? this.explosionLife,
      explosionGravity: explosionGravity ?? this.explosionGravity,
      magnetStyle: magnetStyle ?? this.magnetStyle,
      magnetColors: magnetColors ?? this.magnetColors,
      ambientStyle: ambientStyle ?? this.ambientStyle,
      ambientColors: ambientColors ?? this.ambientColors,
      ambientCount: ambientCount ?? this.ambientCount,
      wallStyle: wallStyle ?? this.wallStyle,
      wallAccentColor: wallAccentColor ?? this.wallAccentColor,
      wallGlowIntensity: wallGlowIntensity ?? this.wallGlowIntensity,
      invertedBallColors: invertedBallColors ?? this.invertedBallColors,
      invertedTrailColors: invertedTrailColors ?? this.invertedTrailColors,
      invertedObstacleColors: invertedObstacleColors ?? this.invertedObstacleColors,
    );
  }

  static Color _ensureContrastOnWhite(Color c) {
    final luminance = c.computeLuminance();
    if (luminance > 0.7) {
      // Too bright for white background — darken
      final hsl = HSLColor.fromColor(c);
      return hsl.withLightness((hsl.lightness * 0.4).clamp(0.0, 1.0)).toColor();
    }
    return c;
  }
}
