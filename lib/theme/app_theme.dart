import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'skin.dart';

ThemeData buildTheme(Skin skin, {String font = 'standard'}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: skin.isDark ? Brightness.dark : Brightness.light,
  );
  final rounded = font == 'rounded';
  final textTheme = (rounded
          ? GoogleFonts.mPlusRounded1cTextTheme(base.textTheme)
          : GoogleFonts.notoSansJpTextTheme(base.textTheme))
      .apply(bodyColor: skin.text, displayColor: skin.text);
  final family = rounded
      ? GoogleFonts.mPlusRounded1c().fontFamily
      : GoogleFonts.notoSansJp().fontFamily;
  return base.copyWith(
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: family),
    colorScheme: ColorScheme.fromSeed(
      seedColor: skin.button,
      brightness: skin.isDark ? Brightness.dark : Brightness.light,
      primary: skin.button,
      onPrimary: skin.buttonText,
      secondary: skin.accent,
      surface: skin.card,
      onSurface: skin.text,
    ),
    scaffoldBackgroundColor: skin.background,
    textTheme: textTheme,
    dividerColor: skin.divider,
    appBarTheme: AppBarTheme(
      backgroundColor: skin.background,
      foregroundColor: skin.heading,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: skin.heading,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: skin.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: skin.button,
        foregroundColor: skin.buttonText,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: skin.heading,
        side: BorderSide(color: skin.divider, width: 2),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: skin.heading),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: skin.isDark ? skin.card : skin.background.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: TextStyle(color: skin.subText),
      hintStyle: TextStyle(color: skin.subText),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: skin.card,
      selectedColor: skin.buttonSoft,
      side: BorderSide(color: skin.divider),
      labelStyle: textTheme.labelLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w700),
      checkmarkColor: skin.heading,
      shape: const StadiumBorder(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: skin.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: skin.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: skin.card,
      indicatorColor: skin.buttonSoft,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? skin.heading : skin.subText,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelSmall?.copyWith(
          color: states.contains(WidgetState.selected) ? skin.heading : skin.subText,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: skin.button,
      foregroundColor: skin.buttonText,
      shape: const StadiumBorder(),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? skin.buttonText : skin.subText,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? skin.button : skin.divider,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: skin.button,
      thumbColor: skin.button,
      inactiveTrackColor: skin.divider,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: skin.heading,
      contentTextStyle: TextStyle(color: skin.buttonText),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
