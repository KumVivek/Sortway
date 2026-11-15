import 'package:flow_core/flow_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../ui/palette.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../levels/level_ref.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerResume());
    ref.read(audioServiceProvider).startMusic();
  }

  /// If the app was killed mid-level, offer to pick up where it stopped.
  Future<void> _offerResume() async {
    final store = ref.read(gameStoreProvider);
    final snap = await store.loadSnapshot();
    final refCode = snap?['ref'];
    final level = LevelRef.tryParse(refCode is String ? refCode : null);
    if (level == null || !mounted) return;
    final campaign = await ref.read(campaignProvider.future);
    if (!mounted) return;
    final l = context.l10n;
    final name = switch (level.kind) {
      LevelKind.campaign => l.levelN(campaign.numberOf(level.id)),
      LevelKind.daily => l.dailyName,
      LevelKind.event => l.eventLevel(level.index),
    };
    final resume = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l.resumeTitle),
            content: Text(l.resumeBody(name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.discard),
              ),
              FilledButton(
                key: const Key('resume-level'),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l.resume),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (resume ?? false) {
      await context.push('/play?ref=${level.encode()}&resume=1');
    } else {
      await store.clearSnapshot();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final campaign = ref.watch(campaignProvider);
    final progress = ref.watch(progressProvider).valueOrNull ?? const {};
    final daily = ref.watch(dailyStatusProvider).valueOrNull;
    final event = ref.watch(activeEventProvider);

    return AppScaffold(
      body: campaign.when(
        loading: () => const LoadingView(),
        error:
            (_, __) =>
                ErrorView(onRetry: () => ref.invalidate(campaignProvider)),
        data: (c) {
          final next = c.nextUnfinished(
            (id) => progress[id]?.completed ?? false,
          );
          final level = c.byNumber(next);
          return ContentWidth(
            max: 460,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const Key('home-settings'),
                        tooltip: l.settings,
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_rounded),
                      ),
                      const Spacer(),
                      CoinChip(onTap: () => context.push('/shop')),
                    ],
                  ),
                  const Spacer(),
                  const _Logo(),
                  const Spacer(),
                  if (level != null)
                    FilledButton(
                      key: const Key('home-play'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(68),
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onPressed:
                          () => context.push(
                            '/play?ref=${LevelRef.campaign(level.id).encode()}',
                          ),
                      child: Text('${l.play} · ${l.levelN(next)}'),
                    )
                  else
                    Text(
                      l.allLevelsDone,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeTile(
                          key: const Key('home-map'),
                          icon: Icons.map_rounded,
                          label: l.levels,
                          onTap: () => context.push('/map'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HomeTile(
                          key: const Key('home-daily'),
                          icon: Icons.today_rounded,
                          label: l.daily,
                          badge: !(daily?.doneToday ?? true),
                          onTap: () => context.push('/daily'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeTile(
                          key: const Key('home-album'),
                          icon: Icons.auto_awesome_rounded,
                          label: l.album,
                          onTap: () => context.push('/album'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HomeTile(
                          key: const Key('home-shop'),
                          icon: Icons.storefront_rounded,
                          label: l.shop,
                          onTap: () => context.push('/shop'),
                        ),
                      ),
                    ],
                  ),
                  if (event != null) ...[
                    const SizedBox(height: 12),
                    _HomeTile(
                      key: const Key('home-event'),
                      icon: Icons.celebration_rounded,
                      label: event.title,
                      onTap: () => context.push('/event'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 56,
        child: CustomPaint(
          size: const Size(260, 56),
          painter: _TokensPainter(),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        context.l10n.appTitle,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 46),
      ),
    ],
  );
}

class _TokensPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const colours = [
      ItemColour.red,
      ItemColour.yellow,
      ItemColour.green,
      ItemColour.blue,
      ItemColour.purple,
    ];
    final r = size.height * 0.4;
    final gap = (size.width - r * 2) / (colours.length - 1);
    for (var i = 0; i < colours.length; i++) {
      paintToken(canvas, Offset(r + gap * i, size.height / 2), r, colours[i]);
    }
  }

  @override
  bool shouldRepaint(_TokensPainter oldDelegate) => false;
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Badge(
              isLabelVisible: badge,
              smallSize: 10,
              backgroundColor: AppColors.bad,
              child: Icon(icon, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
