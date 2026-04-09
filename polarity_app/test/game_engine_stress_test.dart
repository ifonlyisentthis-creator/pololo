import 'package:flutter_test/flutter_test.dart';
import 'package:polarity/features/game/engine/game_engine.dart';

void main() {
  group('GameEngine stress stability', () {
    test('remains stable across long high-speed simulation', () {
      final engine = GameEngine();
      engine.init(1080, 2340);
      engine.startGame();
      engine.debugInvincible = true;

      const dt = 1.0 / 120.0;
      const frames = 120 * 180; // 3 simulated minutes at 120 Hz

      for (int i = 0; i < frames; i++) {
        // Alternate pull direction to stress velocity flips.
        engine.isTouching = (i % 12) < 6;

        // Force highest phase behavior for stress conditions.
        engine.currentPhase = 4;
        engine.update(dt);

        expect(engine.player.x.isFinite, isTrue);
        expect(engine.player.velocityX.isFinite, isTrue);
        expect(engine.obstacles.length, lessThan(180));
        expect(engine.trailParticles.length, lessThan(280));
        expect(engine.magnetParticles.length, lessThan(90));
        expect(engine.ambientParticles.length, inInclusiveRange(20, 30));
      }

      expect(engine.state, GameState.playing);
    });

    test('stays responsive with very high score and long runtime', () {
      final engine = GameEngine();
      engine.init(1080, 2340);
      engine.startGame();
      engine.debugInvincible = true;
      engine.score = 1200;
      engine.highScore = 1400;
      engine.currentPhase = 4;

      const dt = 1.0 / 120.0;
      const frames = 120 * 240; // 4 simulated minutes at 120 Hz

      for (int i = 0; i < frames; i++) {
        engine.isTouching = (i % 10) < 5;
        engine.currentPhase = 4;
        engine.update(dt);

        expect(engine.player.x, greaterThanOrEqualTo(0));
        expect(engine.player.x, lessThanOrEqualTo(engine.screenWidth));
        expect(engine.obstacles.length, lessThan(200));
        expect(engine.particles.length, lessThan(220));
      }

      expect(engine.score, greaterThan(1200));
      expect(engine.state, GameState.playing);
    });

    test('death revive restart churn remains stable', () {
      final engine = GameEngine();
      engine.init(1080, 2340);

      const dt = 1.0 / 120.0;

      for (int cycle = 0; cycle < 80; cycle++) {
        engine.startGame();
        engine.debugInvincible = false;
        engine.easyMode = false;

        // Force immediate wall death.
        engine.player.x = 0;
        engine.update(dt);
        expect(engine.state, GameState.dead);

        // Revive flow should recover to playing after countdown.
        engine.revive();
        expect(engine.state, GameState.countdown);

        for (int i = 0; i < 400; i++) {
          engine.update(dt);
        }

        expect(engine.state, GameState.playing);
        expect(engine.obstacles.length, lessThan(220));
        expect(engine.trailParticles.length, lessThan(320));
        expect(engine.magnetParticles.length, lessThan(120));
        expect(engine.particles.length, lessThan(260));
      }
    });
  });
}
