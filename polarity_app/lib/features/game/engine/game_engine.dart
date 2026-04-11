import 'dart:math';
import 'dart:convert';
import 'package:polarity/core/constants.dart';
import 'package:polarity/core/security/score_guard.dart';
import 'package:polarity/features/game/models/obstacle.dart';
import 'package:polarity/features/game/models/particle.dart';
import 'package:polarity/features/game/models/player.dart';
import 'package:polarity/features/game/visual/visual_theme.dart';
import 'package:polarity/features/game/visual/theme_registry.dart';
import 'package:polarity/features/game/visual/explosion_painters.dart';
import 'package:polarity/features/game/troll/troll_system.dart';
import 'package:flutter/material.dart';

enum GameState { menu, playing, countdown, dead, paused }

class GameEngine {
  late Player player;
  final List<Obstacle> obstacles = [];
  final List<Particle> particles = [];
  final List<Particle> magnetParticles = [];

  final List<Particle> trailParticles = [];

  GameState state = GameState.menu;
  GameState _stateBeforePause =
      GameState.playing; // V5: for pause from countdown
  bool isTouching = false;

  int score = 0;
  int highScore = 0;
  int currentPhase = 0;
  Color accentColor = GameConstants.phaseColors[0];

  double screenWidth = 0;
  double screenHeight = 0;

  // Elapsed game time since start
  double gameTime = 0;

  // Obstacle spawning
  bool _nextFromLeft = true;
  int _consecutiveSameSide = 0;
  double _nextObstacleSpawnY = 0;
  double _previousSpacingMultiplier = 1.0;

  // Revive
  int countdownValue = 3;
  double countdownTimer = 0;
  bool isInvincible = false;
  double invincibilityTimer = 0;

  // Tutorial — shown for new installs or lifetime score < 3
  // Just a text overlay; magnets work normally so user can play
  bool showTutorial = false;
  double tutorialOpacity = 0;

  // Shield mechanic
  bool hasShield = false;
  int _nextShieldScore = GameConstants.firstShieldScore;

  // Phase 5 theme inversion
  bool isPhase5Inverted = false;

  // Magnet animation
  double magnetPhase = 0;

  // Procedural randomization seed per restart (for trail/glow variety)
  double trailLengthSeed = 1.0;
  double trailScatterSeed = 1.0;
  double glowIntensitySeed = 1.0;

  // Squash/stretch factor based on velocity
  double squashStretch = 1.0;

  // Easy mode: walls don't kill (player bounces off)
  bool easyMode = false;

  // Debug invincibility (only for debug builds)
  bool debugInvincible = false;

  // Track if player already used their revive this run (1 per run)
  bool hasRevivedThisRun = false;

  // Track if a new high score was actually set this run (prevents false positive after revive)
  bool _newHighScoreThisRun = false;

  // V3: Score at revive — prevents stale near-high-score after revive
  int _scoreAtRevive = 0;

  // V3: Mode in which high score was set — prevents cross-mode tier inflation
  bool highScoreMode = false; // true = easy

  // ── Premium VFX state ──

  // Screen shake
  double screenShakeIntensity = 0;
  double screenShakeX = 0;
  double screenShakeY = 0;

  // Death flash overlay
  double deathFlashTimer = 0;

  // Shockwave ring
  double shockwaveTimer = 0;
  double shockwaveX = 0;
  double shockwaveY = 0;

  // Phase transition ring
  double phaseRingTimer = 0;
  Color phaseRingColor = const Color(0xFFFFFFFF);

  // Shield VFX
  double shieldPickupTimer = 0;
  bool shieldBreakActive = false;
  double shieldBreakTimer = 0;
  bool shieldJustBroke = false;
  bool shieldJustPickedUp = false;

  // Ambient background particles
  final List<Particle> ambientParticles = [];

  // ── V2: Elite unlock ──
  bool eliteUnlocked = false;
  bool eliteJustUnlocked = false;
  double eliteUnlockTimer = 0; // VFX timer for unlock celebration

  // ── V2: Milestone celebrations ──
  double milestoneGlowTimer = 0;
  Color milestoneGlowColor = const Color(0xFFFFD700);
  int _lastMilestoneTriggered = 0;

  // ── V2: Session best ──
  int sessionBest = 0;
  bool isSessionBest = false;

  // ── V2: Near-high-score tension ──
  bool isNearHighScore = false;
  bool isInRecordTerritory = false;
  bool highScoreJustMatched = false;

  // ── V2: Tier tracking ──
  int currentTier = 0;
  int previousTier = 0;
  bool tierJustUnlocked = false;

  // ── V3: Visual Theme System ──
  VisualTheme? activeTheme;
  VisualTheme?
  _invertedThemeCache; // Cached inverted theme — avoids per-frame allocation
  VisualTheme?
  _whiteSurfaceThemeCache; // Cached white-mode adjusted theme
  bool _useWhiteSurfaceThemeInversion = false;
  int currentThemeTier = 0;
  bool themeJustActivated = false;
  double themeTransitionTimer = 0;
  Map<int, int> themeRotationIndices = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  bool get useWhiteSurfaceThemeInversion => _useWhiteSurfaceThemeInversion;
  set useWhiteSurfaceThemeInversion(bool value) {
    if (_useWhiteSurfaceThemeInversion == value) return;
    _useWhiteSurfaceThemeInversion = value;
    _rebuildThemeCaches();
  }

  /// Returns the effective theme for rendering.
  ///
  /// Priority:
  /// 1) Phase 5 inversion (always white background mode)
  /// 2) User-selected white mode inversion for readability
  /// 3) Raw active theme
  VisualTheme? get effectiveTheme {
    if (activeTheme == null) return null;
    if (isPhase5Inverted) {
      return _invertedThemeCache ?? activeTheme!.withInversion();
    }
    if (_useWhiteSurfaceThemeInversion) {
      return _whiteSurfaceThemeCache ?? activeTheme!.withInversion();
    }
    return activeTheme;
  }

  void _rebuildThemeCaches() {
    _invertedThemeCache = activeTheme?.withInversion();
    _whiteSurfaceThemeCache =
        _useWhiteSurfaceThemeInversion ? activeTheme?.withInversion() : null;
  }

  /// Rebuild theme caches (called after restoring theme from storage).
  void rebuildInvertedCache() {
    _rebuildThemeCaches();
  }

