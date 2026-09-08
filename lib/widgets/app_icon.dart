import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/app_state.dart';

/// Phosphor Icons (MIT) in the duotone style, tinted with the current skin.
enum Ic {
  chest(PhosphorIcons.heart),
  back(PhosphorIcons.butterfly),
  shoulders(PhosphorIcons.personArmsSpread),
  arms(PhosphorIcons.handFist),
  legs(PhosphorIcons.footprints),
  glutes(PhosphorIcons.flower),
  core(PhosphorIcons.star),
  breakfast(PhosphorIcons.coffee),
  lunch(PhosphorIcons.bowlFood),
  dinner(PhosphorIcons.cookingPot),
  snack(PhosphorIcons.cookie),
  meals(PhosphorIcons.forkKnife),
  picks(PhosphorIcons.sparkle),
  trend(PhosphorIcons.chartLineUp),
  history(PhosphorIcons.notePencil),
  day(PhosphorIcons.pushPin),
  language(PhosphorIcons.globe),
  profile(PhosphorIcons.userCircle),
  goal(PhosphorIcons.target),
  targets(PhosphorIcons.bowlFood),
  theme(PhosphorIcons.palette),
  health(PhosphorIcons.heartbeat),
  fire(PhosphorIcons.fire),
  done(PhosphorIcons.checkCircle),
  greeting(PhosphorIcons.flowerTulip),
  cardio(PhosphorIcons.personSimpleRun),
  workout(PhosphorIcons.barbell),
  body(PhosphorIcons.person),
  fat(PhosphorIcons.drop),
  avg(PhosphorIcons.cloud),
  flat(PhosphorIcons.minus),
  down(PhosphorIcons.trendDown),
  up(PhosphorIcons.trendUp),
  streak(PhosphorIcons.fire),
  weeks(PhosphorIcons.calendarCheck),
  month(PhosphorIcons.calendar),
  search(PhosphorIcons.magnifyingGlass),
  empty(PhosphorIcons.ghost),
  mood1(PhosphorIcons.smileyXEyes),
  mood2(PhosphorIcons.smileySad),
  mood3(PhosphorIcons.smileyMeh),
  mood4(PhosphorIcons.smiley),
  mood5(PhosphorIcons.smileyWink);

  const Ic(this._build);
  final PhosphorIconData Function([PhosphorIconsStyle style]) _build;

  IconData get duotone => _build(PhosphorIconsStyle.duotone);
  IconData get fill => _build(PhosphorIconsStyle.fill);
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.ic, {super.key, this.size = 20, this.color});

  final Ic ic;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return PhosphorIcon(
      ic.duotone,
      size: size,
      color: color ?? skin.heading,
      duotoneSecondaryColor: skin.button,
      duotoneSecondaryOpacity: 0.45,
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
