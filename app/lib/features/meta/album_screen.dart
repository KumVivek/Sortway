import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../levels/level_repository.dart';
import 'stickers.dart';

/// Collection album: one page per set of twelve stickers.
class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final owned = ref.watch(stickersProvider).valueOrNull ?? const {};
    final campaignLength = ref.watch(campaignProvider).valueOrNull?.length ?? 0;
    final lang = Localizations.localeOf(context).languageCode;
    final totalSets = (campaignLength / levelsPerSet).ceil().clamp(1, 1000);
    // Show finished sets, the one in progress, and a peek at the next.
    final shown = (currentSetIndex(owned) + 2).clamp(1, totalSets);
    return AppScaffold(
      title: l.albumTitle,
      body: ContentWidth(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: shown + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Text(
                l.albumHint,
                style: const TextStyle(color: AppColors.textDim),
              );
            }
            final set = i - 1;
            final have = ownedInSet(owned, set);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stickerSetName(set, lang),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (have == stickersPerSet)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.good,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          l.countOf(have, stickersPerSet),
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, box) {
                        const perRow = 6;
                        final size = (box.maxWidth - 8 * (perRow - 1)) / perRow;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var s = 0; s < stickersPerSet; s++)
                              StickerView(
                                set: set,
                                index: s,
                                size: size,
                                owned: owned.contains((set: set, index: s)),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
