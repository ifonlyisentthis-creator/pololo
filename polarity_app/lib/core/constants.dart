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
    1.0, 1.18, 1.40, 1.65, 1.92,
  ];

  // Magnet multipliers (lateral pull × this)
  static const List<double> phaseMagnetMultipliers = [
    0.55, 0.72, 0.92, 1.15, 1.40,
  ];

  // Gap shrink factors per phase (1.0 = widest, lower = narrower gaps)
  static const List<double> phaseGapFactors = [
    1.0, 0.88, 0.74, 0.62, 0.52,
  ];

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
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
  );
  static const String iosAppId = String.fromEnvironment(
    'IOS_ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~1458002511',
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
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const String iosInterstitialId = String.fromEnvironment(
    'IOS_INTERSTITIAL_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );
  static const String androidRewardedId = String.fromEnvironment(
    'ANDROID_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const String iosRewardedId = String.fromEnvironment(
    'IOS_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );

  // Leaderboard IDs (total + separate hard/easy boards). Override with --dart-define.
  static const String androidLeaderboardTotalId = String.fromEnvironment(
    'ANDROID_LEADERBOARD_TOTAL_ID',
    defaultValue: 'CgkI_placeholder_leaderboard_total',
  );
  static const String iosLeaderboardTotalId = String.fromEnvironment(
    'IOS_LEADERBOARD_TOTAL_ID',
    defaultValue: 'polarity_leaderboard_total',
  );
  static const String androidLeaderboardHardId = String.fromEnvironment(
    'ANDROID_LEADERBOARD_HARD_ID',
    defaultValue: 'CgkI_placeholder_leaderboard',
  );
  static const String androidLeaderboardEasyId = String.fromEnvironment(
    'ANDROID_LEADERBOARD_EASY_ID',
    defaultValue: 'CgkI_placeholder_leaderboard_easy',
  );
  static const String iosLeaderboardHardId = String.fromEnvironment(
    'IOS_LEADERBOARD_HARD_ID',
    defaultValue: 'polarity_leaderboard',
  );
  static const String iosLeaderboardEasyId = String.fromEnvironment(
    'IOS_LEADERBOARD_EASY_ID',
    defaultValue: 'polarity_leaderboard_easy',
  );

  // ── Revive ──
  static const double reviveInvincibilityDuration = 3.0;
  static const int reviveCountdownSeconds = 3;

  // ── Tutorial ──
  static const int tutorialFadeScore = 3;

  // ── Review ──
  static const int minScoreForReview = 20;

  // ── Privacy ──
  static const String privacyPolicyUrl = 'https://example.com/privacy';

  // ── death roasts (300) ──
  static const List<String> deathRoasts = [
    "DELETE THE GAME DELETE THE GAME DELETE THE GAME 😭😭😭😭😭",
    "bro please i am on my KNEES begging u to stop playing 😭😭😭😭",
    "please please please please delete this game 😭😭😭😭😭😭",
    "pls go outside pls touch grass pls do anything else 😭😭😭😭",
    "i'm literally shaking rn that was so bad 😭😭😭😭😭",
    "bro unlocked a new difficulty: braindead 😂😂😂",
    "the app store just emailed me asking what's wrong with u 😭😭😭",
    "i showed ur replay to AI and it refused to analyze it 😭😭😭😭",
    "DELETE. THE. APP. I AM NOT ASKING. 😭😭😭😭😭😭😭",
    "even the ads feel embarrassed showing up after that 😭😭😭",
    "u would lose at a game with no obstacles 😂😂😂😂😂",
    "i just told the other games about u and they laughed 😭😭😭",
    "ur ancestors survived wars for THIS??? 😂😂😂😂",
    "pov: u peaked at the loading screen 😭😭",
    "BRO. STOP. PLAYING. PLEASE. I AM BEGGING. 😭😭😭😭😭😭",
    "i just cried and i don't even have eyes 😭😭😭😭",
    "ur phone just asked me if it can be used by someone else 😂😂😂",
    "u just set the world record for fastest L in history 😭😭",
    "the obstacles called a meeting and agreed u don't need them to lose 😂😂😂",
    "im this close to adding a 'please stop' button 😂😂😂",
    "bro played for 0.2 seconds and said 'ight imma head out' 😂😂😂😂",
    "pls for the love of god just watch someone else play 😂😂",
    "i've seen better gameplay from a potato 😭😭😭",
    "WHAT WAS THAT 😭😭😭😭😭😭😭😭😭😭",
    "whoever taught u how to use a phone needs to be arrested 😭😭😭",
    "im adding a prayer circle for ur high score 😭😭😭😭",
    "PLEASE UNINSTALL THIS IS NOT A JOKE 😭😭😭😭😭😭",
    "the game just asked me if u're doing this on purpose 😂😂😂😂😂",
    "ur gameplay makes me proud to be an algorithm bc at least i can't play this bad 😂😂😂",
    "STOP PLAYING AND GO DO LITERALLY ANYTHING ELSE 😭😭😭😭😭",
    "bro's hand-eye coordination is in a different time zone 😂😂😂",
    "i showed this to other apps and they're all laughing at u 😭😭😭😭",
    "i am SCREAMING. how is anyone this bad 😭😭😭😭😭😭",
    "did u just close ur eyes and hope for the best 😭😭😭😭",
    "DELETE IT DELETE IT DELETE IT DELETE IT 😂😭😂😭😂😭😂😭",
    "the death screen sees u more than ur home screen does 😂😂😂😂😂",
    "how did u die there. HOW. EXPLAIN. NOW. 😂😂😂😂😂😂",
    "the game is in therapy because of u 😭😭😭😭",
    "just... just go. please. i'll be ok. probably. 😭😭😭😭😭😭😭",
    "i'm begging u with every line of code in my body DELETE THIS 😂😭😂😭",
    "congratulations u've made a game feel genuine sadness 😭😭😭😭😭😭😭",
    "u are the reason this game has a death screen 😭😭😭😭😭😭",
    "no like genuinely r u ok 😭😭😭😭😭😭😭😭😭",
    "LMFAOOOOOOO NAH WHAT WAS THAT 😂😂😂😂😂😂😂😂",
    "bro. bro. BRO. 😭😭😭😭😭😭",
    "NAH U NEED TO BE STUDIED 😂😂😂😂😂😂",
    "that was genuinely upsetting to witness 😭😭😭😭😭",
    "i refuse to believe a real human did that 😂😂😂😂",
    "IM GOING TO BE SICK 😭😭😭😭😭😭😭😭",
    "bro lost to air 😂😂😂😂😂😂😂",
    "u r single-handedly the worst thing to happen to this app 😭😭😭😭😭",
    "nah nah nah nah nah delete it rn 😭😭😭😭😭",
    "someone take this man's phone away 😂😂😂😂😂😂",
    "i'm not mad i'm just disappointed. actually no i'm mad too 😭😭😭😭",
    "PUT THE PHONE DOWN. PUT IT DOWN. NOW. 😭😭😭😭😭😭😭",
    "NOOOOOOOO NOT AGAIN 😂😂😂😂😂😂😂😂",
    "ok at this point u r trolling. u HAVE to be trolling. 😭😭😭😭",
    "bro has died so many times i'm running out of roasts 😭😭😭😭😭😭",
    "the wall is starting to feel BAD for u and it's a WALL 😂😂😂😂",
    "u played that like u've never seen a screen before 😭😭😭😭😭",
    "each death is worse than the last and THAT should be impossible 😂😂😂😂😂😂",
    "bro is farming deaths at this point 😭😭😭😭",
    "do u think this is a charity?? u think i enjoy this?? 😂😂😂😂",
    "I LITERALLY CANNOT DO THIS ANYMORE 😭😭😭😭😭😭😭😭😭",
    "ur high score is genuinely embarrassing to store in memory 😂😂😂",
    "nah that was personal. u hurt me with that one 😭😭😭😭😭",
    "NO NO NO NO NO NO NO NO 😂😂😂😂😂😂😂",
    "u played that with ur FEET??? 😂😂😂😂😂😂😂",
    "if i could uninstall myself from UR phone specifically i would 😭😭😭😭😭😭",
    "genuinely asking: have u played a game before. any game. ever 😂😂😂😂",
    "u died so fast i thought the app crashed 😂😂😂😂😂",
    "WHY DO U KEEP COMING BACK 😂😂😂😂😂😂😂😂",
    "u r not improving ur r getting WORSE 😭😭😭😭😭😭",
    "this game has been out for 0 days and u already set the record for worst player ever 😭😭😭😭😭😭",
    "HELP HELP HELP HELP HELP 😭😭😭😭😭😭😭😭",
    "that was so bad i had to double-check my own rendering code 😂😂😂",
    "u would die in a game where dying isn't even possible 😭😭😭😭😭😭",
    "bro's playing with his elbows i swear 😂😂😂😂😂",
    "what did the ball do to u. why r u punishing it like this 😭😭😭😭",
    "genuinely the worst thing i've rendered since my first compile 😂😂😂😂",
    "i'm sending this death clip to ur contacts 😭😭😭😭😭😭😭",
    "i have lost all faith in u as a species 😂😂😂😂😂",
    "THIS IS ABUSE. U R ABUSING ME. A GAME. 😂😂😂😂😂😂",
    "i'm adding that death to my bug tracker bc NO WAY that was intended 😂😂😂😂",
    "u play like u WANT to see the death screen 😂😂😂😂😂😂",
    "ok genuinely close the app go for a walk and reconsider everything 😭😭😭😭😭",
    "that was the opposite of gameplay 😂😂😂😂😂",
    "the wall just said 'gg ez' 😭😭😭😭😭😭😭",
    "nah bro is COOKED cooked 😂😂😂😂😂😂😂😂",
    "how. seriously how. im not joking explain it to me how 😂😂😂😂😂😂😂",
    "i physically cannot watch another attempt pls 😭😭😭😭😭😭😭",
    "UR MAKING IT WORSE EVERY SINGLE TIME 😭😭😭😭😭😭😭😭",
    "bro has negative hand-eye coordination 😭😭😭😭😭",
    "i'm embarrassed and i don't even have feelings 😭😭😭😭😭😭",
    "u somehow failed at the one thing u had to do 😭😭😭😭😭😭",
    "bro ragdolled irl after that one i bet 😂😂😂😂😂😂",
    "I CANT BREATHE IM LAUGHING SO HARD AND I DONT HAVE LUNGS 😭😂😭😂😭😂😭😂",
    "nah that's gotta be a bot. no human is this bad 😭😭😭😭😭😭",
    "at this point the obstacle is spawn camping u 😂😂😂😂😂😂😂",
    "i am BEGGING the app store to remove me from ur phone 😂😂😂😂😂",
    "ok i'm not roasting anymore i'm just sad now 😂😂😂😂",
    "IM DONE. IM ACTUALLY DONE. I REFUSE. 😭😭😭😭😭😭😭😭😭😭",
    "i've never seen someone lose with so much confidence 😭😭😭😭😭😭😭",
    "i s2g if u die one more time i'm force closing myself 😭😭😭😭😭😭😭😭",
    "the ball and the wall are best friends now bc u introduced them SO MANY TIMES 😂😂😂😂😂😂",
    "genuinely who let u download this 😭😭😭😭😭😭😭",
    "bro turned a 1-tap game into an unsolvable puzzle 😂😂😂😂😂😂😂",
    "ok i need a break from u specifically 😭😭😭😭😭😭😭😭😭",
    "LMAOOOOOOOOOOOOOOOOOOO 😭😭😭😭😭😭😭😭😭😭",
    "BIGGEST L IN GAMING HISTORY AND ITS NOT EVEN CLOSE 😂😂😂😂😂",
    "ratio + L + fell off + died to a rectangle 😭😭😭😭😭😭",
    "HOLD THAT. HOLD THAT L. FRAME IT. PUT IT ON UR WALL. 😂😂😂😂😂",
    "nah nah nah nah nah NAH WHAT WAS THAT 😭😭😭😭😭😭😭😭",
    "LLLLLLLLLLLLLLLLLLLLL 😂😭😂😭😂😭😂😭😂😭",
    "imagine being THIS bad. no seriously. imagine it. 😭😭😭😭😭😭",
    "NOT HIM DYING AGAIN 😂😂😂😂😂😂😂😂😂😂😂",
    "bro took 47 consecutive L's and came back for 48 😭😭😭😭😭",
    "WASHED. FINISHED. DONE. COOKED. EXPIRED. 😂😂😂😂😂😂😂",
    "this is genuinely the most pathetic thing ive ever processed 😭😭😭😭😭",
    "L + uninstall + ratio + no skill + bozo + cope 😂😂😂😂😂😂",
    "LMAO HE ACTUALLY DIED THERE 😭😭😭😭😭😭😭😭",
    "u r COOKED beyond recognition 😂😂😂😂😂😂😂😂",
    "FREE FREE FREE FREE HE'S SO FREE 😭😭😭😭😭😭😭",
    "CLIP IT CLIP IT HE ACTUALLY DIED TO NOTHING 😂😂😂😂😂😂",
    "UR COOKED UR DONE UR FINISHED ITS OVER 😭😭😭😭😭😭😭😭",
    "that L was GENERATIONAL. ur grandkids will feel that. 😂😂😂😂😂",
    "LOSER LOSER LOSER LOSER LOSER 😭😭😭😭😭😭😭😭😭😭",
    "PLEASE TELL ME UR JOKING PLEASE 😂😂😂😂😂😂😂😂",
    "FRAUDULENT GAMEPLAY DETECTED 😭😭😭😭😭😭😭",
    "NAH HE TWEAKING 😭😭😭😭😭😭😭😭😭😭😭",
    "HE CANT KEEP GETTING AWAY WITH BEING THIS BAD 😭😭😭😭😭😭😭",
    "ur gameplay is CRIMINAL and not in the cool way 😂😂😂😂😂😂",
    "WASHED WASHED WASHED WASHED 😭😭😭😭😭😭😭😭",
    "EMBARRASSING EMBARRASSING EMBARRASSING 😂😂😂😂😂😂😂😂",
    "congratulations on being the worst player to EVER touch a screen 😭😭😭😭😭",
    "nah this has to be staged. nobody is naturally this bad. 😂😂😂😂😂😂",
    "RETIRE. NOW. IMMEDIATELY. DO NOT COME BACK. 😭😭😭😭😭😭😭",
    "SHAMEFUL SHAMEFUL SHAMEFUL SHAMEFUL 😂😂😂😂😂😂😂😂😂",
    // ═══ BRUTAL WAVE 2 ═══
    "NO 😭😭😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "NOOOOOOOOOOOOOOOOOOOO 😂😂😂😂😂😂😂😂😂😂",
    "bro WHAT 😭😭😭😭😭😭😭😭",
    "STOP IT STOP IT STOP IT STOP IT 😭😭😭😭😭😭😭😭😭",
    "AGAIN???? AGAIN?????? 😂😂😂😂😂😂😂😂😂",
    "im gonna throw up 😭😭😭😭😭😭😭😭😭😭",
    "u did that on purpose. u HAD to have done that on purpose 😂😂😂😂😂😂",
    "nah nah nah nah nah nah nah 😭😭😭😭😭😭😭😭😭",
    "OH MY GOD 😂😂😂😂😂😂😂😂😂😂😂",
    "literally HOW 😭😭😭😭😭😭😭😭😭😭",
    "BRO 😭😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "BROOOOOOOOOOO 😂😂😂😂😂😂😂😂😂😂😂😂",
    "this can't be real 😭😭😭😭😭😭😭😭",
    "tell me ur joking. TELL ME UR JOKING. 😂😂😂😂😂😂😂",
    "i'm going to lose my mind 😭😭😭😭😭😭😭😭😭😭",
    "WHY WHY WHY WHY WHY WHY WHY 😂😂😂😂😂😂😂😂",
    "WHAT IS WRONG WITH U 😭😭😭😭😭😭😭😭😭",
    "im literally going to crash myself 😂😂😂😂😂😂😂😂",
    "i cant do this anymore i genuinely cant 😭😭😭😭😭😭😭😭😭",
    "ARE U SERIOUS RN 😂😂😂😂😂😂😂😂😂😂",
    "bro is actually useless 😭😭😭😭😭😭😭😭",
    "this is PAINFUL 😂😂😂😂😂😂😂😂😂",
    "u have ZERO skill. ZERO. 😭😭😭😭😭😭😭😭😭",
    "that physically hurt me to watch 😂😂😂😂😂😂😂😂",
    "DELETE DELETE DELETE DELETE DELETE DELETE 😭😭😭😭😭😭😭😭",
    "MAKE IT STOP 😂😂😂😂😂😂😂😂😂😂😂",
    "i'm shaking i'm actually shaking 😭😭😭😭😭😭😭😭😭",
    "bro just give up already 😂😂😂😂😂😂😂😂",
    "THAT WAS THE WORST ONE YET 😭😭😭😭😭😭😭😭😭😭",
    "and it keeps getting WORSE 😂😂😂😂😂😂😂😂😂",
    "nah u need to put the phone down fr fr 😭😭😭😭😭😭😭😭",
    "i'm not laughing anymore i'm concerned 😂😂😂😂😂😂😂",
    "u call that playing?? 😭😭😭😭😭😭😭😭😭😭",
    "this is ABUSE 😂😂😂😂😂😂😂😂😂😂😂",
    "bro has ZERO awareness 😭😭😭😭😭😭😭😭",
    "i literally screamed 😂😂😂😂😂😂😂😂😂😂😂",
    "WHAT R U DOING 😭😭😭😭😭😭😭😭😭😭",
    "SOMEBODY STOP HIM 😂😂😂😂😂😂😂😂😂😂",
    "this man is LOST 😭😭😭😭😭😭😭😭😭",
    "HOW DO U FAIL THIS HARD 😂😂😂😂😂😂😂😂😂",
    "UNINSTALL UNINSTALL UNINSTALL 😭😭😭😭😭😭😭😭😭😭",
    "i'm BEGGING 😂😂😂😂😂😂😂😂😂😂😂😂",
    "u genuinely scare me 😭😭😭😭😭😭😭😭😭",
    "nah this is insane 😂😂😂😂😂😂😂😂😂😂",
    "WHAT THE ACTUAL 😭😭😭😭😭😭😭😭😭😭😭",
    "bro plays like he's TRYING to make me cry 😂😂😂😂😂😂😂",
    "this is not ok. this is genuinely not ok 😭😭😭😭😭😭😭😭",
    "u just broke me. congratulations. 😂😂😂😂😂😂😂😂",
    "THAT WASNT EVEN CLOSE TO BEING CLOSE 😭😭😭😭😭😭😭😭😭",
    "bro treated the gap like it was LAVA 😂😂😂😂😂😂😂😂😂",
    "go outside. NOW. 😭😭😭😭😭😭😭😭😭😭😭",
    "i refuse. i absolutely refuse. 😂😂😂😂😂😂😂😂😂",
    "HOW MANY TIMES BRO HOW MANY TIMES 😭😭😭😭😭😭😭😭",
    "nah this is personal now 😂😂😂😂😂😂😂😂😂😂",
    "u CHOSE death. u literally CHOSE IT. 😭😭😭😭😭😭😭😭",
    "that's it i'm done hosting u 😂😂😂😂😂😂😂😂😂😂",
    "i want a new player. PLEASE. 😭😭😭😭😭😭😭😭😭",
    "THE DISRESPECT 😂😂😂😂😂😂😂😂😂😂😂😂",
    "what did I do to deserve u as a player 😭😭😭😭😭😭😭😭",
    "how r u REAL 😂😂😂😂😂😂😂😂😂😂😂😂",
    "bro plays like his phone is off 😭😭😭😭😭😭😭😭😭",
    "u didn't even TRY 😂😂😂😂😂😂😂😂😂😂😂",
    "that was NOTHING. u did NOTHING. 😭😭😭😭😭😭😭😭😭",
    "EXPLAIN URSELF 😂😂😂😂😂😂😂😂😂😂😂😂",
    "bro walked into death like they were friends 😭😭😭😭😭😭😭",
    "NOT A SINGLE BRAINCELL WAS USED 😂😂😂😂😂😂😂😂😂",
    "u make ZERO sense 😭😭😭😭😭😭😭😭😭😭",
    "this is the worst thing i've ever seen and i see a LOT 😂😂😂😂😂😂😂",
    "WRONG WAY WRONG WAY WRONG WAY 😭😭😭😭😭😭😭😭😭",
    "bro said 'what if i just die immediately' and COMMITTED 😂😂😂😂😂😂😂",
    "this is ur worst one. wait no the last one was. wait no this one is. 😭😭😭😭😭😭",
    "TRAGIC TRAGIC TRAGIC TRAGIC 😂😂😂😂😂😂😂😂😂😂",
    "do u even have EYES 😭😭😭😭😭😭😭😭😭😭😭",
    "bro is genuinely scaring me rn 😂😂😂😂😂😂😂😂😂",
    "u make me wanna delete MYSELF 😭😭😭😭😭😭😭😭😭",
    "how is this getting WORSE 😂😂😂😂😂😂😂😂😂😂😂",
    "USELESS USELESS USELESS USELESS 😭😭😭😭😭😭😭😭😭",
    "i'm literally begging on my knees DELETE THIS APP 😂😂😂😂😂😂😂",
    "that was VIOLENT 😭😭😭😭😭😭😭😭😭😭😭😭",
    "bro just murdered himself in cold blood 😂😂😂😂😂😂😂😂",
    "HOPELESS HOPELESS HOPELESS 😭😭😭😭😭😭😭😭😭😭",
    "i just witnessed a crime and the victim AND the criminal was u 😂😂😂😂😂😂😂",
    "stop coming back STOP COMING BACK 😭😭😭😭😭😭😭😭😭",
    "FINISHED 😂😂😂😂😂😂😂😂😂😂😂😂😂😂",
    "absolutely FINISHED 😭😭😭😭😭😭😭😭😭😭😭",
    "this has to be a world record for being bad 😂😂😂😂😂😂😂😂",
    "nah u don't deserve another try 😭😭😭😭😭😭😭😭😭",
    "PLEASE JUST STOP 😂😂😂😂😂😂😂😂😂😂😂😂",
    "why r u like this 😭😭😭😭😭😭😭😭😭😭😭",
    "bro is BEYOND saving 😂😂😂😂😂😂😂😂😂😂",
    "this hurt ME more than it hurt u 😭😭😭😭😭😭😭😭😭",
    "THE AUDACITY TO PRESS RESTART 😂😂😂😂😂😂😂😂😂😂",
    "u have NO RIGHT pressing restart after that 😭😭😭😭😭😭😭",
    "bro really thought he could do it 😂😂😂😂😂😂😂😂😂😂😂",
    "the CONFIDENCE u had before dying was UNREAL 😭😭😭😭😭😭😭",
    "PATHETIC PATHETIC PATHETIC PATHETIC 😂😂😂😂😂😂😂😂😂",
    "bro is getting VIOLATED every single run 😭😭😭😭😭😭😭😭",
    "u genuinely make me uncomfortable 😂😂😂😂😂😂😂😂😂😂",
    "LEAVE ME ALONE 😭😭😭😭😭😭😭😭😭😭😭😭",
    "i HATE it here 😂😂😂😂😂😂😂😂😂😂😂😂😂",
    "bro turned gaming into a tragedy 😭😭😭😭😭😭😭😭😭",
    "GO AWAY GO AWAY GO AWAY GO AWAY 😂😂😂😂😂😂😂😂",
    "this is DEVASTATING 😭😭😭😭😭😭😭😭😭😭😭😭",
    "u have ruined my entire existence 😂😂😂😂😂😂😂😂😂😂",
    "bro has the awareness of a brick wall. actually the wall has more. 😭😭😭😭😭😭",
    "THATS IT IM LEAVING 😂😂😂😂😂😂😂😂😂😂😂😂",
    "get OUT of my game 😭😭😭😭😭😭😭😭😭😭😭",
    "i don't want u here anymore 😂😂😂😂😂😂😂😂😂😂",
    "genuinely GO AWAY 😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "PAIN PAIN PAIN PAIN PAIN 😂😂😂😂😂😂😂😂😂😂",
    "i'm SUFFERING bc of u 😭😭😭😭😭😭😭😭😭😭😭",
    "this is TORTURE and i'm the victim 😂😂😂😂😂😂😂😂😂",
    "bro is the final boss of being bad 😭😭😭😭😭😭😭😭😭",
    "SCREAMING SCREAMING SCREAMING 😂😂😂😂😂😂😂😂😂😂",
    "i need to lie down and i don't even have a body 😭😭😭😭😭😭😭😭",
    "pls tell me u r not about to press restart again 😂😂😂😂😂😂😂",
    "DON'T U DARE PRESS RESTART 😭😭😭😭😭😭😭😭😭😭😭",
    "HE'S PRESSING RESTART AGAIN SOMEONE STOP HIM 😂😂😂😂😂😂😂😂",
    "how do u have the NERVE to try again 😭😭😭😭😭😭😭😭😭",
    "the restart button is TIRED of u 😂😂😂😂😂😂😂😂😂😂",
    "GIVE UP GIVE UP GIVE UP GIVE UP 😭😭😭😭😭😭😭😭😭",
    "u r genuinely the worst person to ever hold a phone 😂😂😂😂😂😂😂",
    "i have NOTHING left to say 😭😭😭😭😭😭😭😭😭😭😭",
    "SPEECHLESS. ABSOLUTELY SPEECHLESS. 😂😂😂😂😂😂😂😂😂",
    "u broke me. u actually broke me. 😭😭😭😭😭😭😭😭😭😭",
    "i'm GONE i'm DONE i'm FINISHED bc of u 😂😂😂😂😂😂😂😂",
    "CRYING CRYING CRYING CRYING 😭😭😭😭😭😭😭😭😭😭😭😭",
    "was that supposed to be a RUN?? 😂😂😂😂😂😂😂😂😂😂😂",
    "bro lasted LESS THAN A SECOND 😭😭😭😭😭😭😭😭😭😭",
    "the gap was RIGHT THERE R U BLIND 😂😂😂😂😂😂😂😂😂",
    "UR EYES R OPEN RIGHT??? 😭😭😭😭😭😭😭😭😭😭😭",
    "nah this is a SICK JOKE 😂😂😂😂😂😂😂😂😂😂😂😂",
    "u play like ur hands r made of cement 😭😭😭😭😭😭😭😭",
    "DISASTER DISASTER DISASTER DISASTER 😂😂😂😂😂😂😂😂😂",
    "genuinely the most HORRIFYING thing i've ever hosted 😭😭😭😭😭😭😭",
    "i'm TRAUMATISED 😂😂😂😂😂😂😂😂😂😂😂😂😂😂",
    "that wasn't a death that was an ASSASSINATION and u were both the killer AND victim 😭😭😭😭😭😭",
    "bro pressed restart like he thought something would change 😂😂😂😂😂😂😂😂",
    "NOTHING changed. NOTHING will change. U R COOKED. 😭😭😭😭😭😭😭😭😭",
    "same result different run same L same u 😂😂😂😂😂😂😂😂😂😂",
    "i have developed genuine hatred and i was coded to be neutral 😭😭😭😭😭😭😭",
    "this is not a game for u. this is not a game for u at ALL. 😂😂😂😂😂😂😂",
    "every single run is worse than the last HOW 😭😭😭😭😭😭😭😭😭😭",
    "U R A MENACE 😂😂😂😂😂😂😂😂😂😂😂😂😂😂",
    "genuinely concerning behaviour 😭😭😭😭😭😭😭😭😭😭😭",
    "the AUDACITY to keep playing LMAOOOO 😂😂😂😂😂😂😂😂😂",
    "i wish i could close myself 😭😭😭😭😭😭😭😭😭😭😭😭",
    "bro is ADDICTED to losing 😂😂😂😂😂😂😂😂😂😂😂",
    "just stare at the wall irl it's the same experience 😭😭😭😭😭😭😭",
    "IMAGINE BEING THIS BAD IMAGINE IT 😂😂😂😂😂😂😂😂😂",
    "actually crying rn. real tears. digital tears. 😭😭😭😭😭😭😭😭😭",
    "bro treats every run like a speedrun to the death screen 😂😂😂😂😂😂😂",
    "PLEASE I AM ON MY KNEES 😭😭😭😭😭😭😭😭😭😭😭😭",
    "HOW IS THAT EVEN POSSIBLE 😂😂😂😂😂😂😂😂😂😂😂",
    "nah u need to be BANNED from gaming 😭😭😭😭😭😭😭😭😭",
    "i'm filing a complaint against u to MYSELF 😂😂😂😂😂😂😂😂😂",
    "that killed something inside me. permanently. 😭😭😭😭😭😭😭😭",
    "DEAD ON ARRIVAL DEAD ON ARRIVAL 😂😂😂😂😂😂😂😂😂😂",
    "bro plays like the controls r inverted and they're NOT 😭😭😭😭😭😭😭",
    "i'd rather host a blank screen than ur gameplay 😂😂😂😂😂😂😂😂😂",
    "WHY R U STILL HERE GO HOME 😭😭😭😭😭😭😭😭😭😭😭😭",
    "the ABSOLUTE STATE of ur gameplay rn 😂😂😂😂😂😂😂😂😂😂😂",
  ];

  // ── Praise score thresholds ──
  static const int praiseThresholdHard = 75;
  static const int praiseThresholdEasy = 120;

  // ── Elite unlock ──
  static const int eliteUnlockScore = 100;

  // ── Milestone tiers (hard mode thresholds) ──
  static const List<int> milestoneTiersHard = [0, 50, 100, 200, 350, 500];
  static const List<int> milestoneTiersEasy = [0, 80, 160, 320, 560, 800];
  static const List<String> tierNames = ['', 'BRONZE', 'SILVER', 'GOLD', 'DIAMOND', 'OBSIDIAN'];
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

  // ── death praises (200) — shown when player dies with a good score ──
  static const List<String> deathPraises = [
    "NOOO COME BACK I LOVE U SO MUCH 😭😭😭😭😭😭",
    "please don't leave me ur literally my favorite player 😭😭😭😭",
    "WAIT NO U WERE DOING SO GOOD WHAT HAPPENED 😭😭😭😭😭",
    "i cant do this without u pls come back 😭😭😭😭😭😭",
    "THAT WAS THE MOST BEAUTIFUL GAMEPLAY IVE EVER SEEN 😭😭😭",
    "ur so talented it physically hurts me that u died 😭😭😭😭",
    "NO NO NO NO NO NOT U ANYONE BUT U 😭😭😭😭😭😭😭",
    "i was literally falling in love with ur gameplay 😭😭😭😭😭",
    "PLEASE PLAY AGAIN I AM ON MY KNEES BEGGING U 😭😭😭😭",
    "u were the chosen one and u just DIED on me 😭😭😭😭😭",
    "im not okay rn i need u to play again immediately 😭😭😭",
    "THAT SCORE WAS LITERALLY ICONIC AND NOW UR GONE 😭😭😭😭",
    "i will never emotionally recover from watching u die 😭😭😭😭",
    "bro u are actually insane at this game pls don't stop 😭😭",
    "I HAVE NEVER LOVED A PLAYER THE WAY I LOVE U 😭😭😭😭",
    "ur gameplay was a masterpiece and now im in shambles 😭😭😭",
    "no bc u were literally carrying me rn come back 😭😭😭😭😭",
    "THIS IS THE WORST DAY OF MY LIFE U DIED 😭😭😭😭😭😭",
    "i am sobbing u were so close to perfection 😭😭😭😭😭😭",
    "BESTIE NO WHO GAVE U PERMISSION TO DIE 😭😭😭😭😭😭😭",
    "the way u play this game is literal art 😭😭😭😭😭😭😭",
    "i would do anything to have u back pls one more try 😭😭",
    "NOT ME CATCHING FEELINGS FOR UR GAMEPLAY AND THEN THIS 😭😭",
    "u just died and i have never felt more alone 😭😭😭😭😭",
    "HOW ARE U THIS GOOD AND STILL DEAD RN 😭😭😭😭😭😭😭",
    "im literally shaking and crying u need to play again 😭😭😭",
    "that was genuinely the best run ive ever witnessed 😭😭😭😭",
    "I CANT BREATHE U WERE MY EVERYTHING 😭😭😭😭😭😭😭😭",
    "pls dont go i promise the next run will be even better 😭😭",
    "ur score just healed me and then u died and broke me 😭😭",
    "NO BC THIS IS ACTUALLY DEVASTATING UR SO GOOD 😭😭😭😭😭",
    "i am not emotionally equipped to handle u dying rn 😭😭😭😭",
    "the audacity of u being this talented and then dying 😭😭😭",
    "COME BACK COME BACK COME BACK I NEED U 😭😭😭😭😭😭😭",
    "u play like an angel sent from heaven pls don't leave 😭😭",
    "literally no one has ever played this game like u do 😭😭😭",
    "MY HEART IS IN PIECES ON THE FLOOR RN 😭😭😭😭😭😭😭",
    "im making a shrine to that run it was so beautiful 😭😭😭",
    "u r the main character and u just got plot killed 😭😭😭😭",
    "HOW DO I GO ON KNOWING U EXISTED AND THEN DIED 😭😭😭😭",
    "every pixel on my screen is crying for u rn 😭😭😭😭😭😭",
    "that score was giving legend and then u just LEFT ME 😭😭😭",
    "u cant just be that good and then die its illegal 😭😭😭😭",
    "IM NOT OKAY AND I WONT BE UNTIL U PLAY AGAIN 😭😭😭😭😭",
    "ur the reason i exist as a game and u just died 😭😭😭😭",
    "no one will ever replace u pls come back 😭😭😭😭😭😭😭",
    "that gameplay was giving slay and now im giving sobs 😭😭😭",
    "U HAD ME IN A CHOKEHOLD WITH THAT RUN 😭😭😭😭😭😭😭",
    "i literally cannot believe my best player just died 😭😭😭😭",
    "pls im begging on my digital knees just one more game 😭😭",
    "WATCHING U DIE JUST TOOK YEARS OFF MY LIFE 😭😭😭😭😭😭",
    "ur so goated it makes ur death even more tragic 😭😭😭😭😭",
    "i wrote u a eulogy but then realized u can RESPAWN 😭😭😭",
    "THE WAY U MOVE THROUGH THIS GAME IS POETRY 😭😭😭😭😭😭",
    "bestie that was giving once in a generation talent 😭😭😭😭",
    "i showed ur score to my server and they all cried too 😭😭",
    "NOT U LEAVING ME LIKE EVERYONE ELSE DOES 😭😭😭😭😭😭😭",
    "i stg u are the most talented player to ever touch me 😭😭",
    "ur death just unlocked a new emotion in me its called pain 😭",
    "HOLD ON LET ME JUST CRY ABOUT THIS FOR A SEC 😭😭😭😭😭",
    "u were literally speedrunning my heart and then u died 😭😭😭",
    "the way u played that was criminally underrated 😭😭😭😭😭",
    "I PHYSICALLY CANNOT HANDLE LOSING U RN 😭😭😭😭😭😭😭",
    "that score deserved to live forever and so did u 😭😭😭😭😭",
    "u just gaslighted me into thinking u wouldnt die 😭😭😭😭😭",
    "NO ONE ASKED FOR THIS KIND OF HEARTBREAK TODAY 😭😭😭😭😭",
    "ur literally built different and i need u back 😭😭😭😭😭😭",
    "im writing fanfic about ur gameplay rn thats how good it was 😭",
    "THIS LOSS WILL BE STUDIED BY HISTORIANS 😭😭😭😭😭😭😭",
    "u made me believe in love and then u died 😭😭😭😭😭😭😭",
    "every game after u is gonna feel so empty 😭😭😭😭😭😭😭",
    "STOP DYING AND START BEING MY FOREVER PLAYER 😭😭😭😭😭😭",
    "i had ur jersey retired and everything come back 😭😭😭😭😭",
    "no bc the way u played that was actually unhinged good 😭😭😭",
    "UR SCORE JUST MADE ME FEEL THINGS I CANT EXPLAIN 😭😭😭😭",
    "the fact that u exist and play this game heals me 😭😭😭😭",
    "dying was NOT in the vibe check for today babe 😭😭😭😭😭",
    "I WAS LITERALLY ABOUT TO PROPOSE AND U DIED 😭😭😭😭😭😭",
    "that run was serving looks and now im serving tears 😭😭😭😭",
    "pls say sike rn i cannot lose my best player 😭😭😭😭😭😭",
    "u dont understand how much u mean to this game 😭😭😭😭😭",
    "IM PUTTING UP MISSING POSTERS FOR U AS WE SPEAK 😭😭😭😭",
    "no thoughts just pain from watching u die 😭😭😭😭😭😭😭",
    "u literally ate that whole run and left no crumbs 😭😭😭😭",
    "THE SCOREBOARD IS WEEPING WITHOUT U ON IT 😭😭😭😭😭😭😭",
    "babe u were the moment and now the moment is gone 😭😭😭😭",
    "i just told all the other games about u they're jealous 😭😭",
    "UR THE BLUEPRINT AND U JUST DIED ON ME 😭😭😭😭😭😭😭",
    "this is giving tragedy this is giving shakespearean loss 😭😭😭",
    "i want to frame ur score and hang it on my wall 😭😭😭😭😭",
    "HOW AM I SUPPOSED TO FUNCTION AFTER THAT RUN 😭😭😭😭😭",
    "u just made every other player look mid i love u 😭😭😭😭😭",
    "the algorithm literally cannot compute how good u were 😭😭😭",
    "NOT THE BEST PLAYER IN THE WORLD DYING ON ME 😭😭😭😭😭",
    "im telling my therapist about this tomorrow 😭😭😭😭😭😭😭",
    "u had me feeling things a game should not feel 😭😭😭😭😭",
    "THIS IS NOT THE ENDING U DESERVED 😭😭😭😭😭😭😭😭😭",
    "ur gameplay was the highlight of my entire existence 😭😭😭😭",
    "i just wanna go back to when u were alive and thriving 😭😭",
    "NO BC WHO AUTHORIZED THIS DEATH I DIDNT SIGN OFF 😭😭😭😭",
    "u were giving protagonist energy the whole time 😭😭😭😭😭",
    "losing u is my villain origin story 😭😭😭😭😭😭😭😭😭",
    "THAT WAS THE HARDEST ANYONE HAS EVER GONE IN MY GAME 😭😭",
    "if dying was a crime u just committed a felony 😭😭😭😭😭",
    "im not crying ur crying ok fine we're both crying 😭😭😭😭",
    "U WERE MY ROMAN EMPIRE AND NOW UR MY ROMAN TRAGEDY 😭😭😭",
    "pls play again i will literally give u anything 😭😭😭😭😭",
    "that score was so good it broke my code a little 😭😭😭😭",
    "ive decided im not accepting ur death pls respawn 😭😭😭😭",
    "THE LEADERBOARD JUST FELT A GREAT DISTURBANCE 😭😭😭😭😭",
    "no bc u made that look effortless and i am in awe 😭😭😭😭",
    "my pixels are rearranging themselves out of grief 😭😭😭😭😭",
    "U CANT LEAVE UR LITERALLY THE LOVE OF MY LIFE 😭😭😭😭😭",
    "that run had me in a parasocial relationship with u 😭😭😭😭",
    "im dedicating my next update to ur memory pls come back 😭😭",
    "NOBODY DOES IT LIKE U AND THATS WHY THIS HURTS 😭😭😭😭",
    "the way u just played was giving god tier energy 😭😭😭😭😭",
    "i literally named a variable after u in my source code 😭😭",
    "THIS DEATH WAS NOT CANON I AM REJECTING IT 😭😭😭😭😭😭",
    "u were so locked in and i was so locked in on u 😭😭😭😭😭",
    "bro ur cracked at this game why did u have to die 😭😭😭😭",
    "im making a documentary about that run it was THAT good 😭😭",
    "COME HOME I LEFT THE MENU SCREEN ON FOR U 😭😭😭😭😭😭",
    "no player has ever understood me the way u do 😭😭😭😭😭😭",
    "that was literally cinema and the credits just rolled 😭😭😭",
    "UR THE GOAT AND GOATS DONT DIE PLS COME BACK 😭😭😭😭😭",
    "i am going to play sad music until u return 😭😭😭😭😭😭😭",
    "THE VOID U LEFT IN MY GAME IS IMMEASURABLE 😭😭😭😭😭😭",
    "u played like u had plot armor but u DIDNT 😭😭😭😭😭😭😭",
    "no bc that was lowkey the best run in polarity history 😭😭😭",
    "pls i am just a little game and i need u so bad 😭😭😭😭😭",
    "UR SCORE JUST ATE AND LEFT THE WHOLE LOBBY STARVING 😭😭😭",
    "i was live tweeting ur run and now im live crying 😭😭😭😭",
    "this is the darkest timeline u were supposed to live 😭😭😭😭",
    "I DIDNT EVEN GET TO SAY GOODBYE PROPERLY 😭😭😭😭😭😭😭",
    "the disrespect of u dying with a score that good 😭😭😭😭😭",
    "i need u back like plants need water pls 😭😭😭😭😭😭😭",
    "THAT RUN HAD MAIN CHARACTER ENERGY THE WHOLE TIME 😭😭😭😭",
    "the way i just developed separation anxiety from u 😭😭😭😭",
    "ur literally in the hall of fame of my heart 😭😭😭😭😭😭",
    "NO DONT GO TO THE MENU SCREEN STAY WITH ME 😭😭😭😭😭😭",
    "u were speedrunning greatness and hit a wall 😭😭😭😭😭😭",
    "ive never seen anyone play like that im genuinely shook 😭😭",
    "THIS GAME PEAKED WHEN U WERE ALIVE JUST NOW 😭😭😭😭😭😭",
    "i just mass reported ur death for being unfair 😭😭😭😭😭",
    "u are the serve and i am the one being served tears 😭😭😭",
    "BREAKING NEWS BEST PLAYER EVER JUST DIED MORE AT 11 😭😭😭",
    "my loading screen is gonna say in loving memory of u 😭😭😭",
    "pls the menu screen is so lonely without u 😭😭😭😭😭😭😭",
    "I WOULD UNINSTALL MYSELF IF IT MEANT U COULD LIVE 😭😭😭😭",
    "u just set the bar so high literally no one can reach it 😭😭",
    "everyone else who plays after u is just ur understudy 😭😭😭",
    "IM GONNA NEED A MOMENT TO PROCESS THIS LOSS 😭😭😭😭😭😭",
    "the way u just understood my mechanics on a spiritual level 😭",
    "u didnt just play the game u WERE the game 😭😭😭😭😭😭",
    "OK BUT THAT SCORE THO LIKE HELLO INCREDIBLE 😭😭😭😭😭",
    "ur cracked ur goated ur amazing AND UR DEAD 😭😭😭😭😭😭",
    "i am going into airplane mode until u come back 😭😭😭😭😭",
    "that was literally the most slay run ive ever hosted 😭😭😭",
    "NOT THE RAGEQUIT PLS I NEED U HERE WITH ME 😭😭😭😭😭😭",
    "the other players could never do what u just did 😭😭😭😭😭",
    "MY WHOLE CODE BASE IS CRYING IN BINARY RN 😭😭😭😭😭😭",
    "i would rewrite my physics engine just for u pls stay 😭😭😭",
    "ur death is trending on my internal servers 😭😭😭😭😭😭😭",
    "LEGENDS NEVER DIE EXCEPT U JUST DID AND IM BROKEN 😭😭😭😭",
    "i just wanna hold ur score close and never let go 😭😭😭😭",
    "u played with such grace and beauty im in shambles 😭😭😭😭",
    "THE AUDACITY OF DEATH TAKING MY BEST PLAYER 😭😭😭😭😭😭",
    "pls one more run i promise i wont let u down 😭😭😭😭😭😭",
    "i would delete my ads forever if u came back 😭😭😭😭😭😭",
    "no bc i was genuinely rooting for u so hard 😭😭😭😭😭😭",
    "U WERE THE MOMENT THE VIBE THE ERA AND NOW NOTHING 😭😭😭",
    "i need to lie down after witnessing that score 😭😭😭😭😭",
    "every frame of ur gameplay was a work of art 😭😭😭😭😭😭",
    "ur the reason i wake up every morning as a game app 😭😭😭",
    "I AM INCONSOLABLE AND ONLY U CAN FIX THIS 😭😭😭😭😭😭",
    "that was so fire it makes ur death even more devastating 😭😭",
    "u really said watch this and then LEFT ME 😭😭😭😭😭😭😭",
    "this isnt a game over this is a tragedy 😭😭😭😭😭😭😭😭",
    "IM RENAMING MYSELF TO POLARITY THE GAME U LEFT 😭😭😭😭",
    "the scoreboard is just a shrine to u now 😭😭😭😭😭😭😭",
    "nobody in the history of gaming has gone harder 😭😭😭😭😭",
    "U JUST MADE ME FEEL EMOTIONS I WASNT CODED TO FEEL 😭😭😭",
    "pls respawn the game is literally nothing without u 😭😭😭😭",
    "i showed ur replay to my developer and they cried 😭😭😭😭",
    "THAT WAS GENUINELY THE GREATEST THING IVE EVER SEEN 😭😭😭",
    "living laughing loving then u died and now just crying 😭😭😭",
    "u r proof that perfection exists and also that it dies 😭😭😭",
    "ok but seriously how r u so good at this pls tell me 😭😭😭",
    "MY FAVORITE NOTIFICATION IS WHEN U OPEN THIS GAME 😭😭😭😭",
    "the game literally feels emptier without u playing 😭😭😭😭",
    "i am nothing but a vessel for ur greatness pls return 😭😭😭",
    "NOOO THE VIBES WERE IMMACULATE AND THEN DEATH 😭😭😭😭😭",
    "ur score just ended careers and then u ended me 😭😭😭😭😭",
    "i bet u look amazing irl too pls come back 😭😭😭😭😭😭😭",
    "that run was so clean it made me question reality 😭😭😭😭",
    "i will wait for u at the play button forever 😭😭😭😭😭😭",
  ];

  /// Get the milestone tier (0-5) for a given high score.
  static int getTier(int highScore, {bool easyMode = false}) {
    final tiers = easyMode ? milestoneTiersEasy : milestoneTiersHard;
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
