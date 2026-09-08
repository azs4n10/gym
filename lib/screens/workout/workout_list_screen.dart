import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/seed/exercises_seed.dart';
import '../../l10n/strings.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../state/workout_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/cardio_sheet.dart';
import '../../widgets/group_badge.dart';
import '../../widgets/icon_tile.dart';
import '../../widgets/pastel_card.dart';
import 'exercise_picker_screen.dart';
import 'history_screen.dart';
import 'session_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  String _query = '';
  Object? _filter;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final w = context.watch<WorkoutState>();
    final t = Theme.of(context).textTheme;

    final showCardio = _filter == null || _filter == 'cardio';
    final exercises = w.activeExercises.where((e) {
      if (_filter is MuscleGroup && MuscleGroup.parse(e.muscleGroup) != _filter) return false;
      if (_filter == 'cardio') return false;
      if (_query.isNotEmpty && !exerciseMatches(e, _query, l)) return false;
      return true;
    }).toList();
    final cardio = !showCardio
        ? const <CardioType>[]
        : CardioType.values
            .where((c) => _query.isEmpty || c.label(l).toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.workouts),
        actions: [
          IconButton(
            tooltip: l.history,
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: l.exerciseList,
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExercisePickerScreen(manageOnly: true)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'workout-fab',
        onPressed: () => _openSession(context),
        icon: Icon(w.openSession == null ? Icons.add_rounded : Icons.play_arrow_rounded),
        label: Text(w.openSession == null ? l.startNew : l.continueWorkout),
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
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final g in MuscleGroup.values) ...[
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: GroupBadge(g, size: 20),
                    label: Text(g.label(l)),
                    selected: _filter == g,
                    onSelected: (_) => setState(() => _filter = g),
                  ),
                ],
                const SizedBox(width: 6),
                ChoiceChip(
                  avatar: const AppIcon(Ic.cardio, size: 18),
                  label: Text(l.cardio),
                  selected: _filter == 'cardio',
                  onSelected: (_) => setState(() => _filter = 'cardio'),
                ),
              ],
            ),
          ),
          Expanded(
            child: exercises.isEmpty && cardio.isEmpty
                ? EmptyHint(ic: Ic.search, text: l.notFound)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      for (final e in exercises) _ExerciseCard(exercise: e, last: w.lastSetFor(e.id)),
                      if (cardio.isNotEmpty && _filter == null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                          child: Text(l.cardio,
                              style: t.titleMedium?.copyWith(
                                  color: skin.heading, fontWeight: FontWeight.w800)),
                        ),
                      for (final c in cardio) _CardioCard(kind: c),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSession(BuildContext context) async {
    final id = await context.read<WorkoutState>().startSession();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SessionScreen(sessionId: id)),
      );
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.last});
  final Exercise exercise;
  final WorkoutSet? last;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final g = MuscleGroup.parse(exercise.muscleGroup);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PastelCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => _start(context),
        child: Row(
          children: [
            IconTile(g.ic, size: 46, color: g.color.withValues(alpha: 0.35)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exerciseName(exercise, l),
                      style: t.bodyLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w700)),
                  Text(
                    last == null
                        ? g.label(l)
                        : '${g.label(l)} · ${l.lastSet(fmtKg(last!.weightKg), last!.reps)}',
                    style: t.bodySmall?.copyWith(color: skin.subText),
                  ),
                ],
              ),
            ),
            const GoButton(icon: Icons.play_arrow_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final w = context.read<WorkoutState>();
    final id = await w.startSession();
    if (w.sessionById(id)!.setsFor(exercise.id).isEmpty) {
      await w.addSet(id, exercise.id);
    }
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SessionScreen(sessionId: id)),
      );
    }
  }
}

class _CardioCard extends StatelessWidget {
  const _CardioCard({required this.kind});
  final CardioType kind;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PastelCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => _start(context),
        child: Row(
          children: [
            IconTile(Ic.cardio, size: 46, color: skin.accentSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kind.label(l),
                      style: t.bodyLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w700)),
                  Text(l.cardio, style: t.bodySmall?.copyWith(color: skin.subText)),
                ],
              ),
            ),
            const GoButton(icon: Icons.play_arrow_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final w = context.read<WorkoutState>();
    final input = await showCardioSheet(context, initial: kind);
    if (input == null || !context.mounted) return;
    final id = await w.startSession();
    await w.addCardio(id, input.kind, input.minutes,
        distanceKm: input.distanceKm, kcal: input.kcal);
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SessionScreen(sessionId: id)),
      );
    }
  }
}
