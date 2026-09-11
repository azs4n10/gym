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
import '../../theme/skin.dart';
import '../../state/body_state.dart';
import '../../state/meal_state.dart';
import '../../widgets/cover.dart';
import '../../widgets/hero_card.dart';
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
    final ratio = target.kcal == 0 ? 0.0 : (eaten.kcal / target.kcal).clamp(0.0, 1.0);
    final onHero = skin.buttonText;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'meals-fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FoodPickerScreen(day: _day, slot: MealSlot.forNow()),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.logFood),
      ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          PageHeader(
            isToday ? l.todayMeals : l.dateLong(_day),
            actions: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: skin.heading),
                onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: skin.heading),
                onPressed: isToday ? null : () => setState(() => _day = _day.add(const Duration(days: 1))),
              ),
            ],
          ),
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.calorieGoal,
                    style: t.labelLarge?.copyWith(
                        color: onHero.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${eaten.kcal.round()}',
                        style: t.displayMedium?.copyWith(
                            color: onHero, fontWeight: FontWeight.w800, height: 1)),
                    const SizedBox(width: 6),
                    Text('/ ${target.kcal.round()} kcal',
                        style: t.titleSmall?.copyWith(color: onHero.withValues(alpha: 0.85))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        remain.kcal >= 0
                            ? l.kcalLeft(remain.kcal.round())
                            : l.kcalOver((-remain.kcal).round()),
                        style: TextStyle(color: onHero, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 500),
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      color: onHero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MacroCard(label: l.carbs, value: eaten.carbs, target: target.carbs, color: skin.heading)),
              const SizedBox(width: 8),
              Expanded(child: _MacroCard(label: l.protein, value: eaten.protein, target: target.protein, color: skin.button)),
              const SizedBox(width: 8),
              Expanded(child: _MacroCard(label: l.fat, value: eaten.fat, target: target.fat, color: skin.accent)),
            ],
          ),
          const SizedBox(height: 20),
          Text(l.meals,
              style: t.titleLarge?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final slot in MealSlot.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SlotCard(day: _day, slot: slot, detail: meal.mealFor(_day, slot)),
            ),
          const SizedBox(height: 12),
          Text(l.ideas,
              style: t.titleLarge?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
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
                        icon: Icon(Icons.add_circle_rounded, color: skin.heading),
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
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final double value;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    final pct = target <= 0 ? 0 : (value / target * 100).round();
    return PastelCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: t.labelMedium?.copyWith(color: skin.subText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${value.round()}g',
              style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Center(
            child: RingProgress(
              value: target <= 0 ? 0 : (value / target).clamp(0.0, 1.0),
              color: color,
              trackColor: skin.divider,
              size: 48,
              stroke: 5,
              child: Text('$pct%',
                  style: TextStyle(
                      color: skin.subText, fontSize: 11, fontWeight: FontWeight.w800)),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FoodPickerScreen(day: day, slot: slot)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CoverThumb(ic: slot.ic, tint: _slotTint(skin, slot), size: 58),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot.label(l),
                        style: t.labelSmall
                            ?.copyWith(color: skin.subText, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      d == null
                          ? l.noRecords
                          : d.items.map((i) => foodNameByStored(i.name, l)).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyLarge?.copyWith(
                          color: d == null ? skin.subText : skin.text,
                          fontWeight: FontWeight.w700),
                    ),
                    if (d != null)
                      Text('${totals.kcal.round()} kcal',
                          style: t.bodySmall?.copyWith(color: skin.subText)),
                  ],
                ),
              ),
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
              RoundAction(
                icon: d == null ? Icons.add_rounded : Icons.check_rounded,
                background: d == null ? skin.divider : skin.button,
                foreground: d == null ? skin.subText : skin.buttonText,
              ),
            ],
          ),
          if (d != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: [
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
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.servings == 1
                                    ? foodNameByStored(item.name, l)
                                    : '${foodNameByStored(item.name, l)} ×${fmtKg(item.servings)}',
                                style: t.bodySmall?.copyWith(color: skin.text, fontWeight: FontWeight.w600),
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
            ),
        ],
      ),
    );
  }
}

Color _slotTint(Skin skin, MealSlot slot) => switch (slot) {
      MealSlot.breakfast => skin.accent,
      MealSlot.lunch => skin.button,
      MealSlot.dinner => skin.heading,
      MealSlot.snack => Color.lerp(skin.accent, skin.button, 0.5)!,
    };
