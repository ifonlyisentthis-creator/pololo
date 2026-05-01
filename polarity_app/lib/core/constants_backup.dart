import 'dart:ui';

class GameConstants {
  GameConstants._();

  // ── Physics ──
  static const double baseMagnetForce = 2400.0;
  static const double maxHorizontalSpeed = 900.0;
  static const double playerRadius = 10.0;

  // ── Obstacle generation ──
  static const double obstacleMinThickness = 14.0;
  static const double obstacleMaxThickness = 22.0;
  static const double obstacleSpacing = 200.0;
  static const double obstacleSpacingJitter = 0.25; // ±25% random variance
  static const double baseScrollSpeed = 220.0;

  // Per-phase obstacle spacing multiplier (lower = denser = harder)
  static const List<double> phaseSpacingMultipliers = [
    1.15, // Phase 1: comfortable warmup
    0.98, // Phase 2: real game pace
    0.84, // Phase 3: tight rhythm
    0.72, // Phase 4: relentless
    0.62, // Phase 5: god-tier density
  ];

  // Per-phase same-side repeat chance (higher = more unpredictable)
  static const List<double> phaseSameSideChances = [
    0.10, // Phase 1: mostly alternating
    0.18, // Phase 2: occasional surprise
    0.25, // Phase 3: keeps you guessing
    0.32, // Phase 4: chaotic
    0.38, // Phase 5: maximum chaos
  ];

  // ── Safe spawn delay (seconds before first obstacle) ──
  static const double safeSpawnDelay = 0.8;

  // ── 5 Visual & Difficulty Phases ──
  // Phase 1: 0-40    Pure White on Pitch Black (warmup)
  // Phase 2: 41-120  Electric Blue (real game starts)
  // Phase 3: 121-250 Warning Yellow (tighter, faster snaps)
  // Phase 4: 251-420 Crimson Red (brutal, narrow gaps)
  // Phase 5: 421+    Inverted (white bg / black geo), max everything
  static const List<int> phaseThresholds = [0, 41, 121, 251, 421];

  static const List<Color> phaseColors = [
    Color(0xFFFFFFFF), // Phase 1: Pure White
    Color(0xFF007AFF), // Phase 2: Electric Blue
    Color(0xFFFFD60A), // Phase 3: Warning Yellow
    Color(0xFFFF3B30), // Phase 4: Crimson Red
    Color(0xFF000000), // Phase 5: Black (inverted theme)
  ];

  // Speed multipliers per phase (scroll speed × this)
  static const List<double> phaseSpeedMultipliers = [
    1.0,
    1.20,
    1.45,
    1.75,
    2.10,
  ];

  // Magnet multipliers (lateral pull × this)
  static const List<double> phaseMagnetMultipliers = [
    0.50,
    0.68,
    0.90,
    1.15,
    1.45,
  ];

  // Gap shrink factors per phase (1.0 = widest, lower = narrower gaps)
  static const List<double> phaseGapFactors = [1.0, 0.88, 0.74, 0.62, 0.52];

  // ── Shield ──
  // First shield at 20, second at 60, then x2 each time
  static const int firstShieldScore = 20;
  static const int secondShieldScore = 60;
  static const double shieldInvincibilityDuration = 3.0;

  // ── Ads (Time-only Lock) ──
  static const int interstitialMinIntervalSeconds = 70;
  static const double iapPrice = 2.99;
  static const String iapProductId = 'remove_ads';

  // AdMob Test IDs (swap with production IDs before release)
  static const String androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String androidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  // ── Revive ──
  static const double reviveInvincibilityDuration = 3.0;
  static const int reviveCountdownSeconds = 3;

  // ── Tutorial ──
  static const int tutorialFadeScore = 3;

  // ── Review ──
  static const int minScoreForReview = 20;

  // ── Privacy ──
  static const String privacyPolicyUrl = 'https://example.com/privacy';

  // Store-friendly low-score rage-bait deaths.
  static const List<String> deathRoasts = [
    "delete the game? no, you owe me one cleaner run",
    "who let u download this lmao",
    "the wall sent a thank-you note",
    "that was a speedrun to the retry button",
    "bro treated the obstacle like a checkpoint",
    "the tutorial just cleared its throat",
    "u zigged exactly when the game asked for a zag",
    "that attempt had confidence and no evidence",
    "restart button getting more screen time than the ball",
    "the wall barely had to clock in",
    "delete the game after one more run, obviously",
    "u and that wall are getting way too close",
    "the obstacle saw u coming and relaxed",
    "that was brave, not correct, but brave",
    "the ball filed a tiny complaint",
    "u made the easy part look exclusive",
    "the retry button is warming up again",
    "that run lasted exactly one bad idea",
    "bro found the only wrong lane with style",
    "the gap was right there doing jazz hands",
    "u tapped like the wall owed u money",
    "please put that strategy back where u found it",
    "that was not gameplay, that was a plot twist",
    "the scoreboard blinked twice and looked away",
    "u almost avoided the wall, spiritually",
    "that was a limited edition L",
    "the obstacle did not even have to be dramatic",
    "delete game? maybe delete that tactic first",
    "u played that like the walls were optional",
    "the ball wanted freedom and u chose architecture",
    "that route was decorative, not survivable",
    "bro entered the wall subscription plan",
    "the restart button just whispered welcome back",
    "u made the first obstacle feel famous",
    "that was a bold audition for the wall team",
    "i respect the confidence, not the result",
    "the gap had a vacancy and u ignored it",
    "u invented a new way to arrive nowhere",
    "that move was sponsored by panic",
    "the wall said please and u said sure",
  ];
}
