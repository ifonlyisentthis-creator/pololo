class Obstacle {
  /// Which wall: true = left, false = right
  final bool fromLeft;

  /// How far the obstacle protrudes from the wall (in pixels)
  final double width;

  /// Vertical position (world Y coordinate, scrolls down)
  double worldY;

  /// Whether this obstacle has been passed by the player (for scoring)
  bool passed;

  /// Thickness of the obstacle bar
  final double thickness;

  Obstacle({
    required this.fromLeft,
    required this.width,
    required this.worldY,
    this.passed = false,
    this.thickness = 18,
  });
}