  // ── V4: Troll System ──
  final TrollSystem trollSystem = TrollSystem();
  double fakeDeathFlashTimer = 0; // For fakeDeath troll behaviour

  final Random _rng = Random();

  static const double playerYFraction = 0.3;
  static const double _runtimeFixedStep = 1.0 / 120.0;
  static final double _fixedVelocityDrag = pow(
    0.56,
    _runtimeFixedStep,
  ).toDouble();
  static final double _fixedParticleVelocityDamping = pow(
    0.3,
    _runtimeFixedStep,
  ).toDouble();
  static final double _fixedParticleRadiusDamping = pow(
    0.75,
    _runtimeFixedStep,
  ).toDouble();
  static final double _fixedScreenShakeDecay = pow(
    0.01,
    _runtimeFixedStep,
  ).toDouble();

  static bool _isFixedStepDt(double dt) =>
      (dt - _runtimeFixedStep).abs() < 1e-9;

  static double _velocityDragFactor(double dt) =>
      _isFixedStepDt(dt) ? _fixedVelocityDrag : pow(0.56, dt).toDouble();

  static (double velocityDamping, double radiusDamping) _particleDampingFactors(
    double dt,
  ) => _isFixedStepDt(dt)
      ? (_fixedParticleVelocityDamping, _fixedParticleRadiusDamping)
      : (pow(0.3, dt).toDouble(), pow(0.75, dt).toDouble());

  static double _screenShakeDecayFactor(double dt) =>
      _isFixedStepDt(dt) ? _fixedScreenShakeDecay : pow(0.01, dt).toDouble();

  double get _offscreenSpawnStartY =>
      screenHeight + GameConstants.obstacleSpacing * 0.6;

  GameEngine() {
    player = Player(x: 0, y: 0);
    ScoreGuard.initialize();
  }

  void init(double width, double height) {
    screenWidth = width;
    screenHeight = height;
    player.x = screenWidth / 2;
    player.y = screenHeight * playerYFraction;
  }

  /// Called externally: should we show tutorial?
  /// True if new install OR lifetime high score < 3
  void configureTutorial(bool shouldShow) {
    if (shouldShow) {
      showTutorial = true;
      tutorialOpacity = 1.0;
    } else {
      showTutorial = false;
      tutorialOpacity = 0;
    }
  }

  void startGame() {
    particles.clear();
    magnetParticles.clear();
    trailParticles.clear();
    score = 0;
    isTouching = false;
    ScoreGuard.setScore(0);
    currentPhase = 0;
    accentColor = GameConstants.phaseColors[0];
    gameTime = 0;
    isInvincible = false;
    invincibilityTimer = 0;
    _nextFromLeft = _rng.nextBool();
    _consecutiveSameSide = 0;
    _previousSpacingMultiplier = 1.0;
    hasShield = false;
    _nextShieldScore = GameConstants.firstShieldScore;
    isPhase5Inverted = false;
    hasRevivedThisRun = false;
    _newHighScoreThisRun = false;
    _scoreAtRevive = 0;

    // Reset VFX state
    screenShakeIntensity = 0;
    screenShakeX = 0;
    screenShakeY = 0;
    deathFlashTimer = 0;
    shockwaveTimer = 0;
    phaseRingTimer = 0;
    shieldPickupTimer = 0;
    shieldBreakActive = false;
    shieldBreakTimer = 0;
    shieldJustBroke = false;
    shieldJustPickedUp = false;

    // Reset V2 state
    eliteJustUnlocked = false;
    eliteUnlockTimer = 0;
    milestoneGlowTimer = 0;
    _lastMilestoneTriggered = 0;
    isNearHighScore = false;
    isInRecordTerritory = false;
    highScoreJustMatched = false;
    tierJustUnlocked = false;

    // V3: Keep activeTheme from previous run (visual persistence)
    // but reset tier so milestones re-trigger each run with new rotation variant
    currentThemeTier = 0;
    themeJustActivated = false;
    themeTransitionTimer = 0;

    player.x = screenWidth / 2;
    player.y = screenHeight * playerYFraction;
    player.velocityX = 0;
    player.isAlive = true;
    player.glowPhase = 0;
    _seedInitialObstaclesFromBottom();

    // Procedural randomization per restart
    trailLengthSeed = 0.7 + _rng.nextDouble() * 0.6;
    trailScatterSeed = 0.8 + _rng.nextDouble() * 0.4;
    glowIntensitySeed = 0.8 + _rng.nextDouble() * 0.4;

    // Initialize ambient background particles
    _initAmbientParticles();

    // V4: Troll system — track session game count, maybe trigger troll
    trollSystem.onGameStart(screenWidth, screenHeight);
    fakeDeathFlashTimer = 0;

    state = GameState.playing;
  }

  void revive() {
    if (state != GameState.dead) return; // V5: guard against invalid state
    state = GameState.countdown;
    countdownValue = GameConstants.reviveCountdownSeconds;
    countdownTimer = 0;
    player.isAlive = true;
    player.velocityX = 0;
    // Bug fix 9: Re-center player on revive
    player.x = screenWidth / 2;
    player.y = screenHeight * playerYFraction;
    particles.clear();
    magnetParticles.clear();
    trailParticles.clear();
    hasRevivedThisRun = true;
    // Bug fix 4: Prevent false "NEW BEST" after revive
    _newHighScoreThisRun = false;
    // Bug fix 5: Reset touch state
    isTouching = false;
    // Bug fix 8: Clear shield event flags
    shieldJustBroke = false;
    shieldJustPickedUp = false;

    // Reset V2 state that could be stale from pre-death
    isNearHighScore = false;
    isInRecordTerritory = false;
    highScoreJustMatched = false;
    tierJustUnlocked = false;
    // Bug fix 1: Track revive score for near-high-score threshold
    _scoreAtRevive = score;
    // V3: Theme persists across revive, but clear transition flags
    themeJustActivated = false;
    themeTransitionTimer = 0;

    // V4: End active troll on revive
    trollSystem.onRevive();
    fakeDeathFlashTimer = 0;

    // Reset death VFX
    screenShakeIntensity = 0;
    screenShakeX = 0;
    screenShakeY = 0;
    deathFlashTimer = 0;
    shockwaveTimer = 0;

    // Bug fix 9: Remove nearby obstacles that would immediately collide
    final safeZone = GameConstants.obstacleSpacing * 0.5;
    _removeObstaclesNearPlayer(safeZone);
    _previousSpacingMultiplier = 1.0;
    _resetObstacleSpawnCursor();
  }

