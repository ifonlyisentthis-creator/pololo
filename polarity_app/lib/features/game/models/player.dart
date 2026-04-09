import 'dart:ui';

class Player {
  double x;
  double y;
  double velocityX;
  double radius;
  bool isAlive;
  bool isInvincible;
  double invincibilityTimer;
  double glowPhase;

  Player({
    required this.x,
    required this.y,
    this.velocityX = 0,
    this.radius = 10,
    this.isAlive = true,
    this.isInvincible = false,
    this.invincibilityTimer = 0,
    this.glowPhase = 0,
  });

  Rect get bounds => Rect.fromCircle(
        center: Offset(x, y),
        radius: radius,
      );

  void reset(double screenWidth, double screenHeight) {
    x = screenWidth / 2;
    y = screenHeight * 0.4;
    velocityX = 0;
    isAlive = true;
    isInvincible = false;
    invincibilityTimer = 0;
    glowPhase = 0;
  }
}
