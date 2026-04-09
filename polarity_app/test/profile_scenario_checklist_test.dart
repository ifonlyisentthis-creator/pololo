import 'package:flutter_test/flutter_test.dart';
import 'package:polarity/core/constants.dart';
import 'package:polarity/features/game/engine/game_engine.dart';
import 'package:polarity/features/game/models/obstacle.dart';

void main() {
  const dt = 1.0 / 120.0;

  void triggerScoreTick(GameEngine engine) {
    final scoreLine = engine.player.y - GameConstants.playerRadius;
    engine.obstacles.clear();
    engine.obstacles.add(
      Obstacle(
        fromLeft: true,
        width: 0,
        worldY: scoreLine - 1,
        thickness: 10,
      ),
    );
    engine.update(dt);
  }

  group('Profile scenario checklist', () {
    test('score ramp transitions phases at target thresholds', () {
      final engine = GameEngine();
      engine.init(1080, 2340);
      engine.startGame();
      engine.debugInvincible = true;

      const checks = <(int targetScore, int expectedPhase)>[
        (50, 1),
        (130, 2),
        (260, 3),
        (430, 4),
      ];

      for (final check in checks) {
        engine.score = check.$1 - 1;
        engine.phaseRingTimer = 0;
        triggerScoreTick(engine);

        expect(engine.score, check.$1);
        expect(engine.currentPhase, check.$2);
        expect(engine.phaseRingTimer, greaterThan(0));
      }
    });

    test('theme unlock transitions trigger at tier scores', () {
      final engine = GameEngine();
      engine.init(1080, 2340);
      engine.startGame();
      engine.debugInvincible = true;

      const checks = <(int targetScore, int expectedTier)>[
        (100, 1),
        (200, 2),
        (300, 3),
        (400, 4),
        (500, 5),
      ];

      for (final check in checks) {
        engine.score = check.$1 - 1;
        engine.themeJustActivated = false;
        engine.themeTransitionTimer = 0;
        triggerScoreTick(engine);

        expect(engine.score, check.$1);
        expect(engine.currentThemeTier, check.$2);
        expect(engine.activeTheme, isNotNull);
        expect(engine.themeJustActivated, isTrue);
        expect(engine.themeTransitionTimer, greaterThan(0));
      }
    });

    test('shield pickup, break, and next threshold pickup work', () {
      final engine = GameEngine();
      engine.init(1080, 2340);
      engine.startGame();

      engine.debugInvincible = true;
      engine.score = 19;
      engine.shieldJustPickedUp = false;
      triggerScoreTick(engine);

      expect(engine.score, 20);
      expect(engine.hasShield, isTrue);
      expect(engine.shieldJustPickedUp, isTrue);

      engine.debugInvincible = false;
      engine.isInvincible = false;
      engine.easyMode = false;
      engine.shieldJustBroke = false;
      engine.player.x = GameConstants.playerRadius + 1;
      engine.obstacles
        ..clear()
        ..add(
          Obstacle(
            fromLeft: true,
            width: 120,
            worldY: engine.player.y,
            thickness: 20,
          ),
        );
      engine.update(dt);

      expect(engine.state, GameState.playing);
      expect(engine.hasShield, isFalse);
      expect(engine.shieldJustBroke, isTrue);

      engine.debugInvincible = true;
      engine.shieldJustPickedUp = false;
      engine.score = 59;
      triggerScoreTick(engine);

      expect(engine.score, 60);
      expect(engine.hasShield, isTrue);
      expect(engine.shieldJustPickedUp, isTrue);
    });

    test('troll lifecycle triggers on session game 10 and completes', () {
      final engine = GameEngine();
      engine.init(1080, 2340);
      engine.debugInvincible = true;

      for (int i = 0; i < 9; i++) {
        engine.startGame();
        expect(engine.trollSystem.activeTroll, isNull);
      }

      engine.startGame();
      expect(engine.trollSystem.activeTroll, isNotNull);
      expect(engine.trollSystem.activeTroll!.spawned, isFalse);

      var activated = false;
      final activateFrames = (6.0 / dt).round();
      for (int i = 0; i < activateFrames; i++) {
        engine.update(dt);
        if (engine.trollSystem.trollJustActivated) {
          activated = true;
          break;
        }
      }

      expect(activated, isTrue);
      expect(engine.trollSystem.activeTroll!.spawned, isTrue);

      engine.trollSystem.onDeath();
      final rageMessage = engine.getDeathMessage();
      expect(rageMessage.isNotEmpty, isTrue);
      expect(engine.lastMessageWasPraise, isFalse);

      var ended = false;
      final endFrames = (20.0 / dt).round();
      for (int i = 0; i < endFrames; i++) {
        engine.update(dt);
        if (engine.trollSystem.trollJustEnded) {
          ended = true;
          break;
        }
      }

      expect(ended, isTrue);
      expect(engine.trollSystem.activeTroll!.finished, isTrue);
    });
  });
}
