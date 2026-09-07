import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../models/enums.dart';
import '../services/health_sync.dart';
import '../services/nutrition.dart';

class MealDetail {
  const MealDetail({required this.meal, required this.items});
  final Meal meal;
  final List<MealItem> items;

  MealSlot get slot => MealSlot.parse(meal.slot);

  Macros get totals => items.fold(
        const Macros(),
        (m, i) => m +
            Macros(kcal: i.kcal, protein: i.protein, fat: i.fat, carbs: i.carbs),
      );
}

class MealState extends ChangeNotifier {
  MealState(this.db);

  final AppDatabase db;
  List<Food> _foods = [];
  List<MealDetail> _meals = [];

  List<Food> get foods => _foods;
  List<MealDetail> get meals => _meals;

  Future<void> load() async {
    _foods = await (db.select(db.foods)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final meals = await (db.select(db.meals)
          ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.asc(t.loggedAt)]))
        .get();
    final items = await (db.select(db.mealItems)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final by = <int, List<MealItem>>{};
    for (final i in items) {
      by.putIfAbsent(i.mealId, () => []).add(i);
    }
    _meals = [
      for (final m in meals) MealDetail(meal: m, items: by[m.id] ?? const []),
    ];
    notifyListeners();
  }

  List<MealDetail> mealsOn(DateTime day) {
    final d = dayOf(day);
    final list = _meals.where((m) => dayOf(m.meal.date) == d).toList()
      ..sort((a, b) => a.slot.index.compareTo(b.slot.index));
    return list;
  }

  MealDetail? mealFor(DateTime day, MealSlot slot) {
    for (final m in mealsOn(day)) {
      if (m.slot == slot) return m;
    }
    return null;
  }

  Macros totalsOn(DateTime day) =>
      mealsOn(day).fold(const Macros(), (m, d) => m + d.totals);

  Set<DateTime> get loggedDays => _meals.map((m) => dayOf(m.meal.date)).toSet();

  Future<int> _ensureMeal(DateTime day, MealSlot slot) async {
    final existing = mealFor(day, slot);
    if (existing != null) return existing.meal.id;
    return db.into(db.meals).insert(MealsCompanion.insert(
          date: dayOf(day),
          slot: slot.name,
          loggedAt: DateTime.now(),
        ));
  }

  Future<void> addFood(DateTime day, MealSlot slot, Food food,
      double servings) async {
    final mealId = await _ensureMeal(day, slot);
    await db.into(db.mealItems).insert(MealItemsCompanion.insert(
          mealId: mealId,
          foodId: Value(food.id),
          name: food.name,
          servings: servings,
          kcal: food.kcal * servings,
          protein: food.protein * servings,
          fat: food.fat * servings,
          carbs: food.carbs * servings,
        ));
    await load();
  }

  Future<void> addCustomItem(
    DateTime day,
    MealSlot slot, {
    required String name,
    required double kcal,
    required double protein,
    required double fat,
    required double carbs,
  }) async {
    final mealId = await _ensureMeal(day, slot);
    await db.into(db.mealItems).insert(MealItemsCompanion.insert(
          mealId: mealId,
          name: name,
          servings: 1,
          kcal: kcal,
          protein: protein,
          fat: fat,
          carbs: carbs,
        ));
    await load();
  }

  Future<void> deleteItem(MealItem item) async {
    await (db.delete(db.mealItems)..where((t) => t.id.equals(item.id))).go();
    final rest = await (db.select(db.mealItems)
          ..where((t) => t.mealId.equals(item.mealId)))
        .get();
    if (rest.isEmpty) {
      await (db.delete(db.meals)..where((t) => t.id.equals(item.mealId))).go();
    }
    await load();
  }

  Future<Food> addFoodToLibrary({
    required String name,
    required String serving,
    required double kcal,
    required double protein,
    required double fat,
    required double carbs,
    required FoodTag tag,
  }) async {
    final id = await db.into(db.foods).insert(FoodsCompanion.insert(
          name: name,
          serving: serving,
          kcal: kcal,
          protein: protein,
          fat: fat,
          carbs: carbs,
          tag: tag.name,
          isCustom: const Value(true),
        ));
    await load();
    return _foods.firstWhere((f) => f.id == id);
  }

  Future<void> deleteFoodFromLibrary(Food f) async {
    await (db.delete(db.foods)..where((t) => t.id.equals(f.id))).go();
    await load();
  }

  Future<bool> syncMealToHealth(MealDetail m) async {
    if (!HealthSync.instance.isSupported) return false;
    final t = m.totals;
    final ok = await HealthSync.instance.writeMeal(
      at: m.meal.loggedAt,
      slot: m.slot,
      kcal: t.kcal,
      protein: t.protein,
      fat: t.fat,
      carbs: t.carbs,
      name: m.items.map((i) => i.name).join('、'),
    );
    if (ok) {
      await (db.update(db.meals)..where((x) => x.id.equals(m.meal.id)))
          .write(const MealsCompanion(healthSynced: Value(true)));
      await load();
    }
    return ok;
  }
}
