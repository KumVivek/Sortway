import 'dart:async';

import 'package:flame/game.dart';
import 'package:flow_core/flow_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/flow_game.dart';
import '../../game/session_controller.dart';
import '../../providers.dart';
import '../../services/audio_service.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../levels/level_ref.dart';
import '../monetization/ads_service.dart';
import '../monetization/parental_gate.dart';
import '../share/share_card.dart';
import 'level_rewards.dart';
import 'play_sheets.dart';

enum Booster {
  undo('undo', Icons.undo_rounded, adAlternative: true),
  life('life', Icons.favorite_rounded, adAlternative: true),
  slow('slow', Icons.slow_motion_video_rounded, adAlternative: false);

  const Booster(this.id, this.icon, {required this.adAlternative});

  /// Key in `booster_prices` and in analytics.
  final String id;
  final IconData icon;
  final bool adAlternative;
}

/// Counts levels for the `session_end` analytics event.
final sessionStatsProvider = Provider<SessionStats>((_) => SessionStats());

class SessionStats {
  final DateTime startedAt = DateTime.now();
  int levelsPlayed = 0;
}

String levelTitle(BuildContext context, ResolvedLevel r) => switch (r
    .ref
    .kind) {
  LevelKind.campaign => context.l10n.levelN(r.number),
  LevelKind.daily => context.l10n.dailyName,
  LevelKind.event => context.l10n.eventLevel(r.number),
};

class PlayScreen extends ConsumerWidget {
  const PlayScreen({super.key, required this.refCode, this.resume = false});

  final String refCode;
  final bool resume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(resolvedLevelProvider(refCode));
    return resolved.when(
      loading: () => const AppScaffold(body: LoadingView()),
      error:
          (_, __) => AppScaffold(
            title: '',
            body: ErrorView(
              onRetry: () => ref.invalidate(resolvedLevelProvider(refCode)),
            ),
          ),
      data:
          (r) =>
              r == null
                  ? const AppScaffold(title: '', body: ErrorView())
                  : _PlayView(
                    key: ValueKey(refCode),
                    resolved: r,
                    resume: resume,
                  ),
    );
  }
}

class _PlayView extends ConsumerStatefulWidget {
  const _PlayView({super.key, required this.resolved, required this.resume});

  final ResolvedLevel resolved;
  final bool resume;

  @override
  ConsumerState<_PlayView> createState() => _PlayViewState();
}

