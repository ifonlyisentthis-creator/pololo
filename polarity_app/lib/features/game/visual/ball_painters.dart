import 'dart:math';
import 'package:flutter/material.dart';

import 'visual_theme.dart';

class BallPainters {
  BallPainters._();

  static final Map<int, Map<double, Path>> _cachedPaths =
      <int, Map<double, Path>>{};
  static int _cachedPathCount = 0;
  static final Path _pathA = Path();
  static final Path _pathB = Path();

  static const List<int> _branchDirections = <int>[-1, 1];
  static const List<double> _leafVeinOffsets = <double>[-0.35, 0.0, 0.35];

  static void draw(BallShape shape, Canvas canvas, double radius,
      List<Color> colors, double glowPhase, double intensity) {
    switch (shape) {
      case BallShape.circle:
        _drawCircle(canvas, radius, colors, glowPhase, intensity);
      case BallShape.hexagon:
        _drawHexagon(canvas, radius, colors, glowPhase, intensity);
      case BallShape.star5:
        _drawStar5(canvas, radius, colors, glowPhase, intensity);
      case BallShape.star6:
        _drawStar6(canvas, radius, colors, glowPhase, intensity);
      case BallShape.pentagon:
        _drawPentagon(canvas, radius, colors, glowPhase, intensity);
      case BallShape.diamond:
        _drawDiamond(canvas, radius, colors, glowPhase, intensity);
      case BallShape.gear:
        _drawGear(canvas, radius, colors, glowPhase, intensity);
      case BallShape.crescent:
        _drawCrescent(canvas, radius, colors, glowPhase, intensity);
      case BallShape.crown:
        _drawCrown(canvas, radius, colors, glowPhase, intensity);
      case BallShape.cross:
        _drawCross(canvas, radius, colors, glowPhase, intensity);
      case BallShape.cube:
        _drawCube(canvas, radius, colors, glowPhase, intensity);
      case BallShape.spiral:
        _drawSpiral(canvas, radius, colors, glowPhase, intensity);
      case BallShape.eye:
        _drawEye(canvas, radius, colors, glowPhase, intensity);
      case BallShape.snowflake:
        _drawSnowflake(canvas, radius, colors, glowPhase, intensity);
      case BallShape.bolt:
        _drawBolt(canvas, radius, colors, glowPhase, intensity);
      case BallShape.prism:
        _drawPrism(canvas, radius, colors, glowPhase, intensity);
      case BallShape.leaf:
        _drawLeaf(canvas, radius, colors, glowPhase, intensity);
      case BallShape.ring:
        _drawRing(canvas, radius, colors, glowPhase, intensity);
      case BallShape.slit:
        _drawSlit(canvas, radius, colors, glowPhase, intensity);
      case BallShape.singularity:
        _drawSingularity(canvas, radius, colors, glowPhase, intensity);
      case BallShape.doubleRing:
        _drawDoubleRing(canvas, radius, colors, glowPhase, intensity);
      case BallShape.helix:
        _drawHelix(canvas, radius, colors, glowPhase, intensity);
      case BallShape.tesseract:
        _drawTesseract(canvas, radius, colors, glowPhase, intensity);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  static Color _safeColor(List<Color> colors, int index) =>
      colors[index.clamp(0, colors.length - 1)];

  static Path _getCachedPath(
      int shapeKey, double radius, void Function(Path path) builder) {
    Map<double, Path>? perRadius = _cachedPaths[shapeKey];
    final cached = perRadius?[radius];
    if (cached != null) {
      return cached;
    }

    if (_cachedPathCount >= 96) {
      _cachedPaths.clear();
      _cachedPathCount = 0;
      perRadius = null;
    }

    perRadius ??= _cachedPaths.putIfAbsent(shapeKey, () => <double, Path>{});
    final path = Path();
    builder(path);
    perRadius[radius] = path;
    _cachedPathCount++;
    return path;
  }

  static void _buildRegularPolygonPath(Path path, int sides, double r,
      {double rotation = -pi / 2}) {
    path.reset();
    final step = 2 * pi / sides;
    for (var i = 0; i < sides; i++) {
      final angle = rotation + step * i;
      final x = r * cos(angle);
      final y = r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  static Paint _glowPaint(Color color, double sigma) {
    return Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
  }

  // ─── 1. Circle ─────────────────────────────────────────────────────────

  static void _drawCircle(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);

    // Outer glow
    final glowP = _glowPaint(
      _safeColor(colors, 0).withValues(alpha: 0.35 * intensity * glow),
      r * 0.5,
    );
    canvas.drawCircle(Offset.zero, r * 1.15, glowP);

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.15, 1.0],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, fillP);

    // Specular
    final specP = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(Offset(-r * 0.25, -r * 0.25), r * 0.18, specP);
  }

  // ─── 2. Hexagon ────────────────────────────────────────────────────────

  static void _drawHexagon(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final path =
      _getCachedPath(1, r, (p) => _buildRegularPolygonPath(p, 6, r));

    final glow = 0.85 + 0.15 * sin(glowPhase);

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.2, 1.0],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, fillP);

    // Stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _safeColor(colors, 1).withValues(alpha: 0.6 * intensity * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 3. Star5 ──────────────────────────────────────────────────────────

  static void _drawStar5(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);
    final path =
      _getCachedPath(2, r, (p) => _buildStarPath(p, 5, r, r * 0.4));

    // Glow
    final glowP = _glowPaint(
      _safeColor(colors, 0).withValues(alpha: 0.3 * intensity * glow),
      r * 0.35,
    );
    canvas.drawPath(path, glowP);

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, fillP);

    // Tip glow stroke
    final tipP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.3 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(path, tipP);
  }

  static void _buildStarPath(
      Path path, int points, double outerR, double innerR) {
    path.reset();
    final step = pi / points;
    for (var i = 0; i < points * 2; i++) {
      final angle = -pi / 2 + step * i;
      final rad = i.isEven ? outerR : innerR;
      final x = rad * cos(angle);
      final y = rad * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  // ─── 4. Star6 ──────────────────────────────────────────────────────────

  static void _drawStar6(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.85 + 0.15 * sin(glowPhase);

    final path = _getCachedPath(3, r, (p) {
      final tri1 = Path();
      final tri2 = Path();
      _buildRegularPolygonPath(tri1, 3, r, rotation: -pi / 2);
      _buildRegularPolygonPath(tri2, 3, r, rotation: pi / 2);
      p.addPath(Path.combine(PathOperation.union, tri1, tri2), Offset.zero);
    });

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.1, 1.0],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, fillP);

    // Stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _safeColor(colors, 1).withValues(alpha: 0.5 * intensity * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 5. Pentagon ───────────────────────────────────────────────────────

  static void _drawPentagon(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final path =
      _getCachedPath(4, r, (p) => _buildRegularPolygonPath(p, 5, r));
    final glow = 0.85 + 0.15 * sin(glowPhase);

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.2, 1.0],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, fillP);

    // Stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _safeColor(colors, 1).withValues(alpha: 0.55 * intensity * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 6. Diamond ────────────────────────────────────────────────────────

  static void _drawDiamond(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);
    final path = _getCachedPath(5, r, (p) {
      p
        ..moveTo(0, -r * 1.2)
        ..lineTo(r * 0.9, 0)
        ..lineTo(0, r * 1.2)
        ..lineTo(-r * 0.9, 0)
        ..close();
    });

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.15, 1.0],
    );
    final fillP = Paint()
      ..shader =
          gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.2));
    canvas.drawPath(path, fillP);

    // Stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white.withValues(alpha: 0.35 * intensity * glow);
    canvas.drawPath(path, strokeP);

    // Inner facet line
    final lineP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = Colors.white.withValues(alpha: 0.2 * glow);
    canvas.drawLine(Offset(-r * 0.55, 0), Offset(r * 0.55, 0), lineP);
  }

  // ─── 7. Gear ───────────────────────────────────────────────────────────

  static void _drawGear(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.85 + 0.15 * sin(glowPhase);
    final path = _getCachedPath(6, r, (p) {
      const teeth = 8;
      final innerR = r * 0.7;
      final outerR = r;
      final toothW = pi / (teeth * 2.5);

      for (var i = 0; i < teeth; i++) {
        final angle = 2 * pi * i / teeth;
        final a1 = angle - toothW;
        final a2 = angle + toothW;
        final mid1 = angle - toothW * 1.6;
        final mid2 = angle + toothW * 1.6;

        if (i == 0) {
          p.moveTo(innerR * cos(mid1), innerR * sin(mid1));
        } else {
          p.lineTo(innerR * cos(mid1), innerR * sin(mid1));
        }
        p.lineTo(outerR * cos(a1), outerR * sin(a1));
        p.lineTo(outerR * cos(a2), outerR * sin(a2));
        p.lineTo(innerR * cos(mid2), innerR * sin(mid2));
      }
      p.close();
    });

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.3, 1.0],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, fillP);

    // Center axle hole
    final axleP = Paint()
      ..color = Colors.black.withValues(alpha: 0.4);
    canvas.drawCircle(Offset.zero, r * 0.18, axleP);

    // Stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _safeColor(colors, 1).withValues(alpha: 0.5 * intensity * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 8. Crescent ───────────────────────────────────────────────────────

  static void _drawCrescent(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.85 + 0.15 * sin(glowPhase);

    final path = _getCachedPath(7, r, (p) {
      final mainCircle = Path()
        ..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
      final subtracted = Path()
        ..addOval(Rect.fromCircle(center: Offset(r * 0.5, 0), radius: r * 0.85));
      p.addPath(
          Path.combine(PathOperation.difference, mainCircle, subtracted),
          Offset.zero);
    });

    // Outer glow
    final glowP = _glowPaint(
      _safeColor(colors, 0).withValues(alpha: 0.3 * intensity * glow),
      r * 0.4,
    );
    canvas.drawPath(path, glowP);

    // Fill
    final gradient = RadialGradient(
      center: const Alignment(-0.3, 0.0),
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.1, 1.0],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, fillP);

    // Edge stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.25 * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 9. Crown ──────────────────────────────────────────────────────────

  static void _drawCrown(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.85 + 0.15 * sin(glowPhase);
    final w = r * 1.1;
    final h = r * 1.2;

    final path = _getCachedPath(8, r, (p) {
      p
        ..moveTo(-w, h * 0.35) // bottom-left
        ..lineTo(-w, -h * 0.1) // left wall up
        ..lineTo(-w * 0.5, h * 0.1) // first valley
        ..lineTo(-w * 0.25, -h * 0.5) // left peak
        ..lineTo(0, h * 0.05) // center valley
        ..lineTo(w * 0.25, -h * 0.5) // center peak
        ..lineTo(w * 0.5, h * 0.1) // right valley
        ..lineTo(w, -h * 0.1) // right wall up
        ..lineTo(w, h * 0.35) // bottom-right
        ..close();
    });

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.1, 1.0],
    );
    final fillP = Paint()
      ..shader =
          gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.2));
    canvas.drawPath(path, fillP);

    // Jewel dots on tips
    final jewelP = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(Offset(-w * 0.25, -h * 0.5), r * 0.08, jewelP);
    canvas.drawCircle(Offset(w * 0.25, -h * 0.5), r * 0.08, jewelP);

    // Stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _safeColor(colors, 1).withValues(alpha: 0.45 * intensity * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 10. Cross ─────────────────────────────────────────────────────────

  static void _drawCross(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.85 + 0.15 * sin(glowPhase);
    final a = r * 0.3; // half arm width
    final path = _getCachedPath(9, r, (p) {
      p
        ..moveTo(-a, -r)
        ..lineTo(a, -r)
        ..lineTo(a, -a)
        ..lineTo(r, -a)
        ..lineTo(r, a)
        ..lineTo(a, a)
        ..lineTo(a, r)
        ..lineTo(-a, r)
        ..lineTo(-a, a)
        ..lineTo(-r, a)
        ..lineTo(-r, -a)
        ..lineTo(-a, -a)
        ..close();
    });

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.15, 1.0],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, fillP);

    // Stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _safeColor(colors, 1).withValues(alpha: 0.5 * intensity * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 11. Cube ──────────────────────────────────────────────────────────

  static void _drawCube(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.85 + 0.15 * sin(glowPhase);
    final s = r * 0.75; // half edge
    final base = _safeColor(colors, 0);

    // Isometric offsets
    final top = Offset(0, -s * 0.85);
    final left = Offset(-s, s * 0.15);
    final right = Offset(s, s * 0.15);
    final bottom = Offset(0, s * 1.0);
    final backLeft = Offset(-s, -s * 0.7);
    final backRight = Offset(s, -s * 0.7);

    // Top face (brightest)
    final topFace = _getCachedPath(10, r, (p) {
      p
        ..moveTo(top.dx, top.dy)
        ..lineTo(backRight.dx, backRight.dy)
        ..lineTo(0, -s * 0.05)
        ..lineTo(backLeft.dx, backLeft.dy)
        ..close();
    });
    final fillP = Paint()
      ..color = Color.lerp(base, Colors.white, 0.25 * glow)!;
    canvas.drawPath(topFace, fillP);

    // Left face (medium)
    final leftFace = _getCachedPath(11, r, (p) {
      p
        ..moveTo(backLeft.dx, backLeft.dy)
        ..lineTo(0, -s * 0.05)
        ..lineTo(bottom.dx, bottom.dy)
        ..lineTo(left.dx, left.dy)
        ..close();
    });
    fillP.color = Color.lerp(base, Colors.black, 0.15)!;
    canvas.drawPath(leftFace, fillP);

    // Right face (darkest)
    final rightFace = _getCachedPath(12, r, (p) {
      p
        ..moveTo(backRight.dx, backRight.dy)
        ..lineTo(0, -s * 0.05)
        ..lineTo(bottom.dx, bottom.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
    });
    fillP.color = Color.lerp(base, Colors.black, 0.35)!;
    canvas.drawPath(rightFace, fillP);

    // Edges
    final edgeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.3 * intensity * glow);
    canvas.drawPath(topFace, edgeP);
    canvas.drawPath(leftFace, edgeP);
    canvas.drawPath(rightFace, edgeP);
  }

  // ─── 12. Spiral ────────────────────────────────────────────────────────

  static void _drawSpiral(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);
    final path = _pathA..reset();
    const totalAngle = 4 * pi;
    const steps = 40;

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = totalAngle * t + glowPhase * 0.3;
      final rad = r * 0.1 + r * 0.85 * t;
      final x = rad * cos(angle);
      final y = rad * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Outer glow stroke
    final glowP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.22
      ..color = _safeColor(colors, 0).withValues(alpha: 0.2 * intensity * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.15)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowP);

    // Main stroke
    final mainP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round
      ..shader = RadialGradient(
        colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, mainP);
  }

  // ─── 13. Eye ───────────────────────────────────────────────────────────

  static void _drawEye(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.85 + 0.15 * sin(glowPhase);
    final w = r * 1.3;
    final h = r * 0.75;

    // Vesica piscis - upper and lower arcs
    final eyePath = _getCachedPath(13, r, (p) {
      p
        ..moveTo(-w, 0)
        ..quadraticBezierTo(0, -h * 1.6, w, 0)
        ..quadraticBezierTo(0, h * 1.6, -w, 0)
        ..close();
    });

    // Outer glow
    final glowP = _glowPaint(
      _safeColor(colors, 0).withValues(alpha: 0.25 * intensity * glow),
      r * 0.35,
    );
    canvas.drawPath(eyePath, glowP);

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(eyePath, fillP);

    // Iris
    final irisP = Paint()
      ..color = _safeColor(colors, 1).withValues(alpha: 0.9);
    canvas.drawCircle(Offset.zero, r * 0.35, irisP);

    // Pupil
    final pupilP = Paint()
      ..color = Colors.black.withValues(alpha: 0.85);
    canvas.drawCircle(Offset.zero, r * 0.17, pupilP);

    // Specular highlight
    final specP = Paint()
      ..color = Colors.white.withValues(alpha: 0.65 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    canvas.drawCircle(Offset(-r * 0.1, -r * 0.1), r * 0.08, specP);

    // Outline stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.25 * glow);
    canvas.drawPath(eyePath, strokeP);
  }

  // ─── 14. Snowflake ─────────────────────────────────────────────────────

  static void _drawSnowflake(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);

    // Main arm stroke
    final armP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1
      ..strokeCap = StrokeCap.round
      ..color = _safeColor(colors, 0).withValues(alpha: 0.9 * intensity);

    // Glow stroke
    final glowP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18
      ..strokeCap = StrokeCap.round
      ..color = _safeColor(colors, 0).withValues(alpha: 0.25 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12);

    for (var i = 0; i < 6; i++) {
      final angle = pi / 3 * i - pi / 2;
      final tip = Offset(r * cos(angle), r * sin(angle));

      // Main arm
      canvas.drawLine(Offset.zero, tip, glowP);
      canvas.drawLine(Offset.zero, tip, armP);

      // Branches at 60% out
      final branchBase = tip * 0.6;
      final branchLen = r * 0.3;
      for (final dir in _branchDirections) {
        final branchAngle = angle + dir * pi / 3;
        final branchTip = branchBase +
            Offset(branchLen * cos(branchAngle), branchLen * sin(branchAngle));
        canvas.drawLine(branchBase, branchTip, armP);
      }
    }

    // Center dot
    final dotP = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(Offset.zero, r * 0.1, dotP);
  }

  // ─── 15. Bolt ──────────────────────────────────────────────────────────

  static void _drawBolt(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);
    final path = _getCachedPath(14, r, (p) {
      p
        ..moveTo(r * 0.15, -r * 1.1)
        ..lineTo(-r * 0.55, -r * 0.05)
        ..lineTo(-r * 0.05, -r * 0.05)
        ..lineTo(-r * 0.15, r * 1.1)
        ..lineTo(r * 0.55, r * 0.05)
        ..lineTo(r * 0.05, r * 0.05)
        ..close();
    });

    // Outer glow
    final glowP = _glowPaint(
      _safeColor(colors, 0).withValues(alpha: 0.35 * intensity * glow),
      r * 0.4,
    );
    canvas.drawPath(path, glowP);

    // Fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(
          Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2.4));
    canvas.drawPath(path, fillP);

    // Stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.35 * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 16. Prism ─────────────────────────────────────────────────────────

  static void _drawPrism(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.85 + 0.15 * sin(glowPhase);
    final path =
      _getCachedPath(15, r, (p) => _buildRegularPolygonPath(p, 3, r));

    // Fill
    final gradient = RadialGradient(
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.1, 1.0],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, fillP);

    // Internal refraction lines
    final lineP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.white.withValues(alpha: 0.2 * glow);
    canvas.drawLine(Offset(0, -r), Offset(0, r * 0.3), lineP);

    // Stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _safeColor(colors, 1).withValues(alpha: 0.5 * intensity * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 17. Leaf ──────────────────────────────────────────────────────────

  static void _drawLeaf(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.85 + 0.15 * sin(glowPhase);
    final path = _getCachedPath(16, r, (p) {
      p
        ..moveTo(0, -r * 1.1)
        ..cubicTo(r * 0.9, -r * 0.7, r * 0.9, r * 0.5, 0, r * 1.1)
        ..cubicTo(-r * 0.9, r * 0.5, -r * 0.9, -r * 0.7, 0, -r * 1.1)
        ..close();
    });

    // Fill
    final gradient = RadialGradient(
      center: const Alignment(0.0, -0.2),
      colors: [_safeColor(colors, 0), _safeColor(colors, 1)],
      stops: const [0.1, 1.0],
    );
    final fillP = Paint()
      ..shader =
          gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.1));
    canvas.drawPath(path, fillP);

    // Center vein
    final veinP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.35 * glow);
    canvas.drawLine(Offset(0, -r * 0.85), Offset(0, r * 0.85), veinP);

    // Side veins
    veinP.strokeWidth = 0.6;
    veinP.color = Colors.white.withValues(alpha: 0.2 * glow);
    for (final dy in _leafVeinOffsets) {
      canvas.drawLine(Offset(0, r * dy), Offset(r * 0.4, r * (dy - 0.2)), veinP);
      canvas.drawLine(Offset(0, r * dy), Offset(-r * 0.4, r * (dy - 0.2)), veinP);
    }

    // Outline stroke
    final strokeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _safeColor(colors, 1).withValues(alpha: 0.4 * intensity * glow);
    canvas.drawPath(path, strokeP);
  }

  // ─── 18. Ring ──────────────────────────────────────────────────────────

  static void _drawRing(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);

    // Inner faint glow
    final glowP = _glowPaint(
      _safeColor(colors, 0).withValues(alpha: 0.15 * intensity * glow),
      r * 0.4,
    );
    canvas.drawCircle(Offset.zero, r * 0.7, glowP);

    // Outer glow ring
    final outerGlowP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.25
      ..color = _safeColor(colors, 0).withValues(alpha: 0.2 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.15);
    canvas.drawCircle(Offset.zero, r, outerGlowP);

    // Main ring stroke
    final ringP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = SweepGradient(
        colors: [
          _safeColor(colors, 0),
          _safeColor(colors, 1),
          _safeColor(colors, 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, ringP);
  }

  // ─── 19. Slit ──────────────────────────────────────────────────────────

  static void _drawSlit(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);
    final w = r * 1.1;
    final h = r * 0.175;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w * 2, height: h * 2),
      Radius.circular(h),
    );

    // Soft outer glow
    final glowP = Paint()
      ..color = _safeColor(colors, 0).withValues(alpha: 0.3 * intensity * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35);
    canvas.drawRRect(rrect, glowP);

    // Main fill with linear gradient
    final gradient = LinearGradient(
      colors: [
        _safeColor(colors, 1).withValues(alpha: 0.4),
        _safeColor(colors, 0),
        _safeColor(colors, 1).withValues(alpha: 0.4),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final fillP = Paint()
      ..shader = gradient.createShader(
          Rect.fromCenter(center: Offset.zero, width: w * 2, height: h * 2));
    canvas.drawRRect(rrect, fillP);

    // Bright center dot
    final dotP = Paint()
      ..color = Colors.white.withValues(alpha: 0.75 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(Offset.zero, r * 0.09, dotP);
  }

  // ─── 20. Singularity ──────────────────────────────────────────────────

  static void _drawSingularity(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);

    // Outer aura
    final auraP = Paint()
      ..color = _safeColor(colors, 0).withValues(alpha: 0.3 * intensity * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.55);
    canvas.drawCircle(Offset.zero, r * 1.1, auraP);

    // Mid aura ring
    final midP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..color = _safeColor(colors, 0).withValues(alpha: 0.35 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.1);
    canvas.drawCircle(Offset.zero, r * 0.75, midP);

    // Contrasting subtle ring
    final contrastP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _safeColor(colors, 1).withValues(alpha: 0.3 * glow);
    canvas.drawCircle(Offset.zero, r * 0.55, contrastP);

    // Dark gradient core
    final coreGrad = RadialGradient(
      colors: [
        Colors.black,
        Colors.black.withValues(alpha: 0.9),
        _safeColor(colors, 0).withValues(alpha: 0.15),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    final coreP = Paint()
      ..shader =
          coreGrad.createShader(Rect.fromCircle(center: Offset.zero, radius: r * 0.45));
    canvas.drawCircle(Offset.zero, r * 0.45, coreP);
  }

  // ─── 21. Double Ring ───────────────────────────────────────────────────

  static void _drawDoubleRing(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);

    // Outer ring glow
    final outerGlowP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18
      ..color = _safeColor(colors, 0).withValues(alpha: 0.18 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12);
    canvas.drawCircle(Offset.zero, r, outerGlowP);

    // Outer ring
    final outerP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = _safeColor(colors, 0).withValues(alpha: 0.85 * intensity);
    canvas.drawCircle(Offset.zero, r, outerP);

    // Inner ring glow
    final innerGlowP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..color = _safeColor(colors, 1).withValues(alpha: 0.15 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08);
    canvas.drawCircle(Offset.zero, r * 0.6, innerGlowP);

    // Inner ring
    final innerP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _safeColor(colors, 1).withValues(alpha: 0.7 * intensity);
    canvas.drawCircle(Offset.zero, r * 0.6, innerP);

    // Center dot
    final dotP = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(Offset.zero, r * 0.07, dotP);
  }

  // ─── 22. Helix ─────────────────────────────────────────────────────────

  static void _drawHelix(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);
    const steps = 30;
    final path1 = _pathA..reset();
    final path2 = _pathB..reset();

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = -r + 2 * r * t;
      final angle = t * 3 * pi + glowPhase * 0.5;
      final xAmplitude = r * 0.65;
      final perspectiveY = 0.35; // Y compression for perspective

      final x1 = xAmplitude * sin(angle);
      final y1 = y + xAmplitude * cos(angle) * perspectiveY;
      final x2 = xAmplitude * sin(angle + pi);
      final y2 = y + xAmplitude * cos(angle + pi) * perspectiveY;

      if (i == 0) {
        path1.moveTo(x1, y1);
        path2.moveTo(x2, y2);
      } else {
        path1.lineTo(x1, y1);
        path2.lineTo(x2, y2);
      }
    }

    // Strand 1 glow
    final glow1P = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round
      ..color = _safeColor(colors, 0).withValues(alpha: 0.2 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.1);
    canvas.drawPath(path1, glow1P);

    // Strand 1 main
    final main1P = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1
      ..strokeCap = StrokeCap.round
      ..color = _safeColor(colors, 0).withValues(alpha: 0.85 * intensity);
    canvas.drawPath(path1, main1P);

    // Strand 2 glow
    final glow2P = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round
      ..color = _safeColor(colors, 1).withValues(alpha: 0.15 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.1);
    canvas.drawPath(path2, glow2P);

    // Strand 2 main
    final main2P = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1
      ..strokeCap = StrokeCap.round
      ..color = _safeColor(colors, 1).withValues(alpha: 0.7 * intensity);
    canvas.drawPath(path2, main2P);
  }

  // ─── 23. Tesseract ─────────────────────────────────────────────────────

  static void _drawTesseract(Canvas canvas, double r, List<Color> colors,
      double glowPhase, double intensity) {
    final glow = 0.8 + 0.2 * sin(glowPhase);
    final outer = r * 0.95;
    final inner = r * 0.5;

    // 8 outer vertices (cube projected)
    final outerVerts = <Offset>[
      Offset(-outer, -outer),
      Offset(outer, -outer),
      Offset(outer, outer),
      Offset(-outer, outer),
      Offset(-outer * 0.7, -outer * 0.7),
      Offset(outer * 0.7, -outer * 0.7),
      Offset(outer * 0.7, outer * 0.7),
      Offset(-outer * 0.7, outer * 0.7),
    ];

    // 8 inner vertices (inner cube, rotated slightly via phase)
    final phase = glowPhase * 0.15;
    final cosP = cos(phase);
    final sinP = sin(phase);
    final innerVerts = <Offset>[
      Offset(-inner * cosP - inner * sinP, -inner * sinP + (-inner) * cosP),
      Offset(inner * cosP - inner * sinP, inner * sinP + (-inner) * cosP),
      Offset(inner * cosP - (-inner) * sinP, inner * sinP + inner * cosP),
      Offset(-inner * cosP - (-inner) * sinP, -inner * sinP + inner * cosP),
      Offset(-inner * 0.6 * cosP - inner * 0.6 * sinP,
          -inner * 0.6 * sinP + (-inner * 0.6) * cosP),
      Offset(inner * 0.6 * cosP - inner * 0.6 * sinP,
          inner * 0.6 * sinP + (-inner * 0.6) * cosP),
      Offset(inner * 0.6 * cosP - (-inner * 0.6) * sinP,
          inner * 0.6 * sinP + inner * 0.6 * cosP),
      Offset(-inner * 0.6 * cosP - (-inner * 0.6) * sinP,
          -inner * 0.6 * sinP + inner * 0.6 * cosP),
    ];

    // Outer cube edges
    final outerP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _safeColor(colors, 0).withValues(alpha: 0.6 * intensity);

    // Inner cube edges
    final innerP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _safeColor(colors, 1).withValues(alpha: 0.5 * intensity);

    // Connect paint
    final connectP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = _safeColor(colors, 0).withValues(alpha: 0.3 * intensity * glow);

    // Draw outer cube edges (front face, back face, connecting)
    void drawCubeEdges(List<Offset> v, Paint p) {
      // Front face 0-1-2-3
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(v[i], v[(i + 1) % 4], p);
      }
      // Back face 4-5-6-7
      for (var i = 4; i < 8; i++) {
        canvas.drawLine(v[i], v[4 + (i - 4 + 1) % 4], p);
      }
      // Connecting edges
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(v[i], v[i + 4], p);
      }
    }

    drawCubeEdges(outerVerts, outerP);
    drawCubeEdges(innerVerts, innerP);

    // Connect outer to inner (the 4D projection links)
    for (var i = 0; i < 8; i++) {
      canvas.drawLine(outerVerts[i], innerVerts[i], connectP);
    }

    // Vertex glow dots
    final dotP = Paint()
      ..color = _safeColor(colors, 0).withValues(alpha: 0.5 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (final v in outerVerts) {
      canvas.drawCircle(v, r * 0.04, dotP);
    }
  }
}