  void pause() {
    if (state == GameState.playing || state == GameState.countdown) {
      _stateBeforePause = state;
      state = GameState.paused;
    }
  }

  void resume() {
    if (state == GameState.paused) state = _stateBeforePause;
  }

  void update(double dt) {
    if (dt > 0.05) dt = 0.05;
    switch (state) {
      case GameState.playing:
        _updatePlaying(dt);
        break;
      case GameState.countdown:
        _updateCountdown(dt);
        break;
      case GameState.dead:
        _updateDead(dt);
        break;
      default:
        break;
    }
  }

  void _updatePlaying(double dt) {
    gameTime += dt;
    final speedMult = _getSpeedMultiplier();
    final magnetMult = _getMagnetMultiplier();

    magnetPhase += dt * 8;

    // ── Horizontal physics (always active, even during tutorial) ──
    final magnetForce = GameConstants.baseMagnetForce * magnetMult;
    if (isTouching) {
      player.velocityX += magnetForce * dt;
    } else {
      player.velocityX -= magnetForce * dt;
    }

    // Crisp velocity drag for snappy direction switching (frame-rate independent).
    // After 1 second, ~56% velocity remains — fast deceleration for precise control.
    player.velocityX *= _velocityDragFactor(dt);

    player.velocityX = player.velocityX.clamp(
      -GameConstants.maxHorizontalSpeed,
      GameConstants.maxHorizontalSpeed,
    );
    player.x += player.velocityX * dt;

    // Player Y locked
    player.y = screenHeight * playerYFraction;

    // ── Squash/stretch based on horizontal velocity ──
    final velRatio = player.velocityX.abs() / GameConstants.maxHorizontalSpeed;
    squashStretch = 1.0 + velRatio * 0.30; // max 1.30x stretch

    // ── Light trail particles ──
    _spawnTrailParticles(dt);
    _spawnMagnetParticles(dt);

    // ── Wall handling ──
    // Must happen BEFORE the obstacle-collision pass so the ball
    // is inside the playfield when we test obstacle overlap.
    final pr = GameConstants.playerRadius;
    if (!isInvincible && !debugInvincible) {
      if (player.x - pr <= 0 || player.x + pr >= screenWidth) {
        if (easyMode) {
          // Easy mode: wall just stops the ball (magnet holds it there).
          // Player switches input to pull away.
          player.x = player.x.clamp(pr + 1, screenWidth - pr - 1);
          player.velocityX = 0;
        } else {
          // Hard mode: wall = death
          _handleHit();
          return; // skip rest of update — player is dead
        }
      }
    }
    // Always clamp inside walls (safety net)
    player.x = player.x.clamp(pr + 1, screenWidth - pr - 1);

    // ── Scroll obstacles + scoring + recycle (single pass) ──
    final scrollSpeed = GameConstants.baseScrollSpeed * speedMult;
    _advanceObstacles(scrollSpeed * dt, allowScoring: true);

    // ── Generate obstacles (after safe spawn delay) ──
    if (gameTime >= GameConstants.safeSpawnDelay) {
      _generateObstaclesIfNeeded();
    }

    // ── Invincibility ──
    if (isInvincible) {
      invincibilityTimer -= dt;
      if (invincibilityTimer <= 0) isInvincible = false;
    }

    // ── Collision (skip if invincible or debug) ──
    if (!isInvincible && !debugInvincible) {
      _checkCollisions();
    }

    // ── Glow animation ──
    player.glowPhase += dt * 4;

    // ── Tutorial fade: fades when score reaches 3 ──
    if (showTutorial) {
      if (score >= GameConstants.tutorialFadeScore) {
        tutorialOpacity -= dt * 3;
        if (tutorialOpacity <= 0) {
          tutorialOpacity = 0;
          showTutorial = false;
        }
      }
    }

    // ── Update particles ──
    final (velocityDamping, radiusDamping) = _particleDampingFactors(dt);
    _updateAndCullParticles(
      magnetParticles,
      dt,
      velocityDamping,
      radiusDamping,
    );
    _updateAndCullParticles(trailParticles, dt, velocityDamping, radiusDamping);

    // ── Shield break / misc particles (must update during playing too) ──
    _updateAndCullParticles(particles, dt, velocityDamping, radiusDamping);

    // ── VFX timers ──
    if (phaseRingTimer > 0) phaseRingTimer -= dt;
    if (shieldPickupTimer > 0) shieldPickupTimer -= dt;
    if (shieldBreakTimer > 0) {
      shieldBreakTimer -= dt;
      if (shieldBreakTimer <= 0) shieldBreakActive = false;
    }

    // ── Screen shake decay (from shield break) ──
    _decayScreenShake(dt);

    // ── V2 VFX timers ──
    if (eliteUnlockTimer > 0) eliteUnlockTimer -= dt;
    if (milestoneGlowTimer > 0) milestoneGlowTimer -= dt;

    // ── V3 theme transition timer ──
    if (themeTransitionTimer > 0) themeTransitionTimer -= dt;

    // ── Ambient particles ──
    _updateAmbientParticles(dt);

    // ── V4: Troll system update ──
    trollSystem.update(dt, player.x, player.y, screenWidth, screenHeight);
    if (trollSystem.shouldTriggerFakeDeath && fakeDeathFlashTimer <= 0) {
      fakeDeathFlashTimer = 0.3;
      screenShakeIntensity = 6.0;
    }
    if (fakeDeathFlashTimer > 0) fakeDeathFlashTimer -= dt;
  }

