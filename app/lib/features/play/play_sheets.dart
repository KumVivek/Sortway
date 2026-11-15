import 'package:flow_core/flow_core.dart';
import 'package:flutter/material.dart';

import '../../game/session_controller.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../meta/stickers.dart';
import 'level_rewards.dart';

enum WinAction { next, replay, map }

enum FailAction { undoAd, undoCoins, lifeAd, lifeCoins, retry, quit }

enum PauseAction { resume, restart, quit }

class LivesRow extends StatelessWidget {
  const LivesRow({super.key, required this.lives});

  final int lives;

  @override
  Widget build(BuildContext context) {
    final shown = lives.clamp(0, 5);
    final slots = shown < 3 ? 3 : shown;
    return Semantics(
      label: context.l10n.livesLabel(lives),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < slots; i++)
            Icon(
              i < shown
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 22,
              color: i < shown ? AppColors.bad : AppColors.track,
            ),
        ],
      ),
    );
  }
}

class CountdownOverlay extends StatelessWidget {
  const CountdownOverlay({
    super.key,
    required this.phase,
    required this.secondsLeft,
  });

  final PlayPhase phase;
  final double secondsLeft;

  @override
  Widget build(BuildContext context) {
    if (phase != PlayPhase.countdown) return const SizedBox.shrink();
    final n = secondsLeft.ceil();
    return Center(
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgBottom.withAlpha(200),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent, width: 4),
        ),
        child: Text(
          n <= 0 ? context.l10n.go : '$n',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class BoosterButton extends StatelessWidget {
  const BoosterButton({
    super.key,
    required this.icon,
    required this.label,
    required this.price,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final int price;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: active ? AppColors.surfaceHigh : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CoinIcon(size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '$price',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: ContentWidth(
        max: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class WinSheet extends StatefulWidget {
  const WinSheet({
    super.key,
    required this.title,
    required this.reward,
    required this.hasNext,
    required this.canDouble,
    required this.onDouble,
    this.onShare,
    this.extraCoins = 0,
  });

  final String title;
  final LevelReward reward;
  final bool hasNext;
  final bool canDouble;
  final int extraCoins;

  /// Shows the rewarded ad; completes true if the coins were doubled.
  final Future<bool> Function() onDouble;

  /// Shares the result card. Gets the button's context so the share sheet
  /// can anchor to it. Null hides the button.
  final Future<void> Function(BuildContext buttonContext)? onShare;

  @override
  State<WinSheet> createState() => _WinSheetState();
}

class _WinSheetState extends State<WinSheet> {
  bool _doubled = false;
  bool _working = false;

  Future<void> _double() async {
    setState(() => _working = true);
    final ok = await widget.onDouble();
    if (!mounted) return;
    setState(() {
      _working = false;
      _doubled = ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.adUnavailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.reward;
    final coins = (_doubled ? r.coins * 2 : r.coins) + widget.extraCoins;
    final sticker = r.sticker;
    final lang = Localizations.localeOf(context).languageCode;
    return _SheetBody(
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textDim),
        ),
        Text(
          l.levelComplete,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Center(child: StarRow(stars: r.stars, size: 52)),
        ),
        const SizedBox(height: 8),
        if (coins > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CoinIcon(size: 22),
              const SizedBox(width: 8),
              Text(
                l.coinsEarned(coins),
                key: const Key('win-coins'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        if (sticker != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgBottom.withAlpha(140),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                StickerView(set: sticker.set, index: sticker.index, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.newSticker,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        stickerSetName(sticker.set, lang),
                        style: const TextStyle(color: AppColors.textDim),
                      ),
                      if (r.setBonus > 0)
                        Text(
                          l.setCompleteBonus(r.setBonus),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (widget.canDouble && !_doubled) ...[
          OutlinedButton.icon(
            key: const Key('double-coins'),
            onPressed: _working ? null : _double,
            icon: const Icon(Icons.smart_display_rounded),
            label: Text(l.doubleCoins),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.hasNext)
          FilledButton(
            key: const Key('win-next'),
            onPressed:
                _working
                    ? null
                    : () => Navigator.of(context).pop(WinAction.next),
            child: Text(l.next),
          ),
        if (widget.onShare != null) ...[
          const SizedBox(height: 10),
          Builder(
            builder:
                (buttonContext) => OutlinedButton.icon(
                  key: const Key('win-share'),
                  onPressed:
                      _working
                          ? null
                          : () async {
                            setState(() => _working = true);
                            await widget.onShare!(buttonContext);
                            if (mounted) setState(() => _working = false);
                          },
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(l.share),
                ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextButton(
                key: const Key('win-replay'),
                onPressed:
                    _working
                        ? null
                        : () => Navigator.of(context).pop(WinAction.replay),
                child: Text(l.replay),
              ),
            ),
            Expanded(
              child: TextButton(
                key: const Key('win-map'),
                onPressed:
                    _working
                        ? null
                        : () => Navigator.of(context).pop(WinAction.map),
                child: Text(l.close),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FailSheet extends StatelessWidget {
  const FailSheet({
    super.key,
    required this.outcome,
    required this.undoPrice,
    required this.lifePrice,
    required this.canUndo,
    required this.adsAvailable,
    required this.lifeAdAvailable,
  });

  final DeliveryOutcome outcome;
  final int undoPrice;
  final int lifePrice;
  final bool canUndo;
  final bool adsAvailable;

  /// The rewarded extra life can be used once per level.
  final bool lifeAdAvailable;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void close(FailAction a) => Navigator.of(context).pop(a);
    return _SheetBody(
      children: [
        Text(
          l.outOfLives,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          switch (outcome) {
            DeliveryOutcome.overflow => l.failOverflow,
            DeliveryOutcome.locked => l.failLocked,
            _ => l.failWrongBin,
          },
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textDim),
        ),
        const SizedBox(height: 20),
        if (canUndo)
          _ContinueRow(
            icon: Icons.undo_rounded,
            label: l.undoLastItem,
            price: undoPrice,
            onAd: adsAvailable ? () => close(FailAction.undoAd) : null,
            onCoins: () => close(FailAction.undoCoins),
            adKey: const Key('fail-undo-ad'),
            coinsKey: const Key('fail-undo-coins'),
          ),
        const SizedBox(height: 10),
        _ContinueRow(
          icon: Icons.favorite_rounded,
          label: l.extraLife,
          price: lifePrice,
          onAd: lifeAdAvailable ? () => close(FailAction.lifeAd) : null,
          onCoins: () => close(FailAction.lifeCoins),
          adKey: const Key('fail-life-ad'),
          coinsKey: const Key('fail-life-coins'),
        ),
        const SizedBox(height: 18),
        FilledButton(
          key: const Key('fail-retry'),
          onPressed: () => close(FailAction.retry),
          child: Text(l.retry),
        ),
        TextButton(
          key: const Key('fail-quit'),
          onPressed: () => close(FailAction.quit),
          child: Text(l.quitLevel),
        ),
      ],
    );
  }
}

class _ContinueRow extends StatelessWidget {
  const _ContinueRow({
    required this.icon,
    required this.label,
    required this.price,
    required this.onAd,
    required this.onCoins,
    required this.adKey,
    required this.coinsKey,
  });

  final IconData icon;
  final String label;
  final int price;
  final VoidCallback? onAd;
  final VoidCallback onCoins;
  final Key adKey;
  final Key coinsKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.bgBottom.withAlpha(140),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (onAd != null) ...[
            OutlinedButton.icon(
              key: adKey,
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 44)),
              onPressed: onAd,
              icon: const Icon(Icons.smart_display_rounded, size: 18),
              label: Text(l.free),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton(
            key: coinsKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 44)),
            onPressed: onCoins,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinIcon(size: 14),
                const SizedBox(width: 5),
                Text('$price'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PauseSheet extends StatelessWidget {
  const PauseSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _SheetBody(
      children: [
        Text(
          l.paused,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('pause-resume'),
          onPressed: () => Navigator.of(context).pop(PauseAction.resume),
          child: Text(l.resume),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('pause-restart'),
          onPressed: () => Navigator.of(context).pop(PauseAction.restart),
          child: Text(l.restart),
        ),
        TextButton(
          key: const Key('pause-quit'),
          onPressed: () => Navigator.of(context).pop(PauseAction.quit),
          child: Text(l.quitLevel),
        ),
      ],
    );
  }
}
