import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../l10n/strings.dart';
import '../services/health_sync.dart';
import '../state/app_state.dart';
import '../state/body_state.dart';
import '../widgets/app_icon.dart';
import '../widgets/pastel_card.dart';
import '../widgets/stepper_field.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  int _rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final body = context.watch<BodyState>();
    final t = Theme.of(context).textTheme;
    final latest = body.latest;
    final avg7 = body.averageOver(7);
    final series = body.lastDays(_rangeDays);
    final first = series.isEmpty ? null : series.first;
    final delta = latest != null && first != null && first.id != latest.id
        ? latest.weightKg - first.weightKg
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(l.body)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'body-fab',
        onPressed: () => showBodyLogSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.logAction),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: l.weight,
                  ic: Ic.body,
                  value: latest == null ? '--' : fmtKg(latest.weightKg),
                  unit: 'kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: l.bodyFat,
                  ic: Ic.fat,
                  value: latest?.bodyFatPct == null ? '--' : fmtKg(latest!.bodyFatPct!),
                  unit: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: l.avg7,
                  ic: Ic.avg,
                  value: avg7 == null ? '--' : avg7.toStringAsFixed(1),
                  unit: 'kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: l.overDays(_rangeDays),
                  ic: delta == null || delta == 0
                      ? Ic.flat
                      : (delta < 0 ? Ic.down : Ic.up),
                  value: delta == null ? '--' : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                  unit: 'kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionTitle(l.trend, ic: Ic.trend,
              trailing: SegmentedButton<int>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(t.labelSmall),
                ),
                segments: [
                  ButtonSegment(value: 30, label: Text(l.d30)),
                  ButtonSegment(value: 90, label: Text(l.d90)),
                  ButtonSegment(value: 365, label: Text(l.y1)),
                ],
                selected: {_rangeDays},
                onSelectionChanged: (s) => setState(() => _rangeDays = s.first),
              )),
          PastelCard(
            padding: const EdgeInsets.fromLTRB(8, 18, 18, 10),
            child: SizedBox(
              height: 220,
              child: series.length < 2
                  ? EmptyHint(ic: Ic.trend, text: l.chartHint)
                  : _WeightChart(series: series, rangeDays: _rangeDays),
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(l.history, ic: Ic.history),
          if (body.logs.isEmpty)
            EmptyHint(ic: Ic.empty, text: l.noRecords)
          else
            for (final log in body.logs.take(60))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PastelCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  onTap: () => showBodyLogSheet(context, existing: log),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 76,
                        child: Text(l.dateWithWeekday(log.date),
                            style: t.bodyMedium?.copyWith(
                                color: skin.subText, fontWeight: FontWeight.w700)),
                      ),
                      Text('${fmtKg(log.weightKg)} kg',
                          style: t.bodyLarge?.copyWith(
                              color: skin.heading, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 12),
                      if (log.bodyFatPct != null)
                        Text('${fmtKg(log.bodyFatPct!)} %',
                            style: t.bodyMedium?.copyWith(color: skin.text)),
                      const Spacer(),
                      if (log.note.isNotEmpty)
                        Flexible(
                          child: Text(log.note,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(color: skin.subText)),
                        ),
                      if (log.healthSynced)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.favorite_rounded, size: 14, color: skin.accent),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.series, required this.rangeDays});
  final List<BodyLog> series;
  final int rangeDays;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final l = context.l;
    final start = dayOf(DateTime.now()).subtract(Duration(days: rangeDays - 1));
    final spots = [
      for (final log in series)
        FlSpot(dayOf(log.date).difference(start).inDays.toDouble(), log.weightKg),
    ];
    final ys = spots.map((s) => s.y);
    final minY = (ys.reduce((a, b) => a < b ? a : b) - 1).floorToDouble();
    final maxY = (ys.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble();
    final labelStep = rangeDays <= 30 ? 7.0 : (rangeDays <= 90 ? 14.0 : 60.0);
    final yStep = (maxY - minY) / 4 > 0 ? (maxY - minY) / 4 : 1.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (rangeDays - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yStep,
          getDrawingHorizontalLine: (_) => FlLine(color: skin.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yStep,
              getTitlesWidget: (v, meta) => Text(
                v.toStringAsFixed(1),
                style: TextStyle(color: skin.subText, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep,
              reservedSize: 24,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.dateShort(start.add(Duration(days: v.round()))),
                    style: TextStyle(color: skin.subText, fontSize: 10)),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => skin.heading,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${l.dateShort(start.add(Duration(days: s.x.round())))}\n${s.y.toStringAsFixed(1)}kg',
                  TextStyle(color: skin.buttonText, fontWeight: FontWeight.w800, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: skin.button,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: skin.card,
                strokeWidth: 2,
                strokeColor: skin.button,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [skin.button.withValues(alpha: 0.35), skin.button.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showBodyLogSheet(BuildContext context, {BodyLog? existing}) async {
  final body = context.read<BodyState>();
  final app = context.read<AppState>();
  final l = app.l;
  var day = existing?.date ?? DateTime.now();
  var weight = existing?.weightKg ?? body.latestWeight ?? 50.0;
  var fat = existing?.bodyFatPct ?? body.latest?.bodyFatPct ?? 0.0;
  final noteC = TextEditingController(text: existing?.note ?? '');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final skin = app.skin;
        final t = Theme.of(ctx).textTheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l.body,
                      style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: day,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setSheet(() => day = picked);
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(l.dateLong(day)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _sheetRow(l.weight, StepperField(
                value: weight, step: 0.1, unit: 'kg', min: 20, max: 300, width: 150,
                onChanged: (v) => setSheet(() => weight = v),
              )),
              _sheetRow(l.bodyFat, StepperField(
                value: fat, step: 0.1, unit: '%', max: 70, width: 150,
                onChanged: (v) => setSheet(() => fat = v),
              )),
              const SizedBox(height: 6),
              TextField(
                controller: noteC,
                decoration: InputDecoration(hintText: l.memoHint),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (existing != null)
                    TextButton(
                      onPressed: () async {
                        await body.delete(existing);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(l.delete),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      final sync = app.profile.healthSync && HealthSync.instance.isSupported;
                      final synced = await body.upsert(
                        day: day,
                        weightKg: weight,
                        bodyFatPct: fat > 0 ? fat : null,
                        note: noteC.text.trim(),
                        syncHealth: sync,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (synced == false && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.syncFailed)),
                        );
                      }
                    },
                    child: Text(l.save),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
  noteC.dispose();
}

Widget _sheetRow(String label, Widget field) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          field,
        ],
      ),
    );
