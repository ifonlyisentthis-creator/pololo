import 'dart:math';
import 'dart:ui';

class Particle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double life;
  double maxLife;
  double radius;
  Color color;
  double gravity;

  Particle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.life,
    required this.radius,
    required this.color,
    double? maxLife,
    this.gravity = 0.0,
  }) : maxLife = (maxLife ?? life).clamp(0.001, double.infinity);

  bool get isDead => life <= 0;

  void update(double dt) {
    final velocityDamping = pow(0.3, dt).toDouble();
    final radiusDamping = pow(0.75, dt).toDouble();
    updateWithDamping(dt, velocityDamping, radiusDamping);
  }

  void updateWithDamping(
      double dt, double velocityDamping, double radiusDamping) {
    velocityY += gravity * dt;
    x += velocityX * dt;
    y += velocityY * dt;
    velocityX *= velocityDamping;
    velocityY *= velocityDamping;
    life -= dt;
    radius *= radiusDamping;
  }
}
