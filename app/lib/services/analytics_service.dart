import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../features/onboarding/age_policy.dart';

/// Low-level analytics sink. Use [Analytics] from app code.
abstract class AnalyticsService {
  /// Applies collection + consent-mode settings for [policy].
  Future<void> applyPolicy(AgePolicy policy);

  Future<void> logEvent(String name, Map<String, Object> params);
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._fa);

  final FirebaseAnalytics _fa;

  @override
  Future<void> applyPolicy(AgePolicy policy) async {
    final granted = policy.consentSignalsGranted;
    await _fa.setConsent(
      adStorageConsentGranted: granted,
      adUserDataConsentGranted: granted,
      adPersonalizationSignalsConsentGranted: granted,
      analyticsStorageConsentGranted: granted,
    );
    await _fa.setAnalyticsCollectionEnabled(policy.analyticsEnabled);
  }

  @override
  Future<void> logEvent(String name, Map<String, Object> params) =>
      _fa.logEvent(name: name, parameters: params);
}

class LoggedEvent {
  const LoggedEvent(this.name, this.params);

  final String name;
  final Map<String, Object> params;

  @override
  String toString() => '$name $params';
}

/// Fake used in tests and in local mode. Records everything it is given.
class RecordingAnalyticsService implements AnalyticsService {
  RecordingAnalyticsService({this.echo = false});

  final bool echo;
  final List<LoggedEvent> events = [];
  final List<AgePolicy> policies = [];

  @override
  Future<void> applyPolicy(AgePolicy policy) async => policies.add(policy);

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    events.add(LoggedEvent(name, params));
    if (echo) debugPrint('[analytics] $name $params');
  }
}

/// Typed analytics events (plan §10). Nothing is sent unless
/// `AgePolicy.analyticsEnabled` is true at the moment of the call.
class Analytics {
  Analytics(this._service, this._policy);

  final AnalyticsService _service;
  final AgePolicy Function() _policy;

  void _log(String name, [Map<String, Object> params = const {}]) {
    if (!_policy().analyticsEnabled) return;
    _service.logEvent(name, params).catchError((Object e) {
      debugPrint('analytics "$name" failed: $e');
    });
  }

  /// Adults only: for minors nothing at all is sent.
  void ageCheckDone(AgeBand band) =>
      _log('age_check_done', {'band': band.name});

  void tutorialStep(String step) => _log('tutorial_step', {'step': step});

  void levelStart({
    required String level,
    required String pack,
    required String mechanic,
  }) =>
      _log('level_start', {'level': level, 'pack': pack, 'mechanic': mechanic});

  void levelComplete({
    required String level,
    required int timeS,
    required int livesLeft,
    required int stars,
    required int boostersUsed,
  }) => _log('level_complete', {
    'level': level,
    'time_s': timeS,
    'lives_left': livesLeft,
    'stars': stars,
    'boosters_used': boostersUsed,
  });

  /// [reason] is `wrong_bin` or `overflow`.
  void levelFail({required String level, required String reason}) =>
      _log('level_fail', {'level': level, 'reason': reason});

  void levelQuit({required String level, required int secondsIn}) =>
      _log('level_quit', {'level': level, 'seconds_in': secondsIn});

  /// [source] is `coins` or `ad`.
  void boosterUsed({
    required String type,
    required String level,
    required String source,
  }) => _log('booster_used', {'type': type, 'level': level, 'source': source});

  void adOfferShown({required String placement, required String level}) =>
      _log('ad_offer_shown', {'placement': placement, 'level': level});

  void adWatched({required String placement, required String level}) =>
      _log('ad_watched', {'placement': placement, 'level': level});

  void interstitialShown({required String level}) =>
      _log('interstitial_shown', {'level': level});

  void iapView({required String product, required String price}) =>
      _log('iap_view', {'product': product, 'price': price});

  void iapPurchase({required String product, required String price}) =>
      _log('iap_purchase', {'product': product, 'price': price});

  void stickerEarned({required int set, required int index}) =>
      _log('sticker_earned', {'set': set, 'index': index});

  void setComplete({required int set}) =>
      _log('set_complete', {'set': set, 'index': 0});

  void dailyChallenge({required String result, required int streak}) =>
      _log('daily_challenge', {'result': result, 'streak': streak});

  void levelShared({required String level, required int stars}) =>
      _log('level_share', {'level': level, 'stars': stars});

  void sessionEnd({required int levelsPlayed, required int minutes}) =>
      _log('session_end', {'levels_played': levelsPlayed, 'minutes': minutes});
}
