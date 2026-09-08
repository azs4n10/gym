import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/seed/exercises_seed.dart';
import '../../l10n/strings.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../state/workout_state.dart';
import '../../widgets/group_badge.dart';
import '../../widgets/pastel_card.dart';

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key, this.manageOnly = false});
  final bool manageOnly;

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String _query = '';
  MuscleGroup? _group;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final w = context.watch<WorkoutState>();
    final t = Theme.of(context).textTheme;
    final list = w.exercises.where((e) {
      if (!widget.manageOnly && e.isArchived) return false;
      if (_group != null && MuscleGroup.parse(e.muscleGroup) != _group) return false;
      if (_query.isNotEmpty && !exerciseMatches(e, _query, l)) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.manageOnly ? l.exerciseList : l.pickExercise)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'exercise-fab',
        onPressed: () => _addCustom(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.newExercise),
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
                  selected: _group == null,
                  onSelected: (_) => setState(() => _group = null),
                ),
                for (final g in MuscleGroup.values) ...[
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: GroupBadge(g, size: 20),
                    label: Text(g.label(l)),
                    selected: _group == g,
                    onSelected: (_) => setState(() => _group = g),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyHint(icon: Icons.search_off_rounded, text: l.notFound)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final e = list[i];
                      final g = MuscleGroup.parse(e.muscleGroup);
                      final last = w.lastSetFor(e.id);
                      return PastelCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        onTap: widget.manageOnly ? null : () => Navigator.pop(context, e),
                        child: Row(
                          children: [
                            GroupBadge(g),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exerciseName(e, l),
                                      style: t.bodyLarge?.copyWith(
                                        color: e.isArchived ? skin.subText : skin.text,
                                        fontWeight: FontWeight.w800,
                                        decoration: e.isArchived ? TextDecoration.lineThrough : null,
                                      )),
                                  Text(
                                    last == null
                                        ? g.label(l)
                                        : '${g.label(l)} · ${l.lastSet(fmtKg(last.weightKg), last.reps)}',
                                    style: t.bodySmall?.copyWith(color: skin.subText),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.manageOnly)
                              IconButton(
                                tooltip: e.isArchived ? l.showAgain : l.hide,
                                icon: Icon(
                                  e.isArchived ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: skin.subText,
                                ),
                                onPressed: () => w.archiveExercise(e, !e.isArchived),
                              )
                            else
                              Icon(Icons.add_circle_rounded, color: skin.button),
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

  Future<void> _addCustom(BuildContext context) async {
    final w = context.read<WorkoutState>();
    final l = context.read<AppState>().l;
    final nameC = TextEditingController(text: _query);
    var group = _group ?? MuscleGroup.chest;
    final result = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.newExercise,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              TextField(
                controller: nameC,
                autofocus: true,
                decoration: InputDecoration(hintText: l.name),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final g in MuscleGroup.values)
                    ChoiceChip(
                      avatar: GroupBadge(g, size: 20),
                      label: Text(g.label(l)),
                      selected: group == g,
                      onSelected: (_) => setSheet(() => group = g),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameC.text.trim();
                    if (name.isEmpty) return;
                    final e = await w.addExercise(name, group);
                    if (ctx.mounted) Navigator.pop(ctx, e);
                  },
                  child: Text(l.create),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    nameC.dispose();
    if (result != null && !widget.manageOnly && context.mounted) {
      Navigator.pop(context, result);
    }
  }
}
