import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../data/exercise_moves.dart';
import '../../models/enums.dart';
import '../../models/run_play.dart';
import '../../services/run_location.dart';
import '../../services/run_sound.dart';
import '../../services/weather.dart';
import '../../state/app_state.dart';
import '../../state/body_state.dart';
import '../../state/workout_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/skin.dart';
import '../../widgets/companion_rig.dart';
import '../../widgets/companion_sprite.dart';
import '../../widgets/exercise_figure.dart';
import '../../widgets/run_glyphs.dart';
import '../../widgets/run_scene.dart';
import '../../widgets/sticker.dart';
import '../../widgets/window_card.dart';

/// Something to look at while on the treadmill or the road: a companion who
/// runs at your pace through a world that slides past, a road that gets
/// longer every session, a wheel that decides the next minute, and three
/// small goals per outing. Distance comes from the speed you set to match the
/// machine, or from the phone's location outdoors; activities without a
/// distance run on the clock.
class RunScreen extends StatefulWidget {
  const RunScreen({super.key, this.kind = CardioType.running});
  final CardioType kind;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with TickerProviderStateMixin {
  static const _calls = RouletteCall.values;

  late CardioType _kind = widget.kind;
  late final Ticker _ticker = createTicker(_tick);
  Duration _lastTick = Duration.zero;

  bool _running = false;
  bool _gps = false;
  late double _speed = startSpeed(_kind);
  double _gpsSpeed = 0;
  StreamSubscription<GeoFix>? _gpsSub;
  GeoFix? _lastFix;
  bool _gpsHasFix = false;
  bool _weatherAsked = false;
  SceneWeather _weather = SceneWeather.clear;

  double _elapsedS = 0;
  double _distanceKm = 0;

  /// What the road and the laps run on: the distance for activities that have
  /// one, otherwise the clock at ten minutes to the kilometre.
  double _journeyKm = 0;
  double _kcal = 0;
  double _phase = 0;
  double _sceneT = 0;
  double _beat = 0;
  double _incline = 0;
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
  CompanionRig? _rig;
  double _journeyAppliedKm = 0;
  bool _routeDoneSaid = false;

  String? _bubble;
  String _bubbleFace = 'smile';
  Timer? _bubbleTimer;
  late final AnimationController _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  final _rnd = math.Random();

  double get _angle => _angleFrom + (_angleTo - _angleFrom) * Curves.easeOutCubic.transform(_spin.value);
  double get _currentSpeed => _gps ? _gpsSpeed : _speed;
  double get _maxSlider => topSpeed(_kind);
  bool get _distanceKind => hasDistance(_kind);
  bool get _outdoorKind =>
      _kind == CardioType.running || _kind == CardioType.walking || _kind == CardioType.cycling;
  bool get _resting => _distanceKind && _currentSpeed <= 0.3;
  SceneView get _view => _progress?.view == 'ahead' ? SceneView.ahead : SceneView.side;
  bool get _sound => (_progress?.sound ?? false) && RunSound.available;
  bool get _girl => (_progress?.look ?? 'girl') == 'girl';

  /// The stored hat, if it is one the illustration has.
  String get _girlHat {
    final id = _progress?.hat ?? 'none';
    return girlHatUnlocks.any((h) => h.$1 == id) ? id : 'none';
  }

  @override
  void initState() {
    super.initState();
    _ticker.start();
    RunProgress.loadShared().then((p) {
      if (mounted) setState(() => _progress = p);
    });
    CompanionRig.side().then((r) {
      if (mounted) setState(() => _rig = r);
    }).catchError((Object _) {});
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
    if (dt <= 0 || dt > 1) return;
    _sceneT += dt;
    final wantIncline = _call == RouletteCall.incline ? 1.0 : 0.0;
    _incline += (wantIncline - _incline) * math.min(1, dt * 2);
    if (!_running) {
      // Rain, stars and clouds keep moving while paused.
      if (_weather != SceneWeather.clear || _hour < 5.5 || _hour >= 19.5) setState(() {});
      return;
    }
    final speed = _currentSpeed;
    final l = context.read<AppState>().l;
    final weight = context.read<BodyState>().latestWeight ?? 60;

    _elapsedS += dt;
    if (_distanceKind) {
      if (!_gps) _distanceKm += speed * dt / 3600;
      _journeyKm = _distanceKm;
    } else {
      _journeyKm += dt / 600;
    }
    _kcal += estimateKcal(_kind, speed, dt / 3600, weight).toDouble();
    final cycles = _cyclesPerSecond(speed);
    _phase += dt * cycles;
    if (speed > _maxSpeed) _maxSpeed = speed;
    if (speed >= Quest.fastTarget(_kind)) _fastKm += speed * dt / 3600;

    // A click on every footfall, two to a stride.
    if (_sound && !_resting) {
      final before = _beat.floor();
      _beat += dt * cycles * 2;
      if (_beat.floor() != before) RunSound.tick();
    }

    if (_call != null) {
      _callLeft -= dt;
      if (_callLeft <= 0) {
        _call = null;
        _callsDone++;
      }
    }

    while (_journeyKm >= _nextLapKm) {
      _laps++;
      _nextLapKm += _lapM / 1000;
      if (!_spin.isAnimating) _spinWheel();
    }
    if (_distanceKind && _distanceKm >= _nextKmMark) {
      _say(l.kmMark(_nextKmMark));
      _hop.forward(from: 0);
      if (_sound) RunSound.cheer();
      _nextKmMark++;
    }

    final progress = _progress;
    if (progress != null) {
      final delta = _journeyKm - _journeyAppliedKm;
      if (delta > 0) {
        _journeyAppliedKm = _journeyKm;
        final passed = progress.advance(delta);
        for (final lm in passed) {
          _landmarksNow++;
          _award(1);
          _say(l.landmarkReached(lm.label(l.isJa)), face: 'surprised');
          _hop.forward(from: 0);
          if (_sound) RunSound.chime();
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
        _say(l.isJa ? cheersJa[_rnd.nextInt(cheersJa.length)] : cheersEn[_rnd.nextInt(cheersEn.length)], face: 'wink');
        if (_sound) RunSound.cheer();
      }
    }
    setState(() {});
  }

  double get _hour {
    final now = DateTime.now();
    return now.hour + now.minute / 60;
  }

  double _cyclesPerSecond(double speed) {
    if (!_distanceKind) {
      return switch (_kind) {
        CardioType.hiit => 0.7,
        CardioType.yoga => 0.12,
        _ => 0.8,
      };
    }
    if (speed <= 0.3) return 0.12;
    return switch (_kind) {
      CardioType.cycling => 0.5 + speed * 0.06,
      CardioType.elliptical => 0.4 + speed * 0.08,
      CardioType.stairs => 0.5 + speed * 0.1,
      CardioType.rowing => 0.3 + speed * 0.03,
      CardioType.swimming => 0.3 + speed * 0.2,
      // About 110 steps a minute at 5 km/h.
      CardioType.walking => 0.45 + speed * 0.1,
      _ => 0.35 + speed * 0.1,
    };
  }

  void _award(int n) {
    _stampsNow += n;
    _progress?.stamps += n;
  }

  void _say(String text, {String face = 'smile'}) {
    _bubble = text;
    _bubbleFace = face;
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  void _spinWheel() {
    _angleFrom = _angle;
    _angleTo = _angleFrom + 2 * math.pi * (3 + _rnd.nextDouble() * 2);
    _spin.forward(from: 0);
    if (_sound) RunSound.spin();
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
    if (!_running && _sound) RunSound.unlock();
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
      if (!_weatherAsked) {
        _weatherAsked = true;
        Weather.at(fix.lat, fix.lon).then((w) {
          if (w != null && mounted) setState(() => _weather = w);
        });
      }
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

  /// Stops the clock and asks; on yes the outing is saved and the screen is
  /// ready for the next one, on no the clock carries on where it was.
  Future<void> _finish() async {
    final l = context.read<AppState>().l;
    final wasRunning = _running;
    if (wasRunning) setState(() => _running = false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.finishRun),
        content: Text(l.finishRunAsk),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) {
      if (wasRunning) setState(() => _running = true);
      return;
    }
    await _save();
    if (mounted) _reset();
  }

  /// Writes the outing into today's session, unless it was too short to be
  /// worth a line.
  Future<void> _save() async {
    final l = context.read<AppState>().l;
    final w = context.read<WorkoutState>();
    await _progress?.save();
    if (_elapsedS < 30) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.runTooShort)));
      return;
    }
    final id = await w.startSession();
    final minutes = _elapsedS / 60;
    await w.addCardio(
      id,
      _kind,
      double.parse(minutes.toStringAsFixed(1)),
      distanceKm: _distanceKind && _distanceKm >= 0.05 ? double.parse(_distanceKm.toStringAsFixed(2)) : null,
      kcal: _kcal.round() > 0 ? _kcal.round() : null,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text([l.runSaved, if (_stampsNow > 0) l.newStamps(_stampsNow)].join(' · ')),
    ));
  }

  /// Back to the start line: the clock, the distance and the outing's quests
  /// and laps are cleared, the road and the stamps stay.
  void _reset() {
    setState(() {
      _running = false;
      _elapsedS = 0;
      _distanceKm = 0;
      _journeyKm = 0;
      _journeyAppliedKm = 0;
      _kcal = 0;
      _beat = 0;
      _maxSpeed = 0;
      _fastKm = 0;
      _laps = 0;
      _nextLapKm = _lapM / 1000;
      _nextKmMark = 1;
      _call = null;
      _callLeft = 0;
      _callsDone = 0;
      _nonstopKm = 0;
      _stoppedS = 0;
      _steadyS = 0;
      _steadyRef = 0;
      _landmarksNow = 0;
      _stampsNow = 0;
      _routeDoneSaid = false;
      _quests = Quest.draw(_kind, seed: DateTime.now().millisecondsSinceEpoch);
    });
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

  FigureFace get _face {
    if (_resting) return FigureFace.rest;
    if (_call == RouletteCall.sprint || (_distanceKind && _currentSpeed >= Quest.fastTarget(_kind))) {
      return FigureFace.push;
    }
    if (_steadyS > 20 || !_distanceKind) return FigureFace.smile;
    return FigureFace.focus;
  }

  FigureHat get _hat => FigureHat.values.firstWhere((h) => h.name == _progress?.hat, orElse: () => FigureHat.none);

  Color? _shirtColor(Skin skin) => switch (_progress?.shirt ?? 0) {
        1 => skin.button,
        2 => skin.accent,
        3 => skin.heading,
        _ => null,
      };

  /// The move for the scene: the activity's cycle, or sitting down when the
  /// speed is zero; from behind in the ahead view; no floor of its own.
  Move _sceneMove() {
    final base = cardioMoves[_kind] ?? cardioMoves[CardioType.running]!;
    final ahead = _view == SceneView.ahead && hasAheadView(_kind);
    if (_resting) return ahead ? standBackMove : sitMove;
    final gear = [for (final g in base.gear) if (g != Gear.floor) g];
    if (ahead) return backMoveFor(_kind);
    if (base.loops) return Move.cycle(base.cycle!, gear: gear);
    if (base.frames.isNotEmpty) return Move.frames(base.frames, gear: gear);
    return Move(start: base.start!, end: base.end!, gear: gear);
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final speed = _currentSpeed;
    final move = _sceneMove();
    // A lift-style move (start and end pose) is played back and forth; the
    // sitting figure breathes slowly.
    final figureT = move.loops
        ? _phase
        : Curves.easeInOut.transform(1 - (2 * ((_resting ? _sceneT * 0.25 : _phase) % 1) - 1).abs());
    final progress = _progress;

    return Scaffold(
      appBar: AppBar(title: Text(l.runTool)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          Wrap(
            spacing: 6,
            children: [
              for (final k in CardioType.values)
                ChoiceChip(
                  label: Text(k.label(l)),
                  selected: _kind == k,
                  visualDensity: VisualDensity.compact,
                  // Another activity while paused saves the one so far and
                  // starts afresh.
                  onSelected: _running || k == _kind
                      ? null
                      : (_) async {
                          if (_elapsedS > 0) {
                            await _save();
                            if (!mounted) return;
                            _reset();
                          }
                          setState(() {
                            _kind = k;
                            _speed = startSpeed(k);
                            _quests = Quest.draw(k, seed: DateTime.now().millisecondsSinceEpoch);
                            if (!hasDistance(k)) _lapM = 300;
                            _nextLapKm = _journeyKm + _lapM / 1000;
                            if (_gps && !_outdoorKind) _setGps(false);
                          });
                        },
                ),
            ],
          ),
          const SizedBox(height: 12),
          StickerBox(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(kCardRadius - 2)),
                  child: SizedBox(
                    // Most of the width, so the figure and the controls on
                    // it are big enough for a thumb.
                    height: (MediaQuery.sizeOf(context).width * 0.8).clamp(240.0, 340.0),
                    child: LayoutBuilder(
                      builder: (_, c) {
                        final size = c.maxHeight * 0.625;
                        // Water, stairs, machines and the room are only
                        // drawn from the side.
                        final mode = sceneModeFor(_kind);
                        final swim = mode == SceneMode.water;
                        final studio = mode == SceneMode.studio;
                        final ahead = _view == SceneView.ahead && hasAheadView(_kind);
                        final view = ahead ? SceneView.ahead : SceneView.side;
                        final left = ahead ? (c.maxWidth - size) / 2 : c.maxWidth * RunScene.runnerX - size / 2;
                        final top = ahead ? c.maxHeight - size * 0.94 - 6 : c.maxHeight * RunScene.groundY - size * 0.94;
                        // The drawings keep their feet 3% above the canvas bottom.
                        final spriteH = c.maxHeight * (ahead ? 0.625 : 0.733);
                        final spriteW = spriteH * (ahead ? 218 / 477 : 440 / 492);
                        final girlLeft = ahead ? (c.maxWidth - spriteW) / 2 : c.maxWidth * RunScene.runnerX - spriteW / 2;
                        final girlTop = ahead
                            ? c.maxHeight - spriteH * 0.97 - 4
                            : c.maxHeight * RunScene.groundY - spriteH * 0.97;
                        // The rigged drawing: the side view while moving.
                        final rig = _rig;
                        final rigged = _girl && !ahead && !_resting && rig != null;
                        final rigH = spriteH * 1.02;
                        final rigW = rig == null ? 0.0 : rigH * rig.width / rig.height;
                        final rigLeft = (studio ? c.maxWidth / 2 : c.maxWidth * RunScene.runnerX) - rigW / 2;
                        // Swimming, the figure lies along the water line with
                        // her back (the hips are 43% down the canvas) just
                        // above it.
                        // On the stairs her hips are held high above the
                        // treads, so the drawing sits lower on the card.
                        final rigTop = swim
                            ? c.maxHeight * RunScene.waterY - rigH * 0.415
                            : c.maxHeight * RunScene.groundY - rigH * (mode == SceneMode.stairs ? 0.86 : 0.99);
                        // The ground scrolls by the stride, so the feet do
                        // not slide on it.
                        final scroll = _phase * strideUnits(_kind) * CompanionRig.unit * rigH / (rig?.height ?? 1460);
                        final breath = swim ? swimBreathAmount(_phase) : 0.0;
                        return Stack(
                          children: [
                            if (progress != null)
                              Positioned.fill(
                                child: RunScene(
                                  route: progress.route,
                                  km: progress.routeKm,
                                  seconds: _sceneT,
                                  view: view,
                                  weather: _weather,
                                  incline: _incline,
                                  now: DateTime.now(),
                                  skin: skin,
                                  ja: l.isJa,
                                  labelStyle: (t.labelSmall ?? const TextStyle(fontSize: 11))
                                      .copyWith(color: skin.text, fontWeight: FontWeight.w800),
                                  mode: mode,
                                  scroll: scroll,
                                ),
                              ),
                            // In the room, the mirror on the back wall shows
                            // her again the same way round, further off and
                            // so smaller and higher, paler, and only within
                            // the glass; a little to one side, as if seen
                            // from an angle, so she does not hide it.
                            if (rigged && studio)
                              Positioned.fill(
                                child: ClipRect(
                                  clipper: _RectClipper(RunScene.mirrorRect(Size(c.maxWidth, c.maxHeight))),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: c.maxWidth * 0.68 - rigW * 0.45 / 2,
                                        top: c.maxHeight * 0.43 - rigH * 0.45 * 0.99,
                                        child: Opacity(
                                          opacity: 0.4,
                                          child: CompanionRigView(
                                            rig: rig,
                                            pose: move.at(figureT),
                                            height: rigH * 0.45,
                                            hat: _girlHat,
                                            gearColor: skin.button,
                                            ink: skin.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Positioned(
                              left: rigged ? rigLeft : _girl ? girlLeft : left,
                              top: rigged ? rigTop : _girl ? girlTop : top,
                              child: AnimatedBuilder(
                                animation: _hop,
                                builder: (_, child) => Transform.translate(
                                  offset: Offset(0, -22 * math.sin(math.pi * _hop.value)),
                                  child: child,
                                ),
                                child: rigged
                                    ? CompanionRigView(
                                        rig: rig,
                                        pose: move.at(figureT),
                                        height: rigH,
                                        farTint: skin.ink.withValues(alpha: 0.08),
                                        // Trails the bob of the stride by a quarter turn.
                                        hairSway: (_kind == CardioType.running ? 0.09 : 0.05) * math.sin(4 * math.pi * _phase - 1.4),
                                        hat: _girlHat,
                                        ground: !swim && rigPropFor(_kind) == RigProp.none,
                                        // A run leaves the ground a little at each stride.
                                        flight: _kind == CardioType.running ? 140 : 40,
                                        prop: rigPropFor(_kind),
                                        phase: _phase,
                                        flow: swim,
                                        // A breath: the face turns to the viewer and lifts a little.
                                        headTurn: -0.45 * breath,
                                        faceFront: breath,
                                        footFollow: swim ? 1 : 0.35,
                                        gearColor: mode == SceneMode.stairs ? Color.lerp(skin.buttonSoft, skin.ink, 0.22)! : skin.button,
                                        ink: skin.ink,
                                      )
                                    : _girl
                                    ? CompanionSprite(
                                        view: view,
                                        resting: _resting,
                                        face: _face,
                                        phase: _phase,
                                        speed: speed,
                                        height: spriteH,
                                        hat: _girlHat,
                                        hopping: _hop.isAnimating,
                                      )
                                    : ExerciseFigure(
                                        move: move,
                                        size: size,
                                        t: figureT,
                                        gearColor: skin.button,
                                        face: _face,
                                        hat: _hat,
                                        shirt: _shirtColor(skin),
                                        outline: skin.card,
                                      ),
                              ),
                            ),
                            if (swim)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: WaterOverlay(skin: skin, seconds: _sceneT, km: progress?.routeKm ?? 0, swimmerX: RunScene.runnerX),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 12,
                              bottom: 8,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _SceneButton(
                                    icon: Icons.stop_rounded,
                                    label: l.finishRun,
                                    size: 50,
                                    filled: false,
                                    onTap: _elapsedS > 0 ? _finish : null,
                                  ),
                                  const SizedBox(width: 14),
                                  _SceneButton(
                                    icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    label: _running ? l.pause : (_elapsedS > 0 ? l.resume : l.start),
                                    size: 64,
                                    filled: true,
                                    onTap: _toggleRun,
                                  ),
                                ],
                              ),
                            ),
                            if (hasAheadView(_kind))
                              Positioned(
                                left: 10,
                                top: 10,
                                child: Row(
                                  children: [
                                    for (final (v, label) in [(SceneView.side, l.viewSide), (SceneView.ahead, l.viewAhead)])
                                      Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ChoiceChip(
                                          label: Text(label),
                                          selected: _view == v,
                                          visualDensity: VisualDensity.compact,
                                          onSelected: progress == null
                                              ? null
                                              : (_) => setState(() {
                                                    progress.view = v.name;
                                                    progress.save();
                                                  }),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (_bubble != null)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: StickerBox(
                                  color: skin.accentSoft,
                                  radius: 14,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_girl) ...[
                                          CompanionFace(expression: _bubbleFace, size: 30, border: skin.ink, background: skin.card),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(_bubble!,
                                            style: t.labelLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else if (_resting)
                              Positioned(
                                top: 16,
                                right: 12,
                                child: Text(l.resting, style: t.labelMedium?.copyWith(color: skin.text)),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _Stat(label: l.duration, value: _clock(_elapsedS))),
                          if (_distanceKind) ...[
                            Expanded(child: _Stat(label: l.distance, value: '${_distanceKm.toStringAsFixed(2)} km')),
                            Expanded(child: _Stat(label: l.pace, value: _pace(speed))),
                          ],
                          Expanded(child: _Stat(label: 'kcal', value: '${_kcal.round()}')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!_distanceKind)
                        const SizedBox(height: 4)
                      else if (_gps)
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (RunSound.available) ...[
                            Text(l.sound, style: t.labelLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w800)),
                            Switch(
                              value: progress?.sound ?? false,
                              onChanged: progress == null
                                  ? null
                                  : (v) => setState(() {
                                        progress.sound = v;
                                        progress.save();
                                        if (v) RunSound.unlock();
                                      }),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (RunLocation.available && _outdoorKind) ...[
                            Text(l.outdoors, style: t.labelLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w800)),
                            Switch(value: _gps, onChanged: _setGps),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (progress != null) ...[
            _JourneyCard(progress: progress, onRoute: (id) => setState(() {
                  progress.routeId = id;
                  _routeDoneSaid = progress.routeKm >= progress.route.lengthKm;
                  progress.save();
                })),
            const SizedBox(height: 14),
          ],
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
                              for (final m in _distanceKind ? [200.0, 400.0, 1000.0] : [200.0, 300.0, 500.0])
                                ChoiceChip(
                                  // Without a distance, a lap is minutes on the clock.
                                  label: Text(_distanceKind
                                      ? (m >= 1000 ? '1 km' : '${m.toInt()} m')
                                      : '${(m / 100).round()} min'),
                                  selected: _lapM == m,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) => setState(() {
                                    _lapM = m;
                                    _nextLapKm = _journeyKm + m / 1000;
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
                    Text(l.stamps(progress?.stamps ?? 0),
                        style: t.labelLarge?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            _WardrobeCard(progress: progress, onChanged: () => setState(() => progress.save())),
          ],
        ],
      ),
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  const _RectClipper(this.rect);
  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_RectClipper old) => old.rect != rect;
}

/// A big round control on the scene: start, pause or finish, with its name
/// underneath, sized for a thumb.
class _SceneButton extends StatelessWidget {
  const _SceneButton({required this.icon, required this.label, required this.size, required this.filled, this.onTap});
  final IconData icon;
  final String label;
  final double size;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    final enabled = onTap != null;
    final fill = filled ? skin.button : skin.card;
    final fg = filled ? skin.buttonText : skin.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2 + 6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: enabled ? fill : fill.withValues(alpha: 0.5),
                shape: CircleBorder(side: BorderSide(color: skin.ink.withValues(alpha: enabled ? 0.9 : 0.35), width: 1.6)),
                elevation: enabled ? 2 : 0,
                shadowColor: skin.ink.withValues(alpha: 0.4),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Icon(icon, size: size * 0.58, color: enabled ? fg : fg.withValues(alpha: 0.4)),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: skin.card.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
                child: Text(label, style: t.labelSmall?.copyWith(color: skin.text, fontWeight: FontWeight.w800)),
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
                      left: (c.maxWidth - 28) * (lm.km / route.lengthKm),
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

/// Hats and shirt colours, unlocked with stamps.
class _WardrobeCard extends StatelessWidget {
  const _WardrobeCard({required this.progress, required this.onChanged});
  final RunProgress progress;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final stamps = progress.stamps;
    String hatName(String id) => switch (id) {
          'cap' => l.hatCap,
          'flower' => l.hatFlower,
          'beanie' => l.hatBeanie,
          'crown' => l.hatCrown,
          'ribbon' => l.hatRibbon,
          'headphones' => l.hatHeadphones,
          'glasses' => l.hatGlasses,
          _ => l.hatNone,
        };
    final shirtColors = [null, skin.button, skin.accent, skin.heading];
    final stick = progress.look != 'girl';
    final hats = stick ? hatUnlocks : girlHatUnlocks;
    final girlHat = girlHatUnlocks.any((h) => h.$1 == progress.hat) ? progress.hat : 'none';
    return WindowCard(
      title: l.wardrobe,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.look, style: t.labelLarge?.copyWith(color: skin.subText)),
              const SizedBox(width: 8),
              for (final (id, label) in [('girl', l.lookGirl), ('stick', l.lookStick)])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: progress.look == id,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      progress.look = id;
                      onChanged();
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!stick)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(child: DressedPose(frame: 'stand_front', height: 150, hat: girlHat)),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (id, need) in hats)
                ChoiceChip(
                  avatar: need > stamps ? Icon(Icons.lock_rounded, size: 14, color: skin.subText) : null,
                  label: Text(need > stamps ? '${hatName(id)} · ${l.needStamps(need)}' : hatName(id)),
                  selected: progress.hat == id,
                  visualDensity: VisualDensity.compact,
                  onSelected: need > stamps
                      ? null
                      : (_) {
                          progress.hat = id;
                          onChanged();
                        },
                ),
            ],
          ),
          // Shirt colours are painted onto the stick figure only.
          if (stick) const SizedBox(height: 10),
          if (stick) Row(
            children: [
              for (var i = 0; i < shirtColors.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: shirtUnlocks[i] > stamps
                        ? null
                        : () {
                            progress.shirt = i;
                            onChanged();
                          },
                    child: Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: shirtColors[i] ?? skin.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: skin.ink, width: progress.shirt == i ? 3 : kThinBorder),
                          ),
                          child: shirtUnlocks[i] > stamps
                              ? Icon(Icons.lock_rounded, size: 14, color: skin.subText)
                              : (i == 0 ? Icon(Icons.close_rounded, size: 14, color: skin.subText) : null),
                        ),
                        if (shirtUnlocks[i] > stamps)
                          Text(l.needStamps(shirtUnlocks[i]), style: t.labelSmall?.copyWith(color: skin.subText)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
