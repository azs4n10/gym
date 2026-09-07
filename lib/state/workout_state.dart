import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../models/enums.dart';
import '../services/health_sync.dart';
import '../services/suggestions.dart';

class SessionDetail {
  const SessionDetail({
    required this.session,
    required this.sets,
    required this.cardio,
  });

  final WorkoutSession session;
  final List<WorkoutSet> sets;
  final List<CardioEntry> cardio;

  DateTime get day => dayOf(session.startedAt);
  bool get isEmpty => sets.isEmpty && cardio.isEmpty;

  double get volumeKg =>
      sets.fold(0, (sum, s) => sum + s.weightKg * s.reps);

  List<int> get exerciseOrder {
    final seen = <int>[];
    for (final s in sets) {
      if (!seen.contains(s.exerciseId)) seen.add(s.exerciseId);
    }
    return seen;
  }

  List<WorkoutSet> setsFor(int exerciseId) =>
      sets.where((s) => s.exerciseId == exerciseId).toList()
        ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
}

class WorkoutState extends ChangeNotifier {
  WorkoutState(this.db);

  final AppDatabase db;

  List<Exercise> _exercises = [];
  List<SessionDetail> _sessions = [];
  bool _loaded = false;

  List<Exercise> get exercises => _exercises;
  List<Exercise> get activeExercises =>
      _exercises.where((e) => !e.isArchived).toList();
  List<SessionDetail> get sessions => _sessions;
  bool get loaded => _loaded;

