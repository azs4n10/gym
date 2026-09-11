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
import '../../widgets/cover.dart';
import '../../widgets/group_badge.dart';
import '../../widgets/hero_card.dart';
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
  bool _recentFirst = true;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final w = context.watch<WorkoutState>();
    final t = Theme.of(context).textTheme;

    final exercises = w.activeExercises.where((e) {
      if (_filter is MuscleGroup && MuscleGroup.parse(e.muscleGroup) != _filter) return false;
      if (_filter == 'cardio') return false;
      if (_query.isNotEmpty && !exerciseMatches(e, _query, l)) return false;
      return true;
    }).toList();
    if (_recentFirst) {
      exercises.sort((a, b) {
        final da = w.lastDayFor(a.id);
        final db = w.lastDayFor(b.id);
        if (da == null && db == null) return a.id.compareTo(b.id);
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    }
    final cardio = _filter is MuscleGroup
        ? const <CardioType>[]
        : CardioType.values
            .where((c) => _query.isEmpty || c.label(l).toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'workout-fab',
        onPressed: () => _openSession(context),
        icon: Icon(w.openSession == null ? Icons.add_rounded : Icons.play_arrow_rounded),
        label: Text(w.openSession == null ? l.startNew : l.continueWorkout),
      ),
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(l.workouts, actions: [
              IconButton(
                tooltip: l.history,
                icon: Icon(Icons.history_rounded, color: skin.heading),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              IconButton(
                tooltip: l.exerciseList,
                icon: Icon(Icons.edit_note_rounded, color: skin.heading),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExercisePickerScreen(manageOnly: true)),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l.search,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SortButton(
                    recentFirst: _recentFirst,
                    onChanged: (v) => setState(() => _recentFirst = v),
                  ),
                ],
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
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                      children: [
                        for (final e in exercises)
                          _ExerciseCard(exercise: e, last: w.lastSetFor(e.id)),
                        if (cardio.isNotEmpty && exercises.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
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

class _SortButton extends StatelessWidget {
  const _SortButton({required this.recentFirst, required this.onChanged});

  final bool recentFirst;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    return PopupMenuButton<bool>(
      tooltip: l.sort,
      onSelected: onChanged,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(value: true, checked: recentFirst, child: Text(l.recent)),
        CheckedPopupMenuItem(value: false, checked: !recentFirst, child: Text(l.name)),
      ],
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: skin.heading,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.tune_rounded, color: skin.buttonText, size: 20),
      ),
    );
  }
}

/// Wide card with the text on the left and a gradient cover filling the right,
/// mirroring the photo cards in the reference layouts.
class _WideCard extends StatelessWidget {
  const _WideCard({
    required this.title,
    required this.meta,
    required this.tint,
    required this.panel,
    required this.onTap,
  });

  final String title;
  final String meta;
  final Color tint;
  final Widget panel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PastelCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: SizedBox(
          height: 108,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium?.copyWith(
                            color: skin.text, fontWeight: FontWeight.w800, height: 1.15),
                      ),
                      const SizedBox(height: 4),
                      Text(meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(color: skin.subText)),
                      const Spacer(),
                      RoundAction(
                        icon: Icons.play_arrow_rounded,
                        size: 32,
                        background: skin.buttonSoft,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: skin.ink, width: 2)),
                ),
                child: Cover(
                  tint: tint,
                  width: 130,
                  height: 106,
                  radius: 0,
                  outlined: false,
                  child: panel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.last});
  final Exercise exercise;
  final WorkoutSet? last;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final g = MuscleGroup.parse(exercise.muscleGroup);
    final meta = last == null
        ? g.label(l)
        : '${g.label(l)} · ${l.lastSet(fmtKg(last!.weightKg), last!.reps)}';
    return _WideCard(
      title: exerciseName(exercise, l),
      meta: meta,
      tint: g.color,
      panel: _RecordPanel(last: last),
      onTap: () => _start(context),
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
    return _WideCard(
      title: kind.label(l),
      meta: l.cardio,
      tint: skin.accent,
      panel: AppIcon(Ic.cardio, size: 38, color: skin.card),
      onTap: () => _start(context),
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

/// Right-hand panel of an exercise card: the last set in large type, so the
/// coloured area carries information instead of decoration.
class _RecordPanel extends StatelessWidget {
  const _RecordPanel({required this.last});

  final WorkoutSet? last;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final set = last;
    if (set == null) {
      return Text(l.startNew,
          style: t.labelLarge?.copyWith(color: skin.card, fontWeight: FontWeight.w700));
    }
    final bodyweight = set.weightKg == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(bodyweight ? '${set.reps}' : fmtKg(set.weightKg),
            style: t.headlineSmall
                ?.copyWith(color: skin.card, fontWeight: FontWeight.w800, height: 1)),
        const SizedBox(height: 2),
        Text(bodyweight ? l.repsUnit : 'kg × ${set.reps}',
            style: t.labelSmall?.copyWith(color: skin.card.withValues(alpha: 0.85))),
      ],
    );
  }
}
