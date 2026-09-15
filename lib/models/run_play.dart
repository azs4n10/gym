import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'enums.dart';

/// Small pictures drawn next to the route; see run_glyphs.dart.
enum Glyph { flag, tree, house, bridge, lighthouse, spring, castle, windmill, goal, mountain, star, moon, torii }

class Landmark {
  const Landmark(this.id, this.km, this.en, this.ja, this.glyph);
  final String id;
  final double km;
  final String en;
  final String ja;
  final Glyph glyph;

  String label(bool ja) => ja ? this.ja : en;
}

/// An illustrated road whose length is covered across many sessions; every
/// landmark reached leaves a stamp.
class RunRoute {
  const RunRoute(this.id, this.en, this.ja, this.landmarks);
  final String id;
  final String en;
  final String ja;
  final List<Landmark> landmarks;

  String label(bool ja) => ja ? this.ja : en;
  double get lengthKm => landmarks.last.km;
}

const runRoutes = [
  RunRoute('sticker_road', 'Sticker Road', 'ステッカーロード', [
    Landmark('start', 0, 'Start', 'スタート', Glyph.flag),
    Landmark('park', 2, 'Park', '公園', Glyph.tree),
    Landmark('bakery', 5, 'Bakery', 'パン屋', Glyph.house),
    Landmark('bridge', 10, 'Bridge', '橋', Glyph.bridge),
    Landmark('lighthouse', 15, 'Lighthouse', '灯台', Glyph.lighthouse),
    Landmark('spring', 21.1, 'Hot spring', '温泉', Glyph.spring),
    Landmark('castle', 30, 'Castle', 'お城', Glyph.castle),
    Landmark('windmill', 36, 'Windmill', '風車', Glyph.windmill),
    Landmark('goal', 42.2, 'Goal', 'ゴール', Glyph.goal),
  ]),
  RunRoute('island_hop', 'Island Hop', 'アイランドホップ', [
    Landmark('pier', 0, 'Pier', '桟橋', Glyph.flag),
    Landmark('beach', 8, 'Shell beach', '貝がらの浜', Glyph.star),
    Landmark('cape', 20, 'Cape', '岬', Glyph.lighthouse),
    Landmark('village', 33, 'Fishing village', '漁村', Glyph.house),
    Landmark('volcano', 50, 'Volcano', '火山', Glyph.mountain),
    Landmark('banyan', 65, 'Banyan tree', 'ガジュマル', Glyph.tree),
    Landmark('seabridge', 80, 'Sea bridge', '海の橋', Glyph.bridge),
    Landmark('fireworks', 92, 'Fireworks pier', '花火の桟橋', Glyph.star),
    Landmark('goal', 100, 'Goal', 'ゴール', Glyph.goal),
  ]),
  RunRoute('sky_trail', 'Sky Trail', 'スカイトレイル', [
    Landmark('trailhead', 0, 'Trailhead', '登山口', Glyph.flag),
    Landmark('forest', 25, 'Forest', '森', Glyph.tree),
    Landmark('ridge', 60, 'Ridge', '尾根', Glyph.mountain),
    Landmark('shrine', 100, 'Shrine', '神社', Glyph.torii),
    Landmark('summit', 150, 'Summit', '山頂', Glyph.mountain),
    Landmark('cloudbridge', 200, 'Cloud bridge', '雲の橋', Glyph.bridge),
    Landmark('stars', 250, 'Star field', '星の原', Glyph.star),
    Landmark('moongate', 280, 'Moon gate', '月の門', Glyph.moon),
    Landmark('goal', 300, 'Goal', 'ゴール', Glyph.goal),
  ]),
];

RunRoute routeById(String id) => runRoutes.firstWhere((r) => r.id == id, orElse: () => runRoutes.first);

/// How far along each route the runner has come, plus the stamps collected.
class RunProgress {
  RunProgress({
    this.routeId = 'sticker_road',
    Map<String, double>? km,
    Set<String>? reached,
    this.stamps = 0,
    this.finishedRoutes = 0,
    this.hat = 'none',
    this.shirt = 0,
    this.view = 'side',
    this.sound = false,
    this.look = 'girl',
  })  : km = km ?? {},
        reached = reached ?? {};

  String routeId;
  final Map<String, double> km;

  /// What the companion wears and how the scene is shown.
  String hat;
  int shirt;
  String view;
  bool sound;

  /// 'girl' for the illustrated companion, 'stick' for the drawn figure.
  String look;

  /// Keys shaped `route/landmark`.
  final Set<String> reached;
  int stamps;
  int finishedRoutes;

  RunRoute get route => routeById(routeId);
  double get routeKm => km[routeId] ?? 0;

