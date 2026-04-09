import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Procedurally generated audio - no asset files needed.
/// Uses layered harmonics, ADSR envelopes, and stereo-quality synthesis
/// at 44100 Hz for premium sound design.
class AudioService {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, Uint8List> _cachedBytes = {};
  bool enabled = true;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Pre-generate all SFX into memory
    _cachedBytes['score'] = _generateScoreSfx();
    _cachedBytes['death'] = _generateDeathSfx();
    _cachedBytes['tap'] = _generateTapSfx();
    _cachedBytes['phase'] = _generatePhaseSfx();
    _cachedBytes['countdown'] = _generateCountdownSfx();
    _cachedBytes['menu'] = _generateMenuSfx();
    _cachedBytes['revive'] = _generateReviveSfx();
    _cachedBytes['shield_pickup'] = _generateShieldPickupSfx();
    _cachedBytes['shield_break'] = _generateShieldBreakSfx();
    _cachedBytes['elite_unlock'] = _generateEliteUnlockSfx();
    _cachedBytes['tier_up'] = _generateTierUpSfx();

    // Pre-create players for each SFX
    for (final key in _cachedBytes.keys) {
      _players[key] = AudioPlayer();
    }
  }

  Future<void> play(String sfxName) async {
    if (!enabled || !_initialized) return;
    final bytes = _cachedBytes[sfxName];
    if (bytes == null) return;

    try {
      final player = _players[sfxName];
      if (player == null) return;
      await player.stop();
      await player.play(BytesSource(bytes));
    } catch (_) {
      // Silently fail - audio is non-critical
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _cachedBytes.clear();
    _initialized = false;
  }

  // --- WAV Generation Utilities ---

  static const int _sr = 44100; // 44.1 kHz for quality

  static Uint8List _generateWav(List<double> samples, int sampleRate) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2; // 16-bit PCM
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);
    int offset = 0;

    void writeString(String s) {
      for (int i = 0; i < s.length; i++) {
        buffer.setUint8(offset++, s.codeUnitAt(i));
      }
    }

    void writeUint32(int v) {
      buffer.setUint32(offset, v, Endian.little);
      offset += 4;
    }

    void writeUint16(int v) {
      buffer.setUint16(offset, v, Endian.little);
      offset += 2;
    }

    writeString('RIFF');
    writeUint32(fileSize);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16); // chunk size
    writeUint16(1); // PCM
    writeUint16(1); // mono
    writeUint32(sampleRate);
    writeUint32(sampleRate * 2); // byte rate
    writeUint16(2); // block align
    writeUint16(16); // bits per sample
    writeString('data');
    writeUint32(dataSize);

    for (final sample in samples) {
      final clamped = sample.clamp(-1.0, 1.0);
      final intSample = (clamped * 32767).toInt();
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  /// ADSR envelope: attack/decay/sustain-level/release in seconds
  static double _adsr(double t, double dur,
      {double a = 0.005, double d = 0.05, double s = 0.6, double r = 0.05}) {
    final rStart = dur - r;
    if (t < a) return t / a;
    if (t < a + d) return 1.0 - (1.0 - s) * ((t - a) / d);
    if (t < rStart) return s;
    if (t < dur) return s * (1.0 - (t - rStart) / r);
    return 0;
  }

  /// Soft-clip to avoid harsh digital clipping
  static double _softClip(double x) {
    if (x > 1.0) return 1.0;
    if (x < -1.0) return -1.0;
    return x - (x * x * x) / 3.0;
  }

  // ── Score: crisp ascending two-tone ping with harmonics ──
  static Uint8List _generateScoreSfx() {
    const duration = 0.12;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      // Two-stage: first note then second note (major third up)
      final env1 = t < 0.06 ? _adsr(t, 0.06, a: 0.002, d: 0.02, s: 0.5, r: 0.02) : 0.0;
      final env2 = t >= 0.05 ? _adsr(t - 0.05, 0.07, a: 0.002, d: 0.02, s: 0.5, r: 0.03) : 0.0;

      // Note 1: E6 (1318 Hz) with octave harmonic
      final f1 = 1318.5;
      final tone1 = sin(2 * pi * f1 * t) * 0.7 +
          sin(2 * pi * f1 * 2 * t) * 0.2 +
          sin(2 * pi * f1 * 3 * t) * 0.1;

      // Note 2: G#6 (1661 Hz) — major third up
      final f2 = 1661.2;
      final tone2 = sin(2 * pi * f2 * t) * 0.7 +
          sin(2 * pi * f2 * 2 * t) * 0.2 +
          sin(2 * pi * f2 * 3 * t) * 0.1;

      samples[i] = _softClip((tone1 * env1 + tone2 * env2) * 0.4);
    }
    return _generateWav(samples, _sr);
  }

  // ── Death: deep impact with distorted sub-bass drop + noise burst ──
  static Uint8List _generateDeathSfx() {
    const duration = 0.55;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);
    final rng = Random(42);

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      final norm = t / duration;

      // Impact envelope: sharp attack, exponential decay
      final impactEnv = exp(-t * 8.0);

      // Sub-bass: pitch drops from 180Hz to 35Hz
      final subFreq = 180.0 - 145.0 * norm;
      final sub = sin(2 * pi * subFreq * t) * 0.6 +
          sin(2 * pi * subFreq * 2 * t) * 0.25; // octave harmonic

      // Noise burst: filtered white noise, fast decay
      final noiseEnv = exp(-t * 16.0);
      final noise = (rng.nextDouble() * 2 - 1) * noiseEnv;

      // Distortion crunch on the sub
      final crunched = _softClip(sub * 1.8) * impactEnv;

      // Low rumble tail
      final rumble = sin(2 * pi * 40 * t + sin(2 * pi * 3 * t) * 2) *
          exp(-t * 4.0) * 0.3;

      samples[i] = _softClip((crunched * 0.5 + noise * 0.25 + rumble) * 0.55);
    }
    return _generateWav(samples, _sr);
  }

  // ── Tap: ultra-short crisp click with body ──
  static Uint8List _generateTapSfx() {
    const duration = 0.045;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      // Exponential decay for click feel
      final env = exp(-t * 120);

      // Layered: fundamental + perfect fifth + octave for fullness
      final tone = sin(2 * pi * 800 * t) * 0.5 +
          sin(2 * pi * 1200 * t) * 0.3 +
          sin(2 * pi * 1600 * t) * 0.2;

      // Transient click at very start
      final click = t < 0.003 ? sin(2 * pi * 4000 * t) * (1 - t / 0.003) : 0.0;

      samples[i] = _softClip((tone * env + click * 0.15) * 0.3);
    }
    return _generateWav(samples, _sr);
  }

  // ── Phase: majestic ascending sweep with shimmer ──
  static Uint8List _generatePhaseSfx() {
    const duration = 0.5;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      final norm = t / duration;
      final env = _adsr(t, duration, a: 0.02, d: 0.1, s: 0.7, r: 0.12);

      // Ascending sweep: C5 → C6 (523 → 1047)
      final freq = 523.0 + 524.0 * norm * norm; // quadratic for acceleration feel
      final tone = sin(2 * pi * freq * t) * 0.45 +
          sin(2 * pi * freq * 2 * t) * 0.2 +
          sin(2 * pi * freq * 3 * t) * 0.1;

      // Shimmer: high-frequency modulation
      final shimmer = sin(2 * pi * freq * 5 * t) * 0.08 *
          sin(pi * norm); // fades in then out

      // Subtle chorus: slightly detuned second voice
      final chorus = sin(2 * pi * (freq * 1.005) * t) * 0.15;

      samples[i] = _softClip((tone + shimmer + chorus) * env * 0.4);
    }
    return _generateWav(samples, _sr);
  }

  // ── Countdown: clean resonant bell tone ──
  static Uint8List _generateCountdownSfx() {
    const duration = 0.25;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      // Bell-like: fast attack, medium decay with ring
      final env = exp(-t * 12.0);

      // Bell partials: fundamental + inharmonic overtones
      final f = 880.0;
      final bell = sin(2 * pi * f * t) * 0.5 +
          sin(2 * pi * f * 2.0 * t) * 0.25 +
          sin(2 * pi * f * 2.76 * t) * 0.12 + // inharmonic for bell character
          sin(2 * pi * f * 4.07 * t) * 0.08;

      samples[i] = _softClip(bell * env * 0.35);
    }
    return _generateWav(samples, _sr);
  }

  // ── Menu: soft tactile click with warmth ──
  static Uint8List _generateMenuSfx() {
    const duration = 0.09;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      // Two-stage envelope: sharp transient + warm tail
      final transient = t < 0.005 ? (1.0 - t / 0.005) : 0.0;
      final body = exp(-t * 40);

      // Warm fundamental with soft overtone
      final tone = sin(2 * pi * 660 * t) * 0.6 +
          sin(2 * pi * 990 * t) * 0.25 + // perfect fifth
          sin(2 * pi * 1320 * t) * 0.15;

      samples[i] = _softClip((tone * body + transient * 0.2) * 0.28);
    }
    return _generateWav(samples, _sr);
  }

  // ── Revive: hopeful ascending arpeggio with reverb tail ──
  static Uint8List _generateReviveSfx() {
    const duration = 0.6;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);

    // Three-note ascending arpeggio: C5, E5, G5
    const notes = [523.25, 659.25, 783.99];
    const noteStart = [0.0, 0.1, 0.2];
    const noteDur = [0.35, 0.35, 0.4];

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      double sample = 0;

      for (int j = 0; j < 3; j++) {
        final nt = t - noteStart[j];
        if (nt < 0 || nt > noteDur[j]) continue;

        final env = _adsr(nt, noteDur[j], a: 0.008, d: 0.05, s: 0.5, r: 0.15);
        final f = notes[j];
        final tone = sin(2 * pi * f * nt) * 0.5 +
            sin(2 * pi * f * 2 * nt) * 0.2 +
            sin(2 * pi * f * 3 * nt) * 0.1;

        // Slight detune for chorus
        final chorus = sin(2 * pi * f * 1.003 * nt) * 0.12;

        sample += (tone + chorus) * env;
      }

      // Global reverb tail: gentle decay envelope over everything
      samples[i] = _softClip(sample * 0.35);
    }

    // Simple reverb: mix in delayed copies
    for (int delay in [2200, 4800, 7400]) {
      for (int i = delay; i < n; i++) {
        final atten = 0.15 * exp(-(i - delay) / _sr * 3);
        samples[i] += samples[i - delay] * atten;
      }
    }

    // Final soft clip pass
    for (int i = 0; i < n; i++) {
      samples[i] = _softClip(samples[i]);
    }

    return _generateWav(samples, _sr);
  }

  // ── Shield Pickup: bright ascending sparkle micro-arpeggio ──
  static Uint8List _generateShieldPickupSfx() {
    const duration = 0.15;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);

    // Three-note micro-arpeggio: C7, E7, G7
    const notes = [2093.0, 2637.0, 3136.0];
    const noteStart = [0.0, 0.035, 0.07];
    const noteDur = [0.08, 0.08, 0.08];

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      double sample = 0;

      for (int j = 0; j < 3; j++) {
        final nt = t - noteStart[j];
        if (nt < 0 || nt > noteDur[j]) continue;

        final env = exp(-nt * 30.0); // fast sparkle decay
        final f = notes[j];
        final tone = sin(2 * pi * f * nt) * 0.6 +
            sin(2 * pi * f * 2 * nt) * 0.2 +
            sin(2 * pi * f * 3 * nt) * 0.1;

        sample += tone * env;
      }

      samples[i] = _softClip(sample * 0.3);
    }
    return _generateWav(samples, _sr);
  }

  // ── Shield Break: glass-crack impact with sub weight ──
  static Uint8List _generateShieldBreakSfx() {
    const duration = 0.2;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);
    final rng = Random(77);

    for (int i = 0; i < n; i++) {
      final t = i / _sr;

      // Sharp noise burst: glass shatter
      final noiseEnv = t < 0.002 ? 1.0 : exp(-(t - 0.002) * 25.0);
      final noise = (rng.nextDouble() * 2 - 1) * noiseEnv;

      // Sub-tone for impact weight
      final sub = sin(2 * pi * 120 * t) * exp(-t * 15.0) * 0.4;

      // High glass partial
      final glass = sin(2 * pi * 3200 * t) * exp(-t * 35.0) * 0.15;

      samples[i] = _softClip((noise * 0.5 + sub + glass) * 0.35);
    }
    return _generateWav(samples, _sr);
  }

  // ── Elite Unlock: triumphant ascending 4-note major arpeggio with shimmer & reverb ──
  static Uint8List _generateEliteUnlockSfx() {
    const duration = 0.8;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);

    // Four-note ascending major arpeggio: C5, E5, G5, C6
    const notes = [523.25, 659.25, 783.99, 1046.50];
    const noteStart = [0.0, 0.12, 0.24, 0.36];
    const noteDur = [0.45, 0.45, 0.45, 0.44];

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      final norm = t / duration;
      double sample = 0;

      for (int j = 0; j < 4; j++) {
        final nt = t - noteStart[j];
        if (nt < 0 || nt > noteDur[j]) continue;

        final env = _adsr(nt, noteDur[j], a: 0.01, d: 0.06, s: 0.55, r: 0.18);
        final f = notes[j];

        // Rich tone: fundamental + octave + 3rd harmonic + 5th harmonic
        final tone = sin(2 * pi * f * nt) * 0.45 +
            sin(2 * pi * f * 2 * nt) * 0.2 +
            sin(2 * pi * f * 3 * nt) * 0.1 +
            sin(2 * pi * f * 5 * nt) * 0.05;

        // Chorus: detuned voices for width
        final chorus = sin(2 * pi * f * 1.004 * nt) * 0.1 +
            sin(2 * pi * f * 0.997 * nt) * 0.08;

        // Shimmer: high harmonic that swells with arpeggio progress
        final shimmerAmt = 0.06 * (j + 1) / 4;
        final shimmer = sin(2 * pi * f * 6 * nt) * shimmerAmt *
            sin(pi * nt / noteDur[j]);

        sample += (tone + chorus + shimmer) * env;
      }

      // Global brightness lift toward the peak
      final brightness = sin(2 * pi * 1046.50 * 4 * t) * 0.03 *
          sin(pi * norm) * _adsr(t, duration, a: 0.3, d: 0.1, s: 0.4, r: 0.2);

      samples[i] = _softClip((sample + brightness) * 0.32);
    }

    // Reverb: layered delays for spacious hall feel
    for (int delay in [2000, 4400, 7200, 10000]) {
      for (int i = delay; i < n; i++) {
        final atten = 0.14 * exp(-(i - delay) / _sr * 2.5);
        samples[i] += samples[i - delay] * atten;
      }
    }

    // Final soft clip pass
    for (int i = 0; i < n; i++) {
      samples[i] = _softClip(samples[i]);
    }

    return _generateWav(samples, _sr);
  }

  // ── Tier Up: resonant power chord with bell partials — deep satisfying gong ──
  static Uint8List _generateTierUpSfx() {
    const duration = 0.5;
    final n = (_sr * duration).toInt();
    final samples = List<double>.filled(n, 0);

    // Major triad: C4, E4, G4
    const chordFreqs = [261.63, 329.63, 392.00];

    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      double sample = 0;

      for (int j = 0; j < 3; j++) {
        final f = chordFreqs[j];

        // Envelope: quick attack, long resonant decay like a struck bell
        final env = _adsr(t, duration, a: 0.005, d: 0.08, s: 0.45, r: 0.2);

        // Core tone with bell-like inharmonic partials
        final tone = sin(2 * pi * f * t) * 0.4 +
            sin(2 * pi * f * 2.0 * t) * 0.2 +
            sin(2 * pi * f * 2.76 * t) * 0.1 + // inharmonic bell partial
            sin(2 * pi * f * 4.07 * t) * 0.06 + // higher inharmonic
            sin(2 * pi * f * 5.4 * t) * 0.03;

        // Exponential ring for gong resonance
        final ring = exp(-t * 5.0);

        sample += tone * env * ring;
      }

      // Sub-bass weight: octave below root for depth
      final subEnv = exp(-t * 6.0);
      final sub = sin(2 * pi * 130.81 * t) * 0.2 * subEnv;

      // Metallic shimmer on attack
      final metalEnv = exp(-t * 18.0);
      final metal = sin(2 * pi * 1568.0 * t) * 0.06 * metalEnv +
          sin(2 * pi * 2093.0 * t) * 0.04 * metalEnv;

      samples[i] = _softClip((sample + sub + metal) * 0.38);
    }

    // Short reverb for resonance
    for (int delay in [1800, 3600, 5800]) {
      for (int i = delay; i < n; i++) {
        final atten = 0.12 * exp(-(i - delay) / _sr * 4.0);
        samples[i] += samples[i - delay] * atten;
      }
    }

    // Final soft clip pass
    for (int i = 0; i < n; i++) {
      samples[i] = _softClip(samples[i]);
    }

    return _generateWav(samples, _sr);
  }
}
