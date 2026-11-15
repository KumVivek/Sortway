import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;

import 'package:flow_sort/app.dart';
import 'package:flow_sort/features/levels/level_repository.dart';
import 'package:flow_sort/features/monetization/ads_service.dart';
import 'package:flow_sort/features/monetization/purchases_service.dart';
import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flow_sort/features/share/share_card.dart';
import 'package:flow_sort/features/share/share_service.dart';
import 'package:flow_sort/providers.dart';
import 'package:flow_sort/services/analytics_service.dart';
import 'package:flow_sort/services/audio_service.dart';
import 'package:flow_sort/services/crash_reporter.dart';
import 'package:flow_sort/services/database.dart';
import 'package:flow_sort/services/game_store.dart';
import 'package:flow_sort/services/remote_config_service.dart';
import 'package:flow_sort/services/settings_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every fake the app needs, wired the same way `bootstrap()` wires the real
/// services.
class TestEnv {
  TestEnv({
    AgeBand? ageBand,
    Map<String, String> remoteConfig = const {},
    int startingCoins = 300,
    DateTime? now,
    this.realShare = false,
  }) : settings = MemorySettingsStore({
         if (ageBand != null) 'age_band': ageBand.name,
       }),
       remote = LocalRemoteConfigService(remoteConfig),
       now = now ?? DateTime(2026, 11, 16, 10),
       _startingCoins = startingCoins;

  final MemorySettingsStore settings;
  final LocalRemoteConfigService remote;
  final GameStore store = GameStore(AppDatabase.memory());
  final RecordingAnalyticsService analytics = RecordingAnalyticsService();
  final LocalCrashReporter crash = LocalCrashReporter();
  final FakeAdsService ads = FakeAdsService();
  final FakePurchasesService purchases = FakePurchasesService();
  final SilentAudioService audio = SilentAudioService();
  final FakeHapticsService haptics = FakeHapticsService();
  final FakeShareService share = FakeShareService();

  /// Use the real share sheet and card renderer (on-device tests only).
  final bool realShare;
  final List<ShareCardData> cards = [];
  final Directory cache = Directory.systemTemp.createTempSync('flow_sort_test');
  DateTime now;
  final int _startingCoins;

  Future<void> init() {
    // Each test opens its own in-memory database on purpose.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    return store.ensureWallet(_startingCoins);
  }

  List<Override> get overrides => [
    settingsStoreProvider.overrideWithValue(settings),
    gameStoreProvider.overrideWithValue(store),
    remoteConfigServiceProvider.overrideWithValue(remote),
    analyticsServiceProvider.overrideWithValue(analytics),
    crashReporterProvider.overrideWithValue(crash),
    adsServiceProvider.overrideWithValue(ads),
    purchasesServiceProvider.overrideWithValue(purchases),
    audioServiceProvider.overrideWithValue(audio),
    hapticsServiceProvider.overrideWithValue(haptics),
    shareServiceProvider.overrideWithValue(
      realShare ? SystemShareService() : share,
    ),
    // Real rendering needs the GPU thread; see share_test.dart for that.
    shareCardRendererProvider.overrideWithValue((data) async {
      cards.add(data);
      return realShare ? renderShareCard(data) : Uint8List.fromList([1, 2, 3]);
    }),
    clockProvider.overrideWithValue(() => now),
    randomProvider.overrideWithValue(math.Random(7)),
    levelRepositoryProvider.overrideWithValue(
      LevelRepository(bundle: rootBundle, cacheDir: () async => cache),
    ),
  ];

  List<String> get eventNames => [for (final e in analytics.events) e.name];

  Future<void> dispose() async {
    await store.close();
    if (cache.existsSync()) cache.deleteSync(recursive: true);
  }
}

/// A phone-sized surface (the default 800x600 test window is landscape).
void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> pumpApp(WidgetTester tester, TestEnv env) async {
  usePhoneSurface(tester);
  await env.init();
  await tester.pumpWidget(
    ProviderScope(overrides: env.overrides, child: const FlowSortApp()),
  );
  await settle(tester);
}

/// Like pumpAndSettle, but tolerant of the endless game loop: pumps a fixed
/// number of frames instead of waiting for "no more frames".
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Unmounts the app so stream subscriptions and timers are released.
Future<void> unmount(WidgetTester tester, TestEnv env) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await env.dispose();
}