  void _updateCountdown(double dt) {
    countdownTimer += dt;
    if (countdownTimer >= 1.0) {
      countdownTimer = 0;
      countdownValue--;
      if (countdownValue <= 0) {
        state = GameState.playing;
        isInvincible = true;
        invincibilityTimer = GameConstants.reviveInvincibilityDuration;
      }
    }

    // Keep obstacles scrolling and ambient alive during countdown
    final speedMult = _getSpeedMultiplier();
    final scrollSpeed = GameConstants.baseScrollSpeed * speedMult;
    _advanceObstacles(scrollSpeed * dt, allowScoring: false);
    _updateAmbientParticles(dt);

    // Fade out any leftover trail/magnet particles
    final (velocityDamping, radiusDamping) = _particleDampingFactors(dt);
    _updateAndCullParticles(trailParticles, dt, velocityDamping, radiusDamping);
    _updateAndCullParticles(
      magnetParticles,
      dt,
      velocityDamping,
      radiusDamping,
    );
  }

  void _updateDead(double dt) {
    final (velocityDamping, radiusDamping) = _particleDampingFactors(dt);
    _updateAndCullParticles(particles, dt, velocityDamping, radiusDamping);

    // Fade out leftover trail/magnet particles from last frame of playing
    _updateAndCullParticles(trailParticles, dt, velocityDamping, radiusDamping);
    _updateAndCullParticles(
      magnetParticles,
      dt,
      velocityDamping,
      radiusDamping,
    );

    // ── Death VFX timers ──
    if (deathFlashTimer > 0) deathFlashTimer -= dt;
    if (shockwaveTimer > 0) shockwaveTimer -= dt;
    _decayScreenShake(dt);

    // ── Keep ambient particles alive during death ──
    _updateAmbientParticles(dt);
  }

  void _decayScreenShake(double dt) {
    if (screenShakeIntensity > 0.5) {
      screenShakeIntensity *= _screenShakeDecayFactor(dt);
      screenShakeX = (_rng.nextDouble() - 0.5) * 2 * screenShakeIntensity;
      screenShakeY = (_rng.nextDouble() - 0.5) * 2 * screenShakeIntensity;
    } else {
      screenShakeIntensity = 0;
      screenShakeX = 0;
      screenShakeY = 0;
    }
  }

  // ── Ambient background particles ──

  static const int _ambientTargetCount = 25;

  void _initAmbientParticles() {
    ambientParticles.clear();
    for (int i = 0; i < _ambientTargetCount; i++) {
      _spawnOneAmbientParticle(randomizeLife: true);
    }
  }

  void _spawnOneAmbientParticle({bool randomizeLife = false}) {
    final life = 4.0 + _rng.nextDouble() * 4.0;
    // V3: Use effective theme ambient color if active.
    final theme = effectiveTheme;
    final ambientColor = theme != null
        ? (theme.ambientColors.isNotEmpty
              ? theme.ambientColors[_rng.nextInt(
                  theme.ambientColors.length,
                )]
              : accentColor)
        : accentColor;
    ambientParticles.add(
      Particle(
        x: _rng.nextDouble() * screenWidth,
        y: randomizeLife
            ? _rng.nextDouble() * screenHeight
            : screenHeight + _rng.nextDouble() * 40,
        velocityX: (_rng.nextDouble() - 0.5) * 16,
        velocityY: -(15 + _rng.nextDouble() * 20),
        life: randomizeLife ? _rng.nextDouble() * life : life,
        radius: 0.5 + _rng.nextDouble() * 1.5,
        color: ambientColor.withValues(alpha: 0.08),
      ),
    );
  }

  void _updateAmbientParticles(double dt) {
    int write = 0;
    for (int i = 0; i < ambientParticles.length; i++) {
      final p = ambientParticles[i];
      p.x += p.velocityX * dt;
      p.y += p.velocityY * dt;
      p.life -= dt;
      if (!p.isDead && p.y >= -20) {
        ambientParticles[write++] = p;
      }
    }
    if (write < ambientParticles.length) {
      ambientParticles.removeRange(write, ambientParticles.length);
    }
    while (ambientParticles.length < _ambientTargetCount) {
      _spawnOneAmbientParticle();
    }
  }

  void _updateAndCullParticles(
    List<Particle> source,
    double dt,
    double velocityDamping,
    double radiusDamping,
  ) {
    int write = 0;
    for (int i = 0; i < source.length; i++) {
      final p = source[i];
      p.updateWithDamping(dt, velocityDamping, radiusDamping);
      if (!p.isDead) {
        source[write++] = p;
      }
    }
    if (write < source.length) {
      source.removeRange(write, source.length);
    }
  }

  void _advanceObstacles(double scrollDelta, {required bool allowScoring}) {
    if (obstacles.isEmpty) {
      _nextObstacleSpawnY = _offscreenSpawnStartY;
    } else {
      _nextObstacleSpawnY -= scrollDelta;
    }
    final scoreLineY = player.y - GameConstants.playerRadius;
    int write = 0;
    for (int i = 0; i < obstacles.length; i++) {
      final obs = obstacles[i];
      obs.worldY -= scrollDelta;

      if (allowScoring && !obs.passed && obs.worldY < scoreLineY) {
        obs.passed = true;
        score++;
        ScoreGuard.setScore(score);
        _updatePhase();
        _checkShieldAward();
        _checkEliteUnlock();
        _checkMilestone();
        _checkThemeTransition();
        _updateNearHighScore();

        // Score micro-burst particles at obstacle tip.
        _spawnScoreParticles(obs);
      }

      if (obs.worldY >= -100) {
        obstacles[write++] = obs;
      }
    }

    if (write < obstacles.length) {
      obstacles.removeRange(write, obstacles.length);
    }
  }

  void _removeObstaclesNearPlayer(double safeZone) {
    int write = 0;
    for (int i = 0; i < obstacles.length; i++) {
      final obs = obstacles[i];
      if ((obs.worldY - player.y).abs() >= safeZone) {
        obstacles[write++] = obs;
      }
    }
    if (write < obstacles.length) {
      obstacles.removeRange(write, obstacles.length);
    }
  }

  void _resetObstacleSpawnCursor() {
    bool hasObstacle = false;
    _nextObstacleSpawnY = _offscreenSpawnStartY;
    for (int i = 0; i < obstacles.length; i++) {
      hasObstacle = true;
      final y = obstacles[i].worldY;
      if (y > _nextObstacleSpawnY) {
        _nextObstacleSpawnY = y;
      }
    }
    // Cursor stores the *next* spawn position, not the last obstacle position.
    if (hasObstacle) {
      _nextObstacleSpawnY += _jitteredSpacing();
    }
  }

