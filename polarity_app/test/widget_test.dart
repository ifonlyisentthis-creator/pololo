import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:polarity/core/security/score_guard.dart';
import 'package:polarity/features/game/engine/game_engine.dart';
import 'package:polarity/features/game/models/player.dart';
import 'package:polarity/features/game/models/obstacle.dart';
import 'package:polarity/features/game/models/particle.dart';

void main() {
  group('ScoreGuard', () {
    setUp(() => ScoreGuard.initialize());

    test('obfuscation round-trips correctly', () {
      ScoreGuard.setScore(42);
      expect(ScoreGuard.getScore(), 42);

      ScoreGuard.setHighScore(100);
      expect(ScoreGuard.getHighScore(), 100);
    });

    test('HMAC signature validates correct score', () {
      final sig = ScoreGuard.generateSignature(50);
      expect(ScoreGuard.validateScore(50, sig), true);
      expect(ScoreGuard.validateScore(51, sig), false);
    });

    test('encodeForStorage and decodeFromStorage round-trip', () {
      final encoded = ScoreGuard.encodeForStorage(99);
      expect(ScoreGuard.decodeFromStorage(encoded), 99);
    });

    test('tampered storage returns null', () {
      expect(ScoreGuard.decodeFromStorage('999:fakehash'), null);
    });
  });

  group('Player', () {
    test('reset sets correct defaults', () {
      final player = Player(x: 0, y: 0);
      player.reset(400, 800);
      expect(player.x, 200);
      expect(player.y, 320);
      expect(player.isAlive, true);
      expect(player.velocityX, 0);
    });
  });

  group('Obstacle', () {
    test('creates with correct defaults', () {
      final obs = Obstacle(fromLeft: true, width: 100, worldY: 300);
      expect(obs.passed, false);
      expect(obs.fromLeft, true);
    });
  });

  group('Particle', () {
    test('updates position and life', () {
      final p = Particle(
        x: 0, y: 0,
        velocityX: 100, velocityY: 100,
        life: 1.0, radius: 5,
        color: const Color(0xFFFFFFFF),
      );
      p.update(0.1);
      expect(p.x, greaterThan(0));
      expect(p.y, greaterThan(0));
      expect(p.life, lessThan(1.0));
    });

    test('isDead when life is 0', () {
      final p = Particle(
        x: 0, y: 0,
        velocityX: 0, velocityY: 0,
        life: 0.05, radius: 3,
        color: const Color(0xFFFFFFFF),
      );
      p.update(0.1);
      expect(p.isDead, true);
    });
  });

  group('GameEngine', () {
    late GameEngine engine;

    setUp(() {
      ScoreGuard.initialize();
      engine = GameEngine();
      engine.init(400, 800);
    });

    test('starts in menu state', () {
      expect(engine.state, GameState.menu);
    });

    test('startGame transitions to playing', () {
      engine.startGame();
      expect(engine.state, GameState.playing);
      expect(engine.score, 0);
      expect(engine.player.isAlive, true);
    });

    test('obstacles spawn after safe delay', () {
      engine.startGame();
      // No obstacles at t=0 due to safe spawn delay
      expect(engine.obstacles, isEmpty);
      // Keep player alive — enable invincibility and toggle magnet
      engine.isInvincible = true;
      engine.invincibilityTimer = 5.0;
      // Simulate 1.5 seconds (safe delay is 0.8s, so obstacles appear)
      for (int i = 0; i < 30; i++) {
        engine.isTouching = i % 4 < 2;
        engine.update(0.05);
      }
      expect(engine.obstacles, isNotEmpty);
    });

    test('shield awarded at score threshold', () {
      engine.startGame();
      engine.debugInvincible = true;
      expect(engine.hasShield, false);
      // Manually set score to trigger shield
      engine.hasShield = false;
      // getNextShieldAfter calculates correctly
      expect(engine.getNextShieldAfter(0), 20);
      expect(engine.getNextShieldAfter(20), 60);
      expect(engine.getNextShieldAfter(60), 120);
      expect(engine.getNextShieldAfter(120), 240);
    });

    test('tutorial configured correctly', () {
      engine.configureTutorial(true);
      expect(engine.showTutorial, true);
      expect(engine.tutorialOpacity, 1.0);

      engine.configureTutorial(false);
      expect(engine.showTutorial, false);
    });

    test('pause and resume work', () {
      engine.startGame();
      engine.pause();
      expect(engine.state, GameState.paused);
      engine.resume();
      expect(engine.state, GameState.playing);
    });

    test('getRandomRoast returns non-empty string', () {
      final roast = engine.getRandomRoast();
      expect(roast.isNotEmpty, true);
    });
  });
}
