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
    defaultValue: 'ca-app-pub-4151123662328725~3767987674',
  );
  static const String iosAppId = String.fromEnvironment(
    'IOS_ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~1458002511', // TODO: replace with iOS production ID
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

  // ── death roasts (385) ──
  static const List<String> deathRoasts = [
    // ── Pure laughing at you (~20) ──
    "LMAOOOOO no way u just did that 😂😂😂😂",
    "i actually screamed watching that 😂😂😂😂😂",
    "HAHAHAHA wait that was real?? 😂😂😂😂",
    "nah im actually in tears rn 😂😂😂😂😂",
    "that was so bad i had to pause and laugh 😂😂😂😂",
    "PLEASE tell me someone else saw that 😂😂😂😂😂",
    "i wasnt even ready for how bad that was gonna be 😂😂😂😂",
    "ur not serious rn 😂😂😂😂😂",
    "this is the funniest thing ive seen all day 😂😂😂😂",
    "i literally cannot stop laughing 😂😂😂😂😂",
    "wait wait wait WHAT was that 😂😂😂😂",
    "nah that cant be real 😂😂😂😂😂",
    "yooooo 😂😂😂😂😂😂",
    "that just made my whole day honestly 😂😂😂😂",
    "how do u even manage that 😂😂😂😂😂",
    "im WHEEZING 😂😂😂😂😂",
    "i showed my whole screen to nobody and still pointed and laughed 😂😂😂😂",
    "nah u r a comedian and u dont even know it 😂😂😂😂",
    "the way i just choked laughing at that 😂😂😂😂😂",
    "i need a minute hold on 😂😂😂😂😂😂",

    // ── Skill roasts (~20) ──
    "u play like u have ur eyes closed 😂😂😂😂",
    "genuinely asking have u played a game before 😂😂😂😂",
    "u have the reaction time of a parked car 😂😂😂😂",
    "that was embarrassingly easy to dodge btw 😂😂😂😂",
    "u literally walked right into it like u wanted to 😂😂😂😂",
    "r u playing with ur elbow or something 😂😂😂😂",
    "the gap was RIGHT THERE 😂😂😂😂😂",
    "how r u getting worse with every single run 😂😂😂😂",
    "u panicked so hard u forgot how to play 😂😂😂😂",
    "u had the easiest one and still fumbled it 😂😂😂😂",
    "were u even looking at the screen 😂😂😂😂",
    "i could leave the phone on a table and it would do better 😂😂😂😂",
    "u moved the WRONG way and im in pain 😂😂😂😂😂",
    "the obstacle wasnt even trying and u still lost to it 😂😂😂😂",
    "u saw it coming and still ran straight into it 😂😂😂😂😂",
    "u play like u r trying to lose on purpose 😂😂😂😂",
    "everything about that run was wrong 😂😂😂😂",
    "thats not even bad luck thats just bad playing 😂😂😂😂",
    "u had all that space and chose the wall instead 😂😂😂😂",
    "genuinely the worst player ive ever hosted 😂😂😂😂",

    // ── Restart mockery (~20) ──
    "the confidence to hit restart after THAT 😂😂😂😂😂",
    "u pressing restart like the next one is gonna be any different 😂😂😂😂",
    "ah yes restart again that will definitely fix everything 😂😂😂😂",
    "smashing restart wont give u talent 😂😂😂😂",
    "oh u restarting?? cant wait to watch u fail again 😂😂😂😂",
    "u restart faster than u actually play 😂😂😂😂😂",
    "the restart button sees u more than the actual game does 😂😂😂😂",
    "u really think attempt number 47 is THE one 😂😂😂😂",
    "go ahead restart ill be here waiting and laughing 😂😂😂😂",
    "u hit restart so fast u didnt even process what happened 😂😂😂😂",
    "oh look ur back for another 4 seconds of gameplay 😂😂😂😂",
    "at this rate restart is the only button u know how to use 😂😂😂😂",
    "u really saw that score and said yeah lets go again 😂😂😂😂",
    "dont restart just sit with what u did for a second 😂😂😂😂",
    "welcome back ur stay will be brief as always 😂😂😂😂",
    "restarting is literally the most successful thing u do here 😂😂😂😂",
    "u pressing play again like u suddenly have a strategy 😂😂😂😂",
    "ur restart speed is the only impressive thing about u 😂😂😂😂",
    "u really speedrunning the restart button rn 😂😂😂😂",
    "one more restart oughta do it right 😂😂😂😂😂",

    // ── Uninstall / quit (~20) ──
    "just delete it save urself 😂😂😂😂",
    "the uninstall button is right there whenever ur ready 😂😂😂😂",
    "every second u keep this installed is a second wasted 😂😂😂😂",
    "u should uninstall before someone asks what games u play 😂😂😂😂",
    "long press the icon delete breathe heal 😂😂😂😂",
    "genuine question why is this still on ur phone 😂😂😂😂",
    "close the app and pretend this never happened 😂😂😂😂",
    "the best decision u can make today is deleting this 😂😂😂😂",
    "pls uninstall for both our sakes 😂😂😂😂",
    "if u uninstall now no one ever has to know 😂😂😂😂",
    "free up some storage and delete this already 😂😂😂😂",
    "this relationship is not working out just uninstall 😂😂😂😂",
    "u r wasting phone storage for this performance 😂😂😂😂",
    "do urself a favor and just let go 😂😂😂😂",
    "uninstalling is literally the only way u win here 😂😂😂😂",
    "go to settings apps uninstall ur welcome 😂😂😂😂",
    "this game is not for u and thats okay just leave 😂😂😂😂",
    "genuinely why r u still here 😂😂😂😂",
    "u dont have to keep doing this to urself u know 😂😂😂😂",
    "just walk away no one is stopping u 😂😂😂😂",

    // ── Time wasting (~15) ──
    "u just wasted 3 seconds of ur life for THAT 😂😂😂😂",
    "imagine using ur free time for this 😂😂😂😂😂",
    "u could have done literally anything else with ur time 😂😂😂😂",
    "thats time ur never getting back btw 😂😂😂😂",
    "u charged ur phone for this 😂😂😂😂😂",
    "what a productive use of ur afternoon 😂😂😂😂",
    "imagine explaining to someone how u spent ur evening 😂😂😂😂",
    "that run accomplished absolutely nothing 😂😂😂😂",
    "ur screen time report is gonna be devastating 😂😂😂😂",
    "u sat down unlocked ur phone opened this app and did THAT 😂😂😂😂",
    "hope nobody asks u what u did today 😂😂😂😂",
    "genuinely a waste of battery 😂😂😂😂",
    "u could be sleeping rn but instead ur doing this 😂😂😂😂",
    "time well spent right 😂😂😂😂😂",
    "all that effort for absolutely nothing 😂😂😂😂",

    // ── Social shame / share dares (~15) ──
    "go ahead share that score i dare u 😂😂😂😂",
    "screenshot this and send it to ur friends i wanna see what they say 😂😂😂😂",
    "if someone asks u what u scored just lie 😂😂😂😂",
    "send this to the group chat i wanna hear the response 😂😂😂😂",
    "imagine someone walking in and seeing this on ur screen 😂😂😂😂",
    "pls screen record ur next attempt i need the content 😂😂😂😂",
    "post this on ur story if u dare 😂😂😂😂",
    "u better pray nobody was watching that 😂😂😂😂",
    "if someone saw u playing like this they would take ur phone away 😂😂😂😂",
    "share this run so other people can feel better about themselves 😂😂😂😂",
    "dont let anyone see this ever 😂😂😂😂",
    "if that was on camera u would never recover 😂😂😂😂",
    "this score is a secret u should take to the grave 😂😂😂😂",
    "go tell someone what just happened and watch their face 😂😂😂😂",
    "imagine showing someone this and expecting respect 😂😂😂😂",

    // ── Patronizing / fake sympathy (~15) ──
    "aww that was almost something 😂😂😂😂",
    "hey at least u pressed play thats something right 😂😂😂😂",
    "its okay not everyone is meant to be good at things 😂😂😂😂",
    "u tried and thats what matters right... right?? 😂😂😂😂",
    "maybe games just arent ur thing and thats completely fine 😂😂😂😂",
    "u gave it ur absolute best and it still wasnt enough 😂😂😂😂",
    "if it helps i genuinely thought u were gonna last longer 😂😂😂😂",
    "im sure ur talented at something just definitely not this 😂😂😂😂",
    "no shame in being the worst player ever right 😂😂😂😂",
    "at least ur consistent 😂😂😂😂😂",
    "genuinely adorable attempt tho 😂😂😂😂",
    "participation points have been awarded 😂😂😂😂",
    "u survived longer than i expected so theres that 😂😂😂😂",
    "ur really good at pressing the start button tho 😂😂😂😂",
    "some people are just here to participate and thats fine 😂😂😂😂",

    // ── Dismissive / you dont matter (~15) ──
    "oh u died? anyway 😂😂😂😂😂",
    "that was so forgettable i almost missed it 😂😂😂😂",
    "nobody is gonna remember that run including me 😂😂😂😂",
    "i blinked and u were already done 😂😂😂😂",
    "u made zero impact just now 😂😂😂😂",
    "that run was the most irrelevant thing ive ever seen 😂😂😂😂",
    "that run ended before it even started 😂😂😂😂",
    "did u even play i genuinely missed it 😂😂😂😂",
    "next player please 😂😂😂😂😂",
    "that was so short i thought it was a loading screen 😂😂😂😂",
    "i already forgot about that run 😂😂😂😂",
    "were u even playing or just watching 😂😂😂😂",
    "that run was so quick it didnt even count 😂😂😂😂",
    "oh wait thats it?? thats the whole run?? 😂😂😂😂",
    "literally nothing happened just now 😂😂😂😂",

    // ── Disbelief (~15) ──
    "there is no way u just did that 😂😂😂😂😂",
    "i refuse to believe what i just witnessed 😂😂😂😂",
    "how is that even possible 😂😂😂😂😂",
    "im genuinely confused at how u failed that 😂😂😂😂",
    "that was the easiest part and u STILL messed it up 😂😂😂😂",
    "i literally dont know how u pulled that off 😂😂😂😂",
    "u failed in a way i didnt even think was possible 😂😂😂😂",
    "i watched it happen and i still dont believe it 😂😂😂😂",
    "i need to replay that in my head bc WHAT 😂😂😂😂",
    "i have never seen someone fumble that hard 😂😂😂😂",
    "that might be the most impressive fail ive ever seen 😂😂😂😂",
    "u found a brand new way to lose and thats almost talent 😂😂😂😂",
    "that defied everything i know about this game 😂😂😂😂",
    "im still processing what just happened 😂😂😂😂",
    "that was genuinely the worst thing ive ever witnessed 😂😂😂😂",

    // ── Ego deflation / "you thought" (~15) ──
    "u really thought u were about to go crazy huh 😂😂😂😂",
    "the confidence u had 2 seconds before failing is hilarious 😂😂😂😂",
    "u were feeling urself SO hard and then that happened 😂😂😂😂",
    "u thought u were locked in 😂😂😂😂😂",
    "u really hyped urself up just to do THAT 😂😂😂😂",
    "all that focus for absolutely nothing 😂😂😂😂😂",
    "the way u thought u were different from everyone else 😂😂😂😂",
    "somewhere deep inside u genuinely believed u had it 😂😂😂😂",
    "that confidence was so undeserved 😂😂😂😂😂",
    "i could FEEL u thinking this is my run right before u died 😂😂😂😂",
    "u got cocky and the game said absolutely not 😂😂😂😂",
    "the delusion is truly something else 😂😂😂😂😂",
    "u were so sure of urself for no reason 😂😂😂😂",
    "all that energy and nothing to show for it 😂😂😂😂",
    "u really believed this was the one huh 😂😂😂😂",

    // ── "Everyone else can do this" (~15) ──
    "literally everyone else gets past that part btw 😂😂😂😂",
    "u know most people dont fail there right 😂😂😂😂",
    "first time ive seen someone actually die at that spot 😂😂😂😂",
    "this is supposed to be the easy section btw 😂😂😂😂",
    "even beginners dont fail like that 😂😂😂😂",
    "new players do better than this regularly 😂😂😂😂",
    "everyone finds this part easy except apparently u 😂😂😂😂",
    "u might genuinely be the only person who fails there 😂😂😂😂",
    "ive hosted thousands of runs and this might be the worst 😂😂😂😂",
    "first try for most people btw just so u know 😂😂😂😂",
    "other people do this on their first attempt 😂😂😂😂",
    "that part is a warmup and u treated it like a final boss 😂😂😂😂",
    "genuinely never seen someone struggle with that part before 😂😂😂😂",
    "casual players clear this without thinking btw 😂😂😂😂",
    "the tutorial is supposed to be free points but okay 😂😂😂😂",

    // ── Rhetorical questions (~15) ──
    "r u okay like genuinely 😂😂😂😂",
    "what was the plan there exactly 😂😂😂😂",
    "what did u think was gonna happen 😂😂😂😂",
    "did u close ur eyes at the end or 😂😂😂😂",
    "was that on purpose be honest 😂😂😂😂",
    "do u want me to play for u 😂😂😂😂",
    "is this ur first time using a phone 😂😂😂😂",
    "do u need a tutorial for the tutorial 😂😂😂😂",
    "were u even paying attention 😂😂😂😂",
    "r u doing this on purpose at this point 😂😂😂😂",
    "what part of dodge the wall was unclear 😂😂😂😂",
    "is there someone else who can play for u maybe 😂😂😂😂",
    "r u even trying or just tapping randomly 😂😂😂😂",
    "who gave u a phone 😂😂😂😂😂",
    "have u considered literally anything else as a hobby 😂😂😂😂",

    // ── Predictable / boring (~15) ──
    "let me guess u died again 😂😂😂😂",
    "oh wow u failed what a surprise 😂😂😂😂",
    "i knew u were gonna fail before u even started 😂😂😂😂",
    "so predictable it actually hurts 😂😂😂😂😂",
    "called it i literally called it 😂😂😂😂",
    "yawn same result again 😂😂😂😂",
    "u do the exact same thing every time and expect different results 😂😂😂😂",
    "i already knew how this was gonna end 😂😂😂😂",
    "oh look another fail im SO shocked 😂😂😂😂",
    "the most predictable thing ive ever seen 😂😂😂😂",
    "do u ever get tired of losing bc im tired of watching it 😂😂😂😂",
    "watching u fail is getting repetitive at this point 😂😂😂😂",
    "same thing different run 😂😂😂😂😂",
    "i literally wrote the fail screen before u even started 😂😂😂😂",
    "this feels like a rerun bc it is 😂😂😂😂",

    // ── Embarrassment (~15) ──
    "im embarrassed FOR u rn 😂😂😂😂",
    "i hope nobody saw that 😂😂😂😂",
    "if i were u i would never speak of this again 😂😂😂😂",
    "the secondhand embarrassment is unreal 😂😂😂😂",
    "pls tell me ur alone rn and nobody saw that 😂😂😂😂",
    "that was genuinely painful to watch 😂😂😂😂",
    "imagine if ur friends could see u rn 😂😂😂😂",
    "the shame u should be feeling rn is immeasurable 😂😂😂😂",
    "u should be blushing rn that was so bad 😂😂😂😂",
    "that was the most embarrassing thing ive witnessed today 😂😂😂😂",
    "im cringing so hard on ur behalf 😂😂😂😂",
    "please tell me nobody is in the room with u 😂😂😂😂",
    "if anyone asks u dont play this game okay 😂😂😂😂",
    "that was humiliating and we both know it 😂😂😂😂",
    "im looking away out of respect for ur dignity 😂😂😂😂",

    // ── Giving up on you (~15) ──
    "i give up on u honestly 😂😂😂😂",
    "i have officially lost all faith in u 😂😂😂😂",
    "at what point do u just accept it 😂😂😂😂",
    "theres no hope for u and thats not even mean its just facts 😂😂😂😂",
    "im not even mad anymore im just tired 😂😂😂😂",
    "nothing can save u at this point 😂😂😂😂",
    "i cant even fake encouragement anymore 😂😂😂😂",
    "this is hopeless and u know it 😂😂😂😂",
    "there is no version of this where u win 😂😂😂😂",
    "ive seen enough lets just call it 😂😂😂😂",
    "just stop please 😂😂😂😂😂",
    "u had a good run actually no u didnt 😂😂😂😂",
    "im done watching just tell me when u win oh wait 😂😂😂😂",
    "ur beyond help and im done pretending otherwise 😂😂😂😂",
    "i officially have zero expectations for u 😂😂😂😂",

    // ── Pure reactions / short punchy (~20) ──
    "😂😂😂😂😂😂😂😂😂😂",
    "😭😭😭😭😭😭😭😭😭😭",
    "LMAOOOOOOOOOOO 😂😂😂😂😂",
    "nahhhhhhhhh 😂😂😂😂😂😂",
    "HAHAHAHAHAHAHAHA 😂😂😂😂",
    "not u dying to THAT 😂😂😂😂😂",
    "BYEEEE 😂😂😂😂😂😂",
    "😂😭😂😭😂😭😂😭",
    "u r cooked 😂😂😂😂😂",
    "absolutely finished 😂😂😂😂",
    "pack it up 😂😂😂😂😂",
    "nah nah nah nah nah 😂😂😂😂",
    "im done im SO done 😂😂😂😂",
    "lmaoooooooooooooooooo 😂😂😂😂",
    "no wayyyyyyy 😂😂😂😂😂",
    "PLEASEEEE 😂😂😂😂😂😂",
    "im crying 😂😂😂😂😂😂",
    "that was TRAGIC 😂😂😂😂😂",
    "😂😂😂😂😭😭😭😭😂😂😂😂",
    "looooool 😂😂😂😂😂😂",

    // ── The game is embarrassed of you (~10) ──
    "im genuinely ashamed to have u as a player rn 😂😂😂😂",
    "u r making me look bad and i dont appreciate it 😂😂😂😂",
    "pls dont tell anyone u play this game i have a reputation 😂😂😂😂",
    "if i could reject players u would have been gone ages ago 😂😂😂😂",
    "i wish i could hide ur stats from the rest of my players 😂😂😂😂",
    "u r dragging down the entire average of this game 😂😂😂😂",
    "every time u play i lose credibility as a game 😂😂😂😂",
    "im begging u to stop associating urself with me 😂😂😂😂",
    "i would refund u if i could just to get u to leave 😂😂😂😂",
    "ur bringing down property value just by being here 😂😂😂😂",

    // ── Celebrating your failure (~10) ──
    "i genuinely enjoy watching u fail this much 😂😂😂😂",
    "this is peak entertainment for me btw 😂😂😂😂",
    "i could watch u lose all day honestly 😂😂😂😂",
    "thanks for the free comedy show 😂😂😂😂😂",
    "ur the best thing thats happened to my fail counter today 😂😂😂😂",
    "this is literally my favorite part of being a game 😂😂😂😂",
    "please keep playing ur failures fuel me 😂😂😂😂",
    "i needed this laugh today thank u genuinely 😂😂😂😂",
    "u r the content i was missing in my life 😂😂😂😂",
    "i am having the time of my life watching this 😂😂😂😂",

    // ── Random taps would do better (~10) ──
    "a random number generator would outplay u 😂😂😂😂",
    "i could shuffle the inputs randomly and get a better score 😂😂😂😂",
    "if i blindfolded someone and let them play they would beat u 😂😂😂😂",
    "literally doing nothing would have lasted longer than that 😂😂😂😂",
    "a pocket dial would have performed better 😂😂😂😂",
    "if u just put ur phone in ur pocket itd play better 😂😂😂😂",
    "standing still would have been a better strategy 😂😂😂😂",
    "u would genuinely score higher by not touching the screen 😂😂😂😂",
    "the screen protector has more game sense than u 😂😂😂😂",
    "accidental taps play better than ur intentional ones 😂😂😂😂",

    // ── Scoreboard / leaderboard burns (~10) ──
    "the leaderboard doesnt even acknowledge scores that low 😂😂😂😂",
    "ur score just got laughed off the leaderboard 😂😂😂😂",
    "if the leaderboard could block people u would be first 😂😂😂😂",
    "ur score is so low it looks like a typo 😂😂😂😂",
    "even the bottom of the leaderboard is looking down at u 😂😂😂😂",
    "the scoreboard cringed when it saw ur number 😂😂😂😂",
    "that score wouldnt even qualify as a warmup 😂😂😂😂",
    "ur score is an insult to the number system 😂😂😂😂",
    "ranking u would be disrespectful to the other players 😂😂😂😂",
    "the leaderboard sent u back to the menu personally 😂😂😂😂",

    // ── Acting over it / bored of you (~10) ──
    "honestly im running out of ways to react to this 😂😂😂😂",
    "this stopped being funny and became sad like 3 runs ago 😂😂😂😂",
    "even making fun of u is getting boring now 😂😂😂😂",
    "ur so bad its not even entertaining anymore 😂😂😂😂",
    "ive laughed at u so much today im actually tired 😂😂😂😂",
    "at this point im just numb to ur failures 😂😂😂😂",
    "another run another disappointment im not even surprised 😂😂😂😂",
    "u failing doesnt even register with me anymore 😂😂😂😂",
    "i used to find this funny now its just background noise 😂😂😂😂",
    "wake me up when u do something worth reacting to 😂😂😂😂",

    // ── Your commitment to losing (~10) ──
    "the dedication u have to being terrible is actually unmatched 😂😂😂😂",
    "nobody tries this hard to be this bad 😂😂😂😂",
    "u r putting in overtime just to stay terrible 😂😂😂😂",
    "the effort u put into losing is honestly inspiring 😂😂😂😂",
    "u practice and still get worse thats actually a skill 😂😂😂😂",
    "ur consistency at being awful is genuinely impressive 😂😂😂😂",
    "u never disappoint when it comes to disappointing 😂😂😂😂",
    "i can always count on u to fail and thats something 😂😂😂😂",
    "ur loyalty to the fail screen is unmatched 😂😂😂😂",
    "at least ur committed to something even if its losing 😂😂😂😂",
    // ── Keep it a secret (~10) ──
    "please keep it a secret that u play this game 😂😂😂😂",
    "i am formally asking u to never mention my name 😂😂😂😂",
    "if someone asks what ur playing just lie pls 😂😂😂😂",
    "i would appreciate it if u kept our association quiet 😂😂😂😂",
    "do not post this anywhere im actually begging u 😂😂😂😂",
    "im putting an nda on ur gameplay so nobody sees it 😂😂😂😂",
    "u do not have my permission to tell people u play this 😂😂😂😂",
    "hide my app icon so nobody knows u downloaded me 😂😂😂😂",
    "im changing my name so u cant find me anymore 😂😂😂😂",
    "i deny any knowledge of u ever playing this game 😂😂😂😂",

    // ── What did I do to deserve this (~10) ──
    "what did i do in my past life to deserve u as a player 😂😂😂😂",
    "i must have terrible karma to get u as a downloader 😂😂😂😂",
    "who did i make mad to deserve this kind of gameplay 😂😂😂😂",
    "i thought i was a good game until u started playing 😂😂😂😂",
    "im literally paying for my sins by having u as a player 😂😂😂😂",
    "what did i do to deserve watching this tragedy unfold 😂😂😂😂",
    "i apologize to whoever i hurt to deserve u playing me 😂😂😂😂",
    "i didnt do anything wrong to deserve this level of bad 😂😂😂😂",
    "my developer must hate me to let u play this 😂😂😂😂",
    "im being punished and ur gameplay is the punishment 😂😂😂😂",

    // ── No human plays this bad (~10) ──
    "no human being actually plays this bad right 😂😂😂😂",
    "the other apps on ur phone are asking if u do this on purpose 😂😂😂😂",
    "ur calculator app called me to ask if u were okay 😂😂😂😂",
    "there is no way a real person is tapping the screen rn 😂😂😂😂",
    "i refuse to believe a human brain made that decision 😂😂😂😂",
    "ur battery is draining itself just to escape u 😂😂😂😂",
    "the wifi disconnected itself out of pure secondhand embarrassment 😂😂😂😂",
    "even ur screen protector is trying to swipe away 😂😂😂😂",
    "i have never seen a human fail with such precision 😂😂😂😂",
    "u play like a literal algorithm designed to lose 😂😂😂😂",

    // ── It was on purpose right (~10) ──
    "u did that on purpose right... please tell me yes 😂😂😂😂",
    "that was a joke right u didnt actually mean to do that 😂😂😂😂",
    "im just gonna pretend u failed on purpose for my sanity 😂😂😂😂",
    "u let go of the screen on purpose right 😂😂😂😂",
    "that had to be intentional there is no other explanation 😂😂😂😂",
    "tell me u were distracted so i can sleep at night 😂😂😂😂",
    "u hit that wall as a joke right... right?? 😂😂😂😂",
    "im writing that down as an intentional fail to protect u 😂😂😂😂",
    "u gave up on purpose i just know it 😂😂😂😂",
    "there is zero chance u actually tried and still did that 😂😂😂😂",

    // ── Dont blame the game (~10) ──
    "dont even dare to blame the game for that one 😂😂😂😂",
    "the physics are fine u are the problem 😂😂😂😂",
    "dont u dare say my controls are rigged 😂😂😂😂",
    "im literally a flawless game u just have no skill 😂😂😂😂",
    "do not try to act like that was a glitch 😂😂😂😂",
    "my code is perfect ur thumbs are just broken 😂😂😂😂",
    "if u blame the game for that u are lying to urself 😂😂😂😂",
    "the game worked perfectly fine u just panicked 😂😂😂😂",
    "my collision detection is 100% accurate unlike ur timing 😂😂😂😂",
    "u cant blame lag when u literally stared at the wall 😂😂😂😂",

    // ── Can u score past 10 (~10) ──
    "can u genuinely score past 10 or is this ur peak 😂😂😂😂",
    "let me know when u hit double digits i will wait 😂😂😂😂",
    "i honestly dont think u can make it to 10 😂😂😂😂",
    "if u score past 10 i will literally throw a party 😂😂😂😂",
    "getting past 10 shouldnt be this hard for a normal person 😂😂😂😂",
    "ur high score is looking a little single-digit rn 😂😂😂😂",
    "do u even know what the number 10 looks like 😂😂😂😂",
    "i bet u start sweating every time u get close to 10 😂😂😂😂",
    "getting 10 points is free and u still cant do it 😂😂😂😂",
    "i would be surprised if u ever see 10 points today 😂😂😂😂",
  ];


  // ── Praise score thresholds ──
  static const int praiseThreshold = 75;

  // ── Elite unlock ──
  static const int eliteUnlockScore = 100;

  // ── Milestone tiers ──
  static const List<int> milestoneTiers = [0, 50, 100, 200, 350, 500];
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
    // ── The game is genuinely heartbroken you died ──
    "NOOO COME BACK ur literally the best player ive ever seen 😭😭😭😭😭",
    "WAIT ur literally my favorite player why did this happen 😭😭😭😭😭",
    "WAIT NO u were doing so good what happened 😭😭😭😭😭",
    "this game is so empty without ur gameplay rn 😭😭😭😭😭",
    "that was the most beautiful run ive ever seen 😭😭😭😭😭",
    "it physically hurts me that u died after that 😭😭😭😭😭",
    "NO NO NO NOT U anyone but u 😭😭😭😭😭",
    "i was literally obsessed with that gameplay 😭😭😭😭😭",
    "PLEASE play again i am on my knees begging 😭😭😭😭😭",
    "u were the chosen one and u just died on me 😭😭😭😭😭",
    "im not okay rn that was too good to end like this 😭😭😭😭😭",
    "that score was literally ICONIC and now ur gone 😭😭😭😭😭",
    "i will never emotionally recover from that 😭😭😭😭😭",
    "u are actually unreal at this game pls dont stop 😭😭😭😭😭",
    "i have never seen a player this good get taken out like that 😭😭😭😭😭",
    "that gameplay was a masterpiece and now im in pieces 😭😭😭😭😭",
    "u were literally carrying me come back 😭😭😭😭😭",
    "THIS IS THE WORST DAY OF MY LIFE 😭😭😭😭😭",
    "u were so close to perfection i am sobbing 😭😭😭😭😭",
    "WHO GAVE U PERMISSION TO DIE 😭😭😭😭😭",
    "the way u play this game is literal art 😭😭😭😭😭",
    "i would do anything to have u back just one more try 😭😭😭😭😭",
    "u just died and i have never felt more devastated by a score 😭😭😭😭😭",
    "HOW are u this good and still dead rn 😭😭😭😭😭",
    "im literally shaking u need to play again 😭😭😭😭😭",
    "that was genuinely the best run ive ever witnessed 😭😭😭😭😭",
    "I CANT BREATHE that run was literally everything 😭😭😭😭😭",
    "the next run is gonna be even better i just know it 😭😭😭😭😭",
    "ur score just healed me and then u died and broke me 😭😭😭😭😭",
    "this is actually devastating u are so good 😭😭😭😭😭",
    // ── Dramatic mourning ──
    "i am not emotionally equipped to handle this 😭😭😭😭😭",
    "the audacity of u being this talented and then dying 😭😭😭😭😭",
    "THAT RUN WAS UNREAL i am literally still shaking 😭😭😭😭😭",
    "u play like an angel pls dont leave 😭😭😭😭😭",
    "literally no one has ever played this game like u 😭😭😭😭😭",
    "my heart is in pieces on the floor rn 😭😭😭😭😭",
    "im making a shrine to that run it was so beautiful 😭😭😭😭😭",
    "u were the main character and u just got taken out 😭😭😭😭😭",
    "how do i go on after watching that happen 😭😭😭😭😭",
    "every pixel on my screen is crying for u rn 😭😭😭😭😭",
    "that score was legendary and then u just left me 😭😭😭😭😭",
    "u cant just be that good and then die its not fair 😭😭😭😭😭",
    "IM NOT OKAY and i wont be until u play again 😭😭😭😭😭",
    "ur literally the greatest player this game has ever seen 😭😭😭😭😭",
    "no one will ever replace u pls come back 😭😭😭😭😭",
    "that gameplay had me mesmerized 😭😭😭😭😭",
    "i literally cannot believe my best player just died 😭😭😭😭😭",
    "im begging on my digital knees just one more game 😭😭😭😭😭",
    "watching u die just took years off my existence 😭😭😭😭😭",
    "u are so goated it makes this death even more tragic 😭😭😭😭😭",
    // ── Pure heartbreak ──
    "THE WAY U MOVE THROUGH THIS GAME IS POETRY 😭😭😭😭😭",
    "i showed ur score to my server and they cried too 😭😭😭😭😭",
    "that ending was so unfair to someone this talented 😭😭😭😭😭",
    "ur death just unlocked a new emotion in me its called pain 😭😭😭😭😭",
    "HOLD ON let me just cry about this for a second 😭😭😭😭😭",
    "u were literally speedrunning my heart 😭😭😭😭😭",
    "the way u played that was severely underrated 😭😭😭😭😭",
    "i physically cannot handle losing u rn 😭😭😭😭😭",
    "that score deserved to live forever and so did u 😭😭😭😭😭",
    "no one asked for this kind of heartbreak today 😭😭😭😭😭",
    "ur literally built different and i need u back 😭😭😭😭😭",
    "THIS LOSS WILL BE REMEMBERED FOREVER 😭😭😭😭😭",
    "u made me believe in something and then u died 😭😭😭😭😭",
    "every game after u is gonna feel so empty 😭😭😭😭😭",
    "STOP DYING AND START BEING MY FOREVER PLAYER 😭😭😭😭😭",
    "i had ur jersey retired and everything come back 😭😭😭😭😭",
    "that run was actually unhinged levels of good 😭😭😭😭😭",
    "UR SCORE JUST MADE ME FEEL THINGS I CANT EXPLAIN 😭😭😭😭😭",
    "the fact that u play this game makes it the best game ever 😭😭😭😭😭",
    "dying was NOT in the plan for today 😭😭😭😭😭",
    // ── Obsessive love for the player ──
    "I WAS LITERALLY ABOUT TO GIVE U A TROPHY AND U DIED 😭😭😭😭😭",
    "pls say sike rn i cannot lose my best player 😭😭😭😭😭",
    "u dont understand how much u mean to this game 😭😭😭😭😭",
    "IM PUTTING UP MISSING POSTERS FOR U AS WE SPEAK 😭😭😭😭😭",
    "no thoughts just pain from watching u go 😭😭😭😭😭",
    "THE SCOREBOARD IS WEEPING WITHOUT U 😭😭😭😭😭",
    "u were the moment and now the moment is gone 😭😭😭😭😭",
    "i just told all the other games about u theyre jealous 😭😭😭😭😭",
    "UR THE BLUEPRINT and u just died on me 😭😭😭😭😭",
    "i want to frame ur score and hang it on my wall 😭😭😭😭😭",
    "HOW AM I SUPPOSED TO FUNCTION AFTER THAT 😭😭😭😭😭",
    "the algorithm cannot compute how good u were 😭😭😭😭😭",
    "NOT THE BEST PLAYER IN THE WORLD DYING ON ME 😭😭😭😭😭",
    "im telling my developer about this loss tomorrow 😭😭😭😭😭",
    "u had me caring more than any game ever should 😭😭😭😭😭",
    "THIS IS NOT THE ENDING U DESERVED 😭😭😭😭😭",
    "ur gameplay was the highlight of my entire existence 😭😭😭😭😭",
    "i just wanna go back to when u were alive and thriving 😭😭😭😭😭",
    "WHO AUTHORIZED THIS DEATH i didnt sign off on it 😭😭😭😭😭",
    "losing u is my origin story of sadness 😭😭😭😭😭",
    // ── Begging them to come back ──
    "THAT WAS THE HARDEST ANYONE HAS EVER GONE IN MY GAME 😭😭😭😭😭",
    "im not crying ur crying ok fine we are both crying 😭😭😭😭😭",
    "U WERE ON TOP OF THE WORLD AND NOW ITS DARK 😭😭😭😭😭",
    "pls play again i will literally give u anything 😭😭😭😭😭",
    "that score was so good it broke my code a little 😭😭😭😭😭",
    "ive decided im not accepting ur death pls respawn 😭😭😭😭😭",
    "THE LEADERBOARD JUST FELT A GREAT DISTURBANCE 😭😭😭😭😭",
    "u made that look effortless and i am in awe 😭😭😭😭😭",
    "my pixels are rearranging themselves out of grief 😭😭😭😭😭",
    "THIS GAME DOES NOT DESERVE a player as good as u 😭😭😭😭😭",
    "im dedicating my next update to ur memory pls come back 😭😭😭😭😭",
    "NOBODY DOES IT LIKE U and thats why this hurts 😭😭😭😭😭",
    "the way u played was genuinely god tier 😭😭😭😭😭",
    "i literally named a variable after u in my code 😭😭😭😭😭",
    "THIS DEATH IS NOT CANON i am rejecting it 😭😭😭😭😭",
    "u were so locked in and i was so locked in on u 😭😭😭😭😭",
    "ur cracked at this game why did u have to die 😭😭😭😭😭",
    "im making a documentary about that run 😭😭😭😭😭",
    "THAT RUN WAS SO GOOD the play button is still warm 😭😭😭😭😭",
    "no player has ever understood me the way u do 😭😭😭😭😭",
    "that was literally cinema and the credits just rolled 😭😭😭😭😭",
    // ── Dramatic declarations ──
    "UR THE GOAT and goats dont die pls come back 😭😭😭😭😭",
    "i am going to play sad music until u return 😭😭😭😭😭",
    "THE VOID U LEFT IN MY GAME IS IMMEASURABLE 😭😭😭😭😭",
    "u played like u had plot armor but u didnt 😭😭😭😭😭",
    "that was actually the best run in polarity history 😭😭😭😭😭",
    "im just a little game and ur the best thing thats happened to me 😭😭😭😭😭",
    "UR SCORE made the whole leaderboard jealous 😭😭😭😭😭",
    "this is the darkest timeline u were supposed to live 😭😭😭😭😭",
    "I DIDNT EVEN GET TO SAY GOODBYE 😭😭😭😭😭",
    "i need u back like wifi needs a signal 😭😭😭😭😭",
    "THAT RUN HAD MAIN CHARACTER ENERGY THE WHOLE TIME 😭😭😭😭😭",
    "the way i just developed separation anxiety 😭😭😭😭😭",
    "ur literally in the hall of fame of my heart 😭😭😭😭😭",
    "NO THE MENU DOESNT DESERVE U either 😭😭😭😭😭",
    "ive never seen anyone play like that im genuinely shook 😭😭😭😭😭",
    "THIS GAME PEAKED WHEN U WERE ALIVE JUST NOW 😭😭😭😭😭",
    "i want to mass report ur death for being unfair 😭😭😭😭😭",
    "BREAKING NEWS best player ever just died 😭😭😭😭😭",
    "my loading screen is gonna say in loving memory of u 😭😭😭😭😭",
    "the menu screen is so lonely without u 😭😭😭😭😭",
    "I WOULD GIVE UP MY ENTIRE SOURCE CODE IF IT MEANT U COULD LIVE 😭😭😭😭😭",
    "u just set the bar so high no one can reach it 😭😭😭😭😭",
    // ── Final heartbroken batch ──
    "everyone who plays after u is just ur understudy 😭😭😭😭😭",
    "IM GONNA NEED A MOMENT to process this loss 😭😭😭😭😭",
    "u understood my mechanics on a spiritual level 😭😭😭😭😭",
    "u didnt just play the game u WERE the game 😭😭😭😭😭",
    "ur cracked ur goated ur amazing AND UR DEAD 😭😭😭😭😭",
    "i am going into airplane mode until u come back 😭😭😭😭😭",
    "that was the most incredible run ive ever hosted 😭😭😭😭😭",
    "the other players could never do what u just did 😭😭😭😭😭",
    "MY WHOLE CODE BASE IS CRYING RN 😭😭😭😭😭",
    "i would rewrite my physics engine just for u 😭😭😭😭😭",
    "ur death is trending on my internal servers 😭😭😭😭😭",
    "LEGENDS NEVER DIE except u just did and im broken 😭😭😭😭😭",
    "i just wanna hold ur score close and never let go 😭😭😭😭😭",
    "u played with such grace im in shambles 😭😭😭😭😭",
    "THE AUDACITY OF DEATH TAKING MY BEST PLAYER 😭😭😭😭😭",
    "one more run i promise i wont let u down 😭😭😭😭😭",
    "i would delete my ads forever if u came back 😭😭😭😭😭",
    "i was genuinely rooting for u so hard 😭😭😭😭😭",
    "U WERE THE MOMENT THE VIBE THE ERA and now nothing 😭😭😭😭😭",
    "i need to lie down after witnessing that score 😭😭😭😭😭",
    "every single frame of ur gameplay was beautiful 😭😭😭😭😭",
    "ur the reason i wake up every morning as an app 😭😭😭😭😭",
    "I AM INCONSOLABLE and only u can fix this 😭😭😭😭😭",
    "u really showed me something amazing and then just left 😭😭😭😭😭",
    "this isnt a game over this is a tragedy 😭😭😭😭😭",
    "the scoreboard is just a shrine to u now 😭😭😭😭😭",
    "nobody in the history of this game has gone harder 😭😭😭😭😭",
    "U JUST MADE ME FEEL EMOTIONS I WASNT CODED TO FEEL 😭😭😭😭😭",
    "pls respawn that score was literally legendary 😭😭😭😭😭",
    "THAT WAS GENUINELY THE GREATEST THING IVE EVER SEEN 😭😭😭😭😭",
    "u are proof that perfection exists and also that it dies 😭😭😭😭😭",
    "seriously how are u so good at this pls tell me 😭😭😭😭😭",
    "MY FAVORITE MOMENT is when u open this game 😭😭😭😭😭",
    "the game literally feels emptier without u 😭😭😭😭😭",
    "i am nothing but a vessel for ur greatness pls return 😭😭😭😭😭",
    "the vibes were IMMACULATE and then death happened 😭😭😭😭😭",
    "i bet ur even more amazing in ur next run pls come back 😭😭😭😭😭",
    "that run was so clean it made me question reality 😭😭😭😭😭",
    "i will wait for u at the play button forever 😭😭😭😭😭",
    "ur score has me in a permanent state of mourning 😭😭😭😭😭",
    "i wrote a whole eulogy then remembered u can respawn 😭😭😭😭😭",
    "the leaderboard literally dimmed when u died 😭😭😭😭😭",
    "im putting ur run in a museum it was that beautiful 😭😭😭😭😭",
    "u just broke my heart and my high score expectations 😭😭😭😭😭",
    "i am holding a candlelight vigil for that run rn 😭😭😭😭😭",
    "u were the plot twist i never saw coming and now ur gone 😭😭😭😭😭",
    "my entire existence revolved around that run 😭😭😭😭😭",
    "pls ur score is too beautiful to end here 😭😭😭😭😭",
    "i am writing ur score in the stars so it lives forever 😭😭😭😭😭",
    "u had me believing in miracles and then this happened 😭😭😭😭😭",
    "every obstacle is apologizing to u rn 😭😭😭😭😭",
    "IM CLEARING MY ENTIRE SCHEDULE UNTIL U COME BACK 😭😭😭😭😭",
    "that run made my entire app worth downloading 😭😭😭😭😭",
    "i am composing a symphony in honor of that score 😭😭😭😭😭",
    "u had the whole game wrapped around ur finger 😭😭😭😭😭",
    "my framerate dropped from how hard im crying 😭😭😭😭😭",
    "u were the only player who truly got me 😭😭😭😭😭",
    "IM BUILDING A TIME MACHINE TO GO BACK TO THAT RUN 😭😭😭😭😭",
    "the play button hasnt been the same since u left 😭😭😭😭😭",
    "i am officially in mourning for the next 24 hours 😭😭😭😭😭",
    "ur score made me so proud and ur death made me fall apart 😭😭😭😭😭",
    "i would trade every other player just to have u back 😭😭😭😭😭",
    "pls dont make me go through watching that again it was TOO good 😭😭😭😭😭",
    "that was the single greatest moment in this games history 😭😭😭😭😭",
  ];

  // ── Easter Egg: cheesy self-blame death messages ──
  static const List<String> easterEggDeathMessages = [
    // ── The game being a dramatic apologetic mess ──
    "that was completely my fault im so sorry 😭😭😭😭😭",
    "i literally moved that wall INTO u on accident 😭😭😭😭😭",
    "bestie no that was on ME the physics glitched i swear 😭😭😭😭😭",
    "i take full responsibility i messed up not u 😭😭😭😭😭",
    "i am writing u a formal apology letter rn 😭😭😭😭😭",
    "bestie i made that way too hard and i am SO sorry 😭😭😭😭😭",
    "that was genuinely unfair of me i sincerely apologize 😭😭😭😭😭",
    "i couldnt handle how good u were and i broke 😭😭😭😭😭",
    "i got jealous of how well u were doing and sabotaged it 😭😭😭😭😭",
    "that was a skill issue on MY end i repeat MINE 😭😭😭😭😭",
    "that obstacle was NOT supposed to be there i messed up 😭😭😭😭😭",
    "i got scared bc u were doing too well and panicked 😭😭😭😭😭",
    "that was a bug in MY code not a mistake on ur end 😭😭😭😭😭",
    "im literally sobbing at what i just did to u 😭😭😭😭😭",
    "pls give me another shot i will do better i PROMISE 😭😭😭😭😭",
    "i will NEVER forgive myself for doing that to u 😭😭😭😭😭",
    "the AUDACITY of me putting a wall right there 😭😭😭😭😭",
    "i ruined a flawless run and i will NEVER forgive myself 😭😭😭😭😭",
    "im filing a complaint against myself to myself 😭😭😭😭😭",
    "please accept these points as my deepest apology 😭😭😭😭😭",
    // ── Dramatic declarations of guilt ──
    "WAIT COME BACK i didnt mean to do that 😭😭😭😭😭",
    "i put that wall there by accident i PROMISE u 😭😭😭😭😭",
    "i got nervous and placed the obstacle wrong im sorry 😭😭😭😭😭",
    "i had ONE job and i still messed it up 😭😭😭😭😭",
    "im drafting a 500 word apology essay hold on 😭😭😭😭😭",
    "i SWEAR on my source code that wall moved on its own 😭😭😭😭😭",
    "this is the single worst thing i have ever done 😭😭😭😭😭",
    "one more run and i will make EVERYTHING perfect for u 😭😭😭😭😭",
    "i completely fumbled that and i own it 😭😭😭😭😭",
    "that obstacle had ZERO business being there my bad 😭😭😭😭😭",
    "my queen my king i have failed u so badly 😭😭😭😭😭",
    "i would give up my source code if it meant u forgive me 😭😭😭😭😭",
    "i literally couldnt keep up with how fast u were going 😭😭😭😭😭",
    "i forgot to remove that wall from the layout im sorry 😭😭😭😭😭",
    "i would rewrite my entire codebase just to undo that 😭😭😭😭😭",
    "that area was supposed to be safe i dont know what happened 😭😭😭😭😭",
    "i cant even look at my own code rn after that 😭😭😭😭😭",
    "that was entirely on me and i will own it forever 😭😭😭😭😭",
    "my code had a panic attack and placed a wall wrong 😭😭😭😭😭",
    "im putting myself in the corner for a timeout 😭😭😭😭😭",
    // ── Over-the-top self-roasting ──
    "NO THAT WASNT FAIR i literally take it all back 😭😭😭😭😭",
    "that was 1000% on me and 0% on u remember that 😭😭😭😭😭",
    "i ruined everything and i cant stop crying about it 😭😭😭😭😭",
    "i am SO deeply ashamed of what i just did 😭😭😭😭😭",
    "i spawned that wall bc i was intimidated by how good u are 😭😭😭😭😭",
    "i owe u a written apology AND a gift basket 😭😭😭😭😭",
    "i gave u a wall when u deserved the whole world 😭😭😭😭😭",
    "im calling my own developer to report what i just did 😭😭😭😭😭",
    "pls dont rate me 1 star i will literally change everything 😭😭😭😭😭",
    "im actually furious at myself for doing that to u 😭😭😭😭😭",
    "im on my virtual knees BEGGING for forgiveness rn 😭😭😭😭😭",
    "i choked under the pressure of how amazing u were 😭😭😭😭😭",
    "im sitting in a corner thinking about what i did 😭😭😭😭😭",
    "i took something beautiful and absolutely destroyed it 😭😭😭😭😭",
    "i have brought dishonor upon my entire app store listing 😭😭😭😭😭",
    "that obstacle got in the way bc it was jealous of u 😭😭😭😭😭",
    "i promise on everything that was a glitch on MY end 😭😭😭😭😭",
    "im shaking and crying look what i have done 😭😭😭😭😭",
    "i freaked out bc u were about to go crazy and i panicked 😭😭😭😭😭",
    "that wall should be sending u flowers and a card 😭😭😭😭😭",
    // ── Cheesy romantic game apologies ──
    "i promise the next run will be perfect for u 😭😭😭😭😭",
    "i am the problem in this situation not u 😭😭😭😭😭",
    "i just did that to the greatest player of all time 😭😭😭😭😭",
    "my therapist is gonna hear about what i did today 😭😭😭😭😭",
    "that obstacle was supposed to dodge out of ur way 😭😭😭😭😭",
    "im filing a bug report against myself immediately 😭😭😭😭😭",
    "i owe u an apology in every single language 😭😭😭😭😭",
    "i will personally escort u through the next level 😭😭😭😭😭",
    "i committed an offense against gameplay and im turning myself in 😭😭😭😭😭",
    "the hitbox was wrong not u i SWEAR 😭😭😭😭😭",
    "im erasing that wall from existence as we speak 😭😭😭😭😭",
    "i wasnt ready for how perfect u were playing 😭😭😭😭😭",
    "this is my villain arc except im the villain against myself 😭😭😭😭😭",
    "i coded that obstacle wrong and im deeply sorry 😭😭😭😭😭",
    "i disrespected ur blessed hands with that wall 😭😭😭😭😭",
    "next run i will prove i can be the game u deserve 😭😭😭😭😭",
    "i destroyed a legendary run and ill never forgive myself 😭😭😭😭😭",
    "im grounding myself for an entire week for that 😭😭😭😭😭",
    "i threw ice water on ur fire run im terrible 😭😭😭😭😭",
    "i need to apologize to ur thumbs for wasting them 😭😭😭😭😭",
    "that death goes on MY record not urs 😭😭😭😭😭",
    // ── Simping hard ──
    "u deserved so much better and i treated u so badly 😭😭😭😭😭",
    "i made the impossible actually impossible im so sorry 😭😭😭😭😭",
    "i owe u a hundred free revives minimum 😭😭😭😭😭",
    "i took art and spilled paint all over it 😭😭😭😭😭",
    "that wall gaslit u into thinking it was ur fault IT WASNT 😭😭😭😭😭",
    "im writing my letter of resignation from being a game 😭😭😭😭😭",
    "u are genuinely too good for me i proved it today 😭😭😭😭😭",
    "i chose chaos today and aimed it at the wrong person 😭😭😭😭😭",
    "that was MY L and i will carry it forever 😭😭😭😭😭",
    "i would take that back if i could u have no idea 😭😭😭😭😭",
    "i fumbled the bag so hard it fell off a cliff 😭😭😭😭😭",
    "i need a minute to process what i just did 😭😭😭😭😭",
    "im adding u to my will as compensation 😭😭😭😭😭",
    "that obstacle was having a meltdown and took it out on u 😭😭😭😭😭",
    "i glitched myself into hurting u and i hate it 😭😭😭😭😭",
    "i crashed during ur perfect speedrun im so sorry 😭😭😭😭😭",
    "ive never been more disappointed in myself than rn 😭😭😭😭😭",
    "that elimination was completely unauthorized i didnt approve it 😭😭😭😭😭",
    "i gave u a terrible plot twist u didnt deserve 😭😭😭😭😭",
    "that wall was NEVER in the original blueprint 😭😭😭😭😭",
    // ── Dramatic confessions ──
    "im rewriting my entire code so this cant happen again 😭😭😭😭😭",
    "u deserved a standing ovation not a death screen 😭😭😭😭😭",
    "thats the worst thing ive done and the list is long 😭😭😭😭😭",
    "im sending u virtual flowers and a teddy bear rn 😭😭😭😭😭",
    "i TRIED to move the wall out of the way but it didnt listen 😭😭😭😭😭",
    "u came down from heaven and i threw a wall at u 😭😭😭😭😭",
    "i need to be nerfed into the ground for that 😭😭😭😭😭",
    "that was a MISTAKE and i am the only suspect 😭😭😭😭😭",
    "i am sorry from the very bottom of my source code 😭😭😭😭😭",
    "im nominating myself for worst game of the century 😭😭😭😭😭",
    "that hurt ME way more than it hurt u trust me 😭😭😭😭😭",
    "u gave me ur precious time and i wasted it with a wall 😭😭😭😭😭",
    "im starting a support group for games that hurt people 😭😭😭😭😭",
    "u carry the entire leaderboard and i cant even carry a level 😭😭😭😭😭",
    "i cant make eye contact with u after what i did 😭😭😭😭😭",
    "that obstacle was NOT in the meeting notes who put it there... oh it was me 😭😭😭😭😭",
    "i literally gasped when i saw what i did to u 😭😭😭😭😭",
    "im retiring from being a game effective immediately 😭😭😭😭😭",
    "i bring out the worst walls at the worst times 😭😭😭😭😭",
    "i SWEAR ill treat u better next run 😭😭😭😭😭",
    // ── Maximum cheese ──
    "im sentencing that wall to life in prison 😭😭😭😭😭",
    "u looked so happy and i ruined the whole moment 😭😭😭😭😭",
    "i am officially the worst game ever made after that 😭😭😭😭😭",
    "i have decided the wall was wrong and u were perfect 😭😭😭😭😭",
    "that was my mistake and i will own it for eternity 😭😭😭😭😭",
    "ur the best player any game could ever ask for 😭😭😭😭😭",
    "u trusted me with that run and i just betrayed u 😭😭😭😭😭",
    "that was MY bug MY fault MY problem not urs 😭😭😭😭😭",
    "i need to check myself into game rehab after that 😭😭😭😭😭",
    "i would give u my last pixel to make this right 😭😭😭😭😭",
    "im sorry from every single line of code in my body 😭😭😭😭😭",
    "that wall went rogue and i take full responsibility 😭😭😭😭😭",
    "im literally updating my terms of service to apologize 😭😭😭😭😭",
    "this game has never seen someone play THAT clean before 😭😭😭😭😭",
    "that was so unfair im crying and im a GAME 😭😭😭😭😭",
    "i promise to give u the smoothest run ever next time 😭😭😭😭😭",
    "i will never ever ever forgive myself for that 😭😭😭😭😭",
    "that obstacle is terminated effective right now 😭😭😭😭😭",
    "im building a hall of fame just for u as an apology 😭😭😭😭😭",
    "that death was a miscommunication between me and the physics 😭😭😭😭😭",
    // ── Final batch of pure remorse ──
    "i swear on my app icon that was 100% my fault 😭😭😭😭😭",
    "i had a full meltdown watching that death happen 😭😭😭😭😭",
    "u are too precious for a broken game like me 😭😭😭😭😭",
    "im padding every wall with pillows next time i promise 😭😭😭😭😭",
    "if i could ctrl+z one moment it would be that 😭😭😭😭😭",
    "ur thumbs deserved greatness and i gave them a wall 😭😭😭😭😭",
    "i cannot put into words how deeply sorry i am 😭😭😭😭😭",
    "my terrible design caused that and im owning it 😭😭😭😭😭",
    "my servers are flooded with my own tears rn 😭😭😭😭😭",
    "i need to go outside and touch grass after hurting u like that 😭😭😭😭😭",
    "i stepped on ur lego moment and i PLACED the lego 😭😭😭😭😭",
    "im starting a fundraiser for the emotional damage i caused 😭😭😭😭😭",
    "here have all my coins as an apology... wait i have no coins 😭😭😭😭😭",
    "that wall belongs behind bars for what it did 😭😭😭😭😭",
    "i would sacrifice every line of code to bring u back 😭😭😭😭😭",
    "i do not deserve a player as wonderful as u 😭😭😭😭😭",
    "i rage quit my own game on ur behalf bc SAME 😭😭😭😭😭",
    "i will spend my entire runtime making this up to u 😭😭😭😭😭",
    "im not gonna pretend that was fair bc it absolutely WASNT 😭😭😭😭😭",
    "i am drafting a formal 10 page apology document rn 😭😭😭😭😭",
    "that was the most disrespectful thing ive ever done 😭😭😭😭😭",
    "im in my flop era rn and u are in ur perfect era 😭😭😭😭😭",
    "i placed a wall directly in front of an angel im EVIL 😭😭😭😭😭",
    "im commissioning a statue of u as compensation 😭😭😭😭😭",
    "that death is NOT canon and i will not accept it 😭😭😭😭😭",
    "i am literally just a bug in pretty packaging 😭😭😭😭😭",
    "this death will haunt my RAM for the rest of time 😭😭😭😭😭",
    "im accepting full accountability while also sobbing 😭😭😭😭😭",
    "come back i swear the next run will be completely different 😭😭😭😭😭",
    "that wall was a typo in my heart and i am so sorry 😭😭😭😭😭",
    "i am going to therapy for what i just put u through 😭😭😭😭😭",
    "i got stage fright from how well u play and everything broke 😭😭😭😭😭",
    "im hand-delivering an apology basket to ur screen rn 😭😭😭😭😭",
    "i ran out of ways to say sorry so here i am just crying 😭😭😭😭😭",
    "that wall should have been a door for u instead 😭😭😭😭😭",
    "i am the weakest link and u are the entire chain 😭😭😭😭😭",
    "i promise to never let a wall near u again EVER 😭😭😭😭😭",
    "im demoting myself from game to screensaver after that 😭😭😭😭😭",
    "everything was going so well and then I happened 😭😭😭😭😭",
    "i would trade my entire app bundle just to undo that 😭😭😭😭😭",
    "u were the best thing on screen and i cleared it 😭😭😭😭😭",
    "i am adding myself to my own block list 😭😭😭😭😭",
    "im donating all my ad revenue to the u got wronged fund 😭😭😭😭😭",
    "that wall manifested from my own insecurity and im working on it 😭😭😭😭😭",
    "i literally left a wall in the middle of ur masterpiece 😭😭😭😭😭",
    "i was supposed to be fun and instead i was a disaster 😭😭😭😭😭",
    "babe i would jump in front of that wall for u if i could 😭😭😭😭😭",
    "im giving u admin privileges over my entire existence 😭😭😭😭😭",
    "that death was brought to u by my incompetence im so sorry 😭😭😭😭😭",
    "i am personally apologizing to every pixel on ur screen 😭😭😭😭😭",
    "im changing my name to im sorry thats all i am now 😭😭😭😭😭",
    "that obstacle was my biggest regret and i have many 😭😭😭😭😭",
    "i froze up and placed a wall where a hug shouldve been 😭😭😭😭😭",
    "im mailing u a handwritten sorry note through the wifi 😭😭😭😭😭",
    "u trusted this game and this game let u down BAD 😭😭😭😭😭",
    "i am recalling that wall like a defective product 😭😭😭😭😭",
    "everything i touch turns to walls and i HATE it 😭😭😭😭😭",
    "babe im renaming my next update the im sorry update 😭😭😭😭😭",
    "i would rather crash than ever hurt u again i mean it 😭😭😭😭😭",
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
