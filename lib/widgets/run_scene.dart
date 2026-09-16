import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/run_play.dart';
import '../theme/skin.dart';
import 'run_glyphs.dart';

enum SceneView { side, ahead }

enum SceneWeather { clear, cloudy, rain, snow }

/// The world the companion runs through: a sky that follows the clock, hills
/// and trees sliding past at different speeds, landmarks that show up far off
/// and grow as they come near, rain or snow when the weather says so. Drawn
/// from the side or from behind the runner; the figure itself is laid on top
/// by the run screen.
class RunScene extends StatelessWidget {
  const RunScene({
    super.key,
    required this.route,
    required this.km,
    required this.seconds,
    required this.view,
    required this.weather,
    required this.incline,
    required this.now,
    required this.skin,
    required this.ja,
    required this.labelStyle,
    this.water = false,
  });

  /// Open water instead of a road: the swimmer's world.
  final bool water;

  /// The water surface as a fraction of the height, when [water].
  static const waterY = 0.6;

  /// The colour of the water in a skin: its accent pulled toward a sea blue.
  static Color waterColor(Skin skin) => Color.lerp(skin.accent, const Color(0xFF6FA8C9), 0.55)!;

  final RunRoute route;

  /// Position on the route.
  final double km;

  /// Time on the clock, for things that move on their own.
  final double seconds;
  final SceneView view;
  final SceneWeather weather;

  /// 0 to 1: how much the road tilts up ahead.
  final double incline;
  final DateTime now;
  final Skin skin;
  final bool ja;
  final TextStyle labelStyle;

