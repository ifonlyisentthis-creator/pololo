import 'dart:math';

/// Describes a troll ball's movement behaviour.
enum TrollBehaviour {
  mirror, // Mirrors player X
  opposite, // Opposite X of player
  orbit, // Orbits around the player
  drunk, // Random wobble near player
  speedDemon, // Races ahead of obstacles
  copycatDelay, // Copies player with 500ms delay
  gravityFlip, // Falls upward visually
  strobe, // Rapidly blinks in/out
  sizeShift, // Grows/shrinks continuously
  shadowClone, // 3 transparent copies
  reverseMagnet, // Repels from player
  zigzag, // Zigzags across screen
  bouncer, // Bounces off walls
  spinner, // Spins in circles at center
  stalker, // Slowly approaches then runs
  teleporter, // Teleports every 2s
  waveRider, // Follows sine wave
  phaseGhost, // Phases through obstacles
  shrinkingRing, // Traces shrinking spiral
  fakeDeath, // Brief death flash fake-out
}

/// Runtime state for a single troll event.
class TrollEvent {
  final TrollBehaviour behaviour;
  final double duration; // seconds
  double elapsed = 0;
  double spawnTimer = 0; // delay before appearing
  bool spawned = false;
  bool finished = false;

  // Troll ball position
  double x = 0;
  double y = 0;
  double radius = 10;
  double alpha = 0; // 0 = invisible, builds to 0.4

  // Behaviour-specific state
  double teleportTimer = 0;
  double stalkerPhase = 0;
  List<double> delayBuffer = []; // for copycat delay
  bool fakeDeathTriggered = false; // V5: one-shot flag for fakeDeath

  TrollEvent({required this.behaviour, required this.duration});
}

/// Manages troll/easter-egg events. Session-only (not persisted).
class TrollSystem {
  final Random _rng = Random();

  // Session game counter — reset when app closes
  int sessionGameCount = 0;

  // Current active troll (null when not active)
  TrollEvent? activeTroll;

  // Whether user died during active troll
  bool diedDuringTroll = false;

  // Troll just activated flag (consumed by game_screen for haptic/audio)
  bool trollJustActivated = false;

  // Troll just ended flag
  bool trollJustEnded = false;

  // ── Shuffled decks (Fisher-Yates, no repeats) ──
  late List<int> _trollDeck = _buildShuffledDeck(20);
  int _trollCursor = 0;

  late List<int> _rageDeck = _buildShuffledDeck(trollRageBaitMessages.length);
  int _rageCursor = 0;

  List<int> _buildShuffledDeck(int size) {
    final deck = List<int>.generate(size, (i) => i);
    deck.shuffle(_rng);
    return deck;
  }

  /// Called on every startGame(). Tracks session count and decides if a troll triggers.
  void onGameStart(double screenWidth, double screenHeight) {
    sessionGameCount++;
    activeTroll = null;
    diedDuringTroll = false;
    trollJustActivated = false;
    trollJustEnded = false;

    // Trigger every 10th game
    if (sessionGameCount > 0 && sessionGameCount % 10 == 0) {
      _spawnTroll(screenWidth, screenHeight);
    }
  }

  void _spawnTroll(double screenWidth, double screenHeight) {
    final behaviour = _pickNextBehaviour();
    final duration = 8.0 + _rng.nextDouble() * 4.0; // 8-12 seconds

    activeTroll = TrollEvent(behaviour: behaviour, duration: duration)
      ..spawnTimer =
          3.0 +
          _rng.nextDouble() *
              2.0 // appear 3-5s in
      ..x = screenWidth / 2
      ..y = screenHeight * 0.3;
  }

  TrollBehaviour _pickNextBehaviour() {
    if (_trollCursor >= _trollDeck.length) {
      final lastShown = _trollDeck.last;
      _trollDeck = _buildShuffledDeck(20);
      if (_trollDeck.first == lastShown && _trollDeck.length > 1) {
        final swapIdx = 1 + _rng.nextInt(_trollDeck.length - 1);
        _trollDeck[0] = _trollDeck[swapIdx];
        _trollDeck[swapIdx] = lastShown;
      }
      _trollCursor = 0;
    }

    final idx = _trollDeck[_trollCursor++];
    // First 20 → hardcoded behaviours; beyond use DFA
    if (idx < TrollBehaviour.values.length) {
      return TrollBehaviour.values[idx];
    }
    // DFA: combine behaviours deterministically
    final seed = sessionGameCount;
    return TrollBehaviour.values[(seed * 7 + 3) % TrollBehaviour.values.length];
  }

