import 'package:shared_preferences/shared_preferences.dart';

import 'enums.dart';

class UserProfile {
  const UserProfile({
    this.nickname = '',
    this.sex = Sex.female,
    this.birthYear = 2000,
    this.heightCm = 160,
    this.goal = Goal.maintain,
    this.activity = ActivityLevel.light,
    this.weeklyGoalDays = 3,
    this.kcalOverride,
    this.proteinOverride,
    this.fatOverride,
    this.carbsOverride,
    this.skinId = 'beige_rose',
    this.healthSync = false,
    this.lang = 'en',
    this.font = 'standard',
  });

  final String nickname;
  final Sex sex;
  final int birthYear;
  final double heightCm;
  final Goal goal;
  final ActivityLevel activity;
  final int weeklyGoalDays;
  final int? kcalOverride;
  final double? proteinOverride;
  final double? fatOverride;
  final double? carbsOverride;
  final String skinId;
  final bool healthSync;
  final String lang;
  final String font;

  int get age => DateTime.now().year - birthYear;

  UserProfile copyWith({
    String? nickname,
    Sex? sex,
    int? birthYear,
    double? heightCm,
    Goal? goal,
    ActivityLevel? activity,
    int? weeklyGoalDays,
    int? kcalOverride,
    bool clearKcal = false,
    double? proteinOverride,
    double? fatOverride,
    double? carbsOverride,
    bool clearMacros = false,
    String? skinId,
    bool? healthSync,
    String? lang,
    String? font,
  }) =>
      UserProfile(
        nickname: nickname ?? this.nickname,
        sex: sex ?? this.sex,
        birthYear: birthYear ?? this.birthYear,
        heightCm: heightCm ?? this.heightCm,
        goal: goal ?? this.goal,
        activity: activity ?? this.activity,
        weeklyGoalDays: weeklyGoalDays ?? this.weeklyGoalDays,
        kcalOverride: clearKcal ? null : (kcalOverride ?? this.kcalOverride),
        proteinOverride:
            clearMacros ? null : (proteinOverride ?? this.proteinOverride),
        fatOverride: clearMacros ? null : (fatOverride ?? this.fatOverride),
        carbsOverride:
            clearMacros ? null : (carbsOverride ?? this.carbsOverride),
        skinId: skinId ?? this.skinId,
        healthSync: healthSync ?? this.healthSync,
        lang: lang ?? this.lang,
        font: font ?? this.font,
      );

  static Future<UserProfile> load() async {
    final p = await SharedPreferences.getInstance();
    return UserProfile(
      nickname: p.getString('nickname') ?? '',
      sex: Sex.parse(p.getString('sex') ?? ''),
      birthYear: p.getInt('birthYear') ?? 2000,
      heightCm: p.getDouble('heightCm') ?? 160,
      goal: Goal.parse(p.getString('goal') ?? ''),
      activity: ActivityLevel.parse(p.getString('activity') ?? ''),
      weeklyGoalDays: p.getInt('weeklyGoalDays') ?? 3,
      kcalOverride: p.getInt('kcalOverride'),
      proteinOverride: p.getDouble('proteinOverride'),
      fatOverride: p.getDouble('fatOverride'),
      carbsOverride: p.getDouble('carbsOverride'),
      skinId: p.getString('skinId') ?? 'beige_rose',
      healthSync: p.getBool('healthSync') ?? false,
      lang: p.getString('lang') ?? 'en',
      font: p.getString('font') ?? 'standard',
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('nickname', nickname);
    await p.setString('sex', sex.name);
    await p.setInt('birthYear', birthYear);
    await p.setDouble('heightCm', heightCm);
    await p.setString('goal', goal.name);
    await p.setString('activity', activity.name);
    await p.setInt('weeklyGoalDays', weeklyGoalDays);
    await _setOrRemoveInt(p, 'kcalOverride', kcalOverride);
    await _setOrRemoveDouble(p, 'proteinOverride', proteinOverride);
    await _setOrRemoveDouble(p, 'fatOverride', fatOverride);
    await _setOrRemoveDouble(p, 'carbsOverride', carbsOverride);
    await p.setString('skinId', skinId);
    await p.setBool('healthSync', healthSync);
    await p.setString('lang', lang);
    await p.setString('font', font);
  }

  static Future<void> _setOrRemoveInt(
      SharedPreferences p, String key, int? v) async {
    if (v == null) {
      await p.remove(key);
    } else {
      await p.setInt(key, v);
    }
  }

  static Future<void> _setOrRemoveDouble(
      SharedPreferences p, String key, double? v) async {
    if (v == null) {
      await p.remove(key);
    } else {
      await p.setDouble(key, v);
    }
  }
}