  Exercise? exerciseById(int id) {
    for (final e in _exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  SessionDetail? sessionById(int id) {
    for (final s in _sessions) {
      if (s.session.id == id) return s;
    }
    return null;
  }

  SessionDetail? get openSession {
    for (final s in _sessions) {
      if (s.session.endedAt == null) return s;
    }
    return null;
  }

  Iterable<DateTime> get gymDays =>
      _sessions.where((s) => !s.isEmpty).map((s) => s.day);

  List<SessionDetail> sessionsOn(DateTime day) {
    final d = dayOf(day);
    return _sessions.where((s) => s.day == d).toList();
  }

  Future<void> load() async {
    _exercises = await (db.select(db.exercises)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final sessions = await (db.select(db.workoutSessions)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    final sets = await (db.select(db.workoutSets)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final cardio = await (db.select(db.cardioEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final setsBy = <int, List<WorkoutSet>>{};
    for (final s in sets) {
      setsBy.putIfAbsent(s.sessionId, () => []).add(s);
    }
    final cardioBy = <int, List<CardioEntry>>{};
    for (final c in cardio) {
      cardioBy.putIfAbsent(c.sessionId, () => []).add(c);
    }
    _sessions = [
      for (final s in sessions)
        SessionDetail(
          session: s,
          sets: setsBy[s.id] ?? const [],
          cardio: cardioBy[s.id] ?? const [],
        ),
    ];
    _loaded = true;
    notifyListeners();
  }

  Future<int> startSession({DateTime? at}) async {
    final existing = openSession;
    if (existing != null) return existing.session.id;
    final id = await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(startedAt: at ?? DateTime.now()),
        );
    await load();
    return id;
  }

  Future<void> addSet(int sessionId, int exerciseId,
      {double? weightKg, int? reps}) async {
    final detail = sessionById(sessionId);
    final prev = detail?.setsFor(exerciseId) ?? const [];
    final last = prev.isNotEmpty ? prev.last : lastSetFor(exerciseId);
    await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
          sessionId: sessionId,
          exerciseId: exerciseId,
          setIndex: prev.length + 1,
          weightKg: weightKg ?? last?.weightKg ?? 0,
          reps: reps ?? last?.reps ?? 10,
        ));
    await load();
  }

  Future<void> updateSet(WorkoutSet set, {double? weightKg, int? reps}) async {
    await db.update(db.workoutSets).replace(set.copyWith(
          weightKg: weightKg ?? set.weightKg,
          reps: reps ?? set.reps,
        ));
    await load();
  }

  Future<void> deleteSet(WorkoutSet set) async {
    await (db.delete(db.workoutSets)..where((t) => t.id.equals(set.id))).go();
    final remaining = sessionById(set.sessionId)
            ?.setsFor(set.exerciseId)
            .where((s) => s.id != set.id)
            .toList() ??
        const [];
    for (var i = 0; i < remaining.length; i++) {
      if (remaining[i].setIndex != i + 1) {
        await db
            .update(db.workoutSets)
            .replace(remaining[i].copyWith(setIndex: i + 1));
      }
    }
    await load();
  }

  Future<void> removeExerciseFromSession(int sessionId, int exerciseId) async {
    await (db.delete(db.workoutSets)
          ..where((t) =>
              t.sessionId.equals(sessionId) & t.exerciseId.equals(exerciseId)))
        .go();
    await load();
  }

  Future<void> addCardio(int sessionId, CardioType kind, double durationMin,
      {double? distanceKm, int? kcal}) async {
    await db.into(db.cardioEntries).insert(CardioEntriesCompanion.insert(
          sessionId: sessionId,
          kind: kind.name,
          durationMin: durationMin,
          distanceKm: Value(distanceKm),
          kcal: Value(kcal),
        ));
    await load();
  }

  Future<void> deleteCardio(CardioEntry c) async {
    await (db.delete(db.cardioEntries)..where((t) => t.id.equals(c.id))).go();
    await load();
  }

  Future<void> updateSessionMeta(int sessionId,
      {String? note, int? mood}) async {
    await (db.update(db.workoutSessions)..where((t) => t.id.equals(sessionId)))
        .write(WorkoutSessionsCompanion(
      note: note == null ? const Value.absent() : Value(note),
      mood: mood == null ? const Value.absent() : Value(mood),
    ));
    await load();
  }

  Future<bool?> finishSession(int sessionId, {bool syncHealth = false}) async {
    final detail = sessionById(sessionId);
    if (detail == null) return null;
    if (detail.isEmpty) {
      await deleteSession(sessionId);
      return null;
    }
    final endedAt = DateTime.now();
    var synced = false;
    if (syncHealth && HealthSync.instance.isSupported) {
      synced = await _syncSession(detail, endedAt);
    }
    await (db.update(db.workoutSessions)..where((t) => t.id.equals(sessionId)))
        .write(WorkoutSessionsCompanion(
      endedAt: Value(endedAt),
      healthSynced: Value(synced),
    ));
    await load();
    return syncHealth ? synced : null;
  }

  Future<bool> _syncSession(SessionDetail d, DateTime endedAt) async {
    final start = d.session.startedAt;
    var ok = true;
    if (d.sets.isNotEmpty) {
      ok &= await HealthSync.instance.writeWorkout(
        start: start,
        end: d.cardio.isEmpty ? endedAt : start.add(_strengthSpan(d, endedAt)),
        hasStrength: true,
      );
    }
    var cursor = d.sets.isEmpty ? start : start.add(_strengthSpan(d, endedAt));
    for (final c in d.cardio) {
      final end = cursor.add(Duration(minutes: c.durationMin.round()));
      ok &= await HealthSync.instance.writeWorkout(
        start: cursor,
        end: end,
        hasStrength: false,
        cardio: CardioType.parse(c.kind),
        distanceKm: c.distanceKm,
        kcal: c.kcal,
      );
      cursor = end;
    }
    return ok;
  }

  Duration _strengthSpan(SessionDetail d, DateTime endedAt) {
    final cardioMin = d.cardio.fold<double>(0, (s, c) => s + c.durationMin);
    final total = endedAt.difference(d.session.startedAt);
    final strength = total - Duration(minutes: cardioMin.round());
    return strength.inMinutes < 10 ? const Duration(minutes: 30) : strength;
  }

  Future<void> deleteSession(int sessionId) async {
    await (db.delete(db.workoutSessions)..where((t) => t.id.equals(sessionId)))
        .go();
    await load();
  }

  WorkoutSet? lastSetFor(int exerciseId, {int? excludeSession}) {
    for (final s in _sessions) {
      if (s.session.id == excludeSession) continue;
      final sets = s.setsFor(exerciseId);
      if (sets.isNotEmpty) return sets.last;
    }
    return null;
  }

  List<WorkoutSet> previousSetsFor(int exerciseId, {int? excludeSession}) {
    for (final s in _sessions) {
      if (s.session.id == excludeSession) continue;
      final sets = s.setsFor(exerciseId);
      if (sets.isNotEmpty) return sets;
    }
    return const [];
  }

  double? bestWeightFor(int exerciseId) {
    double? best;
    for (final s in _sessions) {
      for (final set in s.setsFor(exerciseId)) {
        if (best == null || set.weightKg > best) best = set.weightKg;
      }
    }
    return best;
  }

  List<SetRecord> get history => [
        for (final s in _sessions)
          if (s.session.endedAt != null)
            for (final set in s.sets)
              SetRecord(date: s.session.startedAt, set: set),
      ];

  Future<Exercise> addExercise(String name, MuscleGroup group) async {
    final id = await db.into(db.exercises).insert(ExercisesCompanion.insert(
          name: name,
          muscleGroup: group.name,
          isCustom: const Value(true),
        ));
    await load();
    return exerciseById(id)!;
  }

  Future<void> archiveExercise(Exercise e, bool archived) async {
    await db.update(db.exercises).replace(e.copyWith(isArchived: archived));
    await load();
  }
}
