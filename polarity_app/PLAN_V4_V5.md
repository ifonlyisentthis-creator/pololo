# V3 Fixes + V4 Troll System + V5 Audit — Implementation Plan

---

## V3 Fix 1: Theme Persistence After Death

**Problem:** `startGame()` resets `activeTheme = null` and `currentThemeTier = 0`. If user dies at score 120 (tier 1 theme active), restarting loses the theme completely. User expects the earned theme to persist.

**Solution:**
- In `game_engine.dart` `startGame()`: Remove the lines that reset `activeTheme` and `currentThemeTier` to null/0.
- Instead, preserve the theme from the previous run. Only reset `themeJustActivated` and `themeTransitionTimer` (VFX flags).
- The theme tier and active theme naturally get overwritten when `_checkThemeTransition()` hits a new milestone during gameplay.
- Edge case: If score was 150 and they restart, `currentThemeTier` stays at 1 with the last theme active. When they hit 100 again, `_checkThemeTransition()` checks `newTier > currentThemeTier` — but since both are 1, it won't re-trigger. This is correct: the theme persists until a *new* tier (200) is reached.
- **BUT:** If player hit score 250 (tier 2) then dies, restarts and reaches 100 — tier 1 < tier 2, so no trigger. Then at 200, tier 2 == currentThemeTier, no trigger. Theme stays from last run's tier 2. Need to handle this: On `startGame()`, keep the *previous* theme active but reset `currentThemeTier = 0` so milestones re-trigger each run.
- **Actually the correct approach:** Keep `activeTheme` from previous run (visual persistence), but reset `currentThemeTier = 0` so each score milestone re-triggers in the new run. The theme selection rotation already advanced, so they'll get a *different* theme variant at the same score next time. This gives the best behavior: theme persists visually, and new themes activate at each milestone.

**Files:** `game_engine.dart`

---

## V3 Fix 2: Performance Optimization

**Problem:** Choppy/jittery animations, especially death effects. High particle counts, excessive MaskFilter.blur, and complex path computations every frame.

**Root causes identified:**
1. **MaskFilter.blur on every particle** — trail_painters.dart uses MaskFilter on every single trail/death particle. Blur is GPU-expensive. With 100-300 explosion particles + trail particles all blurred, this kills performance.
2. **Path recomputation per frame** — BallPainters rebuilds complex paths (spiral with 80 steps, helix with 60 steps, tesseract with 16 vertices + connections) every single frame.
3. **Explosion particle counts too high** — Tier 4/5 themes have 200-300 explosion particles, each with individual blur. Low-end devices choke.
4. **withInversion() creates new VisualTheme objects every paint call** — `ThemeRenderer` methods call `theme.withInversion()` on every render frame.
5. **No particle count budget** — Trail, ambient, magnet, and death particles all run uncapped in aggregate.

**Solution — preserve same look, optimize rendering:**

### A. Cache `withInversion()` result
- In `game_engine.dart`: Add `VisualTheme? _invertedThemeCache` field. When `activeTheme` changes or `isPhase5Inverted` changes, recompute once. Pass the correct theme directly to painter instead of letting renderer call `withInversion()` per frame.
- In `game_painter.dart`: Compute `effectiveTheme` once in `paint()`, pass it to all `ThemeRenderer` calls.

### B. Cap particle counts with performance budgets
- Max explosion particles: 100 (clamp down from 200-300 in tier 4/5 themes). The visual density is still high, just capped.
- Max trail particles: 80 total across all types. Already mostly capped but enforce strictly.
- Max death particles rendered per frame: 100 (skip oldest when over budget).
- Max ambient particles: 25 (already done).

### C. Reduce MaskFilter.blur usage
- **Trail particles:** Remove MaskFilter from simple trail styles (dots, streaks, embers, shadows). Only keep blur on styles where it's essential (sparkles, flames, lightning). This is the single biggest performance win.
- **Death particles:** Same — remove blur from simple trail styles used for death.
- **Ball painters:** Keep blur for glow auras (1-2 blurs per frame is fine), but remove redundant secondary blurs.

### D. Simplify complex ball shapes
- Spiral (80-step path), Helix (60-step path), Tesseract (24 vertices + connections): Reduce step counts by ~40% (spiral: 40 steps, helix: 30 steps). Visual difference is negligible at small ball radius.

### E. Object allocation reduction
- `Paint()` objects are created per-particle per-frame. For hot loops (trail/death rendering), create a single reusable Paint and just change color/alpha properties.
- Gradient shaders in obstacle rendering: Avoid LinearGradient().createShader() per obstacle per frame — cache the shader.

**Files:** `theme_renderer.dart`, `trail_painters.dart`, `ball_painters.dart`, `explosion_painters.dart`, `game_painter.dart`, `game_engine.dart`, `visual_theme.dart`

---

## V4: Troll/Easter Egg System

### Design:

**Session game counter:** Track `_sessionGameCount` in `GameEngine` (not persisted — session only). Incremented on each `startGame()` call. Reset when app closes.

**Trigger logic:**
- Every 10th game (10, 20, 30, 40...) triggers a troll event.
- Only counts if games are consecutive within the session (the counter is session-only, so closing the app resets it).
- Troll appears during gameplay after a short delay (3-5 seconds in).

**20 Hardcoded Troll Events:**
Each troll has: type, duration, visual behavior, and a troll ball (secondary ball rendered on screen).

