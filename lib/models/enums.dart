import 'package:flutter/material.dart';

import '../l10n/strings.dart';

enum MuscleGroup {
  chest('Chest', '胸', 'CH', Color(0xFFF2A7B8)),
  back('Back', '背中', 'BK', Color(0xFFA8C5E8)),
  shoulders('Shoulders', '肩', 'SH', Color(0xFFC9B6E4)),
  arms('Arms', '腕', 'AR', Color(0xFFF5C48A)),
  legs('Legs', '脚', 'LG', Color(0xFF9FD3C7)),
  glutes('Glutes', 'お尻', 'GL', Color(0xFFF7B7A3)),
  core('Core', 'お腹', 'CO', Color(0xFFF3D67F));

  const MuscleGroup(this.en, this.ja, this.code, this.color);
  final String en;
  final String ja;
  final String code;
  final Color color;

  String label(L l) => l.isJa ? ja : en;
  String shortCode(L l) => l.isJa ? ja.replaceAll('お', '').substring(0, 1) : code;

  static MuscleGroup parse(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => core);
}

enum CardioType {
  running('Running', 'ランニング'),
  walking('Walking', 'ウォーキング'),
  cycling('Cycling', 'バイク'),
  elliptical('Elliptical', 'クロストレーナー'),
  stairs('Stair climber', 'ステアクライマー'),
  rowing('Rowing', 'ローイング'),
  swimming('Swimming', '水泳'),
  hiit('HIIT', 'HIIT'),
  yoga('Yoga / stretch', 'ヨガ・ストレッチ'),
  other('Other', 'その他');

  const CardioType(this.en, this.ja);
  final String en;
  final String ja;

  String label(L l) => l.isJa ? ja : en;

  static CardioType parse(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => other);
}

enum MealSlot {
  breakfast('Breakfast', '朝ごはん', Icons.free_breakfast_outlined),
  lunch('Lunch', '昼ごはん', Icons.lunch_dining_outlined),
  dinner('Dinner', '夜ごはん', Icons.dinner_dining_outlined),
  snack('Snack', '間食', Icons.cookie_outlined);

  const MealSlot(this.en, this.ja, this.icon);
  final String en;
  final String ja;
  final IconData icon;

  String label(L l) => l.isJa ? ja : en;

  static MealSlot parse(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => snack);

  static MealSlot forNow([DateTime? at]) {
    final h = (at ?? DateTime.now()).hour;
    if (h < 10) return breakfast;
    if (h < 15) return lunch;
    if (h < 17) return snack;
    if (h < 22) return dinner;
    return snack;
  }
}

enum Sex {
  female('Female', '女性'),
  male('Male', '男性');

  const Sex(this.en, this.ja);
  final String en;
  final String ja;

  String label(L l) => l.isJa ? ja : en;

  static Sex parse(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => female);
}

enum Goal {
  cut('Lean down', '引き締め', -300),
  maintain('Maintain', 'キープ', 0),
  bulk('Build muscle', '筋肉を増やす', 300);

  const Goal(this.en, this.ja, this.kcalOffset);
  final String en;
  final String ja;
  final int kcalOffset;

  String label(L l) => l.isJa ? ja : en;

  static Goal parse(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => maintain);
}

enum ActivityLevel {
  low('Mostly sitting', 'デスクワーク中心', 1.2),
  light('Exercise 1–2×/week', '週1〜2回運動', 1.375),
  moderate('Exercise 3–4×/week', '週3〜4回運動', 1.55),
  high('Exercise 5+×/week', '週5回以上運動', 1.725);

  const ActivityLevel(this.en, this.ja, this.factor);
  final String en;
  final String ja;
  final double factor;

  String label(L l) => l.isJa ? ja : en;

  static ActivityLevel parse(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => light);
}

enum FoodTag {
  protein('Protein', 'たんぱく質'),
  staple('Staples', '主食'),
  vegetable('Veggies & fruit', '野菜・果物'),
  dairy('Dairy & drinks', '乳製品・飲み物'),
  dish('Dishes & eating out', 'おかず・外食'),
  sweet('Sweets', 'スイーツ');

  const FoodTag(this.en, this.ja);
  final String en;
  final String ja;

  String label(L l) => l.isJa ? ja : en;

  static FoodTag parse(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => dish);
}
