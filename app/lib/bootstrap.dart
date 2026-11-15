import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'config/env.dart';
import 'features/levels/level_repository.dart';
import 'features/monetization/admob_ads_service.dart';
import 'features/monetization/ads_service.dart';
import 'features/monetization/purchases_service.dart';
import 'features/monetization/revenuecat_purchases_service.dart';
import 'features/monetization/simulated_ads_service.dart';
import 'features/onboarding/age_policy.dart';
import 'features/share/share_service.dart';
import 'providers.dart';
import 'services/analytics_service.dart';
import 'services/audio_service.dart';
import 'services/crash_reporter.dart';
import 'services/database.dart';
import 'services/game_store.dart';
import 'services/remote_config_service.dart';
import 'services/settings_store.dart';

/// Builds every real service and returns the provider overrides for the app.
///
/// Each external service has a safe fallback, so a missing config file or a
/// failed SDK start never stops the game from launching (offline first).
Future<List<Override>> bootstrap() async {
  final settings = await PrefsSettingsStore.load();
  final store = GameStore(AppDatabase.open());

  AnalyticsService analytics = RecordingAnalyticsService(echo: kDebugMode);
  CrashReporter crash = LocalCrashReporter();
  RemoteConfigService remoteConfig = LocalRemoteConfigService();

  if (Env.useFirebase) {
    try {
      await Firebase.initializeApp();
      final fa = FirebaseAnalyticsService(FirebaseAnalytics.instance);
      // Collection stays off until an adult age band is confirmed. The
      // native manifests also ship with collection disabled by default.
      await fa.applyPolicy(AgePolicy.unanswered);
      analytics = fa;
      final reporter = CrashlyticsReporter(FirebaseCrashlytics.instance);
      await reporter.initialize();
      crash = reporter;
      final rc = FirebaseRemoteConfigService(FirebaseRemoteConfig.instance);
      await rc.initialize();
      remoteConfig = rc;
    } on Object catch (e) {
      debugPrint('Firebase unavailable, running on local services: $e');
    }
  }

  FlutterError.onError = crash.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crash.recordError(error, stack, fatal: true);
    return true;
  };

  await store.ensureWallet(remoteConfig.values.startingCoins);

  final AdsService ads;
  if (Env.useAdMob && (Platform.isAndroid || Platform.isIOS)) {
    ads = AdMobAdsService();
  } else if (Env.allowSimulatedServices) {
    ads = SimulatedAdsService(rootNavigatorKey);
  } else {
    ads = NoAdsService();
  }

  final rcKey =
      Platform.isIOS ? Env.revenueCatIosKey : Env.revenueCatAndroidKey;
  final PurchasesService purchases;
  if (rcKey.isNotEmpty) {
    purchases = RevenueCatPurchasesService(rcKey);
  } else if (Env.allowSimulatedServices) {
    purchases = FakePurchasesService();
  } else {
    purchases = NoPurchasesService();
  }

  final audio = FlameAudioService();
  await audio.preload();

  return [
    settingsStoreProvider.overrideWithValue(settings),
    gameStoreProvider.overrideWithValue(store),
    remoteConfigServiceProvider.overrideWithValue(remoteConfig),
    analyticsServiceProvider.overrideWithValue(analytics),
    crashReporterProvider.overrideWithValue(crash),
    adsServiceProvider.overrideWithValue(ads),
    purchasesServiceProvider.overrideWithValue(purchases),
    audioServiceProvider.overrideWithValue(audio),
    hapticsServiceProvider.overrideWithValue(DeviceHapticsService()),
    shareServiceProvider.overrideWithValue(SystemShareService()),
    levelRepositoryProvider.overrideWithValue(
      LevelRepository(
        bundle: rootBundle,
        cacheDir: getApplicationSupportDirectory,
      ),
    ),
  ];
}