1. **Mirror Ball** — A ghost ball mirrors your X position exactly
2. **Opposite Ball** — Ghost ball moves to the opposite X position
3. **Orbit Ball** — Ghost ball orbits around the player
4. **Drunk Ball** — Ghost ball wobbles randomly near player
5. **Speed Demon** — Ghost ball races ahead of obstacles
6. **Copycat Delay** — Ghost ball copies player position with 500ms delay
7. **Gravity Flip** — Ghost ball falls upward (visual only)
8. **Strobe Ball** — Ghost ball rapidly blinks in/out
9. **Size Shift** — Ghost ball grows/shrinks continuously
10. **Shadow Clone** — 3 transparent copies of the player
11. **Reverse Magnet** — Ghost ball repels from the player
12. **Zigzag** — Ghost ball zigzags across the screen
13. **Bouncer** — Ghost ball bounces off walls
14. **Spinner** — Ghost ball spins in circles at screen center
15. **Stalker** — Ghost ball slowly approaches player then runs away
16. **Teleporter** — Ghost ball randomly teleports every 2 seconds
17. **Wave Rider** — Ghost ball follows a sine wave pattern
18. **Phase Ghost** — Ghost ball phases through obstacles visually
19. **Shrinking Ring** — Ghost ball traces a shrinking spiral
20. **Fake Death** — Screen briefly flashes as if you died (0.3s), then continues

**DFA beyond 20:** Use deterministic seed (sessionGameCount) to combine behaviors: ball movement from one troll + visual effect from another.

**Rage-bait death messages (20):** If user dies while troll is active, show one of these instead of normal roast/praise:

1. "hawww 😂😂😂😂"
2. "cry about it 😂😂😂😂"
3. "yess I did that lmaoooo 😂😂😂😂"
4. "✌️😂😂😂😂"
5. "😂😂😂😂😂"
6. "that was ME btw 😂😂😂😂"
7. "u fell for it LMAOOO 😂😂😂😂"
8. "get trolled bozo ✌️😂😂"
9. "skill issue fr fr 😂😂😂😂"
10. "imagine dying to a joke 😂😂✌️"
11. "I literally warned u lmao 😂😂😂😂"
12. "hehehehe 😂😂😂😂😂"
13. "too easy 😂😂✌️✌️"
14. "mission accomplished ✌️😂😂😂😂"
15. "not my fault u panicked 😂😂😂😂"
16. "lol lol lol lol lol 😂😂😂😂"
17. "gotcha ✌️✌️😂😂😂😂"
18. "u mad? 😂😂😂😂😂"
19. "stay mad bestie 😂✌️😂✌️"
20. "absolutely rekt 😂😂😂😂✌️"

**Visual design:**
- Troll ball rendered as semi-transparent (alpha 0.4) version with a subtle glow
- Uses the current theme/accent color with a slight color shift (hue rotate +30°)
- Does NOT affect collision — purely visual
- Appears with a small pop animation (scale 0->1 over 0.3s)
- Disappears with a fade-out (alpha 1->0 over 0.5s)
- Duration: 8-12 seconds depending on troll type

**Fisher-Yates shuffled deck** for troll selection (no repeats).

### New files:
- `lib/features/game/troll/troll_system.dart` — TrollEvent data class, TrollSystem state machine, 20 hardcoded events, rage-bait messages, DFA generator
- No new painter file — troll ball rendering integrated into existing `game_painter.dart` via a simple method.

### Modified files:
- `game_engine.dart` — Add `TrollSystem` instance, session game counter, troll update in `_updatePlaying()`, troll death message override
- `game_painter.dart` — Add `_drawTrollBall()` method
- `game_screen.dart` — Poll troll events for haptic/audio

---

## V5: Deep Audit Checklist

### Cross-cutting concerns to verify:

1. **All 5 difficulty phases** — Every visual element respects phase speed/magnet/gap multipliers
2. **Both UI themes** (light/dark) — All custom rendering uses `bgColor`/`fgColor` correctly
3. **Both modes** (easy/hard) — Wall collision, shield timing, tier calculation, praise threshold
4. **Phase 5 inversion** — All themed + classic visuals contrast correctly on white background
5. **Revive flow** — All state properly reset, no stale flags, theme persists, troll state handled
6. **Theme system** — All 50 themes + DFA + rotation persistence + Phase 5 inversion for bright themes
7. **Troll system** — Session-only counter, proper cleanup on death/revive, no collision interference
8. **Memory safety** — Particle lists bounded, no unbounded growth, proper cleanup
9. **Frame-rate independence** — All animations use `dt` or `pow()` correctly
10. **Race conditions** — One-shot flags consumed immediately, no stale state across screens

### Specific bugs to hunt:
- Shield pickup during troll: should work normally
- Elite unlock during theme: should work normally
- Milestone celebration during troll: should work normally
- Troll active + revive: troll should end
- Theme transition during troll: should work, troll visual adapts
- DFA theme at 550+ during troll: should work
- Death during countdown (impossible but verify guard)
- Double-tap restart during death animation
- Near-high-score tension with theme active

**Files to audit:** All game files touched in V1-V4.

---

## Implementation Order:

1. V3 Fix 1 (theme persistence) — 1 file, 5 lines
2. V3 Fix 2 (performance) — 6 files, focused edits
3. V4 (troll system) — 1 new file + 3 modified files
4. V5 audit — Review all edge cases, fix any issues found
5. `flutter analyze` + `flutter build apk --debug`
