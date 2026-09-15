import 'package:web/web.dart' as web;

bool get available => true;

web.AudioContext? _ctx;

void unlock() {
  _ctx ??= web.AudioContext();
  if (_ctx!.state == 'suspended') _ctx!.resume();
}

/// A short sine tone with a quick fade, [delay] seconds from now.
void tone(double hz, double seconds, double gain, {double delay = 0}) {
  final ctx = _ctx;
  if (ctx == null) return;
  final osc = ctx.createOscillator();
  final vol = ctx.createGain();
  osc.frequency.value = hz;
  osc.type = 'sine';
  final t0 = ctx.currentTime + delay;
  vol.gain.setValueAtTime(0, t0);
  vol.gain.linearRampToValueAtTime(gain, t0 + 0.008);
  vol.gain.exponentialRampToValueAtTime(0.0001, t0 + seconds);
  osc.connect(vol);
  vol.connect(ctx.destination);
  osc.start(t0);
  osc.stop(t0 + seconds + 0.02);
}
