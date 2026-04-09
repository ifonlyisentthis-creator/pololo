import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  bool enabled = true;
  bool _hasVibrator = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        _hasVibrator = await Vibration.hasVibrator();
      }
    } catch (_) {
      _hasVibrator = false;
    }
  }

  /// Light tap feedback
  Future<void> lightTap() async {
    if (!enabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium impact for scoring
  Future<void> mediumImpact() async {
    if (!enabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact for death
  Future<void> heavyImpact() async {
    if (!enabled) return;
    try {
      HapticFeedback.heavyImpact();
      if (_hasVibrator) {
        Vibration.vibrate(duration: 100, amplitude: 200);
      }
    } catch (_) {}
  }

  /// Selection click for UI
  Future<void> selectionClick() async {
    if (!enabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Phase transition vibration pattern
  Future<void> phaseVibrate() async {
    if (!enabled) return;
    try {
      if (_hasVibrator) {
        Vibration.vibrate(pattern: [0, 50, 30, 50, 30, 80], intensities: [0, 128, 0, 200, 0, 255]);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }
}
