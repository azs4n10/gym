import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/seed/exercises_seed.dart';
import '../../l10n/strings.dart';
import '../../models/enums.dart';
import '../../services/health_sync.dart';
import '../../state/app_state.dart';
import '../../state/workout_state.dart';
import '../../widgets/group_badge.dart';
import '../../widgets/pastel_card.dart';
import '../../widgets/stepper_field.dart';
import 'exercise_picker_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.sessionId});
  final int sessionId;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final w = context.watch<WorkoutState>();
    final t = Theme.of(context).textTheme;
    final d = w.sessionById(widget.sessionId);
    if (d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyHint(icon: Icons.delete_outline_rounded, text: l.sessionDeleted),
      );
    }
    final isOpen = d.session.endedAt == null;
    final started = d.session.startedAt;
    final ended = d.session.endedAt ?? DateTime.now();
    final minutes = ended.difference(started).inMinutes;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.dateLong(started)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await _confirm(context, l);
                if (ok && context.mounted) {
                  await w.deleteSession(d.session.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: skin.subText),
              const SizedBox(width: 4),
              Text(
                l.minutes(minutes),
                style: t.bodyMedium?.copyWith(color: skin.subText, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (d.sets.isNotEmpty) ...[
                Icon(Icons.fitness_center_rounded, size: 16, color: skin.heading),
                const SizedBox(width: 4),
                Text(
                  l.totalVolume(d.volumeKg.round()),
                  style: t.bodyMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          for (final exId in d.exerciseOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExerciseBlock(
                detail: d,
                exercise: w.exerciseById(exId),
                editable: isOpen,
              ),
            ),
          for (final c in d.cardio)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PastelCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.directions_run_rounded, size: 24, color: skin.heading),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(CardioType.parse(c.kind).label(l),
                              style: t.bodyMedium?.copyWith(
                                  color: skin.text, fontWeight: FontWeight.w800)),
                          Text(
                            [
                              l.minutes(c.durationMin.round()),
                              if (c.distanceKm != null) '${c.distanceKm}km',
                              if (c.kcal != null) '${c.kcal}kcal',
                            ].join(' · '),
                            style: t.bodySmall?.copyWith(color: skin.subText),
                          ),
                        ],
                      ),
                    ),
                    if (isOpen)
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: skin.subText),
                        onPressed: () => w.deleteCardio(c),
                      ),
                  ],
                ),
              ),
            ),
          if (isOpen) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ex = await Navigator.of(context).push<Exercise>(
                        MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
                      );
                      if (ex != null && context.mounted) {
                        await w.addSet(d.session.id, ex.id);
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.addExercise),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addCardio(context, d.session.id),
                    icon: const Icon(Icons.directions_run_rounded),
                    label: Text(l.cardio),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          _MetaCard(detail: d, editable: isOpen),
        ],
      ),
      bottomNavigationBar: isOpen
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: d.isEmpty ? null : () => _finish(context, d.session.id),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l.finishWorkout),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _finish(BuildContext context, int id) async {
    final app = context.read<AppState>();
    final l = app.l;
    final w = context.read<WorkoutState>();
    final sync = app.profile.healthSync && HealthSync.instance.isSupported;
    final synced = await w.finishSession(id, syncHealth: sync);
    if (!context.mounted) return;
    final msg = switch (synced) {
      true => l.savedSynced,
      false => l.savedSyncFailed,
      null => l.saved,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    Navigator.of(context).pop();
  }

  Future<void> _addCardio(BuildContext context, int sessionId) async {
    final w = context.read<WorkoutState>();
    final result = await showModalBottomSheet<_CardioInput>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CardioSheet(),
    );
    if (result != null) {
      await w.addCardio(sessionId, result.kind, result.minutes,
          distanceKm: result.distanceKm, kcal: result.kcal);
    }
  }
}

