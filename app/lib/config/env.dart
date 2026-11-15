import 'package:flutter/foundation.dart';

/// Build-time configuration, supplied with `--dart-define-from-file`.
///
/// With no defines the app runs in *local mode*: no Firebase, simulated ads
/// and purchases (debug/profile builds only). See `app/config/`.
abstract final class Env {
  /// `dev` or `prod`.
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  /// Turn on Firebase (Analytics, Crashlytics, Remote Config). Requires the
  /// platform config files produced by `flutterfire configure`.
  static const useFirebase = bool.fromEnvironment('USE_FIREBASE');

  /// Turn on AdMob. Unit ids default to Google's public test units.
  static const useAdMob = bool.fromEnvironment('USE_ADMOB');

  static const admobRewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const admobInterstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const admobRewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );
  static const admobInterstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );

  /// RevenueCat public SDK keys. Empty = store purchases unavailable.
  static const revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );
  static const revenueCatIosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

  /// Shown on the privacy page.
  static const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  static bool get isProd => flavor == 'prod';

  /// Simulated ads/purchases are only ever allowed outside release builds.
  static bool get allowSimulatedServices => !kReleaseMode;
}

/// Must match `version:` in pubspec.yaml (checked by a test). Compared with
/// the `force_update_min_version` Remote Config key.
const String kAppVersion = '1.0.0';
