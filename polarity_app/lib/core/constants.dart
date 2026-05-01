import 'dart:ui';

class GameConstants {
  GameConstants._();

  // ── Physics ──
  static const double baseMagnetForce = 2600.0;
  static const double maxHorizontalSpeed = 920.0;
  static const double playerRadius = 10.0;

  // ── Obstacle generation ──
  static const double obstacleMinThickness = 14.0;
  static const double obstacleMaxThickness = 22.0;
  static const double obstacleSpacing = 200.0;
  static const double obstacleSpacingJitter = 0.20; // ±20% random variance
  static const double baseScrollSpeed = 220.0;

  // Per-phase obstacle spacing multiplier (lower = denser = harder)
  static const List<double> phaseSpacingMultipliers = [
    1.15, // Phase 1: comfortable warmup
    1.00, // Phase 2: real game pace
    0.86, // Phase 3: tight rhythm
    0.74, // Phase 4: relentless
    0.64, // Phase 5: god-tier density
  ];

  // Per-phase max consecutive same-side obstacles (enforced in game_engine)
  // Phase 1-2: 2, Phase 3-4: 3, Phase 5: 4

  // ── Safe spawn delay (seconds before first obstacle) ──
  static const double safeSpawnDelay = 0.8;

  // ── 5 Visual & Difficulty Phases ──
  // Phase 1: 0-40    Pure White on Pitch Black (warmup)
  // Phase 2: 41-120  Electric Blue (real game starts)
  // Phase 3: 121-250 Warning Yellow (tighter, faster snaps)
  // Phase 4: 251-420 Crimson Red (brutal, narrow gaps)
  // Phase 5: 421+    Inverted (white bg / black geo), max everything
  static const List<int> phaseThresholds = [0, 50, 130, 260, 430];

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
    1.18,
    1.40,
    1.65,
    1.92,
  ];

  // Magnet multipliers (lateral pull × this)
  static const List<double> phaseMagnetMultipliers = [
    0.55,
    0.72,
    0.92,
    1.15,
    1.40,
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

  // AdMob IDs can be overridden with --dart-define for production.
  static const String androidAppId = String.fromEnvironment(
    'ANDROID_ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-4151123662328725~3767987674',
  );
  static const String iosAppId = String.fromEnvironment(
    'IOS_ADMOB_APP_ID',
    defaultValue:
        'ca-app-pub-3940256099942544~1458002511', // TODO: replace with iOS production ID
  );

  static const String androidBannerId = String.fromEnvironment(
    'ANDROID_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
  static const String iosBannerId = String.fromEnvironment(
    'IOS_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716',
  );
  static const String androidInterstitialId = String.fromEnvironment(
    'ANDROID_INTERSTITIAL_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-4151123662328725/3311844641',
  );
  static const String iosInterstitialId = String.fromEnvironment(
    'IOS_INTERSTITIAL_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );
  static const String androidRewardedId = String.fromEnvironment(
    'ANDROID_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-4151123662328725/6877578771',
  );
  static const String iosRewardedId = String.fromEnvironment(
    'IOS_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );

  // Leaderboard IDs. Override with --dart-define.
  static const String androidLeaderboardId = String.fromEnvironment(
    'ANDROID_LEADERBOARD_ID',
    defaultValue: 'CgkI8OfvjJcWEAIQAQ',
  );
  static const String iosLeaderboardId = String.fromEnvironment(
    'IOS_LEADERBOARD_ID',
    defaultValue: 'polarity_leaderboard',
  );

  // ── Revive ──
  static const double reviveInvincibilityDuration = 3.0;
  static const int reviveCountdownSeconds = 3;

  // ── Tutorial ──
  static const int tutorialFadeScore = 5;

  // ── Review ──
  static const int minScoreForReview = 20;

  // ── Privacy ──
  static const String privacyPolicyUrl = 'https://polarityprivacy.netlify.app/';

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
    "u turned a 1-tap game into paperwork",
    "that attempt left without saying goodbye",
    "bro took the scenic route into trouble",
    "the ball needs a tiny roadmap",
    "u were cooking, but the recipe was walls",
    "that was a masterclass in almost",
    "the obstacle politely accepted ur donation",
    "u found the express lane to restart",
    "delete the game? nah, the game wants a rematch",
    "the wall is not a collectible",
    "that was less dodge, more handshake",
    "u moved like the safe gap had bad reviews",
    "the leaderboard remained emotionally neutral",
    "bro saw danger and called it a destination",
    "the next run has requested different choices",
    "that mistake had premium timing",
    "u gave the wall a free highlight clip",
    "the obstacle was stationary and still outplayed u",
    "that was one tap away from common sense",
    "u treated the retry button like a loyalty program",
    "the wall just got promoted",
    "that run had side quest energy",
    "u almost had it, in an alternate timeline",
    "the ball would like a different manager",
    "that was not a lane, that was a rumor",
    "bro speedran the learning experience",
    "the game asked for focus and got improv",
    "that gap was waving like hello??",
    "u made the wall feel useful",
    "the retry button is carrying the brand",
    "that was a tiny disaster with excellent pacing",
    "u brought chaos to a straight line",
    "the obstacle barely moved and still ate",
    "delete this tactic immediately",
    "u and clean movement are currently on a break",
    "the wall saw ur plan and approved it",
    "that run had no business ending that quickly",
    "the ball deserved a better itinerary",
    "u missed the gap with suspicious precision",
    "that was pure confidence with zero steering",
    "bro got folded by geometry",
    "the wall did not chase u, remember that",
    "u made the simple path look rare",
    "that attempt got archived instantly",
    "the obstacle is putting that on its resume",
    "u turned left, right, and somehow wrong",
    "that was not a skill check, it was a vibe check",
    "the game paused internally to process that",
    "u went directly from start to excuse me??",
    "the wall asked no questions and collected points",
    "delete the game? maybe after beating ur score first",
    "that was a certified retry moment",
    "u made the ball look unsupervised",
    "the gap was available for a limited time",
    "bro got out-negotiated by a rectangle",
    "that line choice was extra crunchy",
    "the score counter barely had time to wake up",
    "u chose the wall with your whole heart",
    "that was not clean, but it was memorable",
    "the obstacle said thanks for visiting",
    "u created a new category: decorative movement",
    "the restart button just got employee of the month",
    "that run was over before the music believed in it",
    "u missed safety by a confident mile",
    "the wall remains undefeated in this household",
    "bro made the gap feel ignored",
    "that was a quick tour of what not to do",
    "the ball asked for space and got a wall",
    "u did not lose, u delivered content",
    "the obstacle had popcorn ready",
    "that attempt needs a gentle rewrite",
    "u are not beating the wall friendship allegations",
    "delete the game? no, delete that route",
    "that was legally a run, emotionally a shrug",
    "the next obstacle is already smirking",
    "u made the screen say really? without words",
    "that move had no map and plenty of attitude",
    "bro discovered gravity-adjacent decision making",
    "the wall got exactly what it wanted",
    "u played chicken with architecture and blinked late",
    "that was a small L in a fancy jacket",
    "the game is politely requesting a do-over",
    "u found the wrong answer with premium accuracy",
    "that run had retry written all over it",
  ];

  // ── Praise score thresholds ──
  static const int praiseThreshold = 75;

  // ── Elite unlock ──
  static const int eliteUnlockScore = 100;

  // ── Milestone tiers ──
  static const List<int> milestoneTiers = [0, 50, 100, 200, 350, 500];
  static const List<String> tierNames = [
    '',
    'BRONZE',
    'SILVER',
    'GOLD',
    'DIAMOND',
    'OBSIDIAN',
  ];
  static const List<Color> tierColors = [
    Color(0x00000000), // None
    Color(0xFFCD7F32), // Bronze
    Color(0xFFC0C0C0), // Silver
    Color(0xFFFFD700), // Gold
    Color(0xFF00E5FF), // Diamond
    Color(0xFF9C27B0), // Obsidian
  ];

  // ── In-game milestone celebration scores ──
  static const List<int> milestoneScores = [25, 50, 100, 200, 300, 400, 500];

  // Store-friendly praise deaths shown after strong runs.
  static const List<String> deathPraises = [
    "that run was clean enough to frame",
    "ok that score actually had aura",
    "the scoreboard stood up for that one",
    "u were gliding and i was taking notes",
    "that was genuinely smooth",
    "clean movement, rough ending, huge respect",
    "that score did not happen by accident",
    "u were cooking until the wall interrupted dinner",
    "the ball looked expensive that run",
    "i need the replay because that was crisp",
    "that was main character movement",
    "u made the hard part look casual",
    "the leaderboard definitely noticed",
    "that run had rhythm",
    "u almost made the obstacles look polite",
    "that score deserves a tiny spotlight",
    "i was quiet because i was impressed",
    "that was a very serious run from a very unserious game",
    "u put together an actual highlight reel",
    "that ending was rude to a beautiful run",
    "the wall got lucky and knows it",
    "that was smooth with receipts",
    "u had the game behaving for a while there",
    "that score has presence",
    "i respect every tap in that run",
    "the obstacles were sweating politely",
    "that was the kind of run that changes the lobby mood",
    "u were locked in and it showed",
    "that finish does not erase the sauce",
    "the ball moved like it had a plan",
    "that score is staying on the fridge",
    "u made chaos look organized",
    "the game needed a moment after that",
    "that run had clean lines and brave choices",
    "the scoreboard is glowing for a reason",
    "u played like the gap owed u rent",
    "that was seriously good",
    "the ending was messy, the run was not",
    "u turned pressure into choreography",
    "that score deserves another attempt immediately",
    "the wall interrupted art",
    "u were one calm breath away from magic",
    "that was sharp, fast, and very real",
    "the game is saving that one in its memory",
    "u made the early game look sleepy",
    "the ball had premium footwork",
    "that run had momentum and manners",
    "u earned every point on that board",
    "that was not luck, that was timing",
    "the ending was temporary, the score is permanent",
    "u made the screen look fluent",
    "that run deserves a respectful nod",
    "the obstacles got a little nervous there",
    "u were threading gaps like a pro",
    "that score walked in with confidence",
    "i would absolutely run that back",
    "that was a clean climb",
    "u made the ball look legendary for a minute",
    "the wall clipped a masterpiece",
    "that attempt had championship posture",
    "u played with real control",
    "that score has weight",
    "the run ended, the respect did not",
    "u were moving like the game slowed down for u",
    "that was elite focus",
    "the scoreboard is still processing the glow-up",
    "u gave the game a proper workout",
    "that route selection was mostly chef-grade",
    "the finish was loud, the run was louder",
    "that score says run it back",
    "u had the rhythm pinned down",
    "that was far too good to stop here",
    "the wall got the final word, not the best one",
    "u played that like u knew the future",
    "that run had patience and snap",
    "the game is impressed and trying to act normal",
    "that score belongs in the nice column",
    "u made every point feel earned",
    "that was a polished little rocket of a run",
    "the ending was one frame of nonsense after a lot of skill",
  ];

  // Store-friendly easter egg self-blame deaths.
  static const List<String> easterEggDeathMessages = [
    "that one is on me, i put drama where a gap should be",
    "i owe your next run a calmer lane",
    "my obstacle timing got too spicy, sorry",
    "u deserved a door and i gave u a wall",
    "i will be more reasonable next run, probably",
    "that wall was freelancing and i should have stopped it",
    "i apologize to your thumbs personally",
    "i made that harder than it needed to be",
    "that ending was my bad, the paperwork is already filed",
    "i placed that obstacle with zero emotional intelligence",
    "u were playing well and i got nervous",
    "that route deserved better hosting from me",
    "i accept full responsibility for that suspicious wall",
    "i let the obstacle get too confident",
    "that was not the welcome mat i meant to roll out",
    "i owe u one very smooth opening",
    "my level design got dramatic again",
    "that was my corner, not your mistake",
    "i saw your good run and forgot how to behave",
    "i will tell the next wall to relax",
    "that obstacle was supposed to be decorative",
    "i fumbled the layout and u paid for it",
    "please accept this sincere digital apology",
    "i should have moved that wall two pixels to the left",
    "that gap had poor customer service and i apologize",
    "i made the lane weird and i know it",
    "u brought skill and i brought a wall, unfair trade",
    "i can be better than that obstacle placement",
    "that was me getting carried away with rectangles",
    "i owe the ball a safer commute",
    "your run deserved a softer ending",
    "i briefly forgot this was supposed to be playable",
    "that wall was overacting and i encouraged it",
    "i am sending the obstacle to etiquette class",
    "the timing was rude and i take that seriously",
    "i gave u chaos when u deserved clarity",
    "that one goes in my apology folder",
    "i should not have trusted that wall unsupervised",
    "u were doing great and my geometry panicked",
    "i will try not to place nonsense next time",
    "that was a layout oops with a dramatic exit",
    "i owe your score a cleaner runway",
    "my bad, the wall got main character energy",
    "i designed that moment with my eyes metaphorically closed",
    "that obstacle owes both of us an apology",
    "i put a wall where hope should have been",
    "that ending was not up to my standards",
    "i let the level get smug and i regret it",
    "u trusted me and i handed u a rectangle",
    "i am taking notes and the notes say be nicer",
    "that wall was too eager, fully noted",
    "i owe u a run that does not do that",
    "my spacing got theatrical and i apologize",
    "that was a tiny design tantrum from me",
    "i placed the obstacle like it had a personal agenda",
    "u deserved cleaner geometry",
    "i am refunding that wall emotionally",
    "that one should have been a gap and we both know it",
    "i let the difficulty wear fancy shoes indoors",
    "my sincere apologies from every pixel on screen",
    "that route got messy under my supervision",
    "i will keep the next wall on a shorter leash",
    "u were graceful, my wall was not",
    "that mistake belongs to the game side of the table",
    "i am revising my relationship with obstacles",
    "that wall had too much confidence and not enough manners",
    "i owe u a better ending than that",
    "your thumbs deserved a kinder timeline",
    "i made the run weird and i will reflect",
    "that obstacle placement was deeply unserious",
  ];

  /// Get the milestone tier (0-5) for a given high score.
  static int getTier(int highScore) {
    final tiers = milestoneTiers;
    int tier = 0;
    for (int i = tiers.length - 1; i >= 0; i--) {
      if (highScore >= tiers[i]) {
        tier = i;
        break;
      }
    }
    return tier;
  }
}
