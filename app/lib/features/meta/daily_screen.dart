import 'package:flow_core/flow_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../levels/level_ref.dart';

class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(dailyStatusProvider);
    final reward = ref.watch(remoteConfigProvider.select((c) => c.coinsDaily));
    final today = dailySeed(ref.watch(clockProvider)());
    return AppScaffold(
      title: l.dailyTitle,
      actions: const [CoinChip()],
      body: status.when(
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(),
        data:
            (s) => ContentWidth(
              max: 440,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.today_rounded,
                      size: 72,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.dailyBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textDim),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: AppColors.bad,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l.dailyStreak(s.streak),
                                  key: const Key('daily-streak'),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.doneToday ? l.dailyDone : l.dailyReward(reward),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('daily-play'),
                      onPressed:
                          () => context.push(
                            '/play?ref=${LevelRef.daily(today).encode()}',
                          ),
                      child: Text(s.doneToday ? l.replay : l.dailyPlay),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

/// Weekly event: a themed pack of levels, available Monday to Sunday.
class EventScreen extends ConsumerWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final event = ref.watch(activeEventProvider);
    final levels = ref.watch(eventLevelsProvider);
    final progress = ref.watch(progressProvider).valueOrNull ?? const {};
    if (event == null) {
      return AppScaffold(title: l.event, body: const ErrorView());
    }
    return AppScaffold(
      title: event.title,
      actions: const [CoinChip()],
      body: levels.when(
        loading: () => const LoadingView(),
        error:
            (_, __) =>
                ErrorView(onRetry: () => ref.invalidate(eventLevelsProvider)),
        data: (list) {
          final done =
              list.where((x) => progress[x.id]?.completed ?? false).length;
          return ContentWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text(
                  done == list.length
                      ? l.eventDone
                      : l.eventReward(list.length, event.reward),
                  style: const TextStyle(color: AppColors.textDim),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < list.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        key: Key('event-level-${i + 1}'),
                        enabled: i <= done,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        leading: Icon(
                          i <= done
                              ? Icons.play_circle_fill_rounded
                              : Icons.lock_rounded,
                          color: i <= done ? AppColors.accent : AppColors.track,
                        ),
                        title: Text(l.eventLevel(i + 1)),
                        trailing:
                            progress[list[i].id]?.completed ?? false
                                ? StarRow(stars: progress[list[i].id]!.stars)
                                : null,
                        onTap:
                            () => context.push(
                              '/play?ref=${LevelRef.event(event.id, i + 1).encode()}',
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
