import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';

class StepperField extends StatefulWidget {
  const StepperField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.step,
    this.min = 0,
    this.max = 999,
    this.decimals = 1,
    this.unit,
    this.width = 118,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final int decimals;
  final String? unit;
  final double width;

  @override
  State<StepperField> createState() => _StepperFieldState();
}

class _StepperFieldState extends State<StepperField> {
  late final TextEditingController _c;
  final _focus = FocusNode();
  late double _value = widget.value;
  DateTime? _lastLocalEdit;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _fmt(_value));
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(StepperField old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value || _focus.hasFocus) return;
    // Rapid taps fire several async saves; ignore their stale echoes for a moment.
    final edit = _lastLocalEdit;
    if (edit != null && DateTime.now().difference(edit).inMilliseconds < 800) return;
    _value = widget.value;
    _c.text = _fmt(_value);
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      widget.decimals == 0 || v == v.roundToDouble()
          ? v.round().toString()
          : v.toStringAsFixed(widget.decimals);

  void _apply(double v) {
    _value = v.clamp(widget.min, widget.max).toDouble();
    _lastLocalEdit = DateTime.now();
    _c.text = _fmt(_value);
    widget.onChanged(_value);
  }

  void _commit() {
    final parsed = double.tryParse(_c.text.replaceAll('，', '.').replaceAll('、', '.'));
    if (parsed == null) {
      _c.text = _fmt(_value);
      return;
    }
    final v = parsed.clamp(widget.min, widget.max).toDouble();
    if (v == _value) {
      _c.text = _fmt(_value);
      return;
    }
    _apply(v);
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return SizedBox(
      width: widget.width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundIcon(icon: Icons.remove, onTap: () => _apply(_value - widget.step)),
          Expanded(
            child: TextField(
              controller: _c,
              focusNode: _focus,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onSubmitted: (_) => _commit(),
              style: TextStyle(
                color: skin.heading,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixText: widget.unit,
                suffixStyle: TextStyle(color: skin.subText, fontSize: 11),
              ),
            ),
          ),
          _RoundIcon(icon: Icons.add, onTap: () => _apply(_value + widget.step)),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: skin.buttonSoft, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: skin.heading),
      ),
    );
  }
}
