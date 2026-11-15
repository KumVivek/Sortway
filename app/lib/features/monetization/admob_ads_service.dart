import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/env.dart';
import '../onboarding/age_policy.dart';
import 'ads_service.dart';

/// AdMob implementation. Every request is tagged from [AdRequestProfile];
/// this class makes no age decisions of its own.
class AdMobAdsService implements AdsService {
  AdRequestProfile _profile = AdRequestProfile.forPolicy(AgePolicy.unanswered);
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _initialized = false;
  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;
  int _generation = 0;

  @override
  bool get available => true;

  String get _rewardedUnit =>
      Platform.isIOS ? Env.admobRewardedIos : Env.admobRewardedAndroid;
  String get _interstitialUnit =>
      Platform.isIOS ? Env.admobInterstitialIos : Env.admobInterstitialAndroid;

  AdRequest get _request =>
      AdRequest(nonPersonalizedAds: _profile.nonPersonalizedOnly);

  @override
  Future<void> initialize(AgePolicy policy) async {
    await _configure(policy);
    if (!_initialized) {
      await MobileAds.instance.initialize();
      _initialized = true;
    }
    _loadRewarded();
    _loadInterstitial();
  }

  @override
  Future<void> applyPolicy(AgePolicy policy) async {
    if (!_initialized) return initialize(policy);
    // Ads loaded under the old flags must not be shown under the new ones.
    _generation++;
    await _rewarded?.dispose();
    await _interstitial?.dispose();
    _rewarded = null;
    _interstitial = null;
    await _configure(policy);
    _loadRewarded();
    _loadInterstitial();
  }

  Future<void> _configure(AgePolicy policy) async {
    _profile = AdRequestProfile.forPolicy(policy);
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForUnderAgeOfConsent:
            _profile.tagForUnderAgeOfConsent
                ? TagForUnderAgeOfConsent.yes
                : TagForUnderAgeOfConsent.no,
        tagForChildDirectedTreatment:
            _profile.tagForChildDirectedTreatment
                ? TagForChildDirectedTreatment.yes
                : TagForChildDirectedTreatment.unspecified,
        maxAdContentRating:
            _profile.maxAdContentRating ?? MaxAdContentRating.unspecified,
      ),
    );
    await _gatherConsent();
  }

  /// UMP consent (EU/UK). Minors are tagged under the age of consent, which
  /// means no form is shown to them and they only get non-personalized ads.
  Future<void> _gatherConsent() {
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(
        tagForUnderAgeOfConsent: _profile.tagForUnderAgeOfConsent,
      ),
      () {
        if (!_profile.mayShowConsentForm) return finish();
        ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('UMP form: ${error.message}');
          finish();
        });
      },
      (error) {
        debugPrint('UMP update: ${error.message}');
        finish();
      },
    );
    return done.future.timeout(const Duration(seconds: 12), onTimeout: () {});
  }

  void _loadRewarded() {
    if (_rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    final generation = _generation;
    RewardedAd.load(
      adUnitId: _rewardedUnit,
      request: _request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          if (generation != _generation) {
            ad.dispose();
            _loadRewarded();
          } else {
            _rewarded = ad;
          }
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          debugPrint('Rewarded failed to load: ${error.message}');
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (_interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    final generation = _generation;
    InterstitialAd.load(
      adUnitId: _interstitialUnit,
      request: _request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          if (generation != _generation) {
            ad.dispose();
            _loadInterstitial();
          } else {
            _interstitial = ad;
          }
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint('Interstitial failed to load: ${error.message}');
        },
      ),
    );
  }

  @override
  Future<bool> showRewarded(RewardedPlacement placement) async {
    if (!_initialized) return false;
    if (_rewarded == null) {
      _loadRewarded();
      // Give a cold load a short chance before giving up.
      for (var i = 0; i < 16 && _rewarded == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (!_initialized || ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show();
    return done.future;
  }
}
