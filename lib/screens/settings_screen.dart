import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../services/health_sync.dart';
import '../services/nutrition.dart';
import '../state/app_state.dart';
import '../state/body_state.dart';
import '../theme/skin.dart';
import '../widgets/app_icon.dart';
import '../widgets/pastel_card.dart';
import '../widgets/stepper_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: context.read<AppState>().profile.nickname);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final skin = app.skin;
    final l = app.l;
    final p = app.profile;
    final body = context.watch<BodyState>();
    final t = Theme.of(context).textTheme;
    final auto = computeTargets(
      p.copyWith(clearKcal: true, clearMacros: true),
      body.latestWeight,
    );
    final manual = p.kcalOverride != null;
    final targets = computeTargets(p, body.latestWeight);
    final health = HealthSync.instance;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          SectionTitle(l.language, ic: Ic.language),
          PastelCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'ja', label: Text('日本語')),
              ],
              selected: {p.lang},
              onSelectionChanged: (s) => app.setLang(s.first),
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(l.profile, ic: Ic.profile),
          PastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l.name),
                  onChanged: (v) => app.update(p.copyWith(nickname: v.trim())),
                ),
                const SizedBox(height: 12),
                SegmentedButton<Sex>(
                  showSelectedIcon: false,
                  segments: [
                    for (final s in Sex.values) ButtonSegment(value: s, label: Text(s.label(l))),
                  ],
                  selected: {p.sex},
                  onSelectionChanged: (s) => app.update(p.copyWith(sex: s.first)),
                ),
                const SizedBox(height: 12),
                _fieldRow(l.birthYear, StepperField(
                  value: p.birthYear.toDouble(), step: 1, decimals: 0,
                  min: 1930, max: DateTime.now().year.toDouble(), width: 150,
                  onChanged: (v) => app.update(p.copyWith(birthYear: v.round())),
                )),
                _fieldRow(l.height, StepperField(
                  value: p.heightCm, step: 0.5, unit: 'cm', min: 100, max: 250, width: 150,
                  onChanged: (v) => app.update(p.copyWith(heightCm: v)),
                )),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(l.goal, ic: Ic.goal),
          PastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final g in Goal.values)
                      ChoiceChip(
                        label: Text(g.label(l)),
                        selected: p.goal == g,
                        onSelected: (_) => app.update(p.copyWith(goal: g)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _label(context, l.activity),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in ActivityLevel.values)
                      ChoiceChip(
                        label: Text(a.label(l)),
                        selected: p.activity == a,
                        onSelected: (_) => app.update(p.copyWith(activity: a)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _fieldRow(l.daysPerWeek, StepperField(
                  value: p.weeklyGoalDays.toDouble(), step: 1, decimals: 0,
                  min: 1, max: 7, width: 150,
                  onChanged: (v) => app.update(p.copyWith(weeklyGoalDays: v.round())),
                )),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(l.targets, ic: Ic.targets),
          PastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.manual),
                  value: manual,
                  onChanged: (v) => app.update(v
                      ? p.copyWith(
                          kcalOverride: auto.kcal.round(),
                          proteinOverride: auto.protein.roundToDouble(),
                          fatOverride: auto.fat.roundToDouble(),
                          carbsOverride: auto.carbs.roundToDouble(),
                        )
                      : p.copyWith(clearKcal: true, clearMacros: true)),
                ),
                if (manual) ...[
                  _fieldRow(l.calories, StepperField(
                    value: targets.kcal, step: 50, decimals: 0, unit: 'kcal', min: 800, max: 6000, width: 160,
                    onChanged: (v) => app.update(p.copyWith(kcalOverride: v.round())),
                  )),
                  _fieldRow(l.protein, StepperField(
                    value: targets.protein, step: 5, decimals: 0, unit: 'g', max: 500, width: 160,
                    onChanged: (v) => app.update(p.copyWith(proteinOverride: v)),
                  )),
                  _fieldRow(l.fat, StepperField(
                    value: targets.fat, step: 5, decimals: 0, unit: 'g', max: 300, width: 160,
                    onChanged: (v) => app.update(p.copyWith(fatOverride: v)),
                  )),
                  _fieldRow(l.carbs, StepperField(
                    value: targets.carbs, step: 10, decimals: 0, unit: 'g', max: 1000, width: 160,
                    onChanged: (v) => app.update(p.copyWith(carbsOverride: v)),
                  )),
                ] else
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _chip(context, '${targets.kcal.round()} kcal'),
                      _chip(context, 'P ${targets.protein.round()}'),
                      _chip(context, 'F ${targets.fat.round()}'),
                      _chip(context, 'C ${targets.carbs.round()}'),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(l.theme, ic: Ic.theme),
          PastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in allSkins) _SkinSwatch(skin: s, selected: s.id == p.skinId),
                  ],
                ),
                const SizedBox(height: 14),
                _label(context, l.font),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'standard', label: Text(l.fontStandard)),
                    ButtonSegment(value: 'rounded', label: Text(l.fontRounded)),
                  ],
                  selected: {p.font},
                  onSelectionChanged: (s) => app.setFont(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(l.health, ic: Ic.health),
          PastelCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(health.isSupported ? health.platformName(l) : l.healthNotSupported),
              value: p.healthSync,
              onChanged: !health.isSupported
                  ? null
                  : (v) async {
                      if (v) {
                        final ok = await health.requestPermissions();
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.permissionDenied)),
                          );
                          return;
                        }
                      }
                      await app.update(p.copyWith(healthSync: v));
                    },
            ),
          ),
          const SizedBox(height: 14),
          Text(l.foodDisclaimer, style: t.bodySmall?.copyWith(color: skin.subText)),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final skin = context.skin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(color: skin.subText, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _fieldRow(String label, Widget field) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            field,
          ],
        ),
      );

  Widget _chip(BuildContext context, String text) {
    final skin = context.skin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: skin.buttonSoft, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: skin.heading, fontWeight: FontWeight.w700)),
    );
  }
}

class _SkinSwatch extends StatelessWidget {
  const _SkinSwatch({required this.skin, required this.selected});
  final Skin skin;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final current = context.skin;
    final l = context.l;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.read<AppState>().setSkin(skin.id),
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: skin.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? current.heading : current.divider,
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(skin.button),
                _dot(skin.accent),
                _dot(skin.heading),
              ],
            ),
            const SizedBox(height: 6),
            Text(l.isJa ? skin.nameJa : skin.name,
                textAlign: TextAlign.center,
                style: TextStyle(color: skin.text, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}