Future<bool> _confirm(BuildContext context, L l) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(l.deleteRecordQ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
      ],
    ),
  );
  return r ?? false;
}

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({
    required this.detail,
    required this.exercise,
    required this.editable,
  });

  final SessionDetail detail;
  final Exercise? exercise;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final w = context.watch<WorkoutState>();
    final t = Theme.of(context).textTheme;
    final ex = exercise;
    if (ex == null) return const SizedBox.shrink();
    final sets = detail.setsFor(ex.id);
    final prev = w.previousSetsFor(ex.id, excludeSession: detail.session.id);
    final best = w.bestWeightFor(ex.id);
    final group = MuscleGroup.parse(ex.muscleGroup);

    return PastelCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GroupBadge(group),
              const SizedBox(width: 6),
              Expanded(
                child: Text(exerciseName(ex, l),
                    style: t.titleMedium?.copyWith(
                        color: skin.heading, fontWeight: FontWeight.w800)),
              ),
              if (editable)
                IconButton(
                  tooltip: l.removeExercise,
                  icon: Icon(Icons.close_rounded, color: skin.subText),
                  onPressed: () => w.removeExerciseFromSession(detail.session.id, ex.id),
                ),
            ],
          ),
          if (prev.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${l.lastTime(prev.map((s) => '${fmtKg(s.weightKg)}×${s.reps}').join('  '))}'
                '${best == null || best == 0 ? '' : '   ${l.best(fmtKg(best))}'}',
                style: t.bodySmall?.copyWith(color: skin.subText),
              ),
            ),
          for (final s in sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: skin.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${s.setIndex}',
                        style: TextStyle(
                            color: skin.heading, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  if (editable)
                    StepperField(
                      value: s.weightKg,
                      step: 2.5,
                      unit: 'kg',
                      max: 500,
                      onChanged: (v) => w.updateSet(s, weightKg: v),
                    )
                  else
                    SizedBox(
                      width: 118,
                      child: Text('${fmtKg(s.weightKg)} kg',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: skin.text, fontWeight: FontWeight.w800)),
                    ),
                  const SizedBox(width: 8),
                  if (editable)
                    StepperField(
                      value: s.reps.toDouble(),
                      step: 1,
                      unit: l.repsUnit,
                      decimals: 0,
                      max: 200,
                      width: 118,
                      onChanged: (v) => w.updateSet(s, reps: v.round()),
                    )
                  else
                    SizedBox(
                      width: 118,
                      child: Text('${s.reps} ${l.repsUnit}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: skin.text, fontWeight: FontWeight.w800)),
                    ),
                  const Spacer(),
                  if (editable)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.remove_circle_outline_rounded, color: skin.subText),
                      onPressed: () => w.deleteSet(s),
                    ),
                ],
              ),
            ),
          if (editable)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => w.addSet(detail.session.id, ex.id),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l.addSet),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatefulWidget {
  const _MetaCard({required this.detail, required this.editable});
  final SessionDetail detail;
  final bool editable;

  @override
  State<_MetaCard> createState() => _MetaCardState();
}

class _MetaCardState extends State<_MetaCard> {
  late final TextEditingController _note =
      TextEditingController(text: widget.detail.session.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final w = context.read<WorkoutState>();
    final mood = widget.detail.session.mood;
    if (!widget.editable && mood == null && widget.detail.session.note.isEmpty) {
      return const SizedBox.shrink();
    }
    return PastelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: widget.editable
                      ? () => w.updateSessionMeta(widget.detail.session.id, mood: i)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: mood == i ? skin.buttonSoft : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(moodIcon(i),
                        size: mood == i ? 32 : 26,
                        color: mood == i ? skin.heading : skin.subText),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.editable)
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(hintText: l.memoHint),
              onChanged: (v) => w.updateSessionMeta(widget.detail.session.id, note: v),
            )
          else if (widget.detail.session.note.isNotEmpty)
            Text(widget.detail.session.note, style: TextStyle(color: skin.text)),
        ],
      ),
    );
  }
}

class _CardioInput {
  const _CardioInput(this.kind, this.minutes, this.distanceKm, this.kcal);
  final CardioType kind;
  final double minutes;
  final double? distanceKm;
  final int? kcal;
}

class _CardioSheet extends StatefulWidget {
  const _CardioSheet();

  @override
  State<_CardioSheet> createState() => _CardioSheetState();
}

class _CardioSheetState extends State<_CardioSheet> {
  CardioType _kind = CardioType.running;
  double _minutes = 20;
  double _distance = 0;
  double _kcal = 0;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.addCardio,
              style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final k in CardioType.values)
                ChoiceChip(
                  label: Text(k.label(l)),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _row(l.duration, StepperField(
            value: _minutes, step: 5, unit: l.minUnit, decimals: 0, max: 600, width: 140,
            onChanged: (v) => setState(() => _minutes = v),
          )),
          _row(l.distance, StepperField(
            value: _distance, step: 0.5, unit: 'km', max: 200, width: 140,
            onChanged: (v) => setState(() => _distance = v),
          )),
          _row(l.burned, StepperField(
            value: _kcal, step: 10, unit: 'kcal', decimals: 0, max: 5000, width: 140,
            onChanged: (v) => setState(() => _kcal = v),
          )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _CardioInput(
                  _kind,
                  _minutes,
                  _distance > 0 ? _distance : null,
                  _kcal > 0 ? _kcal.round() : null,
                ),
              ),
              child: Text(l.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, Widget field) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            field,
          ],
        ),
      );
}
