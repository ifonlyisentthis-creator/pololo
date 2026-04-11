import 'package:flutter_test/flutter_test.dart';
import 'package:polarity/features/game/engine/game_engine.dart';
import 'package:polarity/features/game/visual/theme_registry.dart';

void main() {
  test('themes unlock at score 100', () {
    expect(ThemeRegistry.scoreToTier(99), 0);
    expect(ThemeRegistry.scoreToTier(100), 1);
  });

  test('white mode inversion is applied while dark mode stays unchanged', () {
    final engine = GameEngine();
    final theme = ThemeRegistry.selectTheme(
      100,
      {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );

    expect(theme, isNotNull);
    engine.activeTheme = theme;
    engine.rebuildInvertedCache();

    // Dark mode path: should keep the raw active theme.
    engine.useWhiteSurfaceThemeInversion = false;
    engine.isPhase5Inverted = false;
    expect(identical(engine.effectiveTheme, engine.activeTheme), isTrue);

    // White mode path: should switch to contrast-safe derived theme.
    engine.useWhiteSurfaceThemeInversion = true;
    final whiteTheme = engine.effectiveTheme;
    expect(whiteTheme, isNotNull);
    expect(identical(whiteTheme, engine.activeTheme), isFalse);

    final hasTooBrightBallColor =
        whiteTheme!.ballColors.any((c) => c.computeLuminance() > 0.7);
    final hasTooBrightTrailColor =
        whiteTheme.trailColors.any((c) => c.computeLuminance() > 0.7);
    expect(hasTooBrightBallColor, isFalse);
    expect(hasTooBrightTrailColor, isFalse);

    // Phase 5 inversion still has highest priority.
    engine.isPhase5Inverted = true;
    final phase5Theme = engine.effectiveTheme;
    expect(phase5Theme, isNotNull);
    expect(identical(phase5Theme, engine.activeTheme), isFalse);
  });
}