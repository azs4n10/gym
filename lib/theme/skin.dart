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
    this.inkOverride,
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
  final Color? inkOverride;
  final bool isDark;

  /// Outline colour. Everything in this style is drawn with a border rather
  /// than a blurred shadow, so one dark ink carries the whole contrast.
  Color get ink =>
      inkOverride ?? (isDark ? text : Color.lerp(heading, const Color(0xFF2E1F33), 0.5)!);

  Color get accentSoft => Color.lerp(accent, card, 0.6)!;
  Color get buttonSoft => Color.lerp(button, card, 0.7)!;

  /// Hard drop shadow sitting just below and right of an element.
  Color get shadow => ink.withValues(alpha: isDark ? 0.55 : 0.22);

  /// Faint ruling for the grid-paper background.
  Color get grid => isDark
      ? Colors.white.withValues(alpha: 0.05)
      : ink.withValues(alpha: 0.11);
}

const Skin stickerPinkSkin = Skin(
  id: 'sticker_pink',
  name: 'Sticker Pink',
  nameJa: 'ステッカーピンク',
  background: Color(0xFFFDF0F5),
  card: Color(0xFFFFFFFF),
  heading: Color(0xFFC2547E),
  accent: Color(0xFFC7B2EF),
  button: Color(0xFFFBBBD3),
  buttonText: Color(0xFF4A3550),
  text: Color(0xFF4A3550),
  subText: Color(0xFF9A7F9B),
  divider: Color(0xFFF3D3E2),
  inkOverride: Color(0xFF4A3550),
);

const Skin stickerLilacSkin = Skin(
  id: 'sticker_lilac',
  name: 'Sticker Lilac',
  nameJa: 'ステッカーラベンダー',
  background: Color(0xFFF3EEFE),
  card: Color(0xFFFFFFFF),
  heading: Color(0xFF7A5BB5),
  accent: Color(0xFFFFC2DF),
  button: Color(0xFFC9B3F5),
  buttonText: Color(0xFF3D2C57),
  text: Color(0xFF3D2C57),
  subText: Color(0xFF8B7BAA),
  divider: Color(0xFFE2D8F7),
  inkOverride: Color(0xFF3D2C57),
);

const Skin stickerMintSkin = Skin(
  id: 'sticker_mint',
  name: 'Sticker Mint',
  nameJa: 'ステッカーミント',
  background: Color(0xFFEAF7F2),
  card: Color(0xFFFFFFFF),
  heading: Color(0xFF2F7F72),
  accent: Color(0xFFFFC9A8),
  button: Color(0xFF9EE0CE),
  buttonText: Color(0xFF23433F),
  text: Color(0xFF23433F),
  subText: Color(0xFF6E958D),
  divider: Color(0xFFD2EBE2),
  inkOverride: Color(0xFF23433F),
);

const Skin stickerCreamSkin = Skin(
  id: 'sticker_cream',
  name: 'Sticker Cream',
  nameJa: 'ステッカークリーム',
  background: Color(0xFFFDF4E7),
  card: Color(0xFFFFFDF8),
  heading: Color(0xFFB5763F),
  accent: Color(0xFFF3C3A0),
  button: Color(0xFFF7D9A8),
  buttonText: Color(0xFF4C3A2A),
  text: Color(0xFF4C3A2A),
  subText: Color(0xFF9A8168),
  divider: Color(0xFFEEDCC3),
  inkOverride: Color(0xFF4C3A2A),
);

const Skin beigeRoseSkin = Skin(
  id: 'beige_rose',
  name: 'Beige Rose',
  nameJa: 'ベージュローズ',
  background: Color(0xFFF5EBE0),
  card: Color(0xFFFFFAF5),
  heading: Color(0xFF8B5A6B),
  accent: Color(0xFFD4A5A5),
  button: Color(0xFFC9A88D),
  buttonText: Color(0xFF4A3038),
  text: Color(0xFF6B4858),
  subText: Color(0xFF8F7669),
  divider: Color(0xFFE8D5C4),
  inkOverride: Color(0xFF4A3038),
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
  buttonText: Color(0xFF56304A),
  text: Color(0xFF56304A),
  subText: Color(0xFF9C7488),
  divider: Color(0xFFF5D2E1),
  inkOverride: Color(0xFF56304A),
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
  buttonText: Color(0xFF241C3A),
  text: Color(0xFFF5EBE0),
  subText: Color(0xFFB8A8D0),
  divider: Color(0xFF4A4070),
  inkOverride: Color(0xFFF0E3F5),
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
  buttonText: Color(0xFF2B2320),
  text: Color(0xFFF0E6DE),
  subText: Color(0xFFB5A89E),
  divider: Color(0xFF4A3E3A),
  inkOverride: Color(0xFFF3E7DD),
  isDark: true,
);

const List<Skin> allSkins = [
  stickerPinkSkin,
  stickerLilacSkin,
  stickerMintSkin,
  stickerCreamSkin,
  beigeRoseSkin,
  yumekawaSkin,
  nightStarSkin,
  cocoaNightSkin,
];

const Skin defaultSkin = stickerPinkSkin;

Skin skinById(String id) =>
    allSkins.firstWhere((s) => s.id == id, orElse: () => defaultSkin);
