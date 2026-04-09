import 'package:flutter/material.dart';

class PolarityTheme {
  PolarityTheme._();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        surface: Colors.black,
        primary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 72,
          fontWeight: FontWeight.w100,
          color: Colors.white,
          letterSpacing: -2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 48,
          fontWeight: FontWeight.w200,
          color: Colors.white,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 28,
          fontWeight: FontWeight.w300,
          color: Colors.white,
          letterSpacing: 4,
        ),
        titleLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: Colors.white70,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: Colors.white60,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: Colors.white54,
        ),
        labelLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 3,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white70, size: 24),
      useMaterial3: true,
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        surface: Colors.white,
        primary: Colors.black,
        onSurface: Colors.black,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 72,
          fontWeight: FontWeight.w100,
          color: Colors.black,
          letterSpacing: -2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 48,
          fontWeight: FontWeight.w200,
          color: Colors.black,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 28,
          fontWeight: FontWeight.w300,
          color: Colors.black,
          letterSpacing: 4,
        ),
        titleLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: Colors.black54,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: Colors.black45,
        ),
        labelLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          letterSpacing: 3,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87, size: 24),
      useMaterial3: true,
    );
  }
}
