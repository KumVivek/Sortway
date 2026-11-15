import 'dart:async';
import 'dart:math' as math;

import 'package:flow_core/flow_core.dart';
import 'package:flow_levelgen/flow_levelgen.dart' as gen;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/levels/level_ref.dart';
import 'features/levels/level_repository.dart';
import 'features/meta/daily.dart';
import 'features/monetization/ads_service.dart';
import 'features/monetization/purchases_service.dart';
import 'features/onboarding/age_policy.dart';
import 'features/share/share_card.dart';
import 'features/share/share_service.dart';
import 'services/analytics_service.dart';
import 'services/audio_service.dart';
import 'services/crash_reporter.dart';
import 'services/game_store.dart';
import 'services/remote_config_service.dart';
import 'services/settings_store.dart';

// ---- services: overridden at bootstrap (and with fakes in tests) ---------

Never _unset(String name) =>
    throw StateError('$name must be overridden in ProviderScope');

final settingsStoreProvider = Provider<SettingsStore>(
  (_) => _unset('settingsStoreProvider'),
);
final gameStoreProvider = Provider<GameStore>(
  (_) => _unset('gameStoreProvider'),
);
final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (_) => LocalRemoteConfigService(),
);
final analyticsServiceProvider = Provider<AnalyticsService>(
  (_) => RecordingAnalyticsService(),
);
final crashReporterProvider = Provider<CrashReporter>(
  (_) => LocalCrashReporter(),
);
final adsServiceProvider = Provider<AdsService>((_) => NoAdsService());
final purchasesServiceProvider = Provider<PurchasesService>(
  (_) => NoPurchasesService(),
);
final audioServiceProvider = Provider<AudioService>(
  (_) => SilentAudioService(),
);
final hapticsServiceProvider = Provider<HapticsService>(
  (_) => FakeHapticsService(),
);
final shareServiceProvider = Provider<ShareService>((_) => FakeShareService());

/// Turns result data into the PNG that gets shared (swapped out in tests).
final shareCardRendererProvider =
    Provider<Future<Uint8List> Function(ShareCardData)>((_) => renderShareCard);
final levelRepositoryProvider = Provider<LevelRepository>(
  (_) => _unset('levelRepositoryProvider'),
);
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);
final randomProvider = Provider<math.Random>((_) => math.Random());

/// Used by the simulated ad to show its dialog above everything.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// ---- settings -----------------------------------------------------------

@immutable
class AppSettings {
  const AppSettings({
    this.soundOn = true,
    this.musicOn = true,
    this.hapticsOn = true,
    this.languageCode,
    this.ageBand,
  });

  final bool soundOn;
  final bool musicOn;
  final bool hapticsOn;

  /// null = follow the system language.
  final String? languageCode;

  /// null = the age question has not been answered yet.
  final AgeBand? ageBand;

  AppSettings copyWith({
    bool? soundOn,
    bool? musicOn,
    bool? hapticsOn,
    String? Function()? languageCode,
    AgeBand? Function()? ageBand,
  }) => AppSettings(
    soundOn: soundOn ?? this.soundOn,
    musicOn: musicOn ?? this.musicOn,
    hapticsOn: hapticsOn ?? this.hapticsOn,
    languageCode: languageCode != null ? languageCode() : this.languageCode,
    ageBand: ageBand != null ? ageBand() : this.ageBand,
  );
}

class SettingsController extends Notifier<AppSettings> {
  static const _sound = 'sound_on';
  static const _music = 'music_on';
  static const _haptics = 'haptics_on';
  static const _language = 'language';
  static const _ageBand = 'age_band';

  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  AppSettings build() {
    final s = ref.watch(settingsStoreProvider);
    final settings = AppSettings(
      soundOn: s.getBool(_sound) ?? true,
      musicOn: s.getBool(_music) ?? true,
      hapticsOn: s.getBool(_haptics) ?? true,
      languageCode: s.getString(_language),
      ageBand: AgeBand.tryParse(s.getString(_ageBand)),
    );
    _apply(settings);
    return settings;
  }

  void _apply(AppSettings s) {
    ref.read(audioServiceProvider)
      ..soundOn = s.soundOn
      ..musicOn = s.musicOn;
    ref.read(hapticsServiceProvider).enabled = s.hapticsOn;
  }

  void _set(AppSettings next) {
    state = next;
    _apply(next);
  }

  Future<void> setSound({required bool on}) async {
    _set(state.copyWith(soundOn: on));
    await _store.setBool(_sound, value: on);
  }

  Future<void> setMusic({required bool on}) async {
    _set(state.copyWith(musicOn: on));
    final audio = ref.read(audioServiceProvider);
    on ? audio.startMusic() : audio.stopMusic();
    await _store.setBool(_music, value: on);
  }

  Future<void> setHaptics({required bool on}) async {
    _set(state.copyWith(hapticsOn: on));
    await _store.setBool(_haptics, value: on);
  }

  Future<void> setLanguage(String? code) async {
    _set(state.copyWith(languageCode: () => code));
    code == null
        ? await _store.remove(_language)
        : await _store.setString(_language, code);
  }

  /// Stores the age band (never the birth year).
  Future<void> setAgeBand(AgeBand band) async {
    _set(state.copyWith(ageBand: () => band));
    await _store.setString(_ageBand, band.name);
  }

