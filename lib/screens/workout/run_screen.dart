import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../data/exercise_moves.dart';
import '../../models/enums.dart';
import '../../models/run_play.dart';
import '../../services/run_location.dart';
import '../../state/app_state.dart';
import '../../state/body_state.dart';
import '../../state/workout_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_figure.dart';
import '../../widgets/run_glyphs.dart';
import '../../widgets/sticker.dart';
import '../../widgets/window_card.dart';

/// Something to look at while on the treadmill or the road: a companion who
/// runs at your pace, a road that gets longer every session, a wheel that
/// decides the next minute, and three small goals per outing. Distance comes
/// from the speed you set to match the machine, or from the phone's location
/// outdoors.
class RunScreen extends StatefulWidget {
  const RunScreen({super.key, this.kind = CardioType.running});
  final CardioType kind;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with TickerProviderStateMixin {
  static const _kinds = [CardioType.running, CardioType.walking, CardioType.cycling];
  static const _calls = RouletteCall.values;

  late CardioType _kind = _kinds.contains(widget.kind) ? widget.kind : CardioType.running;
  late final Ticker _ticker = createTicker(_tick);
  Duration _lastTick = Duration.zero;

  bool _running = false;
  bool _gps = false;
  double _speed = 6;
  double _gpsSpeed = 0;
  StreamSubscription<GeoFix>? _gpsSub;
  GeoFix? _lastFix;
  bool _gpsHasFix = false;

  double _elapsedS = 0;
  double _distanceKm = 0;
  double _kcal = 0;
  double _phase = 0;
  double _maxSpeed = 0;
  double _fastKm = 0;

  double _lapM = 400;
  int _laps = 0;
  double _nextLapKm = 0.4;
  int _nextKmMark = 1;

  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..addListener(() => setState(() {}))
    ..addStatusListener(_spinDone);
  double _angleFrom = 0;
  double _angleTo = 0;
  RouletteCall? _call;
  double _callLeft = 0;
  int _callsDone = 0;

  late List<Quest> _quests = Quest.draw(_kind, seed: DateTime.now().millisecondsSinceEpoch);
  double _nonstopKm = 0;
  double _stoppedS = 0;
  double _steadyS = 0;
  double _steadyRef = 0;
  int _landmarksNow = 0;
  int _stampsNow = 0;

  RunProgress? _progress;
  double _journeyAppliedKm = 0;
  bool _routeDoneSaid = false;

  String? _bubble;
  Timer? _bubbleTimer;
  late final AnimationController _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  final _rnd = math.Random();

  double get _angle => _angleFrom + (_angleTo - _angleFrom) * Curves.easeOutCubic.transform(_spin.value);
  double get _currentSpeed => _gps ? _gpsSpeed : _speed;
  double get _maxSlider => _kind == CardioType.cycling ? 40 : 16;

  @override
  void initState() {
    super.initState();
    _ticker.start();
    RunProgress.load().then((p) {
      if (mounted) setState(() => _progress = p);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _spin.dispose();
    _hop.dispose();
    _bubbleTimer?.cancel();
    _gpsSub?.cancel();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_running || dt <= 0 || dt > 1) return;
    final speed = _currentSpeed;
    final l = context.read<AppState>().l;
    final weight = context.read<BodyState>().latestWeight ?? 60;

    _elapsedS += dt;
    if (!_gps) _distanceKm += speed * dt / 3600;
    _kcal += estimateKcal(_kind, speed, dt / 3600, weight).toDouble();
    _phase += dt * _cyclesPerSecond(speed);
    if (speed > _maxSpeed) _maxSpeed = speed;
    if (speed >= Quest.fastTarget(_kind)) _fastKm += speed * dt / 3600;

    if (_call != null) {
      _callLeft -= dt;
      if (_callLeft <= 0) {
        _call = null;
        _callsDone++;
      }
    }

    while (_distanceKm >= _nextLapKm) {
      _laps++;
      _nextLapKm += _lapM / 1000;
      if (!_spin.isAnimating) _spinWheel();
    }
    if (_distanceKm >= _nextKmMark) {
      _say(l.kmMark(_nextKmMark));
      _hop.forward(from: 0);
      _nextKmMark++;
    }

    final progress = _progress;
    if (progress != null) {
      final delta = _distanceKm - _journeyAppliedKm;
      if (delta > 0) {
        _journeyAppliedKm = _distanceKm;
        final passed = progress.advance(delta);
        for (final lm in passed) {
          _landmarksNow++;
          _award(1);
          _say(l.landmarkReached(lm.label(l.isJa)));
          _hop.forward(from: 0);
        }
        if (progress.routeKm >= progress.route.lengthKm && !_routeDoneSaid) {
          _routeDoneSaid = true;
          progress.finishedRoutes++;
          _award(3);
          _say(l.routeDone);
        }
        if (passed.isNotEmpty) progress.save();
      }
    }

    if (speed > 0.3) {
      _stoppedS = 0;
      _nonstopKm += speed * dt / 3600;
    } else {
      _stoppedS += dt;
      if (_stoppedS > 3) _nonstopKm = 0;
    }
    if ((speed - _steadyRef).abs() <= 0.5 && speed > 0.3) {
      _steadyS += dt;
    } else {
      _steadyRef = speed;
      _steadyS = 0;
    }
    for (final q in _quests) {
      if (q.done) continue;
      q.progress = switch (q.kind) {
        QuestKind.nonstop1k => _nonstopKm,
        QuestKind.steady2m => _steadyS,
        QuestKind.laps3 => _laps.toDouble(),
        QuestKind.calls3 => _callsDone.toDouble(),
        QuestKind.landmark => _landmarksNow.toDouble(),
        QuestKind.minutes10 => _elapsedS,
        QuestKind.km2 => _distanceKm,
        QuestKind.fast => _fastKm,
      };
      if (q.progress >= q.target) {
        q.done = true;
        _award(1);
        _say(l.isJa ? cheersJa[_rnd.nextInt(cheersJa.length)] : cheersEn[_rnd.nextInt(cheersEn.length)]);
      }
    }
    setState(() {});
  }

  double _cyclesPerSecond(double speed) {
    if (speed <= 0.3) return 0.12;
    return switch (_kind) {
      CardioType.cycling => 0.5 + speed * 0.06,
      _ => 0.35 + speed * 0.1,
    };
  }

  void _award(int n) {
    _stampsNow += n;
    _progress?.stamps += n;
  }

  void _say(String text) {
    _bubble = text;
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  void _spinWheel() {
    _angleFrom = _angle;
    _angleTo = _angleFrom + 2 * math.pi * (3 + _rnd.nextDouble() * 2);
    _spin.forward(from: 0);
  }

  void _spinDone(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    final step = 2 * math.pi / _calls.length;
    final i = (((-_angleTo) % (2 * math.pi)) / step).floor() % _calls.length;
    setState(() {
      _call = _calls[i];
      _callLeft = _calls[i].seconds.toDouble();
    });
  }

  void _toggleRun() {
    setState(() => _running = !_running);
    if (!_running) _progress?.save();
  }

  void _setGps(bool on) {
    setState(() {
      _gps = on;
      _gpsHasFix = false;
      _lastFix = null;
      _gpsSpeed = 0;
    });
    _gpsSub?.cancel();
    _gpsSub = null;
    if (!on) return;
    _gpsSub = RunLocation.watch().listen((fix) {
      if (fix.accuracyM > 40) return;
      final last = _lastFix;
      _lastFix = fix;
      _gpsHasFix = true;
      if (last == null) return;
      final dt = fix.at.difference(last.at).inMilliseconds / 1000;
      if (dt <= 0) return;
      final d = RunLocation.distanceKm(last, fix);
      final kmh = d / dt * 3600;
      if (kmh > 60) return;
      final measured = fix.speedMs != null && !fix.speedMs!.isNaN ? fix.speedMs! * 3.6 : kmh;
      _gpsSpeed = _gpsSpeed * 0.5 + measured * 0.5;
      if (_running) _distanceKm += d;
      if (mounted) setState(() {});
    }, onError: (_) {});
  }

  Future<void> _finish() async {
    final l = context.read<AppState>().l;
    final w = context.read<WorkoutState>();
    setState(() => _running = false);
    await _progress?.save();
    final id = await w.startSession();
    final minutes = _elapsedS / 60;
    await w.addCardio(
      id,
      _kind,
      double.parse(minutes.toStringAsFixed(1)),
      distanceKm: _distanceKm >= 0.05 ? double.parse(_distanceKm.toStringAsFixed(2)) : null,
      kcal: _kcal.round() > 0 ? _kcal.round() : null,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text([l.runSaved, if (_stampsNow > 0) l.newStamps(_stampsNow)].join(' · ')),
    ));
    Navigator.of(context).pop();
  }

  String _pace(double speed) {
    if (speed <= 0.3) return '--';
    final secPerKm = 3600 / speed;
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).round();
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  String _clock(double seconds) {
    final t = seconds.floor();
    final h = t ~/ 3600;
    final m = (t % 3600) ~/ 60;
    final s = t % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final speed = _currentSpeed;
    final move = cardioMoves[_kind] ?? cardioMoves[CardioType.running]!;

    return Scaffold(
      appBar: AppBar(title: Text(l.runTool)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          Wrap(
            spacing: 6,
            children: [
              for (final k in _kinds)
                ChoiceChip(
                  label: Text(k.label(l)),
                  selected: _kind == k,
                  onSelected: _elapsedS > 0
                      ? null
                      : (_) => setState(() {
                            _kind = k;
                            _quests = Quest.draw(k, seed: DateTime.now().millisecondsSinceEpoch);
                            if (_speed > _maxSlider) _speed = _maxSlider;
                          }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StickerBox(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  SizedBox(
                    height: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _hop,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, -22 * math.sin(math.pi * _hop.value)),
                            child: child,
                          ),
                          child: ExerciseFigure(move: move, size: 170, t: _phase, gearColor: skin.button),
                        ),
                        if (_bubble != null)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: StickerBox(
                              color: skin.accentSoft,
                              radius: 14,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(_bubble!,
                                    style: t.labelLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                        if (speed <= 0.3 && _bubble == null)
                          Positioned(
                            top: 4,
                            right: 0,
                            child: Text(l.resting, style: t.labelMedium?.copyWith(color: skin.subText)),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: _Stat(label: l.duration, value: _clock(_elapsedS))),
                      Expanded(child: _Stat(label: l.distance, value: '${_distanceKm.toStringAsFixed(2)} km')),
                      Expanded(child: _Stat(label: l.pace, value: _pace(speed))),
                      Expanded(child: _Stat(label: 'kcal', value: '${_kcal.round()}')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_gps)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        _gpsHasFix ? '${speed.toStringAsFixed(1)} km/h' : l.gpsWaiting,
                        style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w800),
                      ),
                    )
                  else
                    Row(
                      children: [
                        SizedBox(
                          width: 84,
                          child: Text('${_speed.toStringAsFixed(1)} km/h',
                              style: t.titleSmall?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
                        ),
                        Expanded(
                          child: Slider(
                            value: _speed,
                            min: 0,
                            max: _maxSlider,
                            divisions: (_maxSlider * 2).round(),
                            onChanged: (v) => setState(() => _speed = v),
                          ),
                        ),
                      ],
                    ),
                  if (RunLocation.available)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('GPS', style: t.labelLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w800)),
                        Switch(value: _gps, onChanged: _setGps),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_progress case final p?) _JourneyCard(progress: p, onRoute: (id) => setState(() {
                p.routeId = id;
                _routeDoneSaid = p.routeKm >= p.route.lengthKm;
                p.save();
              })),
          const SizedBox(height: 14),
          WindowCard(
            title: l.roulette,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    RouletteWheel(
                      angle: _angle,
                      calls: _calls,
                      colors: [skin.accentSoft, skin.buttonSoft, skin.card],
                      ink: skin.ink,
                      size: 186,
                      labelStyle: TextStyle(color: skin.text, fontSize: 10, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.lapLength, style: t.labelMedium?.copyWith(color: skin.subText)),
                          Wrap(
                            spacing: 4,
                            children: [
                              for (final m in [200.0, 400.0, 1000.0])
                                ChoiceChip(
                                  label: Text(m >= 1000 ? '1 km' : '${m.toInt()} m'),
                                  selected: _lapM == m,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) => setState(() {
                                    _lapM = m;
                                    _nextLapKm = _distanceKm + m / 1000;
                                  }),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(l.laps(_laps),
                              style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          OutlinedButton(
                            onPressed: _spin.isAnimating ? null : _spinWheel,
                            child: Text(l.spin),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_call case final call?) ...[
                  const SizedBox(height: 12),
                  StickerBox(
                    color: skin.accentSoft,
                    radius: 14,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(call.label(l.isJa),
                                style: t.titleMedium?.copyWith(color: skin.text, fontWeight: FontWeight.w800)),
                          ),
                          Text(l.callLeft(_callLeft.ceil()),
                              style: t.labelLarge?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          WindowCard(
            title: l.quests,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final q in _quests) _QuestRow(quest: q, kind: _kind),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(l.stamps(_progress?.stamps ?? 0),
                        style: t.labelLarge?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: _toggleRun,
                  icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(_running ? l.pause : (_elapsedS > 0 ? l.resume : l.start)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _elapsedS >= 30 ? _finish : null,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l.finishRun),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: t.titleMedium?.copyWith(color: skin.text, fontWeight: FontWeight.w800)),
        Text(label, style: t.labelSmall?.copyWith(color: skin.subText)),
      ],
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.progress, required this.onRoute});
  final RunProgress progress;
  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final route = progress.route;
    final km = progress.routeKm;
    Landmark? next;
    for (final lm in route.landmarks) {
      if (lm.km > km) {
        next = lm;
        break;
      }
    }
    return WindowCard(
      title: l.journey,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            children: [
              for (final r in runRoutes)
                ChoiceChip(
                  label: Text('${r.label(l.isJa)} ${r.lengthKm.toStringAsFixed(r.lengthKm % 1 == 0 ? 0 : 1)} km'),
                  selected: progress.routeId == r.id,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => onRoute(r.id),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: LayoutBuilder(
              builder: (_, c) => Stack(
                children: [
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 52,
                    child: Container(height: 3, color: skin.ink.withValues(alpha: 0.25)),
                  ),
                  Positioned(
                    left: 14,
                    top: 52,
                    child: Container(
                      height: 3,
                      width: (c.maxWidth - 28) * (km / route.lengthKm).clamp(0.0, 1.0),
                      color: skin.heading,
                    ),
                  ),
                  for (final lm in route.landmarks)
                    Positioned(
                      left: (c.maxWidth - 28) * (lm.km / route.lengthKm) + 14 - 14,
                      top: 14,
                      child: GlyphIcon(
                        lm.glyph,
                        size: 28,
                        ink: skin.ink,
                        tint: skin.accentSoft,
                        dim: lm.km > km && lm.km > 0,
                      ),
                    ),
                  Positioned(
                    left: (c.maxWidth - 28) * (km / route.lengthKm).clamp(0.0, 1.0) + 14 - 7,
                    top: 46,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: skin.heading,
                        shape: BoxShape.circle,
                        border: Border.all(color: skin.ink, width: kThinBorder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next == null
                ? l.routeDone
                : l.nextLandmark(next.label(l.isJa), (next.km - km).toStringAsFixed(1)),
            style: t.bodyMedium?.copyWith(color: skin.text, fontWeight: FontWeight.w800),
          ),
          Text(l.routeTotal(km.toStringAsFixed(1)), style: t.bodySmall?.copyWith(color: skin.subText)),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest, required this.kind});
  final Quest quest;
  final CardioType kind;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.label(l.isJa, kind),
                    style: t.bodyMedium?.copyWith(color: skin.text, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 8,
                    color: skin.ink.withValues(alpha: 0.12),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: quest.ratio,
                      child: Container(color: quest.done ? skin.accent : skin.heading),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: quest.done
                ? Icon(Icons.check_circle_rounded, color: skin.accent, size: 26)
                : Text('${(quest.ratio * 100).round()}%',
                    textAlign: TextAlign.end, style: t.labelSmall?.copyWith(color: skin.subText)),
          ),
        ],
      ),
    );
  }
}
