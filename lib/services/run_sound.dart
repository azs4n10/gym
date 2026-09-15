import 'run_sound_stub.dart' if (dart.library.js_interop) 'run_sound_web.dart' as bridge;

/// Small synthesised sounds for the run companion: a footfall click, a chime
/// at a landmark, the wheel's ticking, a two-note cheer. No files; the browser
/// makes the tones, so this does nothing on other platforms.
class RunSound {
  static bool get available => bridge.available;

  /// Browsers only start audio after a tap, so call this from a button.
  static void unlock() => bridge.unlock();

  static void tick() => bridge.tone(1400, 0.03, 0.12);
  static void cheer() {
    bridge.tone(660, 0.12, 0.25);
    bridge.tone(880, 0.16, 0.25, delay: 0.12);
  }

  static void chime() {
    bridge.tone(523, 0.14, 0.3);
    bridge.tone(659, 0.14, 0.3, delay: 0.14);
    bridge.tone(784, 0.24, 0.3, delay: 0.28);
  }

  static void spin() {
    for (var i = 0; i < 14; i++) {
      bridge.tone(900, 0.02, 0.1, delay: i * i * 0.011);
    }
  }
}