  void _seedInitialObstaclesFromBottom() {
    obstacles.clear();
    _nextObstacleSpawnY = _offscreenSpawnStartY;
    final bufferEnd = screenHeight + screenHeight * 1.5;
    while (_nextObstacleSpawnY < bufferEnd) {
      _addObstacle(_nextObstacleSpawnY);
      _nextObstacleSpawnY += _jitteredSpacing();
    }
  }

  // ── Shield: absorbs one hit, grants 3s invincibility ──
  void _checkShieldAward() {
    if (!hasShield && score >= _nextShieldScore) {
      hasShield = true;
      shieldPickupTimer = 0.3;
      shieldJustPickedUp = true;

      // Sparkle burst around player
      for (int i = 0; i < 12; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final speed = 100 + _rng.nextDouble() * 100;
        trailParticles.add(
          Particle(
            x: player.x + cos(angle) * GameConstants.playerRadius,
            y: player.y + sin(angle) * GameConstants.playerRadius,
            velocityX: cos(angle) * speed,
            velocityY: sin(angle) * speed,
            life: 0.3 + _rng.nextDouble() * 0.2,
            radius: 1.0 + _rng.nextDouble() * 2.0,
            color: accentColor.withValues(alpha: 0.6),
          ),
        );
      }
    }
  }

  int getNextShieldAfter(int current) {
    if (current < GameConstants.firstShieldScore) {
      return GameConstants.firstShieldScore;
    }
    if (current < GameConstants.secondShieldScore) {
      return GameConstants.secondShieldScore;
    }
    // After 60, multiply by 2 each time: 120, 240, 480...
    int s = GameConstants.secondShieldScore;
    while (s <= current) {
      s *= 2;
    }
    return s;
  }

  void _checkCollisions() {
    final px = player.x;
    final pr = GameConstants.playerRadius;

    // Wall collision is handled in _updatePlaying (before clamp).
    // This method only checks obstacle collision.

    // Obstacle collision
    for (int i = 0; i < obstacles.length; i++) {
      final obs = obstacles[i];
      final obsTop = obs.worldY - obs.thickness / 2;
      final obsBottom = obs.worldY + obs.thickness / 2;
      final playerTop = player.y - pr;
      final playerBottom = player.y + pr;

      if (playerBottom > obsTop && playerTop < obsBottom) {
        if (obs.fromLeft) {
          if (px - pr < obs.width) {
            _handleHit();
            return;
          }
        } else {
          if (px + pr > screenWidth - obs.width) {
            _handleHit();
            return;
          }
        }
      }
    }
  }

  void _handleHit() {
    if (hasShield) {
      // Shield absorbs hit, grants invincibility
      hasShield = false;
      isInvincible = true;
      invincibilityTimer = GameConstants.shieldInvincibilityDuration;
      _nextShieldScore = getNextShieldAfter(score);

      // Shield break VFX
      shieldBreakActive = true;
      shieldBreakTimer = 0.5;
      shieldJustBroke = true;
      screenShakeIntensity = 6.0;

      // Ring-pattern particles ejected outward from shield radius
      for (int i = 0; i < 16; i++) {
        final angle = (i / 16) * 2 * pi + _rng.nextDouble() * 0.3;
        final speed = 150 + _rng.nextDouble() * 150;
        particles.add(
          Particle(
            x: player.x + cos(angle) * (GameConstants.playerRadius + 14),
            y: player.y + sin(angle) * (GameConstants.playerRadius + 14),
            velocityX: cos(angle) * speed,
            velocityY: sin(angle) * speed,
            life: 0.4 + _rng.nextDouble() * 0.3,
            radius: 2.0 + _rng.nextDouble() * 2.0,
            color: accentColor.withValues(alpha: 0.8),
          ),
        );
      }

      // Push player to center to prevent instant re-death on wall
      player.x = screenWidth / 2;
      player.velocityX = 0;
      return;
    }
    _die();
  }

  void _die() {
    player.isAlive = false;
    state = GameState.dead;
    hasShield = false; // V5: defensive clear

    if (score > highScore) {
      highScore = score;
      ScoreGuard.setHighScore(highScore);
      _newHighScoreThisRun = true;
      highScoreMode = easyMode; // Bug fix 2: track mode for tier calc
    }

    // V2: Session best
    if (score > sessionBest) {
      sessionBest = score;
      isSessionBest = true;
    } else {
      isSessionBest = false;
    }

    // V2: Tier check — use highScoreMode (not current easyMode) to prevent cross-mode inflation
    if (score == highScore && score > 0) {
      final newTier = GameConstants.getTier(highScore, easyMode: highScoreMode);
      if (newTier > currentTier) {
        previousTier = currentTier;
        currentTier = newTier;
        tierJustUnlocked = true;
      }
    }

    // Death VFX triggers
    screenShakeIntensity = 12.0;
    deathFlashTimer = 0.15;
    shockwaveTimer = 0.5;
    shockwaveX = player.x;
    shockwaveY = player.y;

    _spawnExplosion(player.x, player.y);

    // V4: Notify troll system of death
    trollSystem.onDeath();
  }

