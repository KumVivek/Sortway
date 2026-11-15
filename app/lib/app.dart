import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/env.dart';
import 'features/home/home_screen.dart';
import 'features/levels/level_map_screen.dart';
import 'features/meta/album_screen.dart';
import 'features/meta/daily_screen.dart';
import 'features/monetization/shop_screen.dart';
import 'features/onboarding/age_gate_screen.dart';
import 'features/onboarding/age_policy.dart';
import 'features/play/play_screen.dart';
import 'features/settings/settings_screen.dart';
import 'l10n/gen/app_localizations.dart';
import 'providers.dart';
import 'services/remote_config_service.dart';
import 'ui/theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref
    ..listen(
      settingsProvider.select((s) => s.ageBand),
      (_, __) => refresh.value++,
    )
    ..listen(
      remoteConfigProvider.select((c) => c.forceUpdateMinVersion),
      (_, __) => refresh.value++,
    )
    ..onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final at = state.matchedLocation;
      final minVersion = ref.read(remoteConfigProvider).forceUpdateMinVersion;
      if (compareVersions(kAppVersion, minVersion) < 0) {
        return at == '/update' ? null : '/update';
      }
      if (at == '/update') return '/';
      // The age question comes before anything else, and again after a reset.
      if (ref.read(settingsProvider).ageBand == null) {
        return at == '/age' ? null : '/age';
      }
      if (at == '/age') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/age', builder: (_, __) => const AgeGateScreen()),
      GoRoute(
        path: '/update',
        builder: (_, __) => const UpdateRequiredScreen(),
      ),
      GoRoute(path: '/map', builder: (_, __) => const LevelMapScreen()),
      GoRoute(path: '/album', builder: (_, __) => const AlbumScreen()),
      GoRoute(path: '/daily', builder: (_, __) => const DailyScreen()),
      GoRoute(path: '/event', builder: (_, __) => const EventScreen()),
      GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'privacy', builder: (_, __) => const PrivacyScreen()),
        ],
      ),
      GoRoute(
        path: '/play',
        builder:
            (_, state) => PlayScreen(
              refCode: state.uri.queryParameters['ref'] ?? '',
              resume: state.uri.queryParameters['resume'] == '1',
            ),
      ),
    ],
  );
});

class FlowSortApp extends ConsumerStatefulWidget {
  const FlowSortApp({super.key});

  @override
  ConsumerState<FlowSortApp> createState() => _FlowSortAppState();
}

class _FlowSortAppState extends ConsumerState<FlowSortApp>
    with WidgetsBindingObserver {
  bool _adsStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The one place age policy is pushed into the SDK-facing services. It
    // follows the stored answer rather than the derived policy, because
    // "skipped" and "not asked yet" map to the same (most restrictive)
    // policy but only the first may start the ad SDK.
    ref.listenManual(
      settingsProvider.select((s) => s.ageBand),
      (_, band) => _applyPolicy(band),
      fireImmediately: true,
    );
    _startServices();
  }

  Future<void> _applyPolicy(AgeBand? band) async {
    final policy = band == null ? AgePolicy.unanswered : AgePolicy(band);
    final crash = ref.read(crashReporterProvider);
    try {
      await ref.read(analyticsServiceProvider).applyPolicy(policy);
      final ads = ref.read(adsServiceProvider);
      if (_adsStarted) {
        // Also covers an age reset: ads fall back to the restrictive flags.
        await ads.applyPolicy(policy);
      } else if (band != null) {
        // No ad SDK activity at all until the age question is answered.
        _adsStarted = true;
        await ads.initialize(policy);
      }
    } on Object catch (e, st) {
      await crash.recordError(e, st);
    }
  }

  Future<void> _startServices() async {
    final crash = ref.read(crashReporterProvider);
    try {
      await ref.read(purchasesServiceProvider).initialize();
      await ref.read(removeAdsProvider.notifier).refresh();
      await ref.read(remoteConfigServiceProvider).refresh();
      final manifest = ref.read(remoteConfigProvider).levelPackManifest;
      final saved = await ref.read(levelRepositoryProvider).syncPacks(manifest);
      if (saved > 0) ref.invalidate(campaignProvider);
    } on Object catch (e, st) {
      await crash.recordError(e, st);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = ref.read(audioServiceProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        audio.resumeMusic();
        ref.read(remoteConfigServiceProvider).refresh();
      case AppLifecycleState.paused:
        audio.pauseMusic();
        final stats = ref.read(sessionStatsProvider);
        ref
            .read(analyticsProvider)
            .sessionEnd(
              levelsPlayed: stats.levelsPlayed,
              minutes: DateTime.now().difference(stats.startedAt).inMinutes,
            );
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(settingsProvider.select((s) => s.languageCode));
    return MaterialApp.router(
      title: 'Flow Sort',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
      locale: language == null ? null : Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder:
          (context, child) => MediaQuery.withClampedTextScaling(
            // Keeps the fixed-height HUD usable at large accessibility sizes.
            maxScaleFactor: 1.3,
            child: child!,
          ),
    );
  }
}
