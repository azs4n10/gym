import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../l10n/strings.dart';
import '../services/health_sync.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../state/body_state.dart';
import '../widgets/sticker.dart';
import '../widgets/app_icon.dart';
import '../widgets/page_header.dart';
import '../widgets/pastel_card.dart';
import '../widgets/ring_progress.dart';
import '../widgets/stepper_field.dart';
import '../widgets/window_card.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'body-fab',
        onPressed: () => showBodyLogSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.logAction),
      ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: staggered([
          PageHeader(l.body),
          WindowCard(
            title: l.weight,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(latest == null ? '--' : fmtKg(latest.weightKg),
                              style: t.displaySmall?.copyWith(
                                  color: skin.heading, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 4),
                          Text('kg', style: t.bodyMedium?.copyWith(color: skin.subText)),
                        ],
                      ),
                      if (delta != null)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: skin.buttonSoft,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: skin.ink, width: kThinBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(delta == 0 ? Ic.flat : (delta < 0 ? Ic.down : Ic.up), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg · ${l.overDays(_rangeDays)}',
                                style: TextStyle(color: skin.heading, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                RingProgress(
                  value: latest?.bodyFatPct == null ? 0 : latest!.bodyFatPct! / 40,
                  color: skin.accent,
                  trackColor: skin.divider,
                  size: 84,
                  stroke: 9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(latest?.bodyFatPct == null ? '--' : fmtKg(latest!.bodyFatPct!),
                          style: t.titleMedium?.copyWith(
                              color: skin.heading, fontWeight: FontWeight.w800)),
                      Text(l.bodyFat, style: t.labelSmall?.copyWith(color: skin.subText)),
                    ],
                  ),
                ),
              ],
            ),
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
                  label: l.history,
                  ic: Ic.history,
                  value: '${body.logs.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          WindowCard(
            title: l.trend,
            tint: skin.accent,
            padding: const EdgeInsets.fromLTRB(8, 14, 16, 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final r in [(30, l.d30), (90, l.d90), (365, l.y1)])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _RangePill(
                          label: r.$2,
                          selected: _rangeDays == r.$1,
                          onTap: () => setState(() => _rangeDays = r.$1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 220,
                  child: series.length < 2
                      ? EmptyHint(ic: Ic.trend, text: l.chartHint)
                      : _WeightChart(series: series, rangeDays: _rangeDays),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          WindowCard(
            title: l.history,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: body.logs.isEmpty
                ? EmptyHint(ic: Ic.empty, text: l.noRecords)
                : Column(
                    children: [
                      for (final log in body.logs.take(60))
                        InkWell(
                          onTap: () => showBodyLogSheet(context, existing: log),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              border: log == body.logs.last
                                  ? null
                                  : Border(bottom: BorderSide(color: skin.divider, width: 1.5)),
                            ),
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
                                    child: AppIcon(Ic.health, size: 14, color: skin.accent),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ]),
        ),
      ),
    );
  }
}

/// Small outlined pill used for the chart range switch.
class _RangePill extends StatelessWidget {
  const _RangePill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? skin.button : skin.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: skin.ink, width: kThinBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: skin.ink,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
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
              color: skin.button.withValues(alpha: 0.22),
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
