/// Age band derived from the year-of-birth picker. Only the band is stored,
/// never the year (plan §8).
enum AgeBand {
  /// 18 or older.
  adult,

  /// 13 to 17.
  minor,

  /// Under 13.
  child,

  /// The player skipped the question. Treated exactly like [minor].
  unknown;

  static AgeBand? tryParse(String? name) {
    for (final b in values) {
      if (b.name == name) return b;
    }
    return null;
  }
}

/// Maps a birth year to a band. Only the year is asked, so a birthday later
/// this year is assumed: a player is counted as an adult (or as 13+) only if
/// that is true whatever their birthday is.
AgeBand ageBandForBirthYear(int birthYear, {required int currentYear}) {
  final youngestPossibleAge = currentYear - birthYear - 1;
  if (youngestPossibleAge >= 18) return AgeBand.adult;
  if (youngestPossibleAge >= 13) return AgeBand.minor;
  return AgeBand.child;
}

/// The single place that decides what each age band is allowed (plan §8).
/// Services read these flags; no service decides on its own.
class AgePolicy {
  const AgePolicy(this.band);

  /// Policy before the age question is answered: the most restrictive one.
  static const AgePolicy unanswered = AgePolicy(AgeBand.unknown);

  final AgeBand band;

  bool get isAdult => band == AgeBand.adult;

  /// Personalized ads may be requested (still subject to UMP consent in the
  /// EU/UK). Everyone else gets non-personalized ads only.
  bool get personalizedAds => isAdult;

  /// Firebase Analytics collection and all analytics events.
  bool get analyticsEnabled => isAdult;

  /// Real-money purchases must pass the parental gate first.
  bool get purchasesNeedGate => !isAdult;

  /// Sharing a result leaves the game for another app, so anyone who is not
  /// a confirmed adult passes the parental gate first.
  bool get sharingNeedsGate => !isAdult;

  /// AdMob `tagForUnderAgeOfConsent`.
  bool get tagForUnderAgeOfConsent => !isAdult;

  /// AdMob `tagForChildDirectedTreatment`: under-13 band only.
  bool get tagForChildDirectedTreatment => band == AgeBand.child;

  /// AdMob `maxAdContentRating`; null leaves it unrestricted.
  String? get maxAdContentRating => isAdult ? null : 'G';

  /// Consent-mode signals (ad_storage, ad_user_data, ad_personalization,
  /// analytics_storage) are denied for everyone but adults.
  bool get consentSignalsGranted => isAdult;

  /// Mediation networks beyond AdMob.
  bool get mediationAllowed => isAdult;

  /// The UMP consent form may be shown (never to minors).
  bool get mayShowConsentForm => isAdult;

  /// Crash reports never carry a user id or personal custom keys.
  bool get crashUserIdAllowed => false;

  /// Push notifications are opt-in for adults and off for everyone else.
  bool get pushOptInAllowed => isAdult;

  @override
  bool operator ==(Object other) => other is AgePolicy && other.band == band;

  @override
  int get hashCode => band.hashCode;
}
