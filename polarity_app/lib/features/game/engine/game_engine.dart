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
  GameState _stateBeforePause = GameState.playing; // V5: for pause from countdown
  bool isTouching = false;

  int score = 0;
  int highScore = 0;
  int currentPhase = 0;
  Color accentColor = GameConstants.phaseColors[0];
  Color _targetAccentColor = GameConstants.phaseColors[0];

  double screenWidth = 0;
  double screenHeight = 0;

  // Elapsed game time since start
  double gameTime = 0;

  // Obstacle spawning
  bool _nextFromLeft = true;

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
  VisualTheme? _invertedThemeCache; // Cached inverted theme — avoids per-frame allocation
  int currentThemeTier = 0;
  bool themeJustActivated = false;
  double themeTransitionTimer = 0;
  Map<int, int> themeRotationIndices = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  /// Returns the effective theme for rendering (inverted if Phase 5).
  VisualTheme? get effectiveTheme {
    if (activeTheme == null) return null;
    return isPhase5Inverted ? _invertedThemeCache : activeTheme;
  }

  /// Rebuild the inverted theme cache (called after restoring theme from storage).
  void rebuildInvertedCache() {
    _invertedThemeCache = activeTheme?.withInversion();
  }

  // ── V4: Troll System ──
  final TrollSystem trollSystem = TrollSystem();
  double fakeDeathFlashTimer = 0; // For fakeDeath troll behaviour

  final Random _rng = Random();

  static const double playerYFraction = 0.3;

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
    obstacles.clear();
    particles.clear();
    magnetParticles.clear();
    trailParticles.clear();
    score = 0;
    isTouching = false;
    ScoreGuard.setScore(0);
    currentPhase = 0;
    accentColor = GameConstants.phaseColors[0];
    _targetAccentColor = GameConstants.phaseColors[0];
    gameTime = 0;
    isInvincible = false;
    invincibilityTimer = 0;
    _nextFromLeft = _rng.nextBool();
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

    // V5: Recalculate phase 5 inversion
    isPhase5Inverted = currentPhase >= GameConstants.phaseThresholds.length - 1;

    // Reset death VFX
    screenShakeIntensity = 0;
    screenShakeX = 0;
    screenShakeY = 0;
    deathFlashTimer = 0;
    shockwaveTimer = 0;

    // Bug fix 9: Remove nearby obstacles that would immediately collide
    final safeZone = GameConstants.obstacleSpacing * 0.5;
    obstacles.removeWhere((obs) => (obs.worldY - player.y).abs() < safeZone);
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
    player.velocityX *= pow(0.56, dt).toDouble();

    player.velocityX = player.velocityX.clamp(
      -GameConstants.maxHorizontalSpeed,
      GameConstants.maxHorizontalSpeed,
    );
    player.x += player.velocityX * dt;

    // Player Y locked
    player.y = screenHeight * playerYFraction;

    // ── Squash/stretch based on horizontal velocity ──
    final velRatio =
        player.velocityX.abs() / GameConstants.maxHorizontalSpeed;
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

    // ── Scroll obstacles upward ──
    final scrollSpeed = GameConstants.baseScrollSpeed * speedMult;
    for (final obs in obstacles) {
      obs.worldY -= scrollSpeed * dt;
    }

    // ── Scoring ──
    for (final obs in obstacles) {
      if (!obs.passed && obs.worldY < player.y - GameConstants.playerRadius) {
        obs.passed = true;
        score++;
        ScoreGuard.setScore(score);
        _updatePhase();
        _checkShieldAward();
        _checkEliteUnlock();
        _checkMilestone();
        _checkThemeTransition();
        _updateNearHighScore();

        // Score micro-burst particles at obstacle tip
        _spawnScoreParticles(obs);
      }
    }

    // ── Recycle obstacles ──
    obstacles.removeWhere((o) => o.worldY < -100);

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

    // ── Color transition (skip when already converged) ──
    if (accentColor != _targetAccentColor) {
      accentColor = Color.lerp(accentColor, _targetAccentColor, dt * 3) ??
          _targetAccentColor;
    }

    // ── Phase 5 inversion ──
    isPhase5Inverted =
        currentPhase >= GameConstants.phaseThresholds.length - 1;

    // ── Update particles ──
    for (final p in magnetParticles) {
      p.update(dt);
    }
    magnetParticles.removeWhere((p) => p.isDead);
    for (final p in trailParticles) {
      p.update(dt);
    }
    trailParticles.removeWhere((p) => p.isDead);

    // ── Shield break / misc particles (must update during playing too) ──
    for (final p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.isDead);

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
    for (final obs in obstacles) {
      obs.worldY -= scrollSpeed * dt;
    }
    obstacles.removeWhere((o) => o.worldY < -100);
    _updateAmbientParticles(dt);

    // Fade out any leftover trail/magnet particles
    for (final p in trailParticles) {
      p.update(dt);
    }
    trailParticles.removeWhere((p) => p.isDead);
    for (final p in magnetParticles) {
      p.update(dt);
    }
    magnetParticles.removeWhere((p) => p.isDead);
  }

  void _updateDead(double dt) {
    for (final p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.isDead);

    // Fade out leftover trail/magnet particles from last frame of playing
    for (final p in trailParticles) {
      p.update(dt);
    }
    trailParticles.removeWhere((p) => p.isDead);
    for (final p in magnetParticles) {
      p.update(dt);
    }
    magnetParticles.removeWhere((p) => p.isDead);

    // ── Death VFX timers ──
    if (deathFlashTimer > 0) deathFlashTimer -= dt;
    if (shockwaveTimer > 0) shockwaveTimer -= dt;
    _decayScreenShake(dt);

    // ── Keep ambient particles alive during death ──
    _updateAmbientParticles(dt);
  }

  void _decayScreenShake(double dt) {
    if (screenShakeIntensity > 0.5) {
      screenShakeIntensity *= pow(0.01, dt).toDouble();
      screenShakeX = (_rng.nextDouble() - 0.5) * 2 * screenShakeIntensity;
      screenShakeY = (_rng.nextDouble() - 0.5) * 2 * screenShakeIntensity;
    } else {
      screenShakeIntensity = 0;
      screenShakeX = 0;
      screenShakeY = 0;
    }
  }

  // ── Ambient background particles ──

  void _initAmbientParticles() {
    ambientParticles.clear();
    for (int i = 0; i < 25; i++) {
      _spawnOneAmbientParticle(randomizeLife: true);
    }
  }

  void _spawnOneAmbientParticle({bool randomizeLife = false}) {
    final life = 4.0 + _rng.nextDouble() * 4.0;
    // V3: Use theme ambient color if active
    final ambientColor = activeTheme != null
        ? (activeTheme!.ambientColors.isNotEmpty
            ? activeTheme!.ambientColors[_rng.nextInt(activeTheme!.ambientColors.length)]
            : accentColor)
        : accentColor;
    ambientParticles.add(Particle(
      x: _rng.nextDouble() * screenWidth,
      y: randomizeLife
          ? _rng.nextDouble() * screenHeight
          : screenHeight + _rng.nextDouble() * 40,
      velocityX: (_rng.nextDouble() - 0.5) * 16,
      velocityY: -(15 + _rng.nextDouble() * 20),
      life: randomizeLife ? _rng.nextDouble() * life : life,
      radius: 0.5 + _rng.nextDouble() * 1.5,
      color: ambientColor.withValues(alpha: 0.08),
    ));
  }

  void _updateAmbientParticles(double dt) {
    for (final p in ambientParticles) {
      p.x += p.velocityX * dt;
      p.y += p.velocityY * dt;
      p.life -= dt;
    }
    ambientParticles.removeWhere((p) => p.isDead || p.y < -20);
    while (ambientParticles.length < 25) {
      _spawnOneAmbientParticle();
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
        trailParticles.add(Particle(
          x: player.x + cos(angle) * GameConstants.playerRadius,
          y: player.y + sin(angle) * GameConstants.playerRadius,
          velocityX: cos(angle) * speed,
          velocityY: sin(angle) * speed,
          life: 0.3 + _rng.nextDouble() * 0.2,
          radius: 1.0 + _rng.nextDouble() * 2.0,
          color: accentColor.withValues(alpha: 0.6),
        ));
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
    for (final obs in obstacles) {
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
        particles.add(Particle(
          x: player.x + cos(angle) * (GameConstants.playerRadius + 14),
          y: player.y + sin(angle) * (GameConstants.playerRadius + 14),
          velocityX: cos(angle) * speed,
          velocityY: sin(angle) * speed,
          life: 0.4 + _rng.nextDouble() * 0.3,
          radius: 2.0 + _rng.nextDouble() * 2.0,
          color: accentColor.withValues(alpha: 0.8),
        ));
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

    // V3: Use themed explosion if theme is active
    if (activeTheme != null) {
      // Cap explosion particles for performance (max 120)
      final count = activeTheme!.explosionParticleCount.clamp(0, 120);
      ExplosionSpawner.spawn(
        activeTheme!.explosionPattern,
        particles, x, y,
        activeTheme!.explosionColors,
        count,
        activeTheme!.explosionLife,
        activeTheme!.explosionGravity,
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
        particles.add(Particle(
          x: x + cos(angle) * min(r, 20),
          y: y + sin(angle) * min(r, 20),
          velocityX: cos(angle) * speed,
          velocityY: sin(angle) * speed,
          life: life,
          radius: 2.0 + _rng.nextDouble() * 8,
          color: accentColor,
          gravity: 60.0,
        ));
      }
      // Secondary ring burst
      for (int i = 0; i < 24; i++) {
        final angle = (i / 24) * 2 * pi;
        particles.add(Particle(
          x: x + cos(angle) * 15,
          y: y + sin(angle) * 15,
          velocityX: cos(angle) * 300,
          velocityY: sin(angle) * 300,
          life: 0.4 + _rng.nextDouble() * 0.3,
          radius: 3.0 + _rng.nextDouble() * 3,
          color: accentColor.withValues(alpha: 0.9),
          gravity: 0,
        ));
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
        particles.add(Particle(
          x: x + (_rng.nextDouble() - 0.5) * 6,
          y: y + (_rng.nextDouble() - 0.5) * 6,
          velocityX: cos(angle) * speed + spinOffset,
          velocityY: sin(angle) * speed + spinOffset * 0.5,
          life: life,
          radius: 2.0 + _rng.nextDouble() * 7,
          color: accentColor,
          gravity: 80.0,
        ));
      }
    }
  }

  void _spawnTrailParticles(double dt) {
    if (player.velocityX.abs() < 50) return;

    // V3: Themed trails
    if (activeTheme != null) {
      final cap = (80 * activeTheme!.trailDensity).clamp(0, 200);
      if (trailParticles.length >= cap) return;
      final spawnRate = 55.0 * activeTheme!.trailDensity;
      if (_rng.nextDouble() > dt * spawnRate * trailScatterSeed) return;

      final px = player.x;
      final py = player.y;
      final dir = player.velocityX > 0 ? -1.0 : 1.0;
      final colors = activeTheme!.trailColors;
      final c = colors[_rng.nextInt(colors.length)];
      trailParticles.add(Particle(
        x: px + dir * GameConstants.playerRadius * 0.8,
        y: py + (_rng.nextDouble() - 0.5) * 12,
        velocityX: dir * (40 + _rng.nextDouble() * 80) * trailLengthSeed,
        velocityY: (_rng.nextDouble() - 0.5) * 30,
        life: (0.25 + _rng.nextDouble() * 0.30 * trailLengthSeed) * activeTheme!.trailLife,
        radius: (1.5 * activeTheme!.trailWidth) + _rng.nextDouble() * 3.0,
        color: c.withValues(alpha: 0.7),
      ));
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
    trailParticles.add(Particle(
      x: px + dir * GameConstants.playerRadius * 0.8,
      y: py + (_rng.nextDouble() - 0.5) * (eliteUnlocked ? 12 : 8),
      velocityX: dir * (40 + _rng.nextDouble() * 80) * trailLengthSeed,
      velocityY: (_rng.nextDouble() - 0.5) * 30,
      life: (0.25 + _rng.nextDouble() * 0.30 * trailLengthSeed) * lifeMult,
      radius: (eliteUnlocked ? 2.0 : 1.5) + _rng.nextDouble() * 3.0,
      color: accentColor.withValues(alpha: eliteUnlocked ? 0.75 : 0.6),
    ));
  }

  void _spawnMagnetParticles(double dt) {
    if (magnetParticles.length >= 50) return; // cap for performance
    if (_rng.nextDouble() < dt * 38) {
      final fromRight = isTouching;
      final startX = fromRight ? screenWidth : 0.0;
      final startY = player.y + (_rng.nextDouble() - 0.5) * 80;
      final dx = player.x - startX;

      magnetParticles.add(Particle(
        x: startX,
        y: startY,
        velocityX: dx * (1.5 + _rng.nextDouble()),
        velocityY: (_rng.nextDouble() - 0.5) * 40,
        life: 0.35 + _rng.nextDouble() * 0.25,
        radius: 2.0 + _rng.nextDouble() * 2,
        color: accentColor.withValues(alpha: 0.7),
      ));
    }
  }

  void _spawnScoreParticles(Obstacle obs) {
    final tipX = obs.fromLeft ? obs.width : screenWidth - obs.width;
    final dir = obs.fromLeft ? 1.0 : -1.0;
    for (int i = 0; i < 5; i++) {
      trailParticles.add(Particle(
        x: tipX,
        y: obs.worldY + (_rng.nextDouble() - 0.5) * obs.thickness,
        velocityX: dir * (40 + _rng.nextDouble() * 60),
        velocityY: (_rng.nextDouble() - 0.5) * 50,
        life: 0.2 + _rng.nextDouble() * 0.15,
        radius: 1.0 + _rng.nextDouble() * 1.0,
        color: accentColor.withValues(alpha: 0.4),
      ));
    }
  }

  void _generateObstaclesIfNeeded() {
    // Find the lowest obstacle (highest worldY = furthest below screen)
    double lowestY = player.y;
    for (final obs in obstacles) {
      if (obs.worldY > lowestY) lowestY = obs.worldY;
    }
    // Keep a buffer of obstacles extending ~1.5 screens below
    final bufferEnd = screenHeight + screenHeight * 0.5;
    double nextY = lowestY + _jitteredSpacing();
    while (nextY < bufferEnd) {
      _addObstacle(nextY);
      nextY += _jitteredSpacing();
    }
  }

  /// Randomised spacing: phase-scaled base ±25% jitter
  double _jitteredSpacing() {
    final spacingMult = _getSpacingMultiplier();
    final base = GameConstants.obstacleSpacing * spacingMult;
    final jitter = GameConstants.obstacleSpacingJitter;
    final rMult = 1.0 + (_rng.nextDouble() * 2 - 1) * jitter; // 0.75 – 1.25
    return base * rMult;
  }

  void _addObstacle(double worldY) {
    // Side selection: per-phase same-side repeat chance
    final sameSideChance = _getSameSideChance();
    if (_rng.nextDouble() < sameSideChance) {
      // Keep same side (tension moment)
    } else {
      _nextFromLeft = !_nextFromLeft;
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
    final clampedWidth =
        width.clamp(screenWidth * 0.22, screenWidth - minGap);

    // Randomised thickness for visual variety
    final thickness = GameConstants.obstacleMinThickness +
        _rng.nextDouble() *
            (GameConstants.obstacleMaxThickness -
                GameConstants.obstacleMinThickness);

    obstacles.add(Obstacle(
      fromLeft: fromLeft,
      width: clampedWidth,
      worldY: worldY,
      thickness: thickness,
    ));
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
      _targetAccentColor = GameConstants.phaseColors[
          currentPhase.clamp(0, GameConstants.phaseColors.length - 1)];

      // Phase transition VFX
      phaseRingTimer = 0.6;
      phaseRingColor = _targetAccentColor;
    }
  }

  double _getSpeedMultiplier() {
    final idx = currentPhase.clamp(
        0, GameConstants.phaseSpeedMultipliers.length - 1);
    return GameConstants.phaseSpeedMultipliers[idx];
  }

  double _getMagnetMultiplier() {
    final idx = currentPhase.clamp(
        0, GameConstants.phaseMagnetMultipliers.length - 1);
    return GameConstants.phaseMagnetMultipliers[idx];
  }

  double _getGapFactor() {
    final idx =
        currentPhase.clamp(0, GameConstants.phaseGapFactors.length - 1);
    return GameConstants.phaseGapFactors[idx];
  }

  double _getSpacingMultiplier() {
    final idx = currentPhase.clamp(
        0, GameConstants.phaseSpacingMultipliers.length - 1);
    return GameConstants.phaseSpacingMultipliers[idx];
  }

  double _getSameSideChance() {
    final idx = currentPhase.clamp(
        0, GameConstants.phaseSameSideChances.length - 1);
    return GameConstants.phaseSameSideChances[idx];
  }

  // ── Roast shuffler: Fisher-Yates, no repeats until all shown ──
  late List<int> _roastDeck = _buildShuffledDeck(GameConstants.deathRoasts.length);
  int _roastCursor = 0;

  // ── Praise shuffler: separate deck for praise messages ──
  late List<int> _praiseDeck = _buildShuffledDeck(GameConstants.deathPraises.length);
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
        trailParticles.add(Particle(
          x: player.x + cos(angle) * GameConstants.playerRadius,
          y: player.y + sin(angle) * GameConstants.playerRadius,
          velocityX: cos(angle) * speed,
          velocityY: sin(angle) * speed,
          life: 0.5 + _rng.nextDouble() * 0.4,
          radius: 2.0 + _rng.nextDouble() * 3.0,
          color: const Color(0xFFFFD700).withValues(alpha: 0.8),
        ));
      }
    }
  }

  // ── V2: Milestone celebration check ──
  void _checkMilestone() {
    for (final ms in GameConstants.milestoneScores) {
      if (score == ms && ms > _lastMilestoneTriggered) {
        _lastMilestoneTriggered = ms;
        milestoneGlowTimer = 0.6;
        milestoneGlowColor = ms >= 200
            ? const Color(0xFFFFD700)
            : accentColor;

        // Sparkle burst proportional to milestone
        final count = ms >= 100 ? 15 : 8;
        for (int i = 0; i < count; i++) {
          final angle = _rng.nextDouble() * 2 * pi;
          final speed = 80 + _rng.nextDouble() * 120;
          trailParticles.add(Particle(
            x: player.x + cos(angle) * GameConstants.playerRadius * 1.5,
            y: player.y + sin(angle) * GameConstants.playerRadius * 1.5,
            velocityX: cos(angle) * speed,
            velocityY: sin(angle) * speed,
            life: 0.3 + _rng.nextDouble() * 0.2,
            radius: 1.0 + _rng.nextDouble() * 2.0,
            color: milestoneGlowColor.withValues(alpha: 0.6),
          ));
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
      _invertedThemeCache = activeTheme?.withInversion();

      // Advance rotation for next game at this tier
      if (newTier <= 5) {
        themeRotationIndices[newTier] =
            ThemeRegistry.advanceRotation(newTier, themeRotationIndices[newTier] ?? 0);
      }

      themeJustActivated = true;
      themeTransitionTimer = 1.0;
      screenShakeIntensity = 4.0;

      // Theme activation celebration burst
      final burstColor = activeTheme!.ballColors.first;
      for (int i = 0; i < 20; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final speed = 100 + _rng.nextDouble() * 200;
        trailParticles.add(Particle(
          x: player.x + cos(angle) * GameConstants.playerRadius,
          y: player.y + sin(angle) * GameConstants.playerRadius,
          velocityX: cos(angle) * speed,
          velocityY: sin(angle) * speed,
          life: 0.5 + _rng.nextDouble() * 0.4,
          radius: 2.0 + _rng.nextDouble() * 3.0,
          color: burstColor.withValues(alpha: 0.8),
        ));
      }
    } else if (newTier == currentThemeTier && score >= 500 && activeTheme != null) {
      // Post-500 DFA: check if we crossed a 50-point boundary for new combo
      final prevSeed = ((score - 1) ~/ 50);
      final currSeed = (score ~/ 50);
      if (currSeed > prevSeed && currSeed > 10) {
        activeTheme = ThemeRegistry.selectTheme(score, themeRotationIndices);
        _invertedThemeCache = activeTheme?.withInversion();
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
    return jsonEncode(themeRotationIndices.map((k, v) => MapEntry(k.toString(), v)));
  }

  /// Deserialize theme rotation indices from JSON string.
  void deserializeThemeRotations(String json) {
    if (json.isEmpty) return;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      themeRotationIndices = map.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      // If parsing fails, use defaults
    }
  }

  bool get shouldRequestReview =>
      isNewHighScore && highScore > GameConstants.minScoreForReview;
}
