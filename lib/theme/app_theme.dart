import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'skin.dart';

/// Everything is outlined rather than shadowed: one ink colour draws the
/// borders, fills stay pastel, and corners are generously rounded.
const double kBorderWidth = 2;
const double kCardRadius = 22;

ThemeData buildTheme(Skin skin, {String font = 'rounded'}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: skin.isDark ? Brightness.dark : Brightness.light,
  );
  final rounded = font != 'standard';
  final textTheme = (rounded
          ? GoogleFonts.mPlusRounded1cTextTheme(base.textTheme)
          : GoogleFonts.notoSansJpTextTheme(base.textTheme))
      .apply(bodyColor: skin.text, displayColor: skin.text);
  final family = rounded
      ? GoogleFonts.mPlusRounded1c().fontFamily
      : GoogleFonts.notoSansJp().fontFamily;
  final outline = BorderSide(color: skin.ink, width: kBorderWidth);

  return base.copyWith(
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: family),
    colorScheme: ColorScheme.fromSeed(
      seedColor: skin.button,
      brightness: skin.isDark ? Brightness.dark : Brightness.light,
      primary: skin.button,
      onPrimary: skin.ink,
      secondary: skin.accent,
      surface: skin.card,
      onSurface: skin.text,
    ),
    scaffoldBackgroundColor: skin.background,
    canvasColor: skin.card,
    textTheme: textTheme,
    dividerColor: skin.divider,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: skin.heading,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: skin.heading,
        fontWeight: FontWeight.w800,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: skin.button,
        foregroundColor: skin.ink,
        side: outline,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: skin.card,
        foregroundColor: skin.ink,
        side: outline,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: skin.heading,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? skin.button : skin.card,
        ),
        foregroundColor: WidgetStatePropertyAll(skin.ink),
        side: WidgetStatePropertyAll(outline),
        textStyle: WidgetStatePropertyAll(
          textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: skin.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: outline,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: outline,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: skin.heading, width: kBorderWidth + 0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefixIconColor: skin.subText,
      labelStyle: TextStyle(color: skin.subText),
      hintStyle: TextStyle(color: skin.subText),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: skin.card,
      selectedColor: skin.button,
      side: BorderSide(color: skin.ink, width: 1.6),
      labelStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: skin.ink,
      ),
      showCheckmark: false,
      shape: const StadiumBorder(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: skin.card,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        side: outline,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: skin.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: outline,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: skin.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: outline,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: skin.card,
      indicatorColor: skin.button,
      surfaceTintColor: Colors.transparent,
      indicatorShape: StadiumBorder(side: BorderSide(color: skin.ink, width: 1.6)),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? skin.ink : skin.subText,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelSmall?.copyWith(
          color: states.contains(WidgetState.selected) ? skin.ink : skin.subText,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: skin.button,
      foregroundColor: skin.ink,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: StadiumBorder(side: outline),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? skin.card : skin.subText,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? skin.button : skin.divider,
      ),
      trackOutlineColor: WidgetStatePropertyAll(skin.ink),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: skin.button,
      thumbColor: skin.button,
      inactiveTrackColor: skin.divider,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: skin.card,
      contentTextStyle: TextStyle(color: skin.ink, fontWeight: FontWeight.w700),
      actionTextColor: skin.heading,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: outline,
      ),
    ),
  );
}