  bool isReached(RunRoute r, Landmark l) => reached.contains('${r.id}/${l.id}');

  /// Moves along the current route and returns the landmarks passed.
  List<Landmark> advance(double deltaKm) {
    final r = route;
    final before = routeKm;
    final after = math.min(r.lengthKm, before + deltaKm);
    km[routeId] = after;
    final passed = <Landmark>[];
    for (final l in r.landmarks) {
      if (l.km <= after && l.km > 0 && !isReached(r, l)) {
        reached.add('${r.id}/${l.id}');
        passed.add(l);
      }
    }
    return passed;
  }

  Map<String, dynamic> toJson() => {
        'routeId': routeId,
        'km': km,
        'reached': reached.toList(),
        'stamps': stamps,
        'finishedRoutes': finishedRoutes,
        'hat': hat,
        'shirt': shirt,
        'view': view,
        'sound': sound,
        'look': look,
      };

  static RunProgress fromJson(Map<String, dynamic> j) => RunProgress(
        routeId: j['routeId'] as String? ?? 'sticker_road',
        km: {
          for (final e in (j['km'] as Map<String, dynamic>? ?? {}).entries)
            e.key: (e.value as num).toDouble(),
        },
        reached: {...(j['reached'] as List? ?? []).cast<String>()},
        stamps: j['stamps'] as int? ?? 0,
        finishedRoutes: j['finishedRoutes'] as int? ?? 0,
        hat: j['hat'] as String? ?? 'none',
        shirt: j['shirt'] as int? ?? 0,
        view: j['view'] as String? ?? 'side',
        sound: j['sound'] as bool? ?? false,
        look: j['look'] as String? ?? 'girl',
      );

  static const _key = 'runProgress';

  static Future<RunProgress>? _shared;

  /// One instance for the whole app, so a change in the run screen shows on
  /// the home screen too.
  static Future<RunProgress> loadShared() => _shared ??= load();

  static Future<RunProgress> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return RunProgress();
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return RunProgress();
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(toJson()));
  }
}

/// Hats in the order they unlock, with the stamps each one needs. The
/// index 0 entry is "none".
const hatUnlocks = <(String, int)>[
  ('none', 0),
  ('cap', 3),
  ('flower', 8),
  ('beanie', 15),
  ('crown', 30),
];

/// Shirt colours by index: 0 none, then the theme's button, accent and
/// heading tones; each after the first needs a few more stamps.
const shirtUnlocks = [0, 1, 5, 12];

/// Accessories for the illustrated companion, cut from her design sheet.
const girlHatUnlocks = <(String, int)>[
  ('none', 0),
  ('cap', 3),
  ('flower', 8),
  ('beanie', 15),
  ('ribbon', 20),
  ('headphones', 30),
];

/// Width over height of each pose drawing.
const poseAspect = <String, double>{
  'run_side_a': 440 / 492,
  'run_side_b': 440 / 492,
  'sit_side': 440 / 492,
  'run_side_tired': 440 / 492,
  'run_side_closed': 440 / 492,
  'run_side_c': 440 / 492,
  'run_side_d': 440 / 492,
  'run_back_a': 218 / 477,
  'run_back_b': 218 / 477,
  'stand_back': 218 / 477,
  'stand_front': 131 / 411,
};

/// Where a hat sits on each pose: the top of the hair, centred, as fractions
/// of the drawing's width and height (measured from the images).
const hatAnchors = <String, (double, double)>{
  'run_side_a': (0.634, 0.03),
  'run_side_b': (0.627, 0.057),
  'sit_side': (0.459, 0.124),
  'run_side_tired': (0.63, 0.104),
  'run_side_closed': (0.58, 0.073),
  'run_side_c': (0.634, 0.03),
  'run_side_d': (0.628, 0.057),
  'run_back_a': (0.401, 0.029),
  'run_back_b': (0.578, 0.046),
  'stand_back': (0.454, 0.124),
  'stand_front': (0.462, 0.0),
};

/// What the wheel can land on. Each call lasts [seconds].
enum RouletteCall {
  faster('Speed +1', '速度 +1', 60),
  slower('Speed -1', '速度 -1', 60),
  incline('Incline +2%', '傾斜 +2%', 60),
  keep('Keep pace', 'このまま', 60),
  sprint('Sprint', 'ダッシュ', 20),
  arms('Arm swings', '腕を大きく', 30),
  knees('High knees', 'もも上げ', 30),
  breathe('In 4, out 4', '4秒吸う 4秒吐く', 40),
  smile('Smile', 'にっこり', 15);

  const RouletteCall(this.en, this.ja, this.seconds);
  final String en;
  final String ja;
  final int seconds;

  String label(bool ja) => ja ? this.ja : en;
}

