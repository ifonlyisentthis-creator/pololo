import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  bool enabled = true;
  bool _hasVibrator = false;
  bool _initialized = false;

  int _lastLightMicros = 0;
  int _lastMediumMicros = 0;
  int _lastHeavyMicros = 0;
  int _lastSelectionMicros = 0;
  int _lastPhaseMicros = 0;

  static const int _lightGapMs = 22;
  static const int _mediumGapMs = 35;
  static const int _heavyGapMs = 90;
  static const int _selectionGapMs = 24;
  static const int _phaseGapMs = 180;

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

  int _nowMicros() => DateTime.now().microsecondsSinceEpoch;

  bool _tooSoon(int nowMicros, int lastMicros, int gapMs) {
    if (lastMicros == 0) return false;
    return nowMicros - lastMicros < gapMs * 1000;
  }

  /// Light tap feedback
  Future<void> lightTap() async {
    if (!enabled) return;
    final now = _nowMicros();
    if (_tooSoon(now, _lastLightMicros, _lightGapMs)) return;
    _lastLightMicros = now;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium impact for scoring
  Future<void> mediumImpact() async {
    if (!enabled) return;
    final now = _nowMicros();
    if (_tooSoon(now, _lastMediumMicros, _mediumGapMs)) return;
    _lastMediumMicros = now;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact for death
  Future<void> heavyImpact() async {
    if (!enabled) return;
    final now = _nowMicros();
    if (_tooSoon(now, _lastHeavyMicros, _heavyGapMs)) return;
    _lastHeavyMicros = now;
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
    final now = _nowMicros();
    if (_tooSoon(now, _lastSelectionMicros, _selectionGapMs)) return;
    _lastSelectionMicros = now;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Phase transition vibration pattern
  Future<void> phaseVibrate() async {
    if (!enabled) return;
    final now = _nowMicros();
    if (_tooSoon(now, _lastPhaseMicros, _phaseGapMs)) return;
    _lastPhaseMicros = now;
    try {
      if (_hasVibrator) {
        Vibration.vibrate(pattern: [0, 50, 30, 50, 30, 80], intensities: [0, 128, 0, 200, 0, 255]);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }
}
