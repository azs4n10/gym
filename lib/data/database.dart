import 'package:drift/drift.dart';

import 'seed/exercises_seed.dart';
import 'seed/foods_seed.dart';

part 'database.g.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get mood => integer().nullable()();
  BoolColumn get healthSynced => boolean().withDefault(const Constant(false))();
}

class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()
      .references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setIndex => integer()();
  RealColumn get weightKg => real()();
  IntColumn get reps => integer()();
}

@DataClassName('CardioEntry')
class CardioEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()
      .references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();
  RealColumn get durationMin => real()();
  RealColumn get distanceKm => real().nullable()();
  IntColumn get kcal => integer().nullable()();
}

class BodyLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();
  RealColumn get bodyFatPct => real().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get healthSynced => boolean().withDefault(const Constant(false))();
}

class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get serving => text()();
  RealColumn get kcal => real()();
  RealColumn get protein => real()();
  RealColumn get fat => real()();
  RealColumn get carbs => real()();
  TextColumn get tag => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}

class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get slot => text()();
  DateTimeColumn get loggedAt => dateTime()();
  BoolColumn get healthSynced => boolean().withDefault(const Constant(false))();
}

class MealItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId =>
      integer().references(Meals, #id, onDelete: KeyAction.cascade)();
  IntColumn get foodId => integer().nullable()();
  TextColumn get name => text()();
  RealColumn get servings => real()();
  RealColumn get kcal => real()();
  RealColumn get protein => real()();
  RealColumn get fat => real()();
  RealColumn get carbs => real()();
}

@DriftDatabase(tables: [
  Exercises,
  WorkoutSessions,
  WorkoutSets,
  CardioEntries,
  BodyLogs,
  Foods,
  Meals,
  MealItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await batch((b) {
            b.insertAll(exercises, seedExercises);
            b.insertAll(foods, seedFoods);
          });
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);
