import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/theme.dart';
import '../../ui/widgets.dart';

/// Parental gate for players who are not confirmed adults (plan §8): a
/// multi-digit sum. Shown before any real-money purchase, with the price
/// stated clearly, and before anything that leaves the game (sharing), in
/// which case [price] is null. Returns true only on a correct answer.
Future<bool> showParentalGate(
  BuildContext context, {
  required math.Random random,
  String? price,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ParentalGateDialog(price: price, random: random),
  );
  return ok ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog({required this.random, this.price});

  final String? price;
  final math.Random random;

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  final _controller = TextEditingController();
  late int _a;
  late int _b;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _a = 12 + widget.random.nextInt(18); // 12..29
    _b = 6 + widget.random.nextInt(4); // 6..9
  }

  void _submit() {
    if (int.tryParse(_controller.text.trim()) == _a * _b) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _wrong = true;
      _controller.clear();
      _newQuestion();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.gateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.price == null
                  ? l.gateShareNote
                  : l.gatePrice(widget.price!),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(l.gateBody),
            const SizedBox(height: 12),
            Text(
              l.gateQuestion(_a, _b),
              key: const Key('gate-question'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('gate-answer'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: l.gateAnswer,
                errorText: _wrong ? l.gateWrong : null,
                filled: true,
                fillColor: AppColors.bgBottom,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('gate-confirm'),
          onPressed: _submit,
          child: Text(l.confirm),
        ),
      ],
    );
  }
}
