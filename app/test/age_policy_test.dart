import 'package:flow_sort/features/monetization/ads_service.dart';
import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('age band from birth year', () {
    AgeBand band(int year) => ageBandForBirthYear(year, currentYear: 2026);

    test('adult only when 18 is certain whatever the birthday', () {
      expect(band(2007), AgeBand.adult); // 18 or 19
      expect(band(1990), AgeBand.adult);
      expect(band(2008), AgeBand.minor); // could still be 17
    });

    test('13+ only when that is certain', () {
      expect(band(2012), AgeBand.minor); // 13 or 14
      expect(band(2013), AgeBand.child); // could still be 12
      expect(band(2020), AgeBand.child);
      expect(band(2026), AgeBand.child);
    });

    test('band names round trip; junk is rejected', () {
      for (final b in AgeBand.values) {
        expect(AgeBand.tryParse(b.name), b);
      }
      expect(AgeBand.tryParse('2008'), isNull);
      expect(AgeBand.tryParse(null), isNull);
    });
  });

  group('policy flags (plan section 8)', () {
    test('adult', () {
      const p = AgePolicy(AgeBand.adult);
      expect(p.personalizedAds, isTrue);
      expect(p.analyticsEnabled, isTrue);
      expect(p.purchasesNeedGate, isFalse);
      expect(p.tagForUnderAgeOfConsent, isFalse);
      expect(p.tagForChildDirectedTreatment, isFalse);
      expect(p.maxAdContentRating, isNull);
      expect(p.consentSignalsGranted, isTrue);
      expect(p.mediationAllowed, isTrue);
      expect(p.mayShowConsentForm, isTrue);
      expect(p.pushOptInAllowed, isTrue);
      expect(p.crashUserIdAllowed, isFalse);
    });

    for (final band in [AgeBand.minor, AgeBand.unknown, AgeBand.child]) {
      test('${band.name} is restricted', () {
        final p = AgePolicy(band);
        expect(p.personalizedAds, isFalse);
        expect(p.analyticsEnabled, isFalse);
        expect(p.purchasesNeedGate, isTrue);
        expect(p.tagForUnderAgeOfConsent, isTrue);
        expect(p.maxAdContentRating, 'G');
        expect(p.consentSignalsGranted, isFalse);
        expect(p.mediationAllowed, isFalse);
        expect(p.mayShowConsentForm, isFalse);
        expect(p.pushOptInAllowed, isFalse);
        expect(p.crashUserIdAllowed, isFalse);
      });
    }

    test('unknown is treated exactly like minor', () {
      const a = AgePolicy(AgeBand.minor);
      const b = AgePolicy(AgeBand.unknown);
      expect(b.tagForChildDirectedTreatment, a.tagForChildDirectedTreatment);
      expect(b.personalizedAds, a.personalizedAds);
      expect(b.analyticsEnabled, a.analyticsEnabled);
      expect(AgePolicy.unanswered, b);
      expect(AgePolicy.unanswered.hashCode, b.hashCode);
    });

    test('child-directed tag is for the under-13 band only', () {
      expect(
        const AgePolicy(AgeBand.child).tagForChildDirectedTreatment,
        isTrue,
      );
      expect(
        const AgePolicy(AgeBand.minor).tagForChildDirectedTreatment,
        isFalse,
      );
    });
  });

  group('ad request profile', () {
    test('minor: non-personalized, tagged, G rated, no consent form', () {
      final p = AdRequestProfile.forPolicy(const AgePolicy(AgeBand.minor));
      expect(p.nonPersonalizedOnly, isTrue);
      expect(p.tagForUnderAgeOfConsent, isTrue);
      expect(p.tagForChildDirectedTreatment, isFalse);
      expect(p.maxAdContentRating, 'G');
      expect(p.mayShowConsentForm, isFalse);
    });

    test('adult: personalization allowed, consent form may show', () {
      final p = AdRequestProfile.forPolicy(const AgePolicy(AgeBand.adult));
      expect(p.nonPersonalizedOnly, isFalse);
      expect(p.tagForUnderAgeOfConsent, isFalse);
      expect(p.maxAdContentRating, isNull);
      expect(p.mayShowConsentForm, isTrue);
    });
  });
}