  /// Update troll state each frame. Called from game engine's _updatePlaying.
  void update(
    double dt,
    double playerX,
    double playerY,
    double screenWidth,
    double screenHeight,
  ) {
    final troll = activeTroll;
    if (troll == null || troll.finished) return;

    // Pre-spawn delay
    if (!troll.spawned) {
      troll.spawnTimer -= dt;
      if (troll.spawnTimer <= 0) {
        troll.spawned = true;
        troll.x = screenWidth / 2;
        troll.y = screenHeight * 0.3;
        trollJustActivated = true;
      }
      return;
    }

    troll.elapsed += dt;

    // Fade in (first 0.3s)
    if (troll.elapsed < 0.3) {
      troll.alpha = (troll.elapsed / 0.3) * 0.4;
    }
    // Fade out (last 0.5s)
    else if (troll.elapsed > troll.duration - 0.5) {
      troll.alpha = ((troll.duration - troll.elapsed) / 0.5) * 0.4;
    } else {
      troll.alpha = 0.4;
    }

    // End check
    if (troll.elapsed >= troll.duration) {
      troll.finished = true;
      troll.alpha = 0;
      trollJustEnded = true;
      return;
    }

    // Update position based on behaviour
    _updateBehaviour(troll, dt, playerX, playerY, screenWidth, screenHeight);
  }

  void _updateBehaviour(
    TrollEvent troll,
    double dt,
    double playerX,
    double playerY,
    double screenWidth,
    double screenHeight,
  ) {
    final t = troll.elapsed;
    final pr = 10.0; // player radius

    switch (troll.behaviour) {
      case TrollBehaviour.mirror:
        troll.x = playerX;
        troll.y = playerY + 80;

      case TrollBehaviour.opposite:
        troll.x = screenWidth - playerX;
        troll.y = playerY;

      case TrollBehaviour.orbit:
        final angle = t * 3.0;
        troll.x = playerX + cos(angle) * 60;
        troll.y = playerY + sin(angle) * 60;

      case TrollBehaviour.drunk:
        troll.x += (sin(t * 7) * 200 + (_rng.nextDouble() - 0.5) * 100) * dt;
        troll.y += (cos(t * 5) * 100 + (_rng.nextDouble() - 0.5) * 60) * dt;
        troll.x = troll.x.clamp(pr, screenWidth - pr);
        troll.y = troll.y.clamp(pr * 2, screenHeight * 0.5);

      case TrollBehaviour.speedDemon:
        troll.x = screenWidth / 2 + sin(t * 4) * (screenWidth * 0.3);
        troll.y = playerY - 120 - sin(t * 2) * 40;

      case TrollBehaviour.copycatDelay:
        // Buffer player positions, replay with ~500ms delay
        troll.delayBuffer.add(playerX);
        // V5: Cap buffer to prevent unbounded growth
        if (troll.delayBuffer.length > 120) {
          troll.delayBuffer.removeRange(0, troll.delayBuffer.length - 120);
        }
        final delayFrames = (0.5 / dt).round().clamp(
          1,
          troll.delayBuffer.length,
        );
        final idx = (troll.delayBuffer.length - delayFrames).clamp(
          0,
          troll.delayBuffer.length - 1,
        );
        troll.x = troll.delayBuffer[idx];
        troll.y = playerY + 60;

      case TrollBehaviour.gravityFlip:
        troll.x = playerX + sin(t * 2) * 40;
        troll.y = screenHeight * 0.7 - t * 30; // "falls" upward
        if (troll.y < 0) troll.y = screenHeight * 0.7;

      case TrollBehaviour.strobe:
        troll.x = screenWidth / 2;
        troll.y = playerY - 80;
        // Override alpha with strobe
        troll.alpha = (sin(t * 20) > 0) ? 0.4 : 0.0;

      case TrollBehaviour.sizeShift:
        troll.x = playerX + 50;
        troll.y = playerY;
        troll.radius = (6.0 + sin(t * 3) * 8.0).clamp(2.0, 14.0);

      case TrollBehaviour.shadowClone:
        // Main clone follows with offset; others drawn in painter
        troll.x = playerX;
        troll.y = playerY;

      case TrollBehaviour.reverseMagnet:
        // Move away from player
        final dx = troll.x - playerX;
        final dy = troll.y - playerY;
        final dist = sqrt(dx * dx + dy * dy).clamp(1.0, 999.0);
        if (dist < 100) {
          troll.x += (dx / dist) * 200 * dt;
          troll.y += (dy / dist) * 100 * dt;
        } else {
          troll.x += sin(t * 2) * 80 * dt;
          troll.y += cos(t * 1.5) * 40 * dt;
        }
        troll.x = troll.x.clamp(pr, screenWidth - pr);
        troll.y = troll.y.clamp(pr * 2, screenHeight * 0.6);

      case TrollBehaviour.zigzag:
        troll.x = screenWidth * 0.5 + sin(t * 6) * (screenWidth * 0.35);
        troll.y = playerY + sin(t * 3) * 50;

      case TrollBehaviour.bouncer:
        troll.x += sin(t * 4) * 300 * dt;
        if (troll.x <= pr || troll.x >= screenWidth - pr) {
          troll.x = troll.x.clamp(pr, screenWidth - pr);
        }
        troll.y = playerY + sin(t * 2) * 40;

      case TrollBehaviour.spinner:
        final angle = t * 5;
        final radius = 40 + sin(t * 0.5) * 20;
        troll.x = screenWidth / 2 + cos(angle) * radius;
        troll.y = screenHeight * 0.3 + sin(angle) * radius;

      case TrollBehaviour.stalker:
        troll.stalkerPhase += dt;
        if (troll.stalkerPhase < 3.0) {
          // Approach
          troll.x += (playerX - troll.x) * dt * 0.8;
          troll.y += (playerY - troll.y) * dt * 0.8;
        } else if (troll.stalkerPhase < 4.0) {
          // Run away
          troll.x += (troll.x - playerX) * dt * 2.0;
          troll.y += (troll.y - playerY) * dt * 2.0;
        } else {
          troll.stalkerPhase = 0;
        }
        troll.x = troll.x.clamp(pr, screenWidth - pr);
        troll.y = troll.y.clamp(pr * 2, screenHeight * 0.6);

      case TrollBehaviour.teleporter:
        troll.teleportTimer += dt;
        if (troll.teleportTimer >= 2.0) {
          troll.teleportTimer = 0;
          troll.x = pr + _rng.nextDouble() * (screenWidth - pr * 2);
          troll.y =
              screenHeight * 0.15 + _rng.nextDouble() * (screenHeight * 0.35);
        }

      case TrollBehaviour.waveRider:
        troll.x = screenWidth * 0.5 + sin(t * 2) * (screenWidth * 0.3);
        troll.y = playerY + sin(t * 4) * 60;

      case TrollBehaviour.phaseGhost:
        troll.x = playerX + sin(t * 3) * 80;
        troll.y = playerY - 60 + cos(t * 2) * 30;

      case TrollBehaviour.shrinkingRing:
        final spiralR = max(10.0, 80.0 - t * 8);
        final angle = t * 4;
        troll.x = playerX + cos(angle) * spiralR;
        troll.y = playerY + sin(angle) * spiralR;

      case TrollBehaviour.fakeDeath:
        // This is handled specially — the "troll ball" doesn't really appear
        // Instead, a brief death flash fake-out is triggered once
        troll.x = playerX;
        troll.y = playerY;
        troll.alpha = 0; // invisible ball, effect handled via flag
    }
  }

