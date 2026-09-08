import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/seed/foods_seed.dart';
import '../../l10n/strings.dart';
import '../../models/enums.dart';
import '../../services/health_sync.dart';
import '../../services/nutrition.dart';
import '../../services/suggestions.dart';
import '../../state/app_state.dart';
import '../../state/body_state.dart';
import '../../state/meal_state.dart';
import '../../widgets/pastel_card.dart';
import '../../widgets/ring_progress.dart';
import 'food_picker_screen.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  DateTime _day = dayOf(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final skin = app.skin;
    final l = app.l;
    final meal = context.watch<MealState>();
    final body = context.watch<BodyState>();
    final t = Theme.of(context).textTheme;
    final target = computeTargets(app.profile, body.latestWeight);
    final eaten = meal.totalsOn(_day);
    final remain = target - eaten;
    final ideas = suggestMeals(
      foods: meal.foods,
      target: target,
      eaten: eaten,
      goal: app.profile.goal,
      count: 4,
    );
    final isToday = _day == dayOf(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
            ),
            Text(isToday ? l.todayMeals : l.dateLong(_day)),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: isToday ? null : () => setState(() => _day = _day.add(const Duration(days: 1))),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          PastelCard(
            child: Row(
              children: [
                RingProgress(
                  value: target.kcal == 0 ? 0 : eaten.kcal / target.kcal,
                  color: skin.accent,
                  trackColor: skin.divider,
                  size: 104,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${eaten.kcal.round()}',
                          style: t.titleLarge?.copyWith(
                              color: skin.heading, fontWeight: FontWeight.w800)),
                      Text('/${target.kcal.round()}',
                          style: t.labelSmall?.copyWith(color: skin.subText)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remain.kcal >= 0
                            ? l.kcalLeft(remain.kcal.round())
                            : l.kcalOver((-remain.kcal).round()),
                        style: t.titleMedium?.copyWith(
                            color: remain.kcal >= 0 ? skin.heading : const Color(0xFFE05A7A),
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      MacroBar(label: l.p, value: eaten.protein, target: target.protein,
                          color: skin.button, trackColor: skin.divider, textColor: skin.text),
                      const SizedBox(height: 6),
                      MacroBar(label: l.f, value: eaten.fat, target: target.fat,
                          color: skin.accent, trackColor: skin.divider, textColor: skin.text),
                      const SizedBox(height: 6),
                      MacroBar(label: l.c, value: eaten.carbs, target: target.carbs,
                          color: skin.heading, trackColor: skin.divider, textColor: skin.text),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final slot in MealSlot.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SlotCard(day: _day, slot: slot, detail: meal.mealFor(_day, slot)),
            ),
          const SizedBox(height: 8),
          SectionTitle(l.ideas, icon: Icons.auto_awesome_rounded),
          PastelCard(
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
            child: Column(
              children: [
                for (final m in ideas)
                  Row(
                    children: [
                      Expanded(
                        child: Text(foodName(m.food, l),
                            style: t.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600, color: skin.text)),
                      ),
                      Text('${m.food.kcal.round()} · P${m.food.protein.round()}',
                          style: t.bodySmall?.copyWith(color: skin.subText)),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.add_circle_rounded, color: skin.button),
                        onPressed: () => meal.addFood(_day, MealSlot.forNow(), m.food, 1),
                      ),
                    ],
                  ),
                if (ideas.isEmpty)
                  Text(l.foodListEmpty, style: TextStyle(color: skin.subText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.day, required this.slot, required this.detail});
  final DateTime day;
  final MealSlot slot;
  final MealDetail? detail;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final skin = app.skin;
    final l = app.l;
    final meal = context.read<MealState>();
    final t = Theme.of(context).textTheme;
    final d = detail;
    final totals = d?.totals ?? const Macros();
    final canSync = app.profile.healthSync && HealthSync.instance.isSupported;

    return PastelCard(
      padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(slot.icon, size: 20, color: skin.heading),
              const SizedBox(width: 6),
              Text(slot.label(l),
                  style: t.titleSmall?.copyWith(color: skin.heading, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (d != null)
                Text('${totals.kcal.round()} kcal',
                    style: t.bodyMedium?.copyWith(color: skin.text, fontWeight: FontWeight.w700)),
              if (d != null && canSync)
                IconButton(
                  tooltip: d.meal.healthSynced ? l.synced : l.sync,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    d.meal.healthSynced ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: skin.accent,
                    size: 20,
                  ),
                  onPressed: d.meal.healthSynced ? null : () => meal.syncMealToHealth(d),
                ),
              IconButton(
                tooltip: l.add,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.add_circle_rounded, color: skin.button),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FoodPickerScreen(day: day, slot: slot)),
                ),
              ),
            ],
          ),
          if (d != null)
            for (final item in d.items)
              Dismissible(
                key: ValueKey('item-${item.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => meal.deleteItem(item),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.delete_outline_rounded, color: skin.subText),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.servings == 1
                              ? foodNameByStored(item.name, l)
                              : '${foodNameByStored(item.name, l)} ×${fmtKg(item.servings)}',
                          style: t.bodyMedium?.copyWith(color: skin.text, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        l.macroLine(item.kcal.round(), item.protein.round(), item.fat.round(), item.carbs.round()),
                        style: t.bodySmall?.copyWith(color: skin.subText),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