class _PlayViewState extends ConsumerState<_PlayView>
    with WidgetsBindingObserver {
  LevelSessionController? _controller;
  FlowGame? _game;
  StreamSubscription<SessionEvent>? _sub;
  bool _lifeAdUsed = false;
  bool _sheetOpen = false;
  bool _busy = false;
  bool _left = false;

  ResolvedLevel get _r => widget.resolved;
  LevelDef get _level => _r.level;
  String get _analyticsLevel => _level.id;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Needs localized strings, so it cannot run from initState.
    if (!_started) {
      _started = true;
      _start();
    }
  }

  Future<void> _start() async {
    final store = ref.read(gameStoreProvider);
    GameSession? restored;
    if (widget.resume) {
      final snap = await store.loadSnapshot();
      if (snap != null && snap['ref'] == _r.ref.encode()) {
        try {
          restored = GameSession.fromJson(
            _level,
            snap['session']! as Map<String, Object?>,
          );
        } on Object {
          restored = null;
        }
      }
    }
    if (!mounted) return;
    _setUp(restored);
    if (restored == null) {
      await store.recordAttempt(_r.progressId);
      ref
          .read(analyticsProvider)
          .levelStart(
            level: _analyticsLevel,
            pack: _r.pack,
            mechanic:
                _level.meta.mechanics.isEmpty
                    ? 'basic'
                    : _level.meta.mechanics.join('+'),
          );
    }
    await _maybeShowMechanicIntro();
  }

  void _setUp(GameSession? restored) {
    _sub?.cancel();
    _controller?.dispose();
    final config = ref.read(remoteConfigProvider);
    final controller = LevelSessionController(
      level: _level,
      tickScale: config.tickScale,
      restore: restored,
    );
    _sub = controller.events.listen(_onEvent);
    final l10n = context.l10n;
    setState(() {
      _lifeAdUsed = false;
      _controller = controller;
      _game = FlowGame(
        controller: controller,
        audio: ref.read(audioServiceProvider),
        haptics: ref.read(hapticsServiceProvider),
        itemsLeftText: l10n.itemsLeft,
        showHints: _r.ref.kind == LevelKind.campaign && _r.number <= 4,
      );
    });
    if (controller.phase == PlayPhase.lost) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onLost());
    }
  }

  /// One-time explainer card for a new mechanic (locked bins, gates).
  Future<void> _maybeShowMechanicIntro() async {
    final key = _level.meta.tutorial;
    if (key != Mechanics.lockedBin && key != Mechanics.colourGate) return;
    final settings = ref.read(settingsStoreProvider);
    final seenKey = 'tutorial_seen_$key';
    if (settings.getBool(seenKey) ?? false) return;
    if (!mounted) return;
    final l = context.l10n;
    _controller?.pause();
    ref.read(analyticsProvider).tutorialStep(key!);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              key == Mechanics.lockedBin ? l.tutLockedTitle : l.tutGateTitle,
            ),
            content: Text(
              key == Mechanics.lockedBin ? l.tutLockedBody : l.tutGateBody,
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.gotIt),
              ),
            ],
          ),
    );
    await settings.setBool(seenKey, value: true);
    _controller?.resume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _saveSnapshot();
      if (!_sheetOpen && !(_controller?.isOver ?? true)) _openPause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ---- persistence ------------------------------------------------------

  void _saveSnapshot() {
    final c = _controller;
    if (c == null || _left || c.phase == PlayPhase.won) return;
    ref.read(gameStoreProvider).saveSnapshot({
      'ref': _r.ref.encode(),
      'session': c.session.toJson(),
    }).ignore();
  }

  // ---- events -----------------------------------------------------------

  void _onEvent(SessionEvent event) {
    switch (event) {
      case DeliveredEvent():
        _saveSnapshot();
      case PhaseEvent(phase: PlayPhase.won):
        _game?.confetti();
        Future<void>.delayed(const Duration(milliseconds: 750), _onWon);
      case PhaseEvent(phase: PlayPhase.lost):
        Future<void>.delayed(const Duration(milliseconds: 650), _onLost);
      default:
        break;
    }
  }

  Future<void> _onWon() async {
    final c = _controller;
    if (!mounted || c == null || c.phase != PlayPhase.won || _sheetOpen) return;
    _sheetOpen = true;
    final store = ref.read(gameStoreProvider);
    final config = ref.read(remoteConfigProvider);
    final analytics = ref.read(analyticsProvider);
    final audio = ref.read(audioServiceProvider);
    final kind = _r.ref.kind;
    final now = ref.read(clockProvider)();

    final previous = (await store.progress())[_r.progressId];
    final owned = await store.stickers();
    var dailyDone = false;
    var streak = 0;
    if (kind == LevelKind.daily) {
      final result = await ref.read(dailyTrackerProvider).complete(now);
      dailyDone = !result.first;
      streak = result.streak;
    }
    final reward = rewardFor(
      kind: kind,
      livesLost: c.state.livesLost,
      previous: previous,
      dailyAlreadyDone: dailyDone,
      config: config,
      ownedStickers: owned,
      random: ref.read(randomProvider),
    );
    await store.completeLevel(
      levelId: _r.progressId,
      stars: reward.stars,
      flips: c.session.flips,
      coinsFor: (_, __) => reward.total,
      sticker: reward.sticker,
      now: now,
    );
    var eventBonus = 0;
    if (kind == LevelKind.event) eventBonus = await _maybeGrantEventReward();

    ref.read(sessionStatsProvider).levelsPlayed++;
    ref.read(interstitialPolicyProvider).onLevelFinished();
    analytics.levelComplete(
      level: _analyticsLevel,
      timeS: c.playSeconds.round(),
      livesLeft: c.state.lives,
      stars: reward.stars,
      boostersUsed: c.boosterCount,
    );
    if (reward.sticker case final s?) {
      analytics.stickerEarned(set: s.set, index: s.index);
      if (reward.setBonus > 0) analytics.setComplete(set: s.set);
    }
    if (kind == LevelKind.daily) {
      analytics.dailyChallenge(result: 'win', streak: streak);
    }
    audio.play(Sfx.win);
    if (!mounted) return;

    final adsOn =
        ref.read(adsServiceProvider).available &&
        config.rewardedDoubleCoinsEnabled &&
        reward.coins > 0;
    if (adsOn) {
      analytics.adOfferShown(
        placement: RewardedPlacement.doubleCoins.id,
        level: _analyticsLevel,
      );
    }
    final action = await showModalBottomSheet<WinAction>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder:
          (_) => WinSheet(
            title: levelTitle(context, _r),
            reward: reward,
            extraCoins: eventBonus,
            hasNext: _r.nextRef != null,
            canDouble: adsOn,
            onDouble: () => _doubleCoins(reward.coins),
            onShare:
                (buttonContext) => _share(
                  buttonContext,
                  stars: reward.stars,
                  flips: c.session.flips,
                ),
          ),
    );
    _sheetOpen = false;
    if (!mounted) return;
    switch (action ?? WinAction.map) {
      case WinAction.next:
        await _maybeInterstitial();
        if (!mounted) return;
        _left = true;
        context.pushReplacement('/play?ref=${_r.nextRef!.encode()}');
      case WinAction.replay:
        _restart();
      case WinAction.map:
        await _maybeInterstitial();
        if (!mounted) return;
        _left = true;
        context.pop();
    }
  }

  Future<int> _maybeGrantEventReward() async {
    final event = ref.read(activeEventProvider);
    if (event == null) return 0;
    final store = ref.read(gameStoreProvider);
    final key = 'event_reward_${event.id}';
    if (await store.read(key) != null) return 0;
    final levels = await ref.read(eventLevelsProvider.future);
    final progress = await store.progress();
    if (!levels.every((l) => progress[l.id]?.completed ?? false)) return 0;
    await store.write(key, '1');
    await store.addCoins(event.reward);
    return event.reward;
  }

  /// Rewarded "double coins": once per level end. Returns whether it paid.
  Future<bool> _doubleCoins(int coins) async {
    final earned = await ref
        .read(adsServiceProvider)
        .showRewarded(RewardedPlacement.doubleCoins);
    if (!earned) return false;
    await ref.read(gameStoreProvider).addCoins(coins);
    ref.read(audioServiceProvider).play(Sfx.coin);
    ref
        .read(analyticsProvider)
        .adWatched(
          placement: RewardedPlacement.doubleCoins.id,
          level: _analyticsLevel,
        );
    return true;
  }

  /// Shares a picture of the result through the system share sheet.
  Future<void> _share(
    BuildContext buttonContext, {
    required int stars,
    required int flips,
  }) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (ref.read(agePolicyProvider).sharingNeedsGate) {
      final passed = await showParentalGate(
        context,
        random: ref.read(randomProvider),
      );
      if (!passed || !mounted || !buttonContext.mounted) return;
    }
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final png = await ref.read(shareCardRendererProvider)(
      ShareCardData(
        appName: l.appTitle,
        title: levelTitle(context, _r),
        headline: l.levelComplete,
        stars: stars,
        tagline: l.shareCardTagline,
        detail: l.shareFlips(flips),
      ),
    );
    final text = switch (_r.ref.kind) {
      LevelKind.campaign => l.shareLevelText(_r.number, stars),
      LevelKind.daily => l.shareDailyText(stars),
      LevelKind.event => l.shareEventText(_r.number, stars),
    };
    final ok = await ref
        .read(shareServiceProvider)
        .shareImage(png, text: text, origin: origin);
    if (ok) {
      ref
          .read(analyticsProvider)
          .levelShared(level: _analyticsLevel, stars: stars);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l.shareFailed)));
    }
  }

  Future<void> _maybeInterstitial() async {
    final policy = ref.read(interstitialPolicyProvider);
    final campaign = ref.read(campaignProvider).valueOrNull;
    final progress = ref.read(progressProvider).valueOrNull ?? const {};
    // Non-campaign levels count as the player's current campaign level.
    final levelNumber =
        _r.ref.kind == LevelKind.campaign
            ? _r.number
            : (campaign?.nextUnfinished(
                  (id) => progress[id]?.completed ?? false,
                ) ??
                1);
    final show = policy.shouldShow(
      levelNumber: levelNumber,
      config: ref.read(remoteConfigProvider),
      removeAds: ref.read(removeAdsProvider),
    );
    if (!show) return;
    if (await ref.read(adsServiceProvider).showInterstitial()) {
      policy.onShown();
      ref.read(analyticsProvider).interstitialShown(level: _analyticsLevel);
    }
  }

  Future<void> _onLost({bool reopened = false}) async {
    final c = _controller;
    if (!mounted || c == null || c.phase != PlayPhase.lost || _sheetOpen)
      return;
    _sheetOpen = true;
    final analytics = ref.read(analyticsProvider);
    final outcome = c.state.lastDelivery?.outcome ?? DeliveryOutcome.wrongBin;
    if (!reopened) {
      analytics.levelFail(
        level: _analyticsLevel,
        reason: outcome == DeliveryOutcome.overflow ? 'overflow' : 'wrong_bin',
      );
      if (_r.ref.kind == LevelKind.daily) {
        analytics.dailyChallenge(result: 'fail', streak: 0);
      }
      ref.read(audioServiceProvider).play(Sfx.lose);
      ref.read(interstitialPolicyProvider).onLevelFinished();
      ref.read(sessionStatsProvider).levelsPlayed++;
      _saveSnapshot();
    }

    final ads = ref.read(adsServiceProvider).available;
    if (ads && !reopened) {
      analytics.adOfferShown(
        placement: RewardedPlacement.undo.id,
        level: _analyticsLevel,
      );
    }
    final prices = ref.read(remoteConfigProvider).boosterPrices;
    final action = await showModalBottomSheet<FailAction>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder:
          (_) => FailSheet(
            outcome: outcome,
            undoPrice: prices[Booster.undo.id]!,
            lifePrice: prices[Booster.life.id]!,
            canUndo: c.canUndo,
            adsAvailable: ads,
            lifeAdAvailable: ads && !_lifeAdUsed,
          ),
    );
    _sheetOpen = false;
    if (!mounted) return;
    switch (action ?? FailAction.quit) {
      case FailAction.undoAd:
        await _reviveOrReopen(Booster.undo, viaAd: true);
      case FailAction.undoCoins:
        await _reviveOrReopen(Booster.undo, viaAd: false);
      case FailAction.lifeAd:
        await _reviveOrReopen(Booster.life, viaAd: true);
      case FailAction.lifeCoins:
        await _reviveOrReopen(Booster.life, viaAd: false);
      case FailAction.retry:
        _restart();
      case FailAction.quit:
        await _quit(log: false);
    }
  }

  Future<void> _reviveOrReopen(Booster b, {required bool viaAd}) async {
    final ok = await _applyBooster(b, viaAd: viaAd);
    if (!ok && mounted) await _onLost(reopened: true);
  }

  // ---- boosters ---------------------------------------------------------

  /// Pays for (coins or rewarded ad) and applies a booster.
  Future<bool> _applyBooster(Booster b, {required bool viaAd}) async {
    final c = _controller;
    if (c == null || _busy) return false;
    _busy = true;
    try {
      final l = context.l10n;
      final messenger = ScaffoldMessenger.of(context);
      final analytics = ref.read(analyticsProvider);
      if (b == Booster.undo && !c.canUndo) return false;
      if (viaAd) {
        final placement =
            b == Booster.life
                ? RewardedPlacement.extraLife
                : RewardedPlacement.undo;
        final earned = await ref
            .read(adsServiceProvider)
            .showRewarded(placement);
        if (!earned) {
          messenger.showSnackBar(SnackBar(content: Text(l.adUnavailable)));
          return false;
        }
        if (b == Booster.life) _lifeAdUsed = true;
        analytics.adWatched(placement: placement.id, level: _analyticsLevel);
      } else {
        final price = ref.read(remoteConfigProvider).boosterPrices[b.id]!;
        if (!await ref.read(gameStoreProvider).spendCoins(price)) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l.notEnoughCoins),
              action: SnackBarAction(
                label: l.getCoins,
                onPressed: () => context.push('/shop'),
              ),
            ),
          );
          return false;
        }
      }
      final applied = switch (b) {
        Booster.undo => c.undo(),
        Booster.life => c.addLife(),
        Booster.slow => c.slow(),
      };
      if (applied) {
        analytics.boosterUsed(
          type: b.id,
          level: _analyticsLevel,
          source: viaAd ? 'ad' : 'coins',
        );
        _saveSnapshot();
      }
      return applied;
    } finally {
      _busy = false;
    }
  }

  /// Booster button during play: coins if affordable, otherwise the ad
  /// alternative where one exists.
  Future<void> _tapBooster(Booster b) async {
    final c = _controller;
    if (c == null || c.isOver || _sheetOpen) return;
    final price = ref.read(remoteConfigProvider).boosterPrices[b.id]!;
    final coins = ref.read(coinsProvider).valueOrNull ?? 0;
    if (coins >= price) {
      await _applyBooster(b, viaAd: false);
      return;
    }
    final adOk =
        b.adAlternative &&
        ref.read(adsServiceProvider).available &&
        !(b == Booster.life && _lifeAdUsed);
    if (!adOk) {
      // Reports "not enough coins" with a shortcut to the shop.
      await _applyBooster(b, viaAd: false);
      return;
    }
    c.pause();
    _sheetOpen = true;
    ref
        .read(analyticsProvider)
        .adOfferShown(
          placement:
              (b == Booster.life
                      ? RewardedPlacement.extraLife
                      : RewardedPlacement.undo)
                  .id,
          level: _analyticsLevel,
        );
    final l = context.l10n;
    final watch = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l.adOfferTitle),
            content: Text(l.adOfferBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.smart_display_rounded),
                label: Text(l.watchAd),
              ),
            ],
          ),
    );
    _sheetOpen = false;
    if (watch ?? false) await _applyBooster(b, viaAd: true);
    c.resume();
  }

  // ---- pause / leave ----------------------------------------------------

  Future<void> _openPause() async {
    final c = _controller;
    if (c == null || c.isOver || _sheetOpen) return;
    c.pause();
    _sheetOpen = true;
    final action = await showModalBottomSheet<PauseAction>(
      context: context,
      builder: (_) => const PauseSheet(),
    );
    _sheetOpen = false;
    if (!mounted) return;
    switch (action ?? PauseAction.resume) {
      case PauseAction.resume:
        c.resume();
      case PauseAction.restart:
        _restart();
      case PauseAction.quit:
        await _quit(log: true);
    }
  }

  void _restart() {
    ref.read(gameStoreProvider).clearSnapshot().ignore();
    _setUp(null);
    ref.read(gameStoreProvider).recordAttempt(_r.progressId).ignore();
  }

  Future<void> _quit({required bool log}) async {
    final c = _controller;
    if (log && c != null) {
      ref
          .read(analyticsProvider)
          .levelQuit(level: _analyticsLevel, secondsIn: c.playSeconds.round());
    }
    _left = true;
    await ref.read(gameStoreProvider).clearSnapshot();
    if (mounted) context.pop();
  }

  // ---- UI ---------------------------------------------------------------

  String? _banner(BuildContext context) {
    final l = context.l10n;
    return switch (_level.meta.tutorial) {
      'tap_switch' => l.tutTapSwitch,
      'look_ahead' => l.tutLookAhead,
      'second_switch' => l.tutSecondSwitch,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final game = _game;
    if (controller == null || game == null) {
      return const AppScaffold(body: LoadingView());
    }
    final l = context.l10n;
    final prices = ref.watch(
      remoteConfigProvider.select((c) => c.boosterPrices),
    );
    final banner = _banner(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _openPause();
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 2),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('pause'),
                        tooltip: l.pause,
                        onPressed: _openPause,
                        icon: const Icon(Icons.pause_circle_filled_rounded),
                        iconSize: 32,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              levelTitle(context, _r),
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_level.meta.hard)
                              Text(
                                l.hard,
                                style: const TextStyle(
                                  color: AppColors.bad,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ListenableBuilder(
                        listenable: controller,
                        builder:
                            (_, __) => LivesRow(lives: controller.state.lives),
                      ),
                      const SizedBox(width: 10),
                      const CoinChip(),
                    ],
                  ),
                ),
                if (banner != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      banner,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GameWidget<FlowGame>(
                            key: ObjectKey(game),
                            game: game,
                          ),
                          IgnorePointer(
                            child: ListenableBuilder(
                              listenable: controller,
                              builder:
                                  (_, __) => CountdownOverlay(
                                    phase: controller.phase,
                                    secondsLeft: controller.countdownLeft,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: ListenableBuilder(
                    listenable: controller,
                    builder:
                        (_, __) => Row(
                          children: [
                            for (final b in Booster.values) ...[
                              Expanded(
                                child: BoosterButton(
                                  key: Key('booster-${b.id}'),
                                  icon: b.icon,
                                  label: switch (b) {
                                    Booster.undo => l.boosterUndo,
                                    Booster.life => l.boosterLife,
                                    Booster.slow => l.boosterSlow,
                                  },
                                  price: prices[b.id]!,
                                  active:
                                      b == Booster.slow &&
                                      controller.state.slowTicksLeft > 0,
                                  onTap:
                                      controller.isOver ||
                                              (b == Booster.undo &&
                                                  !controller.canUndo)
                                          ? null
                                          : () => _tapBooster(b),
                                ),
                              ),
                              if (b != Booster.values.last)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
