// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flow Sort';

  @override
  String get play => 'Play';

  @override
  String levelN(int n) {
    return 'Level $n';
  }

  @override
  String get levels => 'Levels';

  @override
  String get album => 'Album';

  @override
  String get daily => 'Daily';

  @override
  String get shop => 'Shop';

  @override
  String get settings => 'Settings';

  @override
  String get event => 'Event';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Try again';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get ageTitle => 'What year were you born?';

  @override
  String get ageBody => 'This sets up the game for you. We only keep an age group on this device, never the year.';

  @override
  String get ageSelectYear => 'Select a year';

  @override
  String get ageContinue => 'Continue';

  @override
  String get ageSkip => 'Skip';

  @override
  String get resumeTitle => 'Continue where you left off?';

  @override
  String resumeBody(String name) {
    return 'You left $name unfinished.';
  }

  @override
  String get resume => 'Resume';

  @override
  String get discard => 'Discard';

  @override
  String get tutTapSwitch => 'Tap the switch to send each item to the bin of the same colour.';

  @override
  String get tutLookAhead => 'Watch the belt. Flip the switch before the next item drops.';

  @override
  String get tutSecondSwitch => 'Two switches now. The bright path shows where the next item will go.';

  @override
  String get tutLockedTitle => 'Locked bins';

  @override
  String get tutLockedBody => 'A locked bin opens after you deliver the number of items shown on its lock. Send nothing there until it opens.';

  @override
  String get tutGateTitle => 'Colour gates';

  @override
  String get tutGateBody => 'A gate repaints every item that passes through it. Use it for items that have no bin of their own.';

  @override
  String get gotIt => 'Got it';

  @override
  String get paused => 'Paused';

  @override
  String get pause => 'Pause';

  @override
  String get restart => 'Restart';

  @override
  String get quitLevel => 'Quit level';

  @override
  String itemsLeft(int n) {
    return '$n left';
  }

  @override
  String get go => 'Go!';

  @override
  String get boosterUndo => 'Undo';

  @override
  String get boosterLife => '+1 Life';

  @override
  String get boosterSlow => 'Slow';

  @override
  String get notEnoughCoins => 'Not enough coins';

  @override
  String get getCoins => 'Get coins';

  @override
  String get watchAd => 'Watch ad';

  @override
  String get adUnavailable => 'No ad is available right now. Try again in a moment.';

  @override
  String get adOfferTitle => 'Use it for free?';

  @override
  String get adOfferBody => 'Watch a short video to use this booster without spending coins.';

  @override
  String useCoins(int n) {
    return 'Use $n coins';
  }

  @override
  String get levelComplete => 'Level complete!';

  @override
  String coinsEarned(int n) {
    return '+$n coins';
  }

  @override
  String get doubleCoins => 'Double coins';

  @override
  String get next => 'Next';

  @override
  String get replay => 'Replay';

  @override
  String get levelMap => 'Level map';

  @override
  String get newSticker => 'New sticker!';

  @override
  String setCompleteBonus(int n) {
    return 'Set complete! +$n coins';
  }

  @override
  String get outOfLives => 'Out of lives';

  @override
  String get failWrongBin => 'That item went to the wrong bin.';

  @override
  String get failOverflow => 'That bin was already full.';

  @override
  String get failLocked => 'That bin was still locked.';

  @override
  String get undoLastItem => 'Undo last item';

  @override
  String get extraLife => 'Extra life';

  @override
  String get free => 'Free';

  @override
  String get hard => 'Hard';

  @override
  String setN(int n) {
    return 'Set $n';
  }

  @override
  String get allLevelsDone => 'You finished every level! More are on the way.';

  @override
  String get albumTitle => 'Sticker album';

  @override
  String get albumHint => 'Finish a new level to earn a sticker.';

  @override
  String countOf(int have, int total) {
    return '$have/$total';
  }

  @override
  String get dailyTitle => 'Daily challenge';

  @override
  String get dailyBody => 'One new level every day, the same for everyone.';

  @override
  String dailyStreak(int n) {
    return '$n-day streak';
  }

  @override
  String dailyReward(int n) {
    return 'Reward: $n coins';
  }

  @override
  String get dailyDone => 'Done for today. Come back tomorrow!';

  @override
  String get dailyPlay => 'Play today\'s level';

  @override
  String get dailyName => 'Daily challenge';

  @override
  String eventReward(int count, int n) {
    return 'Finish all $count levels for $n coins';
  }

  @override
  String get eventDone => 'Event complete!';

  @override
  String eventLevel(int n) {
    return 'Event level $n';
  }

  @override
  String get shopTitle => 'Shop';

  @override
  String get removeAds => 'Remove ads';

  @override
  String get removeAdsDesc => 'No more ads between levels. Reward videos stay optional.';

  @override
  String coinPack(int n) {
    return '$n coins';
  }

  @override
  String get starterPack => 'Starter pack';

  @override
  String starterDesc(int n) {
    return '$n coins, one time only';
  }

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get purchaseDone => 'Thank you! Your purchase is complete.';

  @override
  String get purchaseFailed => 'The purchase did not go through. You were not charged.';

  @override
  String get storeUnavailable => 'The store is not available right now.';

  @override
  String get owned => 'Owned';

  @override
  String get restored => 'Purchases restored.';

  @override
  String get nothingToRestore => 'Nothing to restore.';

  @override
  String get realMoney => 'Costs real money';

  @override
  String get gateTitle => 'Ask a grown-up';

  @override
  String get gateBody => 'A parent or guardian needs to answer this to continue:';

  @override
  String gateQuestion(int a, int b) {
    return '$a × $b = ?';
  }

  @override
  String get gateAnswer => 'Answer';

  @override
  String get gateWrong => 'That is not right. Try again.';

  @override
  String gatePrice(String price) {
    return 'This purchase charges $price of real money.';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get sound => 'Sound effects';

  @override
  String get music => 'Music';

  @override
  String get haptics => 'Vibration';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get privacy => 'Privacy';

  @override
  String get ageReset => 'Change age group';

  @override
  String get ageResetBody => 'You will be asked for your birth year again.';

  @override
  String version(String v) {
    return 'Version $v';
  }

  @override
  String get updateTitle => 'Update needed';

  @override
  String get updateBody => 'Please update Flow Sort to keep playing.';

  @override
  String get privacyTitle => 'Your privacy';

  @override
  String get privacyData => 'Flow Sort does not ask for your name, email, photos, contacts or location. Your progress, coins and stickers are stored only on this device.';

  @override
  String get privacyAge => 'We ask for a birth year once and keep only an age group on this device. It decides which rows below apply to you.';

  @override
  String get privacyAds => 'Ads (Google AdMob): players under 18, or who skipped the age question, only see non-personalized ads rated for general audiences. Adults may see personalized ads, after consent where the law requires it.';

  @override
  String get privacyAnalytics => 'Analytics (Google Firebase Analytics): collected for adults only, to see which levels are too hard. It is switched off for everyone else.';

  @override
  String get privacyCrash => 'Crash reports (Google Firebase Crashlytics): technical details of a crash, with no user ID attached.';

  @override
  String get privacyPurchases => 'Purchases (RevenueCat with Google Play or the App Store): handled by the store. We never see your payment details. Players under 18 need a grown-up to approve.';

  @override
  String get privacyNone => 'There is no chat, no free-text names and no social features inside the game. Sharing a result opens your device\'s own share menu; the picture contains only the level and stars, and the game never sees where you post it.';

  @override
  String privacyPolicyLink(String url) {
    return 'Full privacy policy: $url';
  }

  @override
  String privacyContact(String email) {
    return 'Questions: $email';
  }

  @override
  String get simAdTitle => 'Test ad';

  @override
  String get simAdBody => 'Simulated ad for local testing. Real ads appear in store builds.';

  @override
  String simAdClose(int n) {
    return 'Close ($n)';
  }

  @override
  String starsLabel(int n) {
    return '$n of 3 stars';
  }

  @override
  String livesLabel(int n) {
    return '$n lives';
  }

  @override
  String coinsLabel(int n) {
    return '$n coins';
  }

  @override
  String get switchLabel => 'Switch';

  @override
  String get share => 'Share';

  @override
  String shareLevelText(int n, int stars) {
    return 'I cleared Level $n in Flow Sort with $stars of 3 stars! Can you beat that?';
  }

  @override
  String shareDailyText(int stars) {
    return 'I cleared today\'s Flow Sort daily challenge with $stars of 3 stars! Can you beat that?';
  }

  @override
  String shareEventText(int n, int stars) {
    return 'I cleared event level $n in Flow Sort with $stars of 3 stars! Can you beat that?';
  }

  @override
  String get shareCardTagline => 'Can you sort it faster?';

  @override
  String shareFlips(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n flips',
      one: '1 flip',
    );
    return '$_temp0';
  }

  @override
  String get gateShareNote => 'Sharing opens another app outside the game.';

  @override
  String get shareFailed => 'Sharing is not available right now.';
}