  /// Where the runner stands, as a fraction of the width (side view) and the
  /// ground line as a fraction of the height.
  static const runnerX = 0.3;
  static const groundY = 0.8;
  static const horizonY = 0.42;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScenePainter(this),
      willChange: true,
      child: const SizedBox.expand(),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.s);
  final RunScene s;

  Skin get skin => s.skin;

  // Pixels per metre on the road layer of the side view.
  static const _ppm = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sky = _skyColor();
    canvas.drawRect(Offset.zero & size, Paint()..color = sky);
    _stars(canvas, size);
    _sunMoon(canvas, size);
    _clouds(canvas, size);
    if (s.water) {
      if (s.view == SceneView.side) {
        _water(canvas, size);
      } else {
        _aheadWater(canvas, size);
      }
    } else if (s.view == SceneView.side) {
      _side(canvas, size);
    } else {
      _ahead(canvas, size);
    }
    _precipitation(canvas, size);
    // A thin frame line at the bottom keeps the card edge tidy.
    canvas.drawLine(Offset(0, h - 0.5), Offset(w, h - 0.5), Paint()..color = skin.ink.withValues(alpha: 0.15));
  }

  // ---------------------------------------------------------------- sky

  double get _hour => s.now.hour + s.now.minute / 60;

  bool get _night => _hour < 5.5 || _hour >= 19.5;

  Color _skyColor() {
    final day = Color.lerp(skin.background, skin.card, 0.4)!;
    final dawn = Color.lerp(skin.button, skin.card, 0.45)!;
    final dusk = Color.lerp(skin.accent, skin.card, 0.3)!;
    final night = Color.lerp(skin.ink, skin.heading, 0.3)!;
    final keys = <(double, Color)>[
      (0, night), (5, night), (6.5, dawn), (8, day), (16, day), (18, dusk), (20, night), (24, night),
    ];
    final t = _hour;
    for (var i = 0; i < keys.length - 1; i++) {
      final (h0, c0) = keys[i];
      final (h1, c1) = keys[i + 1];
      if (t >= h0 && t <= h1) return Color.lerp(c0, c1, (t - h0) / (h1 - h0))!;
    }
    return day;
  }

  void _stars(Canvas canvas, Size size) {
    if (!_night) return;
    final paint = Paint()..color = skin.card;
    final rnd = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.5;
      final tw = 0.6 + 0.6 * (0.5 + 0.5 * math.sin(s.seconds * 1.5 + i));
      canvas.drawCircle(Offset(x, y), tw, paint);
    }
  }

  void _sunMoon(Canvas canvas, Size size) {
    final t = _hour;
    final ink = Paint()
      ..color = skin.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    if (_night) {
      final x = size.width * 0.78;
      final y = size.height * 0.18;
      final moon = Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: 11));
      final bite = Path()..addOval(Rect.fromCircle(center: Offset(x + 5, y - 3), radius: 9));
      final crescent = Path.combine(PathOperation.difference, moon, bite);
      canvas.drawPath(crescent, Paint()..color = skin.card);
      canvas.drawPath(crescent, ink);
      return;
    }
    // Across the sky from left at dawn to right at dusk.
    final f = ((t - 5.5) / 14).clamp(0.0, 1.0);
    final x = size.width * (0.1 + 0.8 * f);
    final y = size.height * (0.3 - 0.2 * math.sin(f * math.pi));
    canvas.drawCircle(Offset(x, y), 12, Paint()..color = skin.card);
    canvas.drawCircle(Offset(x, y), 12, ink);
  }

  void _clouds(Canvas canvas, Size size) {
    if (s.weather == SceneWeather.clear) return;
    final fill = Paint()..color = skin.card;
    final ink = Paint()
      ..color = skin.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 3; i++) {
      final span = size.width + 120;
      final x = ((i * 160 + s.seconds * 6) % span) - 60;
      final y = size.height * (0.12 + 0.08 * i);
      final path = Path()
        ..addOval(Rect.fromCircle(center: Offset(x, y), radius: 12))
        ..addOval(Rect.fromCircle(center: Offset(x + 14, y - 6), radius: 14))
        ..addOval(Rect.fromCircle(center: Offset(x + 30, y), radius: 11))
        ..addRect(Rect.fromLTRB(x - 4, y, x + 36, y + 10));
      canvas.drawPath(path, fill);
      canvas.drawPath(path, ink);
    }
  }

  void _precipitation(Canvas canvas, Size size) {
    if (s.weather != SceneWeather.rain && s.weather != SceneWeather.snow) return;
    final rnd = math.Random(3);
    final snow = s.weather == SceneWeather.snow;
    final paint = Paint()
      ..color = snow ? skin.card : skin.ink.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final speed = snow ? 30.0 : 260.0;
    for (var i = 0; i < 50; i++) {
      final x0 = rnd.nextDouble() * size.width;
      final y0 = rnd.nextDouble() * size.height;
      final y = (y0 + s.seconds * speed) % size.height;
      final x = (x0 + (snow ? 12 * math.sin(s.seconds + i) : -s.seconds * 40)) % size.width;
      if (snow) {
        canvas.drawCircle(Offset(x, y), 1.6, paint);
      } else {
        canvas.drawLine(Offset(x, y), Offset(x - 2, y + 9), paint);
      }
    }
  }

  // ---------------------------------------------------------------- side

  void _side(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ground = h * RunScene.groundY;
    final metres = s.km * 1000;
    final runnerX = w * RunScene.runnerX;

    // Far hills, barely moving.
    // Hills a shade off the sky: darker by day, lighter at night, so they
    // never match the ink of the figure.
    final hillColor = _night ? Color.lerp(_skyColor(), skin.card, 0.16)! : Color.lerp(_skyColor(), skin.ink, 0.14)!;
    final hills = Path()..moveTo(0, h);
    final off = metres * _ppm * 0.12;
    for (var x = 0.0; x <= w; x += 6) {
      final wx = x + off;
      final y = ground - 34 - 18 * math.sin(wx / 90) - 9 * math.sin(wx / 37 + 1.3);
      hills.lineTo(x, y);
    }
    hills.lineTo(w, h);
    hills.close();
    canvas.drawPath(hills, Paint()..color = hillColor);

    canvas.save();
    if (s.incline > 0) {
      canvas.translate(runnerX, ground);
      canvas.rotate(-0.13 * s.incline);
      canvas.translate(-runnerX, -ground);
    }

    // Ground and road.
    canvas.drawRect(Rect.fromLTRB(-w, ground, w * 2, h + w), Paint()..color = skin.buttonSoft);
    final road = Rect.fromLTRB(-w, ground, w * 2, ground + 13);
    canvas.drawRect(road, Paint()..color = Color.lerp(skin.background, skin.ink, 0.22)!);
    final dashOff = (metres * _ppm) % 40;
    final dash = Paint()..color = skin.card;
    for (var x = -dashOff - 40; x < w * 2; x += 40) {
      canvas.drawRect(Rect.fromLTWH(x, ground + 5.5, 18, 2.5), dash);
    }

    // Trees and houses along the road, half as fast as the road.
    final midOff = metres * _ppm * 0.5;
    final first = ((midOff - 60) / 90).floor();
    for (var i = first; i * 90 - midOff < w + 60; i++) {
      final x = i * 90 - midOff;
      final kind = (i * 7919) % 5;
      if (kind == 3 || kind == 4) continue;
      final glyph = switch (kind) {
        0 => Glyph.tree,
        1 => Glyph.house,
        _ => Glyph.tree,
      };
      final sz = kind == 1 ? 30.0 : 26.0;
      drawGlyph(canvas, glyph, Rect.fromLTWH(x - sz / 2, ground - sz + 2, sz, sz), skin.ink, skin.accentSoft);
    }

    // Landmarks: far ones sit near the horizon end of the road and come
    // closer slowly, then pass by at road speed.
    for (final lm in s.route.landmarks) {
      final d = lm.km - s.km;
      if (d > 8 || d < -0.12) continue;
      final double x;
      final double scale;
      if (d >= 0) {
        x = runnerX + (w - runnerX - 26) * (1 - math.exp(-d / 1.4));
        scale = 0.42 + 0.58 * math.exp(-d / 1.4);
      } else {
        x = runnerX + d * 1000 * _ppm;
        scale = 1;
      }
      final sz = 44 * scale;
      final reached = d <= 0;
      drawGlyph(canvas, lm.glyph, Rect.fromLTWH(x - sz / 2, ground - sz + 3, sz, sz), skin.ink,
          reached ? skin.accent : skin.accentSoft);
      if (scale > 0.55) {
        _label(canvas, lm.label(s.ja), Offset(x, ground + 16), scale.clamp(0.7, 1.0));
      }
    }

    // Flowers and tufts in front, faster than the road.
    final frontOff = metres * _ppm * 1.6;
    final f0 = ((frontOff - 40) / 70).floor();
    for (var i = f0; i * 70 - frontOff < w + 40; i++) {
      final x = i * 70 - frontOff + (i % 3) * 9;
      final y = ground + 24 + (i % 4) * 7;
      final flower = (i * 31) % 3 == 0;
      if (flower) {
        canvas.drawCircle(Offset(x, y), 3.2, Paint()..color = (i % 2 == 0) ? skin.accent : skin.heading);
        canvas.drawCircle(Offset(x, y), 3.2, Paint()..color = skin.ink..style = PaintingStyle.stroke..strokeWidth = 1);
      } else {
        final p = Paint()
          ..color = skin.ink.withValues(alpha: 0.5)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x, y), Offset(x - 3, y - 6), p);
        canvas.drawLine(Offset(x, y), Offset(x + 3, y - 6), p);
      }
    }
    canvas.restore();
  }

  // --------------------------------------------------------------- water

  /// Open water from the side: a far shore on the horizon, the sea from
  /// there down, buoys drifting past at the swimmer's pace, and the route's
  /// landmarks coming up along the shore.
  void _water(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final surface = h * RunScene.waterY;
    final horizon = surface - 26;
    final metres = s.km * 1000;
    final runnerX = w * RunScene.runnerX;
    final water = RunScene.waterColor(skin);

    // The far shore, drifting slowly.
    final shoreColor = _night ? Color.lerp(_skyColor(), skin.card, 0.16)! : Color.lerp(_skyColor(), skin.ink, 0.14)!;
    final shore = Path()..moveTo(0, horizon + 2);
    final off = metres * _ppm * 0.08;
    for (var x = 0.0; x <= w; x += 6) {
      final wx = x + off;
      shore.lineTo(x, horizon - 10 - 9 * math.sin(wx / 80) - 5 * math.sin(wx / 33 + 1.3));
    }
    shore.lineTo(w, horizon + 2);
    shore.close();
    canvas.drawPath(shore, Paint()..color = shoreColor);
    // Landmarks stand on the far shore and slide by with it.
    for (final lm in s.route.landmarks) {
      final d = lm.km - s.km;
      if (d > 8 || d < -0.12) continue;
      final double x;
      final double scale;
      if (d >= 0) {
        x = runnerX + (w - runnerX - 26) * (1 - math.exp(-d / 1.4));
        scale = 0.42 + 0.58 * math.exp(-d / 1.4);
      } else {
        x = runnerX + d * 1000 * _ppm;
        scale = 1;
      }
      final sz = 34 * scale;
      final reached = d <= 0;
      drawGlyph(canvas, lm.glyph, Rect.fromLTWH(x - sz / 2, horizon - sz + 3, sz, sz), skin.ink,
          reached ? skin.accent : skin.accentSoft);
      if (scale > 0.55) _label(canvas, lm.label(s.ja), Offset(x, horizon + 4), scale.clamp(0.7, 1.0));
    }

    // The sea, deeper toward the bottom.
    final deep = Color.lerp(water, skin.ink, 0.35)!;
    canvas.drawRect(
      Rect.fromLTRB(0, horizon, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, horizon), Offset(0, h), [Color.lerp(water, _skyColor(), 0.35)!, water, deep], [0, 0.25, 1]),
    );
    // Ripples on the surface, sliding past.
    final ripple = Paint()
      ..color = skin.card.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(11);
    for (var i = 0; i < 26; i++) {
      final span = w + 40;
      final speed = 0.4 + rnd.nextDouble() * 0.8;
      final x = ((rnd.nextDouble() * span + span - metres * _ppm * speed) % span) - 20;
      final y = horizon + 6 + rnd.nextDouble() * (h - horizon - 12);
      final len = 6 + 10 * rnd.nextDouble();
      canvas.drawLine(Offset(x, y), Offset(x + len, y), ripple);
    }
    // Buoys along the course, every 50 m.
    final buoyOff = metres * _ppm;
    final first = ((buoyOff - 40) / 200).floor();
    for (var i = first; i * 200 - buoyOff < w + 40; i++) {
      final x = i * 200 - buoyOff;
      final bob = 2 * math.sin(s.seconds * 2 + i);
      final y = surface + bob;
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = i.isEven ? skin.accent : skin.heading);
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = skin.ink..style = PaintingStyle.stroke..strokeWidth = 1);
      canvas.drawLine(Offset(x, y - 5), Offset(x, y - 11), Paint()..color = skin.ink..strokeWidth = 1.2);
    }
  }

  /// Open water from behind: the sea to the horizon with a line of buoys
  /// coming toward the viewer.
  void _aheadWater(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * (RunScene.horizonY - 0.1 * s.incline);
    final cx = w / 2;
    final metres = s.km * 1000;
    final water = RunScene.waterColor(skin);
    final shoreColor = _night ? Color.lerp(_skyColor(), skin.card, 0.16)! : Color.lerp(_skyColor(), skin.ink, 0.14)!;
    final shore = Path()..moveTo(0, horizon + 2);
    for (var x = 0.0; x <= w; x += 6) {
      final wx = x + metres * 0.03;
      shore.lineTo(x, horizon - 8 - 7 * math.sin(wx / 70) - 4 * math.sin(wx / 29 + 2));
    }
    shore.lineTo(w, horizon + 2);
    shore.close();
    canvas.drawPath(shore, Paint()..color = shoreColor);
    final deep = Color.lerp(water, skin.ink, 0.35)!;
    canvas.drawRect(
      Rect.fromLTRB(0, horizon, w, h),
      Paint()..shader = ui.Gradient.linear(Offset(0, horizon), Offset(0, h), [Color.lerp(water, _skyColor(), 0.4)!, water, deep], [0, 0.3, 1]),
    );
    double yAt(double u) => horizon + (h - horizon) * u * u;
    final ripple = Paint()
      ..color = skin.card.withValues(alpha: 0.5)
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(5);
    for (var i = 0; i < 30; i++) {
      final u = ((rnd.nextDouble() + metres / 40) % 1);
      final x = rnd.nextDouble() * w;
      canvas.drawLine(Offset(x, yAt(u)), Offset(x + 4 + 14 * u, yAt(u)), ripple..strokeWidth = 0.6 + 1.4 * u);
    }
    // Buoys every 25 m on both sides, far to near.
    const spacing = 25.0;
    const horizonM = 220.0;
    final firstIndex = (metres / spacing).floor();
    for (var k = 8; k >= 0; k--) {
      final i = firstIndex + k;
      final ahead = i * spacing - metres;
      if (ahead < 0 || ahead > horizonM) continue;
      final u = 1 - ahead / horizonM;
      final scale = 0.15 + 0.85 * u * u;
      for (final side in [-1, 1]) {
        final x = cx + side * (12 + w * 0.3 * u * u);
        final y = yAt(u);
        canvas.drawCircle(Offset(x, y), 5 * scale, Paint()..color = i.isEven ? skin.accent : skin.heading);
        canvas.drawCircle(Offset(x, y), 5 * scale, Paint()..color = skin.ink..style = PaintingStyle.stroke..strokeWidth = 1);
      }
    }
  }

  // --------------------------------------------------------------- ahead

  void _ahead(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * (RunScene.horizonY - 0.1 * s.incline);
    final cx = w / 2;
    final metres = s.km * 1000;

    // Hills on the horizon.
    final hillColor = _night ? Color.lerp(_skyColor(), skin.card, 0.16)! : Color.lerp(_skyColor(), skin.ink, 0.14)!;
    final hills = Path()..moveTo(0, horizon + 2);
    for (var x = 0.0; x <= w; x += 6) {
      final wx = x + metres * 0.05;
      hills.lineTo(x, horizon - 14 - 10 * math.sin(wx / 70) - 6 * math.sin(wx / 29 + 2));
    }
    hills.lineTo(w, horizon + 2);
    hills.close();
    canvas.drawPath(hills, Paint()..color = hillColor);

    // Ground and the road running to the vanishing point.
    canvas.drawRect(Rect.fromLTRB(0, horizon, w, h), Paint()..color = skin.buttonSoft);
    double halfAt(double u) => 7 + (w * 0.42 - 7) * u * u;
    double yAt(double u) => horizon + (h - horizon) * u * u;
    final roadPath = Path()
      ..moveTo(cx - halfAt(1), h)
      ..lineTo(cx - halfAt(0), horizon)
      ..lineTo(cx + halfAt(0), horizon)
      ..lineTo(cx + halfAt(1), h)
      ..close();
    canvas.drawPath(roadPath, Paint()..color = Color.lerp(skin.background, skin.ink, 0.22)!);
    final edge = Paint()
      ..color = skin.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx - halfAt(1), h), Offset(cx - halfAt(0), horizon), edge);
    canvas.drawLine(Offset(cx + halfAt(1), h), Offset(cx + halfAt(0), horizon), edge);

    // Centre dashes coming toward the viewer.
    final phase = (metres / 12) % 1;
    for (var i = 0; i < 9; i++) {
      final u0 = ((i + phase) / 9).clamp(0.0, 1.0);
      final u1 = (u0 + 0.045).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(cx, yAt(u0)),
        Offset(cx, yAt(u1)),
        Paint()
          ..color = skin.card
          ..strokeWidth = 1 + 5 * u0 * u0,
      );
    }

    // Trees and houses at the roadside, every 25 m, drawn far to near.
    const spacing = 25.0;
    const horizonM = 220.0;
    final firstIndex = (metres / spacing).floor();
    for (var k = 8; k >= 0; k--) {
      final i = firstIndex + k;
      final ahead = i * spacing - metres;
      if (ahead < 0 || ahead > horizonM) continue;
      final kind = (i * 7919) % 4;
      if (kind == 3) continue;
      final u = 1 - ahead / horizonM;
      final scale = 0.12 + 0.88 * u * u;
      final side = i.isEven ? -1 : 1;
      final x = cx + side * (halfAt(u) + 18 * scale + 8);
      final sz = (kind == 1 ? 46 : 40) * scale;
      final glyph = kind == 1 ? Glyph.house : Glyph.tree;
      drawGlyph(canvas, glyph, Rect.fromLTWH(x - sz / 2, yAt(u) - sz, sz, sz), skin.ink, skin.accentSoft);
    }

    // The next landmark: a speck by the horizon until it is within 600 m.
    for (final lm in s.route.landmarks) {
      final d = lm.km - s.km;
      if (d < -0.01 || d > 10) continue;
      final near = d <= 0.6;
      final u = near ? 1 - d / 0.6 : 0.0;
      final scale = near ? 0.16 + 0.84 * u * u : 0.16;
      final x = cx + halfAt(u) + 30 * scale + 6;
      final sz = 70 * scale;
      drawGlyph(canvas, lm.glyph, Rect.fromLTWH(x - sz / 2, yAt(u) - sz, sz, sz), skin.ink, skin.accentSoft);
      if (near && scale > 0.4) _label(canvas, lm.label(s.ja), Offset(x, yAt(u) + 4), scale.clamp(0.7, 1.0));
      break;
    }
  }

  void _label(Canvas canvas, String text, Offset at, double scale) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: s.labelStyle.copyWith(fontSize: (s.labelStyle.fontSize ?? 11) * scale)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(_ScenePainter old) => true;
}

