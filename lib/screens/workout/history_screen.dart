import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../state/workout_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/group_badge.dart';
import '../../widgets/pastel_card.dart';
import 'session_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final w = context.watch<WorkoutState>();
    final t = Theme.of(context).textTheme;
    final sessions = w.sessions.where((s) => !s.isEmpty || s.session.endedAt == null).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.history)),
      body: sessions.isEmpty
          ? EmptyHint(ic: Ic.workout, text: l.noWorkoutsYet)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
            ),
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
