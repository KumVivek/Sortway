import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'age_policy.dart';

/// First-launch age question (plan §8): a neutral year-of-birth picker with
/// no pre-selected value and nothing that hints at a "right" answer. Only
/// the resulting age band is stored.
class AgeGateScreen extends ConsumerStatefulWidget {
  const AgeGateScreen({super.key});

  @override
  ConsumerState<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends ConsumerState<AgeGateScreen> {
  int? _year;

  Future<void> _finish(AgeBand band) async {
    await ref.read(settingsProvider.notifier).setAgeBand(band);
    // Reaches analytics only for adults; for everyone else nothing is sent.
    ref.read(analyticsProvider).ageCheckDone(band);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final thisYear = ref.watch(clockProvider)().year;
    return AppScaffold(
      body: ContentWidth(
        max: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.ageTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l.ageBody,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim),
              ),
              const SizedBox(height: 28),
              DropdownButtonFormField<int>(
                key: const Key('birth-year'),
                value: _year,
                isExpanded: true,
                menuMaxHeight: 360,
                dropdownColor: AppColors.surfaceHigh,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: Text(l.ageSelectYear),
                items: [
                  for (var y = thisYear; y >= thisYear - 100; y--)
                    DropdownMenuItem(value: y, child: Text('$y')),
                ],
                onChanged: (y) => setState(() => _year = y),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('age-continue'),
                onPressed:
                    _year == null
                        ? null
                        : () => _finish(
                          ageBandForBirthYear(_year!, currentYear: thisYear),
                        ),
                child: Text(l.ageContinue),
              ),
              const SizedBox(height: 4),
              TextButton(
                key: const Key('age-skip'),
                onPressed: () => _finish(AgeBand.unknown),
                child: Text(l.ageSkip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
