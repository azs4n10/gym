import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/seed/foods_seed.dart';
import '../../l10n/strings.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../state/meal_state.dart';
import '../../widgets/emo.dart';
import '../../widgets/pastel_card.dart';
import '../../widgets/stepper_field.dart';

class FoodPickerScreen extends StatefulWidget {
  const FoodPickerScreen({super.key, required this.day, required this.slot});
  final DateTime day;
  final MealSlot slot;

  @override
  State<FoodPickerScreen> createState() => _FoodPickerScreenState();
}

class _FoodPickerScreenState extends State<FoodPickerScreen> {
  String _query = '';
  FoodTag? _tag;
  late MealSlot _slot = widget.slot;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final meal = context.watch<MealState>();
    final t = Theme.of(context).textTheme;
    final list = meal.foods.where((f) {
      if (_tag != null && FoodTag.parse(f.tag) != _tag) return false;
      if (_query.isNotEmpty && !foodMatches(f, _query)) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<MealSlot>(
            value: _slot,
            style: t.titleLarge?.copyWith(color: skin.heading, fontWeight: FontWeight.w800),
            dropdownColor: skin.card,
            items: [
              for (final s in MealSlot.values)
                DropdownMenuItem(
                  value: s,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [EmoIcon(s.emo, size: 20), const SizedBox(width: 6), Text(s.label(l))],
                  ),
                ),
            ],
            onChanged: (s) => setState(() => _slot = s ?? _slot),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'food-fab',
        onPressed: () => _addCustom(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.custom),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: Text(l.all),
                  selected: _tag == null,
                  onSelected: (_) => setState(() => _tag = null),
                ),
                for (final g in FoodTag.values) ...[
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(g.label(l)),
                    selected: _tag == g,
                    onSelected: (_) => setState(() => _tag = g),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyHint(emo: Emo.search, text: l.notFound)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final f = list[i];
                      return PastelCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        onTap: () => _pickServings(context, f),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(foodName(f, l),
                                      style: t.bodyLarge?.copyWith(
                                          color: skin.text, fontWeight: FontWeight.w800)),
                                  Text(
                                    '${foodServing(f, l)} · P${fmtKg(f.protein)} F${fmtKg(f.fat)} C${fmtKg(f.carbs)}',
                                    style: t.bodySmall?.copyWith(color: skin.subText),
                                  ),
                                ],
                              ),
                            ),
                            Text('${f.kcal.round()}',
                                style: t.titleMedium?.copyWith(
                                    color: skin.heading, fontWeight: FontWeight.w900)),
                            Text(' kcal', style: t.labelSmall?.copyWith(color: skin.subText)),
                            const SizedBox(width: 6),
                            if (f.isCustom)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: l.remove,
                                icon: Icon(Icons.delete_outline_rounded, color: skin.subText, size: 20),
                                onPressed: () => meal.deleteFoodFromLibrary(f),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickServings(BuildContext context, Food f) async {
    final meal = context.read<MealState>();
    var servings = 1.0;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final skin = ctx.skin;
          final l = ctx.l;
          final t = Theme.of(ctx).textTheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(foodName(f, l),
                    style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
                Text(l.oneServing(foodServing(f, l)), style: t.bodySmall?.copyWith(color: skin.subText)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(l.amount, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    StepperField(
                      value: servings, step: 0.5, unit: l.servingsUnit, min: 0.25, max: 20, width: 150,
                      onChanged: (v) => setSheet(() => servings = v),
                    ),
                    const Spacer(),
                    Text('${(f.kcal * servings).round()} kcal',
                        style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'P ${fmtKg(f.protein * servings)}g · F ${fmtKg(f.fat * servings)}g · C ${fmtKg(f.carbs * servings)}g',
                  style: t.bodySmall?.copyWith(color: skin.subText),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l.addTo(_slot.label(l))),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok == true && context.mounted) {
      final l = context.read<AppState>().l;
      await meal.addFood(widget.day, _slot, f, servings);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.added)),
        );
      }
    }
  }

  Future<void> _addCustom(BuildContext context) async {
    final meal = context.read<MealState>();
    final l = context.read<AppState>().l;
    final nameC = TextEditingController(text: _query);
    final servingC = TextEditingController(text: l.isJa ? '1食' : '1 serving');
    var kcal = 0.0, p = 0.0, f = 0.0, c = 0.0;
    var tag = _tag ?? FoodTag.dish;
    var saveToLibrary = true;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final skin = ctx.skin;
          final t = Theme.of(ctx).textTheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.custom,
                      style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextField(controller: nameC, decoration: InputDecoration(hintText: l.name)),
                  const SizedBox(height: 8),
                  TextField(controller: servingC, decoration: InputDecoration(hintText: l.servingHint)),
                  const SizedBox(height: 10),
                  _row('kcal', StepperField(value: kcal, step: 10, decimals: 0, max: 5000, onChanged: (v) => setSheet(() => kcal = v))),
                  _row('P (g)', StepperField(value: p, step: 1, max: 500, onChanged: (v) => setSheet(() => p = v))),
                  _row('F (g)', StepperField(value: f, step: 1, max: 500, onChanged: (v) => setSheet(() => f = v))),
                  _row('C (g)', StepperField(value: c, step: 1, max: 1000, onChanged: (v) => setSheet(() => c = v))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final g in FoodTag.values)
                        ChoiceChip(
                          label: Text(g.label(l)),
                          selected: tag == g,
                          onSelected: (_) => setSheet(() => tag = g),
                        ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.saveToList),
                    value: saveToLibrary,
                    onChanged: (v) => setSheet(() => saveToLibrary = v),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.addTo(_slot.label(l))),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final name = nameC.text.trim();
    final serving = servingC.text.trim().isEmpty ? (l.isJa ? '1食' : '1 serving') : servingC.text.trim();
    nameC.dispose();
    servingC.dispose();
    if (ok != true || name.isEmpty || !context.mounted) return;

    if (saveToLibrary) {
      final food = await meal.addFoodToLibrary(
        name: name, serving: serving, kcal: kcal, protein: p, fat: f, carbs: c, tag: tag,
      );
      await meal.addFood(widget.day, _slot, food, 1);
    } else {
      await meal.addCustomItem(widget.day, _slot, name: name, kcal: kcal, protein: p, fat: f, carbs: c);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.added)),
      );
    }
  }

  Widget _row(String label, Widget field) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 56, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            field,
          ],
        ),
      );
}