/// The water in front of the swimmer: painted over the figure from the
/// surface down, so what is under the surface shows through the water, with
/// the surface itself drawn as a wavy line and a little foam around the
/// swimmer.
class WaterOverlay extends CustomPainter {
  WaterOverlay({required this.skin, required this.seconds, required this.km, required this.swimmerX});

  final Skin skin;
  final double seconds;
  final double km;

  /// Where the swimmer is, as a fraction of the width.
  final double swimmerX;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final surface = h * RunScene.waterY;
    final water = RunScene.waterColor(skin);
    final metres = km * 1000;
    final top = Path()..moveTo(-10, surface);
    for (var x = -10.0; x <= w + 10; x += 4) {
      top.lineTo(x, surface + 2.2 * math.sin((x - metres * 4) / 14 + seconds * 2) + 1.2 * math.sin(x / 5.5 - seconds * 3));
    }
    top.lineTo(w + 10, h + 10);
    top.lineTo(-10, h + 10);
    top.close();
    canvas.drawPath(top, Paint()..color = water.withValues(alpha: 0.42));
    canvas.drawPath(
      top,
      Paint()
        ..color = skin.card.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // Foam where the arms and feet break the surface.
    final foam = Paint()
      ..color = skin.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final cx = w * swimmerX;
    final rnd = math.Random(3);
    for (var i = 0; i < 9; i++) {
      final phase = (seconds * (0.8 + 0.5 * rnd.nextDouble()) + rnd.nextDouble()) % 1;
      final x = cx - 40 + 100 * rnd.nextDouble() + 8 * phase;
      final y = surface - 3 - 9 * math.sin(phase * math.pi);
      final r = 2 + 3 * math.sin(phase * math.pi);
      canvas.drawArc(Rect.fromCircle(center: Offset(x, y), radius: r), math.pi, math.pi, false, foam);
    }
  }

  @override
  bool shouldRepaint(WaterOverlay old) => true;
}