  void _spawnExplosion(double x, double y) {
    particles.clear();

    // V3: Use effective themed explosion if theme is active
    final theme = effectiveTheme;
    if (theme != null) {
      // Cap explosion particles for performance (max 120)
      final count = theme.explosionParticleCount.clamp(0, 120);
      ExplosionSpawner.spawn(
        theme.explosionPattern,
        particles,
        x,
        y,
        theme.explosionColors,
        count,
        theme.explosionLife,
        theme.explosionGravity,
        _rng,
      );
      return;
    }

    if (eliteUnlocked) {
      // Elite death: golden-ratio spiral, more particles, longer life
      final count = 150 + _rng.nextInt(50);
      final goldenAngle = pi * (3 - sqrt(5)); // ~137.5°
      for (int i = 0; i < count; i++) {
        final angle = i * goldenAngle + _rng.nextDouble() * 0.2;
        final r = sqrt(i.toDouble()) * 8;
        final speed = 60 + _rng.nextDouble() * 400;
        final life = 0.8 + _rng.nextDouble() * 1.5;
        particles.add(
          Particle(
            x: x + cos(angle) * min(r, 20),
            y: y + sin(angle) * min(r, 20),
            velocityX: cos(angle) * speed,
            velocityY: sin(angle) * speed,
            life: life,
            radius: 2.0 + _rng.nextDouble() * 8,
            color: accentColor,
            gravity: 60.0,
          ),
        );
      }
      // Secondary ring burst
      for (int i = 0; i < 24; i++) {
        final angle = (i / 24) * 2 * pi;
        particles.add(
          Particle(
            x: x + cos(angle) * 15,
            y: y + sin(angle) * 15,
            velocityX: cos(angle) * 300,
            velocityY: sin(angle) * 300,
            life: 0.4 + _rng.nextDouble() * 0.3,
            radius: 3.0 + _rng.nextDouble() * 3,
            color: accentColor.withValues(alpha: 0.9),
            gravity: 0,
          ),
        );
      }
    } else {
      // Normal death: randomized blast
      final count = 60 + _rng.nextInt(60);
      final blastMult = 0.8 + _rng.nextDouble() * 1.0;
      final spinBase = (_rng.nextDouble() - 0.5) * 200;
      for (int i = 0; i < count; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final speed = (80 + _rng.nextDouble() * 450) * blastMult;
        final life = 0.5 + _rng.nextDouble() * 1.3;
        final spinOffset = spinBase * (_rng.nextDouble() - 0.5);
        particles.add(
          Particle(
            x: x + (_rng.nextDouble() - 0.5) * 6,
            y: y + (_rng.nextDouble() - 0.5) * 6,
            velocityX: cos(angle) * speed + spinOffset,
            velocityY: sin(angle) * speed + spinOffset * 0.5,
            life: life,
            radius: 2.0 + _rng.nextDouble() * 7,
            color: accentColor,
            gravity: 80.0,
          ),
        );
      }
    }
  }

  void _spawnTrailParticles(double dt) {
    if (player.velocityX.abs() < 50) return;

    // V3: Effective themed trails
    final theme = effectiveTheme;
    if (theme != null) {
      final cap = (80 * theme.trailDensity).clamp(0, 200);
      if (trailParticles.length >= cap) return;
      final spawnRate = 55.0 * theme.trailDensity;
      if (_rng.nextDouble() > dt * spawnRate * trailScatterSeed) return;

      final px = player.x;
      final py = player.y;
      final dir = player.velocityX > 0 ? -1.0 : 1.0;
      final colors = theme.trailColors;
      final c = colors[_rng.nextInt(colors.length)];
      trailParticles.add(
        Particle(
          x: px + dir * GameConstants.playerRadius * 0.8,
          y: py + (_rng.nextDouble() - 0.5) * 12,
          velocityX: dir * (40 + _rng.nextDouble() * 80) * trailLengthSeed,
          velocityY: (_rng.nextDouble() - 0.5) * 30,
          life:
              (0.25 + _rng.nextDouble() * 0.30 * trailLengthSeed) *
              theme.trailLife,
          radius: (1.5 * theme.trailWidth) + _rng.nextDouble() * 3.0,
          color: c.withValues(alpha: 0.7),
        ),
      );
      return;
    }

    final cap = eliteUnlocked ? 100 : 80;
    if (trailParticles.length >= cap) return;
    final spawnRate = eliteUnlocked ? 70.0 : 55.0;
    if (_rng.nextDouble() > dt * spawnRate * trailScatterSeed) return;

    final px = player.x;
    final py = player.y;
    final dir = player.velocityX > 0 ? -1.0 : 1.0;
    final lifeMult = (eliteUnlocked && isInRecordTerritory) ? 1.5 : 1.0;
    trailParticles.add(
      Particle(
        x: px + dir * GameConstants.playerRadius * 0.8,
        y: py + (_rng.nextDouble() - 0.5) * (eliteUnlocked ? 12 : 8),
        velocityX: dir * (40 + _rng.nextDouble() * 80) * trailLengthSeed,
        velocityY: (_rng.nextDouble() - 0.5) * 30,
        life: (0.25 + _rng.nextDouble() * 0.30 * trailLengthSeed) * lifeMult,
        radius: (eliteUnlocked ? 2.0 : 1.5) + _rng.nextDouble() * 3.0,
        color: accentColor.withValues(alpha: eliteUnlocked ? 0.75 : 0.6),
      ),
    );
  }

  void _spawnMagnetParticles(double dt) {
    if (magnetParticles.length >= 50) return; // cap for performance
    if (_rng.nextDouble() < dt * 38) {
      final fromRight = isTouching;
      final startX = fromRight ? screenWidth : 0.0;
      final startY = player.y + (_rng.nextDouble() - 0.5) * 80;
      final dx = player.x - startX;

      magnetParticles.add(
        Particle(
          x: startX,
          y: startY,
          velocityX: dx * (1.5 + _rng.nextDouble()),
          velocityY: (_rng.nextDouble() - 0.5) * 40,
          life: 0.35 + _rng.nextDouble() * 0.25,
          radius: 2.0 + _rng.nextDouble() * 2,
          color: accentColor.withValues(alpha: 0.7),
        ),
      );
    }
  }

  void _spawnScoreParticles(Obstacle obs) {
    final tipX = obs.fromLeft ? obs.width : screenWidth - obs.width;
    final dir = obs.fromLeft ? 1.0 : -1.0;
    for (int i = 0; i < 5; i++) {
      trailParticles.add(
        Particle(
          x: tipX,
          y: obs.worldY + (_rng.nextDouble() - 0.5) * obs.thickness,
          velocityX: dir * (40 + _rng.nextDouble() * 60),
          velocityY: (_rng.nextDouble() - 0.5) * 50,
          life: 0.2 + _rng.nextDouble() * 0.15,
          radius: 1.0 + _rng.nextDouble() * 1.0,
          color: accentColor.withValues(alpha: 0.4),
        ),
      );
    }
  }

  void _generateObstaclesIfNeeded() {
    // Keep a buffer of obstacles extending ~1 full screen below the viewport
    // bottom so there's never a visible gap after the pre-seeded batch.
    final bufferEnd = screenHeight + screenHeight * 1.0;
    while (_nextObstacleSpawnY < bufferEnd) {
      _addObstacle(_nextObstacleSpawnY);
      _nextObstacleSpawnY += _jitteredSpacing();
    }
  }