  /// Settings → "Change age group": the question is asked again.
  Future<void> resetAgeBand() async {
    _set(state.copyWith(ageBand: () => null));
    await _store.remove(_ageBand);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// The policy every service reads. Unanswered = most restrictive.
final agePolicyProvider = Provider<AgePolicy>((ref) {
  final band = ref.watch(settingsProvider.select((s) => s.ageBand));
  return band == null ? AgePolicy.unanswered : AgePolicy(band);
});

final analyticsProvider = Provider<Analytics>(
  (ref) => Analytics(
    ref.watch(analyticsServiceProvider),
    () => ref.read(agePolicyProvider),
  ),
);

// ---- remote config ------------------------------------------------------

class RemoteConfigController extends Notifier<RemoteConfigValues> {
  @override
  RemoteConfigValues build() {
    final service = ref.watch(remoteConfigServiceProvider);
    final sub = service.changes.listen((v) => state = v);
    ref.onDispose(sub.cancel);
    return service.values;
  }
}

final remoteConfigProvider =
    NotifierProvider<RemoteConfigController, RemoteConfigValues>(
      RemoteConfigController.new,
    );

// ---- player data --------------------------------------------------------

final coinsProvider = StreamProvider<int>(
  (ref) => ref.watch(gameStoreProvider).watchCoins(),
);

final progressProvider = StreamProvider<Map<String, ProgressEntry>>(
  (ref) => ref.watch(gameStoreProvider).watchProgress(),
);

final stickersProvider = StreamProvider<Set<StickerKey>>(
  (ref) => ref.watch(gameStoreProvider).watchStickers(),
);

/// Remove Ads entitlement, cached locally so it works offline.
class RemoveAdsController extends Notifier<bool> {
  static const _key = 'remove_ads';

  @override
  bool build() => ref.watch(settingsStoreProvider).getBool(_key) ?? false;

  Future<void> set({required bool owned}) async {
    state = owned;
    await ref.read(settingsStoreProvider).setBool(_key, value: owned);
  }

  /// Asks the store; only ever upgrades while offline results are unknown.
  Future<void> refresh() async {
    final service = ref.read(purchasesServiceProvider);
    if (!service.available) return;
    if (await service.hasRemoveAds()) await set(owned: true);
  }
}

final removeAdsProvider = NotifierProvider<RemoveAdsController, bool>(
  RemoveAdsController.new,
);

final interstitialPolicyProvider = Provider<InterstitialPolicy>(
  (ref) => InterstitialPolicy(clock: ref.watch(clockProvider)),
);

// ---- levels -------------------------------------------------------------

final campaignProvider = FutureProvider<Campaign>(
  (ref) => ref.watch(levelRepositoryProvider).loadCampaign(),
);

final dailyTrackerProvider = Provider<DailyTracker>(
  (ref) => DailyTracker(ref.watch(gameStoreProvider)),
);

final dailyStatusProvider = FutureProvider.autoDispose<DailyStatus>((ref) {
  ref.watch(progressProvider);
  return ref.watch(dailyTrackerProvider).status(ref.watch(clockProvider)());
});

LevelDef _generateDaily((int, int) args) {
  final day = args.$1;
  return gen.generateDaily(
    DateTime(day ~/ 10000, (day ~/ 100) % 100, day % 100),
    difficultyOffset: args.$2,
  );
}

List<LevelDef> _generateEvent((String, int, int) args) =>
    gen.generateEvent(eventId: args.$1, seed: args.$2, band: args.$3);

/// Daily level for a `yyyymmdd` day, generated off the UI thread.
final dailyLevelProvider = FutureProvider.family<LevelDef, int>((ref, day) {
  final offset = ref.watch(
    remoteConfigProvider.select((c) => c.difficultyOffset),
  );
  return compute(_generateDaily, (day, offset));
});

/// The active weekly event, if Remote Config has one for this week.
final activeEventProvider = Provider<WeeklyEventConfig?>((ref) {
  final event = ref.watch(remoteConfigProvider.select((c) => c.weeklyEvent));
  if (event == null || !event.isActive(ref.watch(clockProvider)())) return null;
  return event;
});

final eventLevelsProvider = FutureProvider<List<LevelDef>>((ref) {
  final event = ref.watch(activeEventProvider);
  if (event == null) return const [];
  final offset = ref.watch(
    remoteConfigProvider.select((c) => c.difficultyOffset),
  );
  return compute(_generateEvent, (
    event.id,
    event.seed,
    (event.band + offset).clamp(1, 8),
  ));
});

/// Resolves an encoded [LevelRef] to a playable level.
final resolvedLevelProvider = FutureProvider.family<ResolvedLevel?, String>((
  ref,
  encoded,
) async {
  final r = LevelRef.tryParse(encoded);
  if (r == null) return null;
  switch (r.kind) {
    case LevelKind.campaign:
      final campaign = await ref.watch(campaignProvider.future);
      final level = campaign.byId(r.id);
      if (level == null) return null;
      final number = campaign.numberOf(r.id);
      final next = campaign.byNumber(number + 1);
      return ResolvedLevel(
        ref: r,
        level: level,
        number: number,
        pack: campaign.packOf(r.id),
        nextRef: next == null ? null : LevelRef.campaign(next.id),
      );
    case LevelKind.daily:
      final day = int.parse(r.id);
      final level = await ref.watch(dailyLevelProvider(day).future);
      return ResolvedLevel(ref: r, level: level, number: 0, pack: 'daily');
    case LevelKind.event:
      final levels = await ref.watch(eventLevelsProvider.future);
      if (r.index < 1 || r.index > levels.length) return null;
      if (ref.read(activeEventProvider)?.id != r.id) return null;
      return ResolvedLevel(
        ref: r,
        level: levels[r.index - 1],
        number: r.index,
        pack: 'event:${r.id}',
        nextRef:
            r.index < levels.length ? LevelRef.event(r.id, r.index + 1) : null,
      );
  }
});
