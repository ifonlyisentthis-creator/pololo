# Polarity V1.1 Fixes + V2 Feature Plan

---

## V1.1 FIXES (Pre-V2)

### Fix 1: Shield Break Particles Persist Forever (BUG)

**Root Cause**: When shield breaks during `GameState.playing`, 16 particles are added to the `particles` list (line 529, game_engine.dart). But `_updatePlaying()` never updates or cleans the `particles` list — only `_updateDead()` does. The particles' `life` never decrements, so they stay visible forever.

**Fix**: Add 2 lines to `_updatePlaying()` after the trail/magnet particle updates (~line 348):
```dart
for (final p in particles) { p.update(dt); }
particles.removeWhere((p) => p.isDead);
```

**Files**: `game_engine.dart` only

### Fix 2: Cross-Platform Readiness

**Status**: Already cross-platform. All game code uses Flutter Canvas/dart:math/dart:ui — no platform-specific code. AdMob IDs already split by platform. **No changes needed.**

---

## V2 FEATURES

### Feature 1: Score-Based Praise Messages (200 messages)

**Concept**: High-scoring players get love-bombed instead of roasted. The game cries, praises them, begs them to keep playing. Uses ONLY 😭 emojis.

**Score Threshold**:
- **Hard mode**: Score >= 75 → praise (Phase 2 deep, top ~20% of attempts)
- **Easy mode**: Score >= 120 → praise (easy mode ~1.6x longer runs)

**Implementation**:
- Add `deathPraises` (200 entries) to `GameConstants`
- Add `getDeathMessage()` in `GameEngine` — checks score + easyMode → picks praise or roast
- Separate Fisher-Yates deck for praises (same no-repeat logic as roasts)
- Death screen border tints green for praise messages
- Rename `roast` param to `deathMessage` throughout

**Files**: `constants.dart`, `game_engine.dart`, `game_screen.dart`, `death_screen.dart`

### Feature 2: Elite Ball Unlock (Score 100, Permanent)

**Concept**: Scoring 100 in a single run permanently unlocks "Elite" status with unique visuals.

**Threshold**: Score >= 100 (both modes — the achievement is universal)

**Elite Visuals (per phase, respects theme inversion)**:
| Phase | Elite Ball |
|-------|-----------|
| 1 (White) | Sphere with prismatic rainbow edge shimmer (rotating hue ring) |
| 2 (Blue) | Double nested rings rotating opposite directions + 5 orbital dots |
| 3 (Yellow) | Diamond with inner rotating triangle core |
| 4 (Red) | Slit with energy jets pulsing from endpoints |
| 5 (Black) | Singularity with orbiting accretion ring + particle vortex |

**Elite Extras**:
- Trail: Wider, brighter, dual-color fade (accent → white → transparent)
- Death explosion: 150-200 particles in golden-ratio spiral pattern + ring burst
- Shield: 3 orbiting stars instead of 1 diamond icon

**Unlock Moment** (during gameplay when score hits 100):
- Special ascending chime SFX
- Golden expanding ring VFX from player
- Brief "ELITE UNLOCKED" text flash (1.5s)
- Heavy haptic

**Persistence**: `StorageService` → `elite_unlocked: bool` in SharedPreferences

**Files**: `constants.dart`, `game_engine.dart`, `game_painter.dart`, `game_screen.dart`, `storage_service.dart`, `audio_service.dart`

### Feature 3: Milestone Tier System (5 Tiers, Persistent)

**Concept**: Your ALL-TIME high score earns permanent prestige tiers — visible on menu + death screen.

| Tier | Threshold (Hard) | Threshold (Easy) | Color |
|------|-----------------|-----------------|-------|
| None | 0-49 | 0-79 | — |
| Bronze | 50 | 80 | Copper (#CD7F32) |
| Silver | 100 | 160 | Silver (#C0C0C0) |
| Gold | 200 | 320 | Gold (#FFD700) |
| Diamond | 350 | 560 | Cyan (#00E5FF) |
| Obsidian | 500 | 800 | Iridescent Purple (#9C27B0) |

**Display**:
- **Menu**: Below "BEST: X" → "◆ GOLD" in tier color
- **Death screen**: Tier badge next to score, color-coded
- **HUD**: Tiny colored dot next to score

**Tier-Up Event** (first time earning new tier, shown on death screen):
- "TIER UNLOCKED: GOLD ◆" with expansion animation
- Unique resonant chord SFX
- Persisted: `milestone_tier: int` in SharedPreferences

**Files**: `constants.dart`, `storage_service.dart`, `death_screen.dart`, `menu_screen.dart`, `game_screen.dart`, `audio_service.dart`

### Feature 4: Personal Best Proximity (Visceral Tension)

**Concept**: When your current score nears your high score, the game visually intensifies — no text, pure feel.

- `score >= highScore - 5` (and highScore > 10): Screen edges pulse with accent color
- `score == highScore`: Flash + heartbeat haptic
- `score > highScore` (new record territory): Trail 1.5x longer, ambient particles intensify

**Files**: `game_engine.dart`, `game_painter.dart`, `game_screen.dart`

### Feature 5: Session Best + Streak Counter

**Session Best**: Track best score of current app session (non-persisted). Show "SESSION BEST" on death screen if this run was session best but not all-time best. Encourages "one more game."

**Streak Counter**: Track consecutive days played.
- `lastPlayDate` + `streakCount` in SharedPreferences
- Show "🔥 X-DAY STREAK" on menu screen at streak >= 2
- Increments when today > lastPlayDate

**Files**: `game_engine.dart`, `death_screen.dart`, `menu_screen.dart`, `storage_service.dart`

---

## EDGE CASES

1. Shield particles now properly decay during gameplay (V1 fix)
2. Easy mode thresholds scaled for praise (120), tiers (1.6x)
3. Elite unlock works in both modes, during revived runs
4. Phase 5 inversion respected by all elite/tier visuals
5. Light + dark theme: all new colors tested against both backgrounds
6. Near-high-score disabled when highScore <= 10
7. Multiple milestones in same frame: only highest triggers
8. Streak uses local date — no timezone issues
9. First-run: no tier shown, no session best shown
10. Storage migration: new keys default to false/0, backward compatible

---

## IMPLEMENTATION ORDER

1. V1 Fix: Shield particle decay bug
2. StorageService: Add elite_unlocked, milestone_tier, streak keys
3. Constants: Add 200 praise messages, milestone colors, elite thresholds
4. Providers: Add eliteUnlocked, milestoneTier state providers
5. GameEngine: Praise deck, getDeathMessage(), elite unlock, session best, near-high-score
6. AudioService: Elite unlock SFX, tier-up SFX
7. GamePainter: Elite ball (5 phases), elite trail, elite death, near-high-score edge glow
8. GameScreen: Wire unlock events, haptics, pass elite state
9. DeathScreen: Praise vs roast, tier badge, tier-up animation, session best
10. MenuScreen: Tier badge, streak counter
11. Build + test all phases, both modes, both themes