  /// Randomised spacing: phase-scaled base with controlled jitter.
  double _jitteredSpacing() {
    final spacingMult = _getSpacingMultiplier();
    final base = GameConstants.obstacleSpacing * spacingMult;
    final jitter = GameConstants.obstacleSpacingJitter;

    // Triangular noise keeps randomness but naturally reduces extreme outliers.
    final triangularNoise = (_rng.nextDouble() + _rng.nextDouble() - 1.0);
    double rMult = 1.0 + triangularNoise * jitter;

    // Prevent two very large gaps in a row to avoid "empty" feeling streaks.
    const largeGapThreshold = 1.12;
    if (_previousSpacingMultiplier > largeGapThreshold &&
        rMult > largeGapThreshold) {
      rMult = 1.0 + _rng.nextDouble() * (largeGapThreshold - 1.0);
    }

    _previousSpacingMultiplier = rMult;
    return base * rMult;
  }

  void _addObstacle(double worldY) {
    // Side selection: truly random with per-phase same-side cap.
    // Each obstacle has a 50/50 base coin flip, but consecutive same-side runs
    // are capped to maintain fairness (lower phases = shorter cap).
    final maxConsecutive = _getMaxConsecutiveSameSide();
    final bool wantSameSide = _rng.nextBool();  // true 50% of the time

    if (_consecutiveSameSide >= maxConsecutive) {
      // Force flip after too many same-side in a row
      _nextFromLeft = !_nextFromLeft;
      _consecutiveSameSide = 0;
    } else if (wantSameSide) {
      // Keep same side
      _consecutiveSameSide++;
    } else {
      // Flip side
      _nextFromLeft = !_nextFromLeft;
      _consecutiveSameSide = 0;
    }
    final fromLeft = _nextFromLeft;

    final gapFactor = _getGapFactor();
    // Protrusion: 30-62% of screen width, scaled by phase gap factor
    final minProtrusion = screenWidth * 0.30;
    final maxProtrusion = screenWidth * (0.62 * gapFactor);
    final width =
        minProtrusion + _rng.nextDouble() * (maxProtrusion - minProtrusion);

    // Ensure gap is always at least 2.2x player diameter for survivability
    final minGap = GameConstants.playerRadius * 4.4;
    final clampedWidth = width.clamp(screenWidth * 0.22, screenWidth - minGap);

    // Randomised thickness for visual variety
    final thickness =
        GameConstants.obstacleMinThickness +
        _rng.nextDouble() *
            (GameConstants.obstacleMaxThickness -
                GameConstants.obstacleMinThickness);

    obstacles.add(
      Obstacle(
        fromLeft: fromLeft,
        width: clampedWidth,
        worldY: worldY,
        thickness: thickness,
      ),
    );
  }

  void _updatePhase() {
    int newPhase = 0;
    for (int i = GameConstants.phaseThresholds.length - 1; i >= 0; i--) {
      if (score >= GameConstants.phaseThresholds[i]) {
        newPhase = i;
        break;
      }
    }
    if (newPhase != currentPhase) {
      currentPhase = newPhase;
      // Phase ring VFX using current accent color (no color override)
      phaseRingTimer = 0.6;
      phaseRingColor = accentColor;
    }
  }

  double _getSpeedMultiplier() {
    final idx = currentPhase.clamp(
      0,
      GameConstants.phaseSpeedMultipliers.length - 1,
    );
    return GameConstants.phaseSpeedMultipliers[idx];
  }

  double _getMagnetMultiplier() {
    final idx = currentPhase.clamp(
      0,
      GameConstants.phaseMagnetMultipliers.length - 1,
    );
    return GameConstants.phaseMagnetMultipliers[idx];
  }

  double _getGapFactor() {
    final idx = currentPhase.clamp(0, GameConstants.phaseGapFactors.length - 1);
    return GameConstants.phaseGapFactors[idx];
  }

  double _getSpacingMultiplier() {
    final idx = currentPhase.clamp(
      0,
      GameConstants.phaseSpacingMultipliers.length - 1,
    );
    return GameConstants.phaseSpacingMultipliers[idx];
  }

  /// Max consecutive same-side obstacles before a forced flip.
  /// Lower phases = stricter cap to keep it fair, higher phases = allow longer runs.
  int _getMaxConsecutiveSameSide() {
    switch (currentPhase) {
      case 0: return 2;  // Phase 1: max 2 same-side in a row
      case 1: return 2;  // Phase 2: same
      case 2: return 3;  // Phase 3: allows longer runs
      case 3: return 3;  // Phase 4: chaotic
      default: return 4; // Phase 5: nearly uncapped
    }
  }

  // ── Roast shuffler: Fisher-Yates, no repeats until all shown ──
  late List<int> _roastDeck = _buildShuffledDeck(
    GameConstants.deathRoasts.length,
  );
  int _roastCursor = 0;

  // ── Praise shuffler: separate deck for praise messages ──
  late List<int> _praiseDeck = _buildShuffledDeck(
    GameConstants.deathPraises.length,
  );
  int _praiseCursor = 0;

  List<int> _buildShuffledDeck(int size) {
    final deck = List<int>.generate(size, (i) => i);
    deck.shuffle(_rng);
    return deck;
  }

  String getRandomRoast() {
    if (_roastCursor >= _roastDeck.length) {
      final lastShown = _roastDeck.last;
      _roastDeck = _buildShuffledDeck(GameConstants.deathRoasts.length);
      if (_roastDeck.first == lastShown && _roastDeck.length > 1) {
        final swapIdx = 1 + _rng.nextInt(_roastDeck.length - 1);
        _roastDeck[0] = _roastDeck[swapIdx];
        _roastDeck[swapIdx] = lastShown;
      }
      _roastCursor = 0;
    }
    return GameConstants.deathRoasts[_roastDeck[_roastCursor++]];
  }

  String _getRandomPraise() {
    if (_praiseCursor >= _praiseDeck.length) {
      final lastShown = _praiseDeck.last;
      _praiseDeck = _buildShuffledDeck(GameConstants.deathPraises.length);
      if (_praiseDeck.first == lastShown && _praiseDeck.length > 1) {
        final swapIdx = 1 + _rng.nextInt(_praiseDeck.length - 1);
        _praiseDeck[0] = _praiseDeck[swapIdx];
        _praiseDeck[swapIdx] = lastShown;
      }
      _praiseCursor = 0;
    }
    return GameConstants.deathPraises[_praiseDeck[_praiseCursor++]];
  }

