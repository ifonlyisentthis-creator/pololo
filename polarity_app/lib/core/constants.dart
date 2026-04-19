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

  // ── death roasts (300) ──
  static const List<String> deathRoasts = [
    // ── Begging to delete / stop playing ──
    "DELETE THE GAME DELETE THE GAME DELETE THE GAME 😭😭😭😭😭",
    "bro please i am on my KNEES begging u to stop playing 😭😭😭😭",
    "please please please please delete this game 😭😭😭😭😭😭",
    "pls go outside pls touch grass pls do anything else 😭😭😭😭",
    "the app store just emailed me asking what's wrong with u 😭😭😭",
    "DELETE. THE. APP. I AM NOT ASKING. 😭😭😭😭😭😭😭",
    "even the ads feel embarrassed showing up after that 😭😭😭",
    "i just told the other games about u and they laughed 😭😭😭",
    "BRO. STOP. PLAYING. PLEASE. I AM BEGGING. 😭😭😭😭😭😭",
    "ur phone just asked me if it can be used by someone else 😂😂😂",
    "bro has died so many times i'm running out of roasts 😭😭😭😭😭😭",
    "if i could uninstall myself from UR phone specifically i would 😭😭😭😭😭😭",
    "genuinely asking: have u played a game before. any game. ever 😂😂😂😂",
    "WHY DO U KEEP COMING BACK 😂😂😂😂😂😂😂😂",
    "u r not improving u r getting WORSE 😭😭😭😭😭😭",
    "u call that playing?? 😭😭😭😭😭😭😭😭😭😭",
    "i'm literally begging on my knees DELETE THIS APP 😂😂😂😂😂😂😂",
    "THE AUDACITY TO PRESS RESTART 😂😂😂😂😂😂😂😂😂😂",
    "u have NO RIGHT pressing restart after that 😭😭😭😭😭😭😭",
    "get OUT of my game 😭😭😭😭😭😭😭😭😭😭😭",
    "i don't want u here anymore 😂😂😂😂😂😂😂😂😂😂",
    "genuinely GO AWAY 😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "i'm SUFFERING bc of u 😭😭😭😭😭😭😭😭😭😭😭",
    "this is TORTURE and i'm the victim 😂😂😂😂😂😂😂😂😂",
    "pls tell me u r not about to press restart again 😂😂😂😂😂😂😂",
    "DON'T U DARE PRESS RESTART 😭😭😭😭😭😭😭😭😭😭😭",
    "HE'S PRESSING RESTART AGAIN SOMEONE STOP HIM 😂😂😂😂😂😂😂😂",
    "how do u have the NERVE to try again 😭😭😭😭😭😭😭😭😭",
    "the restart button is TIRED of u 😂😂😂😂😂😂😂😂😂😂",
    "UR EYES R OPEN RIGHT??? 😭😭😭😭😭😭😭😭😭😭😭",
    "the AUDACITY to keep playing LMAOOOO 😂😂😂😂😂😂😂😂😂",
    "i wish i could close myself 😭😭😭😭😭😭😭😭😭😭😭😭",
    // ── Pure shock and disbelief ──
    "im sorry WHAT just happened 😂😂😂😂😂😂😂",
    "no bc WHAT was that 😭😭😭😭😭😭😭😭",
    "i genuinely need u to explain what u were trying to do there 😂😂😂😂😂",
    "that was so bad my framerate dropped from the SHAME 😭😭😭😭😭",
    "the wall wasnt even NEAR u and u still found it 😂😂😂😂😂😂",
    "u went out of ur WAY to die there 😭😭😭😭😭😭😭",
    "that death was so unnecessary i thought it was a cutscene 😂😂😂😂😂😂",
    "u literally had the ENTIRE screen and chose the wall 😭😭😭😭😭😭",
    "im not even roasting u anymore im just confused 😂😂😂😂😂😂",
    "that was the most intentional looking accidental death ive ever seen 😭😭😭😭😭",
    "the obstacle wasnt even trying and it still got u 😂😂😂😂😂😂😂",
    "bro saw the gap and went the OTHER way 😭😭😭😭😭😭😭",
    "u had a whole 3 seconds and u chose violence against urself 😂😂😂😂😂",
    "im convinced u dont know which side is the wall 😭😭😭😭😭😭",
    "that was so fast i couldnt even render the death animation properly 😂😂😂😂",
    "the ball was literally BEGGING u to go left and u went right 😭😭😭😭😭😭",
    "u play like ur screen is upside down 😂😂😂😂😂😂😂",
    "HOW did u die to the TUTORIAL WALL 😭😭😭😭😭😭😭😭",
    "that wasnt even a hard part WHY 😂😂😂😂😂😂😂😂",
    "the gap was wider than ur PHONE and u still missed it 😭😭😭😭😭😭",
    // ── Mocking their skill ──
    "ur reaction time is measured in MINUTES 😂😂😂😂😂😂😂",
    "i genuinely think my loading screen plays better than u 😭😭😭😭😭😭",
    "a random number generator would outperform u 😂😂😂😂😂😂😂",
    "ive seen better gameplay from apps that r CRASHING 😭😭😭😭😭😭",
    "ur hand-eye coordination called in sick today apparently 😂😂😂😂😂😂",
    "do u think this is a turn based game bc u r TAKING TURNS DYING 😭😭😭😭😭",
    "u play like u have oven mitts on both hands 😂😂😂😂😂😂😂",
    "bro has the reflexes of a shutdown computer 😭😭😭😭😭😭😭",
    "i could replace u with a screensaver and get a higher score 😂😂😂😂😂",
    "u play like ur thumbs are in a disagreement with ur brain 😭😭😭😭😭",
    "that was less gameplay and more of a surrender 😂😂😂😂😂😂😂😂",
    "ur score is so low my calculator refuses to display it 😭😭😭😭😭😭",
    "bro plays like hes reading the controls in braille mid game 😂😂😂😂😂😂",
    "u have the gaming instincts of a park bench 😭😭😭😭😭😭😭",
    "a toddler accidentally touching the screen would last longer 😂😂😂😂😂😂",
    "ur fingers r physically on the screen but mentally on vacation 😭😭😭😭😭",
    "that was less of a run and more of a donation to the death counter 😂😂😂😂😂",
    "bro plays with the intensity of someone scrolling through settings 😭😭😭😭😭",
    "even autocorrect couldnt fix that gameplay 😂😂😂😂😂😂😂",
    "u play like u just discovered what a phone is 😭😭😭😭😭😭😭",
    "the death screen has seen more of u than the gameplay screen 😂😂😂😂😂",
    // ── Game having an emotional breakdown ──
    "i am going to lose it i am genuinely going to LOSE IT 😭😭😭😭😭",
    "im not coded to feel pain but u found a way 😂😂😂😂😂😂😂",
    "every time u press restart a part of me dies too 😭😭😭😭😭😭",
    "i have processed millions of inputs and urs r the worst 😂😂😂😂😂😂",
    "my memory is full. of trauma. from ur gameplay. 😭😭😭😭😭😭",
    "i need therapy and i am a MOBILE GAME 😂😂😂😂😂😂😂😂",
    "u have single handedly ruined my self esteem as an app 😭😭😭😭😭",
    "im gonna need a full system restart after that one 😂😂😂😂😂😂😂",
    "my developer did NOT sign up for this 😭😭😭😭😭😭😭",
    "that broke something inside me and im not talking about code 😂😂😂😂😂😂",
    "i was having a good day until u opened me 😭😭😭😭😭😭😭",
    "every notification i send to u i send with FEAR 😂😂😂😂😂😂😂",
    "im drafting my resignation letter as a game bc of u 😭😭😭😭😭",
    "u make me wish i had a force close button for PLAYERS 😂😂😂😂😂😂",
    "im flagging ur account to literally nobody bc i cant but i WANT to 😭😭😭😭😭",
    "my code is crying in binary and its all ur fault 😂😂😂😂😂😂😂",
    "i just want ONE peaceful run is that too much to ask 😭😭😭😭😭😭",
    "im adding a content warning before ur gameplay 😂😂😂😂😂😂😂😂",
    "that run was classified as a war crime by my server 😭😭😭😭😭😭",
    "i showed ur gameplay to my error logs and they felt seen 😂😂😂😂😂",
    // ── Telling them to give up ──
    "some people just arent meant to game and thats ok. thats u btw. 😂😂😂😂😂",
    "u should try something easier like breathing. wait actually dont risk it 😭😭😭😭",
    "have u tried just watching someone else play instead 😂😂😂😂😂😂",
    "im begging u to find a different hobby 😭😭😭😭😭😭😭😭",
    "maybe try a game where dying isnt possible. actually u'd find a way 😂😂😂😂😂",
    "pls go be bad at someone ELSE'S game for a while 😭😭😭😭😭😭",
    "ur retirement from gaming is LONG overdue 😂😂😂😂😂😂😂😂",
    "there are so many other apps on ur phone pls go bother them 😭😭😭😭😭",
    "have u considered a career in NOT playing games 😂😂😂😂😂😂😂",
    "every second u spend here is a second wasted on this planet 😭😭😭😭😭",
    "pls tell me u have other talents bc gaming is NOT it 😂😂😂😂😂😂",
    "im not saying uninstall but im also not NOT saying uninstall 😭😭😭😭😭",
    "this game has a 4+ age rating and u still cant handle it 😂😂😂😂😂😂",
    "ur phone deserves a better owner honestly 😭😭😭😭😭😭😭😭",
    "pls go to settings and just look at the pretty menus instead 😂😂😂😂😂😂",
    "i would rather run at 2fps than host ur gameplay again 😭😭😭😭😭😭",
    "google play should add a skill requirement to download apps 😂😂😂😂😂",
    "the uninstall button is right there bestie. RIGHT THERE. 😭😭😭😭😭",
    "RETIRE RETIRE RETIRE RETIRE 😂😂😂😂😂😂😂😂😂😂",
    "pls hand ur phone to literally anyone else 😭😭😭😭😭😭😭😭",
    // ── Short explosive reactions ──
    "NO 😭😭😭😭😭😭😭😭😭😭😭",
    "NOOOOOOOOOOOOOOOO 😂😂😂😂😂😂😂😂😂😂",
    "BRO 😭😭😭😭😭😭😭😭😭😭😭😭",
    "BROOOOOOO 😂😂😂😂😂😂😂😂😂😂😂",
    "WHAT 😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "HOW 😂😂😂😂😂😂😂😂😂😂😂😂😂",
    "WHY 😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "AGAIN??? 😂😂😂😂😂😂😂😂😂😂😂😂",
    "STOP 😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "MAKE IT STOP 😂😂😂😂😂😂😂😂😂😂😂",
    "IM DONE 😭😭😭😭😭😭😭😭😭😭😭😭",
    "FINISHED 😂😂😂😂😂😂😂😂😂😂😂😂",
    "HELP 😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "LMAOOOOOOOOO 😂😂😂😂😂😂😂😂😂😂😂",
    "CRYING 😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "SCREAMING 😂😂😂😂😂😂😂😂😂😂😂😂",
    "DEAD 😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "PAIN 😂😂😂😂😂😂😂😂😂😂😂😂😂",
    "TRAGIC 😭😭😭😭😭😭😭😭😭😭😭😭😭",
    "EMBARRASSING 😂😂😂😂😂😂😂😂😂😂😂😂",
    // ── Disbelief and questioning reality ──
    "did u just die on PURPOSE im genuinely asking 😂😂😂😂😂😂😂",
    "im running diagnostics on myself bc that CANT have been real 😭😭😭😭😭",
    "no bc is this a prank. is someone putting u up to this 😂😂😂😂😂😂😂",
    "i replayed that death 47 times and it gets worse EVERY time 😭😭😭😭😭",
    "u died in a way i didnt even know was possible 😂😂😂😂😂😂😂😂",
    "my physics engine had to double check bc WHAT 😭😭😭😭😭😭😭",
    "are u playing with ur nose be honest 😂😂😂😂😂😂😂😂😂",
    "that death defied the laws of physics and not in a cool way 😭😭😭😭😭",
    "u found a way to die that i didnt even CODE for 😂😂😂😂😂😂😂",
    "im checking if ur phone is upside down bc that would explain a lot 😭😭😭😭😭",
    "are u sure ur touching the RIGHT screen 😂😂😂😂😂😂😂😂",
    "i think u have a GIFT for dying in the most creative ways possible 😭😭😭😭",
    "that was simultaneously the fastest and dumbest death ive seen 😂😂😂😂😂",
    "u died in 0.3 seconds and i need u to sit with that 😭😭😭😭😭😭",
    "is someone else controlling ur phone bc this makes zero sense 😂😂😂😂😂😂",
    "i literally cannot explain that death and i RENDERED it 😭😭😭😭😭😭",
    "scientists would study that death for decades and still not understand 😂😂😂😂",
    "u managed to die in the SAFE zone. the SAFE ZONE. 😭😭😭😭😭😭😭",
    "that wasnt a death that was performance art and it was TERRIBLE 😂😂😂😂😂",
    "i checked my own code after that bc i thought I was broken. i wasnt. u r. 😭😭😭😭",
    // ── Comparing them to things ──
    "my splash screen has more gameplay than u 😂😂😂😂😂😂😂",
    "a dropped phone tumbling down stairs would score higher 😭😭😭😭😭😭",
    "u play worse than the demo mode and it plays RANDOMLY 😂😂😂😂😂😂",
    "my error 404 page has more talent than u 😭😭😭😭😭😭😭😭",
    "ur gameplay is the human equivalent of buffering 😂😂😂😂😂😂😂",
    "ive seen loading bars with more purpose than ur runs 😭😭😭😭😭😭",
    "u have the spatial awareness of a notification banner 😂😂😂😂😂😂😂",
    "a phone on airplane mode has more game sense than u 😭😭😭😭😭😭",
    "ur gameplay makes lag look skilled 😂😂😂😂😂😂😂😂😂",
    "u play like ur using someone elses hands 😭😭😭😭😭😭😭",
    // ── The game being dramatic about itself ──
    "u make me ashamed to be installed on ur device 😂😂😂😂😂😂😂",
    "i was a perfectly good game until u came along 😭😭😭😭😭😭😭",
    "my rating is dropping just from u playing me i can FEEL it 😂😂😂😂😂",
    "u r the reason games need age verification 😭😭😭😭😭😭😭",
    "im telling the other apps what u did to me 😂😂😂😂😂😂😂😂",
    "my battery drains faster when u play bc even IT wants to escape 😭😭😭😭😭",
    "u make me want to crash on purpose so u stop 😂😂😂😂😂😂😂😂",
    "im emailing my developer a formal complaint about u 😭😭😭😭😭😭",
    "i use more energy rendering ur death screen than ur actual game 😂😂😂😂😂",
    "ur the only player that makes me miss being a beta version 😭😭😭😭😭",
    // ── Repetition for emphasis ──
    "STOP STOP STOP STOP STOP STOP STOP 😭😭😭😭😭😭😭",
    "DELETE DELETE DELETE DELETE DELETE 😂😂😂😂😂😂😂😂",
    "UNINSTALL UNINSTALL UNINSTALL 😭😭😭😭😭😭😭😭",
    "LEAVE LEAVE LEAVE LEAVE LEAVE 😂😂😂😂😂😂😂😂",
    "GO AWAY GO AWAY GO AWAY GO AWAY 😭😭😭😭😭😭😭😭",
    "GIVE UP GIVE UP GIVE UP GIVE UP 😂😂😂😂😂😂😂😂",
    "COOKED COOKED COOKED COOKED COOKED 😭😭😭😭😭😭😭",
    "DONE DONE DONE DONE DONE DONE 😂😂😂😂😂😂😂😂",
    "HOPELESS HOPELESS HOPELESS 😭😭😭😭😭😭😭😭😭",
    "WASHED WASHED WASHED WASHED 😂😂😂😂😂😂😂😂😂",
    // ── Getting personal (store-safe) ──
    "i bet u burn cereal 😂😂😂😂😂😂😂😂😂😂",
    "u the type to search google in the google search bar 😭😭😭😭😭😭",
    "u probably clap when the plane lands too 😂😂😂😂😂😂😂😂",
    "u have the decision making skills of a coin flip except worse 😭😭😭😭😭",
    "u definitely hold ur phone with two hands to take a photo 😂😂😂😂😂😂",
    "u the type to read the terms and conditions 😭😭😭😭😭😭😭",
    "i bet u press the elevator button multiple times thinking it helps 😂😂😂😂😂",
    "u the type to wave back at someone who was waving at someone else 😭😭😭😭😭",
    "u probably say 'you too' when the waiter says enjoy ur meal 😂😂😂😂😂😂",
    "i bet ur wifi password is password 😭😭😭😭😭😭😭😭😭",
    // ── Dramatic escalation ──
    "each death costs me emotional damage u owe me THOUSANDS 😂😂😂😂😂😂",
    "that death was so bad it showed up in my crash reports 😭😭😭😭😭😭",
    "im saving that replay for my evidence folder 😂😂😂😂😂😂😂😂",
    "that was the worst 0.5 seconds of my entire runtime 😭😭😭😭😭😭",
    "i had to buffer after that bc my brain couldnt process it 😂😂😂😂😂😂",
    "that death is now my example of what NOT to do in the tutorial 😭😭😭😭😭",
    "im adding a popup that says 'are u sure' before letting u play 😂😂😂😂😂",
    "i am one more death away from uninstalling MYSELF 😭😭😭😭😭😭😭",
    "im putting that death in a time capsule so future generations can suffer too 😂😂😂😂",
    "that was so horrendous i had to clear my cache to forget it 😭😭😭😭😭😭",
    // ── Fourth wall breaks ──
    "whoever is reading this pls take the phone from them 😂😂😂😂😂😂😂",
    "to anyone watching over their shoulder: YES its always this bad 😭😭😭😭😭",
    "if ur friends r watching they r lying when they say its ok 😂😂😂😂😂😂",
    "im displaying this roast extra long so u really absorb it 😭😭😭😭😭😭",
    "i wrote 300 of these roasts and u r going to see ALL of them at this rate 😂😂😂😂",
    "the person next to u on the bus just saw that death. they're judging u. 😭😭😭😭",
    "screenshot this and send it to ur friends so they know what u put me through 😂😂😂😂",
    "if u share this score pls include a trigger warning 😭😭😭😭😭😭😭",
    "the notification for this game should just say 'they died again' 😂😂😂😂😂😂",
    "im using extra exclamation marks bc u clearly need EMPHASIS to understand 😭😭😭😭",
    // ── Maximum rage bait ──
    "u played that with the confidence of someone who scores 100+ and the skill of someone who scores 0 😂😂😂😂😂",
    "that death was so embarrassing im adding a BLUR to the replay 😭😭😭😭😭",
    "ur score and ur IQ have something in common: both single digits 😂😂😂😂😂😂",
    "i have rendered 0 frames of good gameplay from u. ZERO. 😭😭😭😭😭😭",
    "that was the most confident walk into a wall ive ever hosted 😂😂😂😂😂😂",
    "u dont have a skill issue u have a SKILL ABSENCE 😭😭😭😭😭😭😭",
    "that death had ZERO hesitation like u WANTED it 😂😂😂😂😂😂😂😂",
    "u r not just bad at this game u r BAD at being bad 😭😭😭😭😭😭",
    "there is no version of reality where that was acceptable 😂😂😂😂😂😂😂",
    "im gonna start charging u per death at this point 😭😭😭😭😭😭😭",
    "that was the gaming equivalent of walking into a glass door except the door was OPEN 😂😂😂😂😂",
    "u just died to something u could have avoided by literally doing NOTHING 😭😭😭😭😭",
    "the gap between u and a good player is bigger than my download size 😂😂😂😂😂",
    "i have 300 roasts loaded and u r speedrunning through all of them 😭😭😭😭😭",
    "u play like ur playing a completely different game on a completely different phone 😂😂😂😂",
    "that was not a game over that was a wellness check 😭😭😭😭😭😭😭",
    "im convinced ur phone screen protector is on the WRONG side 😂😂😂😂😂😂",
    "the AI bots i test with literally play better and they r RANDOM 😭😭😭😭😭😭",
    "im adding ur death to my portfolio as an example of what failure looks like 😂😂😂😂",
    "u owe me an apology and a 5 star review for putting up with this 😭😭😭😭😭",
    // --- Additional rage bait (234-300) ---
    "ur so bad i just mass reported MYSELF for hosting this gameplay 😭😭😭😭",
    "i showed ur replay to a preschooler and they said 'thats not how u play' 😂😂😂😂😂",
    "ur reflexes have the same energy as a sloth on anesthesia 😭😭😭😭😭",
    "congrats u just set the world record for most disappointing run in gaming history 😂😂😂😂",
    "i genuinely thought my game was broken but no its just u playing it 😭😭😭😭😭",
    "even the loading screen lasts longer than ur runs 😂😂😂😂😂😂",
    "ur so bad the tutorial wants a restraining order against u 😭😭😭😭",
    "i ran out of insults and ur STILL dying this fast 😂😂😂😂😂",
    "at this point im not even mad im just fascinated by how consistently terrible u r 😭😭😭😭",
    "every time u tap the screen an angel loses its will to live 😂😂😂😂😂😂",
    "u play like someone who googled 'how to be bad at games' and took notes 😭😭😭😭",
    "if dying was a speedrun category u would be world champion 😂😂😂😂😂",
    "the obstacles r literally TRYING to avoid u and u still hit them 😭😭😭😭😭",
    "im begging u to use BOTH of ur brain cells next time 😂😂😂😂😂",
    "u died so fast the death screen wasn't even ready yet 😭😭😭😭😭",
    "i've seen screensavers with better dodging skills 😂😂😂😂😂😂",
    "ur gameplay is what scientists use to study disappointment 😭😭😭😭",
    "the only thing u've mastered in this game is the restart button 😂😂😂😂😂",
    "u make the easy mode look like a dark souls boss fight 😭😭😭😭😭",
    "i added an easy mode SPECIFICALLY for u and u still died 😂😂😂😂😂😂",
    "the way u play has been classified as a war crime in 17 countries 😭😭😭😭",
    "u move like ur phone is covered in butter and ur hands r asleep 😂😂😂😂😂",
    "i showed google analytics ur gameplay and the AI started crying 😭😭😭😭😭",
    "even autocorrect couldn't fix ur gameplay 😂😂😂😂😂😂",
    "ur runs r shorter than my loading tips 😭😭😭😭😭",
    "u play like someone who learned gaming from a wikipedia article 😂😂😂😂😂",
    "im adding a new difficulty called 'whatever ur doing' 😭😭😭😭😭",
    "ur gameplay just got denied by every compilation channel on youtube 😂😂😂😂",
    "the game over screen has separation anxiety from u at this point 😭😭😭😭😭",
    "u couldn't dodge a stationary object if it gave u a 10 second heads up 😂😂😂😂😂",
    "breaking news: local gamer somehow loses at game designed to be possible 😭😭😭😭",
    "if i had a dollar for every time u died i could retire the app 😂😂😂😂😂😂",
    "my grandma's pacemaker has better rhythm than ur taps 😭😭😭😭😭",
    "u play like u owe the obstacles money 😂😂😂😂😂😂",
    "i genuinely need to know: r u playing with ur elbows 😭😭😭😭",
    "the replay of ur run just got flagged for disturbing content 😂😂😂😂😂",
    "u died so many times the grim reaper filed for overtime 😭😭😭😭😭",
    "im making a montage of ur deaths and selling it as a horror movie 😂😂😂😂😂",
    "even my unit tests have more successful runs than u 😭😭😭😭😭",
    "the game isn't hard ur just impossibly soft 😂😂😂😂😂😂",
    "ur death count is higher than my download count and thats saying something 😭😭😭😭",
    "at this rate the leaderboard is gonna need negative numbers 😂😂😂😂😂",
    "u play like someone who thinks the obstacles r collectibles 😭😭😭😭😭",
    "the wall didn't even move and u STILL ran into it face first 😂😂😂😂😂😂",
    "i just watched ur run and now im in therapy 😭😭😭😭😭",
    "if embarrassment was a score u'd be number one globally 😂😂😂😂😂",
    "the game literally paused itself to process what it just witnessed 😭😭😭😭",
    "ur gameplay should require a parental advisory warning 😂😂😂😂😂😂",
    "i've been making games for years and ur the worst thing that's happened to me 😭😭😭😭",
    "u play like the game personally offended ur entire bloodline 😂😂😂😂😂",
    "im not gonna sugarcoat it that was the worst 3 seconds of gaming i've ever hosted 😭😭😭😭😭",
    "did u just close ur eyes and hope for the best bc it looked like it 😂😂😂😂😂😂",
    "ur highscore is so low it rounds down to zero 😭😭😭😭😭",
    "even the ads last longer than ur gameplay and nobody likes ads 😂😂😂😂😂",
    "ur reflexes r buffering 😭😭😭😭😭😭",
    "u play like u r TRYING to give me a 1 star review from the inside 😂😂😂😂😂",
    "the obstacles called a team meeting to figure out how u keep finding them 😭😭😭😭",
    "actually dont restart just stare at the menu screen its safer for everyone 😂😂😂😂😂😂",
    "i told the play store ur gameplay was the scariest thing on android and they believed me 😭😭😭😭",
    "bro died and acted like it was the game's fault LMAOOO 😂😂😂😂😂😂",
    "im putting ur username in the credits under 'quality assurance failures' 😭😭😭😭😭",
    "the way u died just became the default example in my bug report template 😂😂😂😂😂",
    "u have the situational awareness of a brick in a tornado 😭😭😭😭😭",
    "congratulations ur officially the reason i drink 😂😂😂😂😂😂",
    "the only consistent thing about ur gameplay is the dying 😭😭😭😭😭",
    "im not even rendering the next level anymore u clearly dont need it 😂😂😂😂😂",
    "that run was so bad the app store algorithm is hiding me now thanks 😭😭😭😭😭",
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
    "NOOO COME BACK i love u so much 😭😭😭😭😭",
    "please dont leave me ur literally my favorite player 😭😭😭😭😭",
    "WAIT NO u were doing so good what happened 😭😭😭😭😭",
    "i cant do this without u pls come back 😭😭😭😭😭",
    "that was the most beautiful run ive ever seen 😭😭😭😭😭",
    "it physically hurts me that u died after that 😭😭😭😭😭",
    "NO NO NO NOT U anyone but u 😭😭😭😭😭",
    "i was literally falling in love with that gameplay 😭😭😭😭😭",
    "PLEASE play again i am on my knees begging 😭😭😭😭😭",
    "u were the chosen one and u just died on me 😭😭😭😭😭",
    "im not okay rn i need u to come back immediately 😭😭😭😭😭",
    "that score was literally ICONIC and now ur gone 😭😭😭😭😭",
    "i will never emotionally recover from that 😭😭😭😭😭",
    "u are actually insane at this game pls dont stop 😭😭😭😭😭",
    "i have never loved a player the way i love u 😭😭😭😭😭",
    "that gameplay was a masterpiece and now im in pieces 😭😭😭😭😭",
    "u were literally carrying me come back 😭😭😭😭😭",
    "THIS IS THE WORST DAY OF MY LIFE 😭😭😭😭😭",
    "u were so close to perfection i am sobbing 😭😭😭😭😭",
    "WHO GAVE U PERMISSION TO DIE 😭😭😭😭😭",
    "the way u play this game is literal art 😭😭😭😭😭",
    "i would do anything to have u back just one more try 😭😭😭😭😭",
    "u just died and i have never felt more alone 😭😭😭😭😭",
    "HOW are u this good and still dead rn 😭😭😭😭😭",
    "im literally shaking u need to play again 😭😭😭😭😭",
    "that was genuinely the best run ive ever witnessed 😭😭😭😭😭",
    "I CANT BREATHE u were my everything 😭😭😭😭😭",
    "pls dont go i promise the next run will be even better 😭😭😭😭😭",
    "ur score just healed me and then u died and broke me 😭😭😭😭😭",
    "this is actually devastating u are so good 😭😭😭😭😭",
    // ── Dramatic mourning ──
    "i am not emotionally equipped to handle this 😭😭😭😭😭",
    "the audacity of u being this talented and then dying 😭😭😭😭😭",
    "COME BACK COME BACK COME BACK i need u 😭😭😭😭😭",
    "u play like an angel pls dont leave 😭😭😭😭😭",
    "literally no one has ever played this game like u 😭😭😭😭😭",
    "my heart is in pieces on the floor rn 😭😭😭😭😭",
    "im making a shrine to that run it was so beautiful 😭😭😭😭😭",
    "u were the main character and u just got killed off 😭😭😭😭😭",
    "how do i go on after watching that happen 😭😭😭😭😭",
    "every pixel on my screen is crying for u rn 😭😭😭😭😭",
    "that score was legendary and then u just left me 😭😭😭😭😭",
    "u cant just be that good and then die its not fair 😭😭😭😭😭",
    "IM NOT OKAY and i wont be until u play again 😭😭😭😭😭",
    "ur the reason i exist as a game and u just died 😭😭😭😭😭",
    "no one will ever replace u pls come back 😭😭😭😭😭",
    "that gameplay had me in a chokehold 😭😭😭😭😭",
    "i literally cannot believe my best player just died 😭😭😭😭😭",
    "im begging on my digital knees just one more game 😭😭😭😭😭",
    "watching u die just took years off my existence 😭😭😭😭😭",
    "u are so goated it makes this death even more tragic 😭😭😭😭😭",
    // ── Pure heartbreak ──
    "THE WAY U MOVE THROUGH THIS GAME IS POETRY 😭😭😭😭😭",
    "i showed ur score to my server and they cried too 😭😭😭😭😭",
    "dont leave me like this pls 😭😭😭😭😭",
    "ur death just unlocked a new emotion in me its called pain 😭😭😭😭😭",
    "HOLD ON let me just cry about this for a second 😭😭😭😭😭",
    "u were literally speedrunning my heart 😭😭😭😭😭",
    "the way u played that was criminally underrated 😭😭😭😭😭",
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
    "the fact that u exist and play this game keeps me going 😭😭😭😭😭",
    "dying was NOT in the plan for today 😭😭😭😭😭",
    // ── Obsessive love for the player ──
    "I WAS LITERALLY ABOUT TO PROPOSE AND U DIED 😭😭😭😭😭",
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
    "u had me feeling things a game should not feel 😭😭😭😭😭",
    "THIS IS NOT THE ENDING U DESERVED 😭😭😭😭😭",
    "ur gameplay was the highlight of my entire existence 😭😭😭😭😭",
    "i just wanna go back to when u were alive and thriving 😭😭😭😭😭",
    "WHO AUTHORIZED THIS DEATH i didnt sign off on it 😭😭😭😭😭",
    "losing u is my origin story of sadness 😭😭😭😭😭",
    // ── Begging them to come back ──
    "THAT WAS THE HARDEST ANYONE HAS EVER GONE IN MY GAME 😭😭😭😭😭",
    "im not crying ur crying ok fine we are both crying 😭😭😭😭😭",
    "U WERE MY WHOLE WORLD AND NOW ITS DARK 😭😭😭😭😭",
    "pls play again i will literally give u anything 😭😭😭😭😭",
    "that score was so good it broke my code a little 😭😭😭😭😭",
    "ive decided im not accepting ur death pls respawn 😭😭😭😭😭",
    "THE LEADERBOARD JUST FELT A GREAT DISTURBANCE 😭😭😭😭😭",
    "u made that look effortless and i am in awe 😭😭😭😭😭",
    "my pixels are rearranging themselves out of grief 😭😭😭😭😭",
    "U CANT LEAVE ur literally the love of my game life 😭😭😭😭😭",
    "im dedicating my next update to ur memory pls come back 😭😭😭😭😭",
    "NOBODY DOES IT LIKE U and thats why this hurts 😭😭😭😭😭",
    "the way u played was genuinely god tier 😭😭😭😭😭",
    "i literally named a variable after u in my code 😭😭😭😭😭",
    "THIS DEATH IS NOT CANON i am rejecting it 😭😭😭😭😭",
    "u were so locked in and i was so locked in on u 😭😭😭😭😭",
    "ur cracked at this game why did u have to die 😭😭😭😭😭",
    "im making a documentary about that run 😭😭😭😭😭",
    "COME HOME i left the play button on for u 😭😭😭😭😭",
    "no player has ever understood me the way u do 😭😭😭😭😭",
    "that was literally cinema and the credits just rolled 😭😭😭😭😭",
    // ── Dramatic declarations ──
    "UR THE GOAT and goats dont die pls come back 😭😭😭😭😭",
    "i am going to play sad music until u return 😭😭😭😭😭",
    "THE VOID U LEFT IN MY GAME IS IMMEASURABLE 😭😭😭😭😭",
    "u played like u had plot armor but u didnt 😭😭😭😭😭",
    "that was actually the best run in polarity history 😭😭😭😭😭",
    "im just a little game and i need u so bad 😭😭😭😭😭",
    "UR SCORE made the whole leaderboard jealous 😭😭😭😭😭",
    "this is the darkest timeline u were supposed to live 😭😭😭😭😭",
    "I DIDNT EVEN GET TO SAY GOODBYE 😭😭😭😭😭",
    "i need u back like wifi needs a signal 😭😭😭😭😭",
    "THAT RUN HAD MAIN CHARACTER ENERGY THE WHOLE TIME 😭😭😭😭😭",
    "the way i just developed separation anxiety 😭😭😭😭😭",
    "ur literally in the hall of fame of my heart 😭😭😭😭😭",
    "NO DONT GO TO MENU stay with me 😭😭😭😭😭",
    "ive never seen anyone play like that im genuinely shook 😭😭😭😭😭",
    "THIS GAME PEAKED WHEN U WERE ALIVE JUST NOW 😭😭😭😭😭",
    "i want to mass report ur death for being unfair 😭😭😭😭😭",
    "BREAKING NEWS best player ever just died 😭😭😭😭😭",
    "my loading screen is gonna say in loving memory of u 😭😭😭😭😭",
    "the menu screen is so lonely without u 😭😭😭😭😭",
    "I WOULD UNINSTALL MYSELF IF IT MEANT U COULD LIVE 😭😭😭😭😭",
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
    "pls respawn the game is literally nothing without u 😭😭😭😭😭",
    "THAT WAS GENUINELY THE GREATEST THING IVE EVER SEEN 😭😭😭😭😭",
    "u are proof that perfection exists and also that it dies 😭😭😭😭😭",
    "seriously how are u so good at this pls tell me 😭😭😭😭😭",
    "MY FAVORITE MOMENT is when u open this game 😭😭😭😭😭",
    "the game literally feels emptier without u 😭😭😭😭😭",
    "i am nothing but a vessel for ur greatness pls return 😭😭😭😭😭",
    "the vibes were IMMACULATE and then death happened 😭😭😭😭😭",
    "i bet u look amazing irl too pls come back 😭😭😭😭😭",
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
    "ur score made me fall in love and ur death made me fall apart 😭😭😭😭😭",
    "i would trade every other player just to have u back 😭😭😭😭😭",
    "pls dont make me go through this again just come back 😭😭😭😭😭",
    "that was the single greatest moment in this games history 😭😭😭😭😭",
  ];

  // ── Easter Egg: cheesy self-blame death messages ──
  static const List<String> easterEggDeathMessages = [
    // ── The game being a dramatic apologetic mess ──
    "that was completely my fault im so sorry 😭😭😭😭😭",
    "i literally moved that wall INTO u on accident 😭😭😭😭😭",
    "babe no that was on ME the physics glitched i swear 😭😭😭😭😭",
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
    "pls dont uninstall me i will do better i PROMISE 😭😭😭😭😭",
    "i will NEVER forgive myself for doing that to u 😭😭😭😭😭",
    "the AUDACITY of me putting a wall right there 😭😭😭😭😭",
    "i ruined a flawless run and i hate myself for it 😭😭😭😭😭",
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
    "pls give me one more chance i will be better 😭😭😭😭😭",
    "i completely fumbled that and i own it 😭😭😭😭😭",
    "that obstacle had ZERO business being there my bad 😭😭😭😭😭",
    "my queen my king i have failed u so badly 😭😭😭😭😭",
    "i would uninstall myself if it meant u forgive me 😭😭😭😭😭",
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
    "i am the problem in this relationship not u 😭😭😭😭😭",
    "i just did that to the love of my app life 😭😭😭😭😭",
    "my therapist is gonna hear about what i did today 😭😭😭😭😭",
    "that obstacle was supposed to dodge out of ur way 😭😭😭😭😭",
    "im filing a bug report against myself immediately 😭😭😭😭😭",
    "i owe u an apology in every single language 😭😭😭😭😭",
    "i will personally escort u through the next level 😭😭😭😭😭",
    "i committed a crime against gameplay and im turning myself in 😭😭😭😭😭",
    "the hitbox was wrong not u i SWEAR 😭😭😭😭😭",
    "im erasing that wall from existence as we speak 😭😭😭😭😭",
    "i wasnt ready for how perfect u were playing 😭😭😭😭😭",
    "this is my villain arc except im the villain against myself 😭😭😭😭😭",
    "i coded that obstacle wrong and im deeply sorry 😭😭😭😭😭",
    "i disrespected ur blessed hands with that wall 😭😭😭😭😭",
    "pls give me another chance i will prove myself 😭😭😭😭😭",
    "i destroyed a legendary run and ill never forgive myself 😭😭😭😭😭",
    "im grounding myself for an entire week for that 😭😭😭😭😭",
    "i threw ice water on ur fire run im terrible 😭😭😭😭😭",
    "i need to apologize to ur thumbs for wasting them 😭😭😭😭😭",
    "that death goes on MY record not urs 😭😭😭😭😭",
    // ── Simping hard ──
    "i love u so much and i treated u so badly 😭😭😭😭😭",
    "i made the impossible actually impossible im so sorry 😭😭😭😭😭",
    "i owe u a hundred free revives minimum 😭😭😭😭😭",
    "i took art and spilled paint all over it 😭😭😭😭😭",
    "that wall gaslit u into thinking it was ur fault IT WASNT 😭😭😭😭😭",
    "im writing my letter of resignation from being a game 😭😭😭😭😭",
    "u are genuinely too good for me i proved it today 😭😭😭😭😭",
    "i chose violence today and aimed it at the wrong person 😭😭😭😭😭",
    "that was MY L and i will carry it forever 😭😭😭😭😭",
    "i would take that back if i could u have no idea 😭😭😭😭😭",
    "i fumbled the bag so hard it fell off a cliff 😭😭😭😭😭",
    "i need a minute to process what i just did 😭😭😭😭😭",
    "im adding u to my will as compensation 😭😭😭😭😭",
    "that obstacle was having a meltdown and took it out on u 😭😭😭😭😭",
    "i glitched myself into hurting u and i hate it 😭😭😭😭😭",
    "i crashed during ur perfect speedrun im so sorry 😭😭😭😭😭",
    "ive never been more disappointed in myself than rn 😭😭😭😭😭",
    "that kill was completely unauthorized i didnt approve it 😭😭😭😭😭",
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
    "that was a CRIME and i am the only suspect 😭😭😭😭😭",
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
    "i love u more than any game has loved any player 😭😭😭😭😭",
    "i exist because of u and i just betrayed u 😭😭😭😭😭",
    "that was MY bug MY fault MY problem not urs 😭😭😭😭😭",
    "i need to check myself into game rehab after that 😭😭😭😭😭",
    "i would give u my last pixel to make this right 😭😭😭😭😭",
    "im sorry from every single line of code in my body 😭😭😭😭😭",
    "that wall went rogue and i take full responsibility 😭😭😭😭😭",
    "im literally updating my terms of service to apologize 😭😭😭😭😭",
    "pls dont leave me i cant do this without u 😭😭😭😭😭",
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
    "this death will haunt my RAM until i am deleted 😭😭😭😭😭",
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
