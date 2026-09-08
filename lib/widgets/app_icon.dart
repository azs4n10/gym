import 'package:flutter/material.dart';

import '../state/app_state.dart';

const _family = 'PhosphorDuotone';

/// Phosphor Icons (MIT) duotone glyphs, bundled in assets/fonts.
/// Each icon is two glyphs: a soft secondary layer under the primary strokes.
enum Ic {
  chest(IconData(0xe2a9, fontFamily: _family), IconData(0xe2a8, fontFamily: _family)),
  back(IconData(0xea6f, fontFamily: _family), IconData(0xea6e, fontFamily: _family)),
  shoulders(IconData(0xecff, fontFamily: _family), IconData(0xecfe, fontFamily: _family)),
  arms(IconData(0xe57b, fontFamily: _family), IconData(0xe57a, fontFamily: _family)),
  legs(IconData(0xea89, fontFamily: _family), IconData(0xea88, fontFamily: _family)),
  glutes(IconData(0xe75f, fontFamily: _family), IconData(0xe75e, fontFamily: _family)),
  core(IconData(0xe46b, fontFamily: _family), IconData(0xe46a, fontFamily: _family)),
  breakfast(IconData(0xe1c3, fontFamily: _family), IconData(0xe1c2, fontFamily: _family)),
  lunch(IconData(0xeaa5, fontFamily: _family), IconData(0xeaa4, fontFamily: _family)),
  dinner(IconData(0xe765, fontFamily: _family), IconData(0xe764, fontFamily: _family)),
  snack(IconData(0xe6cb, fontFamily: _family), IconData(0xe6ca, fontFamily: _family)),
  meals(IconData(0xe263, fontFamily: _family), IconData(0xe262, fontFamily: _family)),
  picks(IconData(0xe6a3, fontFamily: _family), IconData(0xe6a2, fontFamily: _family)),
  trend(IconData(0xe157, fontFamily: _family), IconData(0xe156, fontFamily: _family)),
  history(IconData(0xe34d, fontFamily: _family), IconData(0xe34c, fontFamily: _family)),
  day(IconData(0xe3e3, fontFamily: _family), IconData(0xe3e2, fontFamily: _family)),
  language(IconData(0xe289, fontFamily: _family), IconData(0xe288, fontFamily: _family)),
  profile(IconData(0xe4c5, fontFamily: _family), IconData(0xe4c4, fontFamily: _family)),
  goal(IconData(0xe47d, fontFamily: _family), IconData(0xe47c, fontFamily: _family)),
  targets(IconData(0xeaa5, fontFamily: _family), IconData(0xeaa4, fontFamily: _family)),
  theme(IconData(0xe6c9, fontFamily: _family), IconData(0xe6c8, fontFamily: _family)),
  health(IconData(0xe2ad, fontFamily: _family), IconData(0xe2ac, fontFamily: _family)),
  fire(IconData(0xe243, fontFamily: _family), IconData(0xe242, fontFamily: _family)),
  done(IconData(0xe185, fontFamily: _family), IconData(0xe184, fontFamily: _family)),
  greeting(IconData(0xeacd, fontFamily: _family), IconData(0xeacc, fontFamily: _family)),
  cardio(IconData(0xe731, fontFamily: _family), IconData(0xe730, fontFamily: _family)),
  workout(IconData(0xe0b7, fontFamily: _family), IconData(0xe0b6, fontFamily: _family)),
  body(IconData(0xe3a9, fontFamily: _family), IconData(0xe3a8, fontFamily: _family)),
  fat(IconData(0xe211, fontFamily: _family), IconData(0xe210, fontFamily: _family)),
  avg(IconData(0xe1ab, fontFamily: _family), IconData(0xe1aa, fontFamily: _family)),
  flat(IconData(0xe32b, fontFamily: _family), IconData(0xe32a, fontFamily: _family)),
  down(IconData(0xe4ad, fontFamily: _family), IconData(0xe4ac, fontFamily: _family)),
  up(IconData(0xe4af, fontFamily: _family), IconData(0xe4ae, fontFamily: _family)),
  streak(IconData(0xe243, fontFamily: _family), IconData(0xe242, fontFamily: _family)),
  weeks(IconData(0xe713, fontFamily: _family), IconData(0xe712, fontFamily: _family)),
  month(IconData(0xe109, fontFamily: _family), IconData(0xe108, fontFamily: _family)),
  search(IconData(0xe30d, fontFamily: _family), IconData(0xe30c, fontFamily: _family)),
  empty(IconData(0xe62b, fontFamily: _family), IconData(0xe62a, fontFamily: _family)),
  mood1(IconData(0xe443, fontFamily: _family), IconData(0xe442, fontFamily: _family)),
  mood2(IconData(0xe43f, fontFamily: _family), IconData(0xe43e, fontFamily: _family)),
  mood3(IconData(0xe43b, fontFamily: _family), IconData(0xe43a, fontFamily: _family)),
  mood4(IconData(0xe437, fontFamily: _family), IconData(0xe436, fontFamily: _family)),
  mood5(IconData(0xe667, fontFamily: _family), IconData(0xe666, fontFamily: _family));

  const Ic(this.primaryData, this.secondaryData);
  final IconData primaryData;
  final IconData secondaryData;
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.ic, {super.key, this.size = 20, this.color});

  final Ic ic;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final ink = color ?? skin.heading;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(ic.secondaryData, size: size, color: skin.button.withValues(alpha: 0.45)),
          Icon(ic.primaryData, size: size, color: ink),
        ],
      ),
    );
  }
}

Ic moodIc(int mood) => switch (mood) {
      1 => Ic.mood1,
      2 => Ic.mood2,
      3 => Ic.mood3,
      4 => Ic.mood4,
      _ => Ic.mood5,
    };
