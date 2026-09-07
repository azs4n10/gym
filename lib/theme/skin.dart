import 'package:flutter/material.dart';

@immutable
class Skin {
  const Skin({
    required this.id,
    required this.name,
    required this.nameJa,
    required this.background,
    required this.card,
    required this.heading,
    required this.accent,
    required this.button,
    required this.buttonText,
    required this.text,
    required this.subText,
    required this.divider,
    this.isDark = false,
  });

  final String id;
  final String name;
  final String nameJa;
  final Color background;
  final Color card;
  final Color heading;
  final Color accent;
  final Color button;
  final Color buttonText;
  final Color text;
  final Color subText;
  final Color divider;
  final bool isDark;

  Color get accentSoft => Color.lerp(accent, card, 0.6)!;
  Color get buttonSoft => Color.lerp(button, card, 0.7)!;
  Color get shadow => (isDark ? Colors.black : heading).withValues(alpha: isDark ? 0.35 : 0.10);
}

const Skin beigeRoseSkin = Skin(
  id: 'beige_rose',
  name: 'Beige Rose',
  nameJa: 'ベージュローズ',
  background: Color(0xFFF5EBE0),
  card: Color(0xFFFFFAF5),
  heading: Color(0xFF8B5A6B),
  accent: Color(0xFFD4A5A5),
  button: Color(0xFFC9A88D),
  buttonText: Color(0xFFFFFFFF),
  text: Color(0xFF6B4858),
  subText: Color(0xFF8F7669),
  divider: Color(0xFFE8D5C4),
);

const Skin yumekawaSkin = Skin(
  id: 'yumekawa',
  name: 'Yumekawa',
  nameJa: 'ゆめかわ',
  background: Color(0xFFFCE7F3),
  card: Color(0xFFFFFFFF),
  heading: Color(0xFFBE5A8F),
  accent: Color(0xFFC4A8E1),
  button: Color(0xFFF8A5C2),
  buttonText: Color(0xFFFFFFFF),
  text: Color(0xFF6B4858),
  subText: Color(0xFF9C7488),
  divider: Color(0xFFF5D2E1),
);

const Skin lavenderSkin = Skin(
  id: 'lavender',
  name: 'Lavender Dream',
  nameJa: 'ラベンダー',
  background: Color(0xFFF1E8FF),
  card: Color(0xFFFFFFFF),
  heading: Color(0xFF8C6BB5),
  accent: Color(0xFFFFB6D9),
  button: Color(0xFFB69CE8),
  buttonText: Color(0xFFFFFFFF),
  text: Color(0xFF5E4A7A),
  subText: Color(0xFF8672A6),
  divider: Color(0xFFE3D6F5),
);

const Skin mintPeachSkin = Skin(
  id: 'mint_peach',
  name: 'Mint Peach',
  nameJa: 'ミントピーチ',
  background: Color(0xFFF5F9F4),
  card: Color(0xFFFFF5EE),
  heading: Color(0xFF5C8D89),
  accent: Color(0xFFFFB088),
  button: Color(0xFF88C9BF),
  buttonText: Color(0xFFFFFFFF),
  text: Color(0xFF4A6B68),
  subText: Color(0xFF6F948D),
  divider: Color(0xFFDDE8E0),
);

const Skin sugarPinkSkin = Skin(
  id: 'sugar_pink',
  name: 'Sugar Pink',
  nameJa: 'シュガーピンク',
  background: Color(0xFFFFFFFF),
  card: Color(0xFFFFE4EC),
  heading: Color(0xFFF472B6),
  accent: Color(0xFFFBCFE8),
  button: Color(0xFFEC4899),
  buttonText: Color(0xFFFFFFFF),
  text: Color(0xFF8B2A6B),
  subText: Color(0xFFBB6F98),
  divider: Color(0xFFFBCFE8),
);

const Skin nightStarSkin = Skin(
  id: 'night_star',
  name: 'Night Star',
  nameJa: 'ナイトスター',
  background: Color(0xFF2A2342),
  card: Color(0xFF3D3460),
  heading: Color(0xFFFFC0E2),
  accent: Color(0xFFB69CE8),
  button: Color(0xFFCE82B0),
  buttonText: Color(0xFFFFFFFF),
  text: Color(0xFFF5EBE0),
  subText: Color(0xFFB8A8D0),
  divider: Color(0xFF4A4070),
  isDark: true,
);

const Skin midnightPlumSkin = Skin(
  id: 'midnight_plum',
  name: 'Midnight Plum',
  nameJa: 'ミッドナイトプラム',
  background: Color(0xFF1E1B2E),
  card: Color(0xFF2E2A45),
  heading: Color(0xFFE8B7D4),
  accent: Color(0xFFB69CE8),
  button: Color(0xFFC98DB2),
  buttonText: Color(0xFFFFFFFF),
  text: Color(0xFFEDE7F5),
  subText: Color(0xFFA89CC0),
  divider: Color(0xFF3B3658),
  isDark: true,
);

const Skin cocoaNightSkin = Skin(
  id: 'cocoa_night',
  name: 'Cocoa Night',
  nameJa: 'ココアナイト',
  background: Color(0xFF2B2320),
  card: Color(0xFF3D332F),
  heading: Color(0xFFF0C9B0),
  accent: Color(0xFFD9A299),
  button: Color(0xFFC4939A),
  buttonText: Color(0xFFFFFFFF),
  text: Color(0xFFF0E6DE),
  subText: Color(0xFFB5A89E),
  divider: Color(0xFF4A3E3A),
  isDark: true,
);

const Skin charcoalRoseSkin = Skin(
  id: 'charcoal_rose',
  name: 'Charcoal Rose',
  nameJa: 'チャコールローズ',
  background: Color(0xFF242022),
  card: Color(0xFF353033),
  heading: Color(0xFFEAB8C4),
  accent: Color(0xFFC99AA8),
  button: Color(0xFFC596A0),
  buttonText: Color(0xFFFFFFFF),
  text: Color(0xFFF0E8EC),
  subText: Color(0xFFAEA2A8),
  divider: Color(0xFF443D41),
  isDark: true,
);

const List<Skin> allSkins = [
  beigeRoseSkin,
  yumekawaSkin,
  lavenderSkin,
  mintPeachSkin,
  sugarPinkSkin,
  nightStarSkin,
  midnightPlumSkin,
  cocoaNightSkin,
  charcoalRoseSkin,
];

const Skin defaultSkin = beigeRoseSkin;

Skin skinById(String id) =>
    allSkins.firstWhere((s) => s.id == id, orElse: () => defaultSkin);
