import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../state/app_state.dart';
import 'stepper_field.dart';

class CardioInput {
  const CardioInput(this.kind, this.minutes, this.distanceKm, this.kcal);
  final CardioType kind;
  final double minutes;
  final double? distanceKm;
  final int? kcal;
}

Future<CardioInput?> showCardioSheet(BuildContext context, {CardioType? initial}) =>
    showModalBottomSheet<CardioInput>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CardioSheet(initial: initial ?? CardioType.running),
    );

class _CardioSheet extends StatefulWidget {
  const _CardioSheet({required this.initial});
  final CardioType initial;

  @override
  State<_CardioSheet> createState() => _CardioSheetState();
}

class _CardioSheetState extends State<_CardioSheet> {
  late CardioType _kind = widget.initial;
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
              style: t.titleMedium?.copyWith(color: skin.heading, fontWeight: FontWeight.w700)),
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
                CardioInput(
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
            SizedBox(width: 72, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            field,
          ],
        ),
      );
}