  /// Called when player dies. Marks troll death state.
  void onDeath() {
    if (activeTroll != null && activeTroll!.spawned && !activeTroll!.finished) {
      diedDuringTroll = true;
    }
  }

  /// Called on revive — end active troll.
  void onRevive() {
    if (activeTroll != null) {
      activeTroll!.finished = true;
      activeTroll!.alpha = 0;
    }
    diedDuringTroll = false;
  }

  /// Get rage-bait death message if died during troll, otherwise null.
  String? getTrollDeathMessage() {
    if (!diedDuringTroll) return null;

    if (_rageCursor >= _rageDeck.length) {
      final lastShown = _rageDeck.last;
      _rageDeck = _buildShuffledDeck(trollRageBaitMessages.length);
      if (_rageDeck.first == lastShown && _rageDeck.length > 1) {
        final swapIdx = 1 + _rng.nextInt(_rageDeck.length - 1);
        _rageDeck[0] = _rageDeck[swapIdx];
        _rageDeck[swapIdx] = lastShown;
      }
      _rageCursor = 0;
    }
    return trollRageBaitMessages[_rageDeck[_rageCursor++]];
  }

  /// Whether the troll ball should be rendered.
  bool get shouldRenderTroll {
    final troll = activeTroll;
    if (troll == null || !troll.spawned || troll.finished) return false;
    if (troll.behaviour == TrollBehaviour.fakeDeath) return false;
    return troll.alpha > 0.01;
  }

  /// Whether the fake death flash should trigger (one-shot).
  bool get shouldTriggerFakeDeath {
    final troll = activeTroll;
    if (troll == null || !troll.spawned || troll.finished) return false;
    if (troll.fakeDeathTriggered) return false;
    // Trigger once at elapsed ~0.5s
    if (troll.behaviour == TrollBehaviour.fakeDeath && troll.elapsed > 0.5) {
      troll.fakeDeathTriggered = true;
      return true;
    }
    return false;
  }

  // Store-friendly troll rage-bait death messages.
  static const List<String> trollRageBaitMessages = [
    "gotcha lmao",
    "that was me btw",
    "u trusted a suspicious circle, bold choice",
    "the decoy sends its regards",
    "pranked by geometry",
    "i said nothing and u still believed me",
    "the fake ball really sold the role",
    "u followed the chaos tour perfectly",
    "that troll ball has timing",
    "best supporting actor: that distraction",
    "u saw the bait and brought a plate",
    "the clone did one lap and won",
    "that was a premium distraction",
    "the orbit was decorative, u made it personal",
    "the wobble got u, respectfully",
    "troll event complete, notes taken",
    "u got juked by a circle",
    "the fake-out department is thriving",
    "that was a setup and u RSVP'd",
    "the ghost ball had one job and nailed it",
    "u chased the wrong problem beautifully",
    "that blink was not your friend",
    "the decoy is updating its resume",
    "u trusted the side quest again",
    "that was a tiny prank with big timing",
    "the troll ball remains undefeated today",
    "u got politely bamboozled",
    "the distraction budget was well spent",
    "that fake danger looked very convincing",
    "mission: mildly annoying accomplished",
  ];
}
