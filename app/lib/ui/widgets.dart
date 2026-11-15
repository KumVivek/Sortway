import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';
import '../providers.dart';
import 'theme.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Gold coin drawn in code (no image asset needed).
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.accent,
      border: Border.all(color: const Color(0xFFC78A00), width: size * 0.12),
    ),
  );
}

/// Wallet balance pill.
class CoinChip extends ConsumerWidget {
  const CoinChip({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinsProvider).valueOrNull ?? 0;
    return Semantics(
      label: context.l10n.coinsLabel(coins),
      button: onTap != null,
      excludeSemantics: true,
      child: Material(
        color: AppColors.bgBottom.withAlpha(150),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinIcon(size: 18),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.add_circle, size: 18, color: AppColors.good),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 18});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.starsLabel(stars),
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? AppColors.accent : AppColors.track,
          ),
      ],
    ),
  );
}

/// Scaffold with the shared gradient background and a safe area.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.showBack = true,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final bool showBack;

  @override
  Widget build(BuildContext context) => AppBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar:
          title == null
              ? null
              : AppBar(
                title: Text(title!),
                automaticallyImplyLeading: showBack,
                actions: [...?actions, const SizedBox(width: 8)],
              ),
      body: SafeArea(child: body),
    ),
  );
}

/// Centers content and caps its width so tablets do not stretch it.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.max = 520});

  final Widget child;
  final double max;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max),
      child: child,
    ),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.textDim),
          const SizedBox(height: 12),
          Text(context.l10n.errorGeneric, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ],
      ),
    ),
  );
}