enum QuestKind { nonstop1k, steady2m, laps3, calls3, landmark, minutes10, km2, fast }

/// One of three small goals drawn for a session.
class Quest {
  Quest(this.kind, {required this.target});
  final QuestKind kind;
  final double target;
  double progress = 0;
  bool done = false;

  double get ratio => (progress / target).clamp(0.0, 1.0);

  String label(bool ja, CardioType kind) => switch (this.kind) {
        QuestKind.nonstop1k => ja ? '止まらずに 1 km' : '1 km without stopping',
        QuestKind.steady2m => ja ? '2 分間ペース一定' : 'Steady pace for 2 min',
        QuestKind.laps3 => ja ? '3 周' : '3 laps',
        QuestKind.calls3 => ja ? 'ルーレットの指令を 3 回' : 'Follow 3 roulette calls',
        QuestKind.landmark => ja ? '名所に着く' : 'Reach a landmark',
        QuestKind.minutes10 => ja ? '10 分' : '10 minutes',
        QuestKind.km2 => ja ? '2 km' : '2 km',
        QuestKind.fast => ja ? '${_fmt(fastTarget(kind))} km/h 以上で 200 m' : '200 m at ${_fmt(fastTarget(kind))} km/h or more',
      };

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// Speed the fast quest asks for, by activity; it counts the distance
  /// covered at that speed or above, so nudging a slider is not enough.
  static double fastTarget(CardioType kind) => switch (kind) {
        CardioType.walking => 6.5,
        CardioType.cycling => 30,
        _ => 12,
      };

  static List<Quest> draw(CardioType kind, {int? seed}) {
    final rnd = math.Random(seed);
    const needsDistance = {QuestKind.nonstop1k, QuestKind.steady2m, QuestKind.km2, QuestKind.fast};
    final kinds = [
      for (final k in QuestKind.values)
        if (hasDistance(kind) || !needsDistance.contains(k)) k,
    ]..shuffle(rnd);
    return [
      for (final k in kinds.take(3))
        Quest(
          k,
          target: switch (k) {
            QuestKind.nonstop1k => 1,
            QuestKind.steady2m => 120,
            QuestKind.laps3 => 3,
            QuestKind.calls3 => 3,
            QuestKind.landmark => 1,
            QuestKind.minutes10 => 600,
            QuestKind.km2 => 2,
            QuestKind.fast => 0.2,
          },
        ),
    ];
  }
}

/// A short line the companion says; picked at random for a moment.
const cheersEn = ['Nice!', 'Keep going', 'Looking good', 'One more', 'You got this', 'Steady'];
const cheersJa = ['いいね', 'その調子', 'きれいなフォーム', 'もう少し', 'いける', '安定してる'];

/// Activities measured in distance; the rest run on the clock alone, and the
/// road advances at ten minutes to the kilometre.
bool hasDistance(CardioType kind) =>
    kind != CardioType.hiit && kind != CardioType.yoga && kind != CardioType.other;

/// Fastest setting of the speed slider, in km/h, and where it starts.
double topSpeed(CardioType kind) => switch (kind) {
      CardioType.cycling => 40,
      CardioType.rowing => 20,
      CardioType.running || CardioType.elliptical => 16,
      CardioType.walking || CardioType.stairs => 10,
      CardioType.swimming => 6,
      _ => 0,
    };

double startSpeed(CardioType kind) => switch (kind) {
      CardioType.cycling => 15,
      CardioType.rowing => 10,
      CardioType.running || CardioType.elliptical => 6,
      CardioType.walking || CardioType.stairs => 4,
      CardioType.swimming => 2,
      _ => 0,
    };

/// Rough energy for a stretch of movement: MET by activity and speed, times
/// body weight, times hours. A guide, not a measurement.
int estimateKcal(CardioType kind, double speedKmh, double hours, double weightKg) {
  final met = switch (kind) {
    CardioType.walking => (2.0 + speedKmh * 0.3).clamp(2.0, 5.0),
    CardioType.cycling => (speedKmh * 0.4).clamp(4.0, 12.0),
    CardioType.elliptical => (3.0 + speedKmh * 0.4).clamp(4.0, 10.0),
    CardioType.stairs => (5.0 + speedKmh * 0.6).clamp(6.0, 11.0),
    CardioType.rowing => (3.0 + speedKmh * 0.5).clamp(4.0, 12.0),
    CardioType.swimming => (4.0 + speedKmh * 2).clamp(6.0, 11.0),
    CardioType.hiit => 10.0,
    CardioType.yoga => 3.0,
    CardioType.other => 5.0,
    _ => speedKmh.clamp(6.0, 14.0),
  };
  return (met * weightKg * hours).round();
}
