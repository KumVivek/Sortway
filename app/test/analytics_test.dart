import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flow_sort/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void _fireEverything(Analytics a) {
  a
    ..ageCheckDone(AgeBand.adult)
    ..tutorialStep('locked_bin')
    ..levelStart(level: 'L001', pack: 'core_001', mechanic: 'basic')
    ..levelComplete(
      level: 'L001',
      timeS: 12,
      livesLeft: 3,
      stars: 3,
      boostersUsed: 0,
    )
    ..levelFail(level: 'L001', reason: 'wrong_bin')
    ..levelQuit(level: 'L001', secondsIn: 4)
    ..boosterUsed(type: 'undo', level: 'L001', source: 'coins')
    ..adOfferShown(placement: 'double_coins', level: 'L001')
    ..adWatched(placement: 'double_coins', level: 'L001')
    ..interstitialShown(level: 'L010')
    ..iapView(product: 'remove_ads', price: '₹249')
    ..iapPurchase(product: 'remove_ads', price: '₹249')
    ..stickerEarned(set: 0, index: 3)
    ..setComplete(set: 0)
    ..dailyChallenge(result: 'win', streak: 2)
    ..sessionEnd(levelsPlayed: 5, minutes: 9);
}

void main() {
  for (final band in [AgeBand.minor, AgeBand.unknown, AgeBand.child]) {
    test('${band.name}: no analytics event is ever sent', () {
      final sink = RecordingAnalyticsService();
      _fireEverything(Analytics(sink, () => AgePolicy(band)));
      expect(sink.events, isEmpty);
    });
  }

  test('adult: every plan section 10 event is sent with its params', () {
    final sink = RecordingAnalyticsService();
    _fireEverything(Analytics(sink, () => const AgePolicy(AgeBand.adult)));
    expect(
      [for (final e in sink.events) e.name],
      [
        'age_check_done',
        'tutorial_step',
        'level_start',
        'level_complete',
        'level_fail',
        'level_quit',
        'booster_used',
        'ad_offer_shown',
        'ad_watched',
        'interstitial_shown',
        'iap_view',
        'iap_purchase',
        'sticker_earned',
        'set_complete',
        'daily_challenge',
        'session_end',
      ],
    );
    final complete = sink.events[3].params;
    expect(complete.keys, {
      'level',
      'time_s',
      'lives_left',
      'stars',
      'boosters_used',
    });
    expect(sink.events[0].params, {'band': 'adult'});
    expect(sink.events.first.toString(), contains('age_check_done'));
  });

  test('the gate follows the policy as it changes', () {
    final sink = RecordingAnalyticsService();
    var policy = AgePolicy.unanswered;
    final a = Analytics(sink, () => policy);
    a.tutorialStep('one');
    policy = const AgePolicy(AgeBand.adult);
    a.tutorialStep('two');
    policy = const AgePolicy(AgeBand.minor);
    a.tutorialStep('three');
    expect(sink.events.single.params, {'step': 'two'});
  });
}
