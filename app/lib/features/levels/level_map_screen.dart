import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../services/game_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../meta/stickers.dart';
import 'level_ref.dart';
import 'level_repository.dart';

/// Linear level path, grouped into sets of twelve (one sticker set each).
class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({super.key});

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen> {
  static const double _setHeight = 330;
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final campaign = ref.watch(campaignProvider);
    final progress = ref.watch(progressProvider);
    final lang = Localizations.localeOf(context).languageCode;
    return AppScaffold(
      title: l.levels,
      actions: const [CoinChip()],
      body: switch ((campaign, progress)) {
        (AsyncData(value: final c), AsyncData(value: final p)) => _list(
          c,
          p,
          lang,
        ),
        (AsyncError(), _) || (_, AsyncError()) => ErrorView(
          onRetry: () => ref.invalidate(campaignProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }

  Widget _list(Campaign c, Map<String, ProgressEntry> progress, String lang) {
    final current = c.nextUnfinished((id) => progress[id]?.completed ?? false);
    final sets = (c.length / levelsPerSet).ceil();
    final currentSet = ((current - 1) ~/ levelsPerSet).clamp(0, sets - 1);
    _scroll ??= ScrollController(initialScrollOffset: currentSet * _setHeight);
    return ContentWidth(
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemExtent: _setHeight,
        itemCount: sets,
        itemBuilder: (context, set) {
          final first = set * levelsPerSet + 1;
          final last = (first + levelsPerSet - 1).clamp(first, c.length);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                child: Row(
                  children: [
                    StickerView(set: set, index: 0, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${context.l10n.setN(set + 1)} · ${stickerSetName(set, lang)}',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.02,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var n = first; n <= last; n++)
                      _LevelCell(
                        number: n,
                        stars: progress[c.byNumber(n)!.id]?.stars ?? 0,
                        done: progress[c.byNumber(n)!.id]?.completed ?? false,
                        unlocked: n <= current,
                        isCurrent: n == current,
                        hard: c.byNumber(n)!.meta.hard,
                        onTap:
                            () => context.push(
                              '/play?ref=${LevelRef.campaign(c.byNumber(n)!.id).encode()}',
                            ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelCell extends StatelessWidget {
  const _LevelCell({
    required this.number,
    required this.stars,
    required this.done,
    required this.unlocked,
    required this.isCurrent,
    required this.hard,
    required this.onTap,
  });

  final int number;
  final int stars;
  final bool done;
  final bool unlocked;
  final bool isCurrent;
  final bool hard;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour =
        isCurrent
            ? AppColors.accent
            : unlocked
            ? AppColors.surfaceHigh
            : AppColors.surface;
    final fg = isCurrent ? AppColors.onAccent : AppColors.text;
    return Semantics(
      button: true,
      enabled: unlocked,
      label: context.l10n.levelN(number),
      child: Material(
        key: Key('level-$number'),
        color: colour,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: unlocked ? onTap : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (unlocked)
                    Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    )
                  else
                    const Icon(Icons.lock_rounded, color: AppColors.track),
                  if (done) StarRow(stars: stars, size: 14),
                ],
              ),
              if (hard && unlocked)
                Positioned(
                  top: 4,
                  right: 6,
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: isCurrent ? AppColors.onAccent : AppColors.bad,
                    semanticLabel: context.l10n.hard,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
