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
import '../../widgets/pastel_card.dart';
import 'exercise_picker_screen.dart';
import 'session_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final w = context.watch<WorkoutState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.workouts),
        actions: [
          IconButton(
            tooltip: l.exerciseList,
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ExercisePickerScreen(manageOnly: true),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l.exerciseList)),
                ButtonSegment(value: true, label: Text(l.history)),
              ],
              selected: {_showHistory},
              onSelectionChanged: (s) => setState(() => _showHistory = s.first),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'workout-fab',
        onPressed: () => _openSession(context),
        icon: Icon(w.openSession == null ? Icons.add_rounded : Icons.play_arrow_rounded),
        label: Text(w.openSession == null ? l.startNew : l.continueWorkout),
      ),
      body: _showHistory ? _History(w: w) : _Library(w: w),
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

class _Library extends StatelessWidget {
  const _Library({required this.w});
  final WorkoutState w;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final skin = context.skin;
    final t = Theme.of(context).textTheme;
    final exercises = w.activeExercises;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        for (final g in MuscleGroup.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Row(
              children: [
                GroupBadge(g, size: 26),
                const SizedBox(width: 8),
                Text(g.label(l),
                    style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          for (final e in exercises.where((e) => MuscleGroup.parse(e.muscleGroup) == g))
            _ExerciseRow(exercise: e, last: w.lastSetFor(e.id)),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          child: Row(
            children: [
              const AppIcon(Ic.cardio, size: 24),
              const SizedBox(width: 8),
              Text(l.cardio,
                  style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        for (final c in CardioType.values) _CardioRow(kind: c),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.last});
  final Exercise exercise;
  final WorkoutSet? last;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PastelCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onTap: () => _start(context),
        child: Row(
          children: [
            Expanded(
              child: Text(exerciseName(exercise, l),
                  style: t.bodyLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w600)),
            ),
            if (last != null)
              Text(l.lastSet(fmtKg(last!.weightKg), last!.reps),
                  style: t.bodySmall?.copyWith(color: skin.subText)),
            const SizedBox(width: 6),
            Icon(Icons.play_circle_outline_rounded, color: skin.button),
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

class _CardioRow extends StatelessWidget {
  const _CardioRow({required this.kind});
  final CardioType kind;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PastelCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onTap: () => _start(context),
        child: Row(
          children: [
            Expanded(
              child: Text(kind.label(l),
                  style: t.bodyLarge?.copyWith(color: skin.text, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.play_circle_outline_rounded, color: skin.button),
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

class _History extends StatelessWidget {
  const _History({required this.w});
  final WorkoutState w;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final sessions = w.sessions.where((s) => !s.isEmpty || s.session.endedAt == null).toList();
    if (sessions.isEmpty) return EmptyHint(ic: Ic.workout, text: l.noWorkoutsYet);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = sessions[i];
        final isOpen = s.session.endedAt == null;
        final groups = <MuscleGroup>{};
        for (final id in s.exerciseOrder) {
          final e = w.exerciseById(id);
          if (e != null) groups.add(MuscleGroup.parse(e.muscleGroup));
        }
        return PastelCard(
          color: isOpen ? skin.buttonSoft : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SessionScreen(sessionId: s.session.id)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Text(l.dateShort(s.session.startedAt),
                        style: t.titleMedium?.copyWith(
                            color: skin.heading, fontWeight: FontWeight.w800)),
                    Text(l.weekday(s.session.startedAt),
                        style: t.labelSmall?.copyWith(color: skin.subText)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (final g in groups) ...[
                          GroupBadge(g, size: 20),
                          const SizedBox(width: 4),
                        ],
                        if (s.cardio.isNotEmpty) ...[
                          const AppIcon(Ic.cardio, size: 18),
                          const SizedBox(width: 4),
                        ],
                        if (isOpen)
                          Text(l.workoutInProgress,
                              style: t.bodyMedium?.copyWith(
                                  color: skin.text, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_summary(s, l), style: t.bodySmall?.copyWith(color: skin.subText)),
                  ],
                ),
              ),
              if (s.session.mood != null) AppIcon(moodIc(s.session.mood!), size: 22),
              Icon(Icons.chevron_right_rounded, color: skin.subText),
            ],
          ),
        );
      },
    );
  }

  String _summary(SessionDetail s, L l) {
    final parts = <String>[];
    if (s.sets.isNotEmpty) {
      parts.add(l.setsSummary(s.exerciseOrder.length, s.sets.length, _vol(s.volumeKg)));
    }
    for (final c in s.cardio) {
      final kind = CardioType.parse(c.kind).label(l);
      final dist = c.distanceKm == null ? '' : ' ${c.distanceKm}km';
      parts.add('$kind ${l.minutes(c.durationMin.round())}$dist');
    }
    return parts.join(' / ');
  }

  String _vol(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(1)}t'
      : '${v.round()}kg';
}