  /// Returns either a roast or praise based on score and mode.
  /// V4: If player died during a troll event, returns rage-bait message instead.
  String getDeathMessage() {
    // V4: Troll rage-bait override
    final trollMsg = trollSystem.getTrollDeathMessage();
    if (trollMsg != null) return trollMsg;

    final threshold = easyMode
        ? GameConstants.praiseThresholdEasy
        : GameConstants.praiseThresholdHard;
    if (score >= threshold) {
      return _getRandomPraise();
    }
    return getRandomRoast();
  }

  /// Whether the last death message was a praise (for UI styling).
  /// V4: Troll rage-bait messages are never praise.
  bool get lastMessageWasPraise {
    if (trollSystem.diedDuringTroll) return false;
    final threshold = easyMode
        ? GameConstants.praiseThresholdEasy
        : GameConstants.praiseThresholdHard;
    return score >= threshold;
  }

  // ── V2: Elite unlock check ──
  void _checkEliteUnlock() {
    if (!eliteUnlocked && score >= GameConstants.eliteUnlockScore) {
      eliteUnlocked = true;
      eliteJustUnlocked = true;
      eliteUnlockTimer = 1.5;
      screenShakeIntensity = 4.0;

      // Golden burst
      for (int i = 0; i < 20; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final speed = 120 + _rng.nextDouble() * 180;
        trailParticles.add(
          Particle(
            x: player.x + cos(angle) * GameConstants.playerRadius,
            y: player.y + sin(angle) * GameConstants.playerRadius,
            velocityX: cos(angle) * speed,
            velocityY: sin(angle) * speed,
            life: 0.5 + _rng.nextDouble() * 0.4,
            radius: 2.0 + _rng.nextDouble() * 3.0,
            color: const Color(0xFFFFD700).withValues(alpha: 0.8),
          ),
        );
      }
    }
  }

  // ── V2: Milestone celebration check ──
  void _checkMilestone() {
    for (final ms in GameConstants.milestoneScores) {
      if (score == ms && ms > _lastMilestoneTriggered) {
        _lastMilestoneTriggered = ms;
        milestoneGlowTimer = 0.6;
        milestoneGlowColor = ms >= 200 ? const Color(0xFFFFD700) : accentColor;

        // Sparkle burst proportional to milestone
        final count = ms >= 100 ? 15 : 8;
        for (int i = 0; i < count; i++) {
          final angle = _rng.nextDouble() * 2 * pi;
          final speed = 80 + _rng.nextDouble() * 120;
          trailParticles.add(
            Particle(
              x: player.x + cos(angle) * GameConstants.playerRadius * 1.5,
              y: player.y + sin(angle) * GameConstants.playerRadius * 1.5,
              velocityX: cos(angle) * speed,
              velocityY: sin(angle) * speed,
              life: 0.3 + _rng.nextDouble() * 0.2,
              radius: 1.0 + _rng.nextDouble() * 2.0,
              color: milestoneGlowColor.withValues(alpha: 0.6),
            ),
          );
        }
        break; // Only trigger highest milestone
      }
    }
  }

  // ── V3: Theme transition check ──
  void _checkThemeTransition() {
    final newTier = ThemeRegistry.scoreToTier(score);
    if (newTier > currentThemeTier) {
      currentThemeTier = newTier;
      activeTheme = ThemeRegistry.selectTheme(score, themeRotationIndices);
      _rebuildThemeCaches();

      // Advance rotation for next game at this tier
      if (newTier <= 5) {
        themeRotationIndices[newTier] = ThemeRegistry.advanceRotation(
          newTier,
          themeRotationIndices[newTier] ?? 0,
        );
      }

      themeJustActivated = true;
      themeTransitionTimer = 1.0;
      screenShakeIntensity = 4.0;

      // Theme activation celebration burst
      final burstColor =
          effectiveTheme?.ballColors.first ?? activeTheme!.ballColors.first;
      for (int i = 0; i < 20; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final speed = 100 + _rng.nextDouble() * 200;
        trailParticles.add(
          Particle(
            x: player.x + cos(angle) * GameConstants.playerRadius,
            y: player.y + sin(angle) * GameConstants.playerRadius,
            velocityX: cos(angle) * speed,
            velocityY: sin(angle) * speed,
            life: 0.5 + _rng.nextDouble() * 0.4,
            radius: 2.0 + _rng.nextDouble() * 3.0,
            color: burstColor.withValues(alpha: 0.8),
          ),
        );
      }
    } else if (newTier == currentThemeTier &&
        score >= 500 &&
        activeTheme != null) {
      // Post-500 DFA: check if we crossed a 50-point boundary for new combo
      final prevSeed = ((score - 1) ~/ 50);
      final currSeed = (score ~/ 50);
      if (currSeed > prevSeed && currSeed > 10) {
        activeTheme = ThemeRegistry.selectTheme(score, themeRotationIndices);
        _rebuildThemeCaches();
        themeJustActivated = true;
        themeTransitionTimer = 1.0;
        screenShakeIntensity = 3.0;
      }
    }
  }

  // ── V2: Near-high-score tension ──
  void _updateNearHighScore() {
    // Bug fix 1: After revive, require exceeding the pre-revive score
    if (highScore <= 10 || score <= _scoreAtRevive) {
      isNearHighScore = false;
      isInRecordTerritory = false;
      return;
    }
    final wasInRecord = isInRecordTerritory;
    isNearHighScore = score >= highScore - 5;
    isInRecordTerritory = score > highScore;
    if (score == highScore && !wasInRecord) {
      highScoreJustMatched = true;
    }
  }

  bool get isNewHighScore => _newHighScoreThisRun;

  /// Serialize theme rotation indices to JSON string for storage.
  String serializeThemeRotations() {
    return jsonEncode(
      themeRotationIndices.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  /// Deserialize theme rotation indices from JSON string.
  void deserializeThemeRotations(String json) {
    if (json.isEmpty) return;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      themeRotationIndices = map.map(
        (k, v) => MapEntry(int.parse(k), v as int),
      );
    } catch (_) {
      // If parsing fails, use defaults
    }
  }

  bool get shouldRequestReview =>
      isNewHighScore && highScore > GameConstants.minScoreForReview;
}
