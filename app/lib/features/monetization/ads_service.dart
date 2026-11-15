import '../../services/remote_config_service.dart';
import '../onboarding/age_policy.dart';

enum RewardedPlacement {
  doubleCoins('double_coins'),
  extraLife('extra_life'),
  undo('undo');

  const RewardedPlacement(this.id);
  final String id;
}

/// Ads behind an interface so tests and local mode never touch a real SDK.
abstract class AdsService {
  /// Whether ads exist at all in this build (false hides every ad offer).
  bool get available;

  /// Configures the SDK for [policy] and starts loading ads. Must be called
  /// only after the age question has been answered.
  Future<void> initialize(AgePolicy policy);

  /// Re-applies child-safety flags after the age band changes.
  Future<void> applyPolicy(AgePolicy policy);

  /// Shows a rewarded video. Completes true only if the reward was earned.
  Future<bool> showRewarded(RewardedPlacement placement);

  /// Shows an interstitial if one is loaded. Completes true if it was shown.
  Future<bool> showInterstitial();
}

/// How ad requests must be tagged for an age band (plan §8 table). Pure, so
/// both bands can be unit-tested without the SDK.
class AdRequestProfile {
  const AdRequestProfile({
    required this.nonPersonalizedOnly,
    required this.tagForUnderAgeOfConsent,
    required this.tagForChildDirectedTreatment,
    required this.maxAdContentRating,
    required this.mayShowConsentForm,
  });

  factory AdRequestProfile.forPolicy(AgePolicy policy) => AdRequestProfile(
    nonPersonalizedOnly: !policy.personalizedAds,
    tagForUnderAgeOfConsent: policy.tagForUnderAgeOfConsent,
    tagForChildDirectedTreatment: policy.tagForChildDirectedTreatment,
    maxAdContentRating: policy.maxAdContentRating,
    mayShowConsentForm: policy.mayShowConsentForm,
  );

  final bool nonPersonalizedOnly;
  final bool tagForUnderAgeOfConsent;
  final bool tagForChildDirectedTreatment;
  final String? maxAdContentRating;
  final bool mayShowConsentForm;
}

/// Interstitial frequency caps (plan §9): none before a given level, and a
/// minimum number of levels and seconds between two of them.
class InterstitialPolicy {
  InterstitialPolicy({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _lastShown = _clock();
  }

  final DateTime Function() _clock;
  late DateTime _lastShown;
  int _levelsSinceLast = 0;

  /// Call once for every finished level (won or lost).
  void onLevelFinished() => _levelsSinceLast++;

  bool shouldShow({
    required int levelNumber,
    required RemoteConfigValues config,
    required bool removeAds,
  }) {
    if (removeAds) return false;
    if (levelNumber < config.interstitialFirstLevel) return false;
    if (_levelsSinceLast < config.interstitialMinGapLevels) return false;
    final elapsed = _clock().difference(_lastShown).inSeconds;
    return elapsed >= config.interstitialMinGapSeconds;
  }

  void onShown() {
    _levelsSinceLast = 0;
    _lastShown = _clock();
  }
}

/// Scripted fake for tests.
class FakeAdsService implements AdsService {
  FakeAdsService({this.available = true, this.rewardResult = true});

  @override
  bool available;
  bool rewardResult;
  bool interstitialLoaded = true;

  final List<AgePolicy> policies = [];
  final List<RewardedPlacement> rewardedShown = [];
  int interstitialsShown = 0;

  AdRequestProfile? get profile =>
      policies.isEmpty ? null : AdRequestProfile.forPolicy(policies.last);

  @override
  Future<void> initialize(AgePolicy policy) async => policies.add(policy);

  @override
  Future<void> applyPolicy(AgePolicy policy) async => policies.add(policy);

  @override
  Future<bool> showRewarded(RewardedPlacement placement) async {
    if (!available) return false;
    rewardedShown.add(placement);
    return rewardResult;
  }

  @override
  Future<bool> showInterstitial() async {
    if (!available || !interstitialLoaded) return false;
    interstitialsShown++;
    return true;
  }
}

/// Used when a build has no ad configuration: no ads, no ad offers.
class NoAdsService implements AdsService {
  @override
  bool get available => false;
  @override
  Future<void> initialize(AgePolicy policy) async {}
  @override
  Future<void> applyPolicy(AgePolicy policy) async {}
  @override
  Future<bool> showRewarded(RewardedPlacement placement) async => false;
  @override
  Future<bool> showInterstitial() async => false;
}
