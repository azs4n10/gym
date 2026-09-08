import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Bundled Fluent Emoji (MIT) so every platform shows the same artwork.
enum Emo {
  cherryBlossom('cherry_blossom'),
  butterfly('butterfly'),
  ribbon('ribbon'),
  biceps('biceps'),
  leg('leg'),
  peach('peach'),
  star('star'),
  cooking('cooking'),
  bento('bento'),
  pot('pot'),
  cookie('cookie'),
  sparkles('sparkles'),
  chart('chart'),
  memo('memo'),
  pushpin('pushpin'),
  globe('globe'),
  glowingStar('glowing_star'),
  palette('palette'),
  growingHeart('growing_heart'),
  fire('fire'),
  tulip('tulip'),
  running('running'),
  lifting('lifting'),
  moon('moon'),
  cloud('cloud'),
  dove('dove'),
  seedling('seedling'),
  search('search'),
  bubbles('bubbles'),
  dizzy('dizzy'),
  exhaling('exhaling'),
  smile('smile'),
  smilingEyes('smiling_eyes'),
  hearts('hearts'),
  scale('scale');

  const Emo(this.file);
  final String file;

  String get asset => 'assets/emoji/$file.svg';
}

class EmoIcon extends StatelessWidget {
  const EmoIcon(this.emo, {super.key, this.size = 20, this.opacity = 1});

  final Emo emo;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final img = SvgPicture.asset(emo.asset, width: size, height: size);
    return opacity == 1 ? img : Opacity(opacity: opacity, child: img);
  }
}

Emo moodEmo(int mood) => switch (mood) {
      1 => Emo.dizzy,
      2 => Emo.exhaling,
      3 => Emo.smile,
      4 => Emo.smilingEyes,
      _ => Emo.hearts,
    };
