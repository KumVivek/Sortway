import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flow Sort'**
  String get appTitle;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String levelN(int n);

  /// No description provided for @levels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levels;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @ageTitle.
  ///
  /// In en, this message translates to:
  /// **'What year were you born?'**
  String get ageTitle;

  /// No description provided for @ageBody.
  ///
  /// In en, this message translates to:
  /// **'This sets up the game for you. We only keep an age group on this device, never the year.'**
  String get ageBody;

  /// No description provided for @ageSelectYear.
  ///
  /// In en, this message translates to:
  /// **'Select a year'**
  String get ageSelectYear;

  /// No description provided for @ageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get ageContinue;

  /// No description provided for @ageSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get ageSkip;

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off?'**
  String get resumeTitle;

  /// No description provided for @resumeBody.
  ///
  /// In en, this message translates to:
  /// **'You left {name} unfinished.'**
  String resumeBody(String name);

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @tutTapSwitch.
  ///
  /// In en, this message translates to:
  /// **'Tap the switch to send each item to the bin of the same colour.'**
  String get tutTapSwitch;

  /// No description provided for @tutLookAhead.
  ///
  /// In en, this message translates to:
  /// **'Watch the belt. Flip the switch before the next item drops.'**
  String get tutLookAhead;

  /// No description provided for @tutSecondSwitch.
  ///
  /// In en, this message translates to:
  /// **'Two switches now. The bright path shows where the next item will go.'**
  String get tutSecondSwitch;

  /// No description provided for @tutLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Locked bins'**
  String get tutLockedTitle;

  /// No description provided for @tutLockedBody.
  ///
  /// In en, this message translates to:
  /// **'A locked bin opens after you deliver the number of items shown on its lock. Send nothing there until it opens.'**
  String get tutLockedBody;

  /// No description provided for @tutGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Colour gates'**
  String get tutGateTitle;

  /// No description provided for @tutGateBody.
  ///
  /// In en, this message translates to:
  /// **'A gate repaints every item that passes through it. Use it for items that have no bin of their own.'**
  String get tutGateBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @quitLevel.
  ///
  /// In en, this message translates to:
  /// **'Quit level'**
  String get quitLevel;

  /// No description provided for @itemsLeft.
  ///
  /// In en, this message translates to:
  /// **'{n} left'**
  String itemsLeft(int n);

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go!'**
  String get go;

  /// No description provided for @boosterUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get boosterUndo;

  /// No description provided for @boosterLife.
  ///
  /// In en, this message translates to:
  /// **'+1 Life'**
  String get boosterLife;

  /// No description provided for @boosterSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get boosterSlow;

  /// No description provided for @notEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get notEnoughCoins;

  /// No description provided for @getCoins.
  ///
  /// In en, this message translates to:
  /// **'Get coins'**
  String get getCoins;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get watchAd;

  /// No description provided for @adUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No ad is available right now. Try again in a moment.'**
  String get adUnavailable;

  /// No description provided for @adOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Use it for free?'**
  String get adOfferTitle;

  /// No description provided for @adOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video to use this booster without spending coins.'**
  String get adOfferBody;

  /// No description provided for @useCoins.
  ///
  /// In en, this message translates to:
  /// **'Use {n} coins'**
  String useCoins(int n);

  /// No description provided for @levelComplete.
  ///
  /// In en, this message translates to:
  /// **'Level complete!'**
  String get levelComplete;

  /// No description provided for @coinsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{n} coins'**
  String coinsEarned(int n);

  /// No description provided for @doubleCoins.
  ///
  /// In en, this message translates to:
  /// **'Double coins'**
  String get doubleCoins;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replay;

  /// No description provided for @levelMap.
  ///
  /// In en, this message translates to:
  /// **'Level map'**
  String get levelMap;

  /// No description provided for @newSticker.
  ///
  /// In en, this message translates to:
  /// **'New sticker!'**
  String get newSticker;

  /// No description provided for @setCompleteBonus.
  ///
  /// In en, this message translates to:
  /// **'Set complete! +{n} coins'**
  String setCompleteBonus(int n);

  /// No description provided for @outOfLives.
  ///
  /// In en, this message translates to:
  /// **'Out of lives'**
  String get outOfLives;

  /// No description provided for @failWrongBin.
  ///
  /// In en, this message translates to:
  /// **'That item went to the wrong bin.'**
  String get failWrongBin;

  /// No description provided for @failOverflow.
  ///
  /// In en, this message translates to:
  /// **'That bin was already full.'**
  String get failOverflow;

  /// No description provided for @failLocked.
  ///
  /// In en, this message translates to:
  /// **'That bin was still locked.'**
  String get failLocked;

  /// No description provided for @undoLastItem.
  ///
  /// In en, this message translates to:
  /// **'Undo last item'**
  String get undoLastItem;

  /// No description provided for @extraLife.
  ///
  /// In en, this message translates to:
  /// **'Extra life'**
  String get extraLife;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @setN.
  ///
  /// In en, this message translates to:
  /// **'Set {n}'**
  String setN(int n);

  /// No description provided for @allLevelsDone.
  ///
  /// In en, this message translates to:
  /// **'You finished every level! More are on the way.'**
  String get allLevelsDone;

  /// No description provided for @albumTitle.
  ///
  /// In en, this message translates to:
  /// **'Sticker album'**
  String get albumTitle;

  /// No description provided for @albumHint.
  ///
  /// In en, this message translates to:
  /// **'Finish a new level to earn a sticker.'**
  String get albumHint;

  /// No description provided for @countOf.
  ///
  /// In en, this message translates to:
  /// **'{have}/{total}'**
  String countOf(int have, int total);

  /// No description provided for @dailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get dailyTitle;

  /// No description provided for @dailyBody.
  ///
  /// In en, this message translates to:
  /// **'One new level every day, the same for everyone.'**
  String get dailyBody;

  /// No description provided for @dailyStreak.
  ///
  /// In en, this message translates to:
  /// **'{n}-day streak'**
  String dailyStreak(int n);

  /// No description provided for @dailyReward.
  ///
  /// In en, this message translates to:
  /// **'Reward: {n} coins'**
  String dailyReward(int n);

  /// No description provided for @dailyDone.
  ///
  /// In en, this message translates to:
  /// **'Done for today. Come back tomorrow!'**
  String get dailyDone;

  /// No description provided for @dailyPlay.
  ///
  /// In en, this message translates to:
  /// **'Play today\'s level'**
  String get dailyPlay;

  /// No description provided for @dailyName.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get dailyName;

  /// No description provided for @eventReward.
  ///
  /// In en, this message translates to:
  /// **'Finish all {count} levels for {n} coins'**
  String eventReward(int count, int n);

  /// No description provided for @eventDone.
  ///
  /// In en, this message translates to:
  /// **'Event complete!'**
  String get eventDone;

  /// No description provided for @eventLevel.
  ///
  /// In en, this message translates to:
  /// **'Event level {n}'**
  String eventLevel(int n);

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @removeAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get removeAds;

  /// No description provided for @removeAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'No more ads between levels. Reward videos stay optional.'**
  String get removeAdsDesc;

  /// No description provided for @coinPack.
  ///
  /// In en, this message translates to:
  /// **'{n} coins'**
  String coinPack(int n);

  /// No description provided for @starterPack.
  ///
  /// In en, this message translates to:
  /// **'Starter pack'**
  String get starterPack;

  /// No description provided for @starterDesc.
  ///
  /// In en, this message translates to:
  /// **'{n} coins, one time only'**
  String starterDesc(int n);

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @purchaseDone.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your purchase is complete.'**
  String get purchaseDone;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase did not go through. You were not charged.'**
  String get purchaseFailed;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is not available right now.'**
  String get storeUnavailable;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get owned;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get restored;

  /// No description provided for @nothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore.'**
  String get nothingToRestore;

  /// No description provided for @realMoney.
  ///
  /// In en, this message translates to:
  /// **'Costs real money'**
  String get realMoney;

  /// No description provided for @gateTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask a grown-up'**
  String get gateTitle;

  /// No description provided for @gateBody.
  ///
  /// In en, this message translates to:
  /// **'A parent or guardian needs to answer this to continue:'**
  String get gateBody;

  /// No description provided for @gateQuestion.
  ///
  /// In en, this message translates to:
  /// **'{a} × {b} = ?'**
  String gateQuestion(int a, int b);

  /// No description provided for @gateAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get gateAnswer;

  /// No description provided for @gateWrong.
  ///
  /// In en, this message translates to:
  /// **'That is not right. Try again.'**
  String get gateWrong;

  /// No description provided for @gatePrice.
  ///
  /// In en, this message translates to:
  /// **'This purchase charges {price} of real money.'**
  String gatePrice(String price);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get sound;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get haptics;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @ageReset.
  ///
  /// In en, this message translates to:
  /// **'Change age group'**
  String get ageReset;

  /// No description provided for @ageResetBody.
  ///
  /// In en, this message translates to:
  /// **'You will be asked for your birth year again.'**
  String get ageResetBody;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {v}'**
  String version(String v);

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update needed'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In en, this message translates to:
  /// **'Please update Flow Sort to keep playing.'**
  String get updateBody;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get privacyTitle;

  /// No description provided for @privacyData.
  ///
  /// In en, this message translates to:
  /// **'Flow Sort does not ask for your name, email, photos, contacts or location. Your progress, coins and stickers are stored only on this device.'**
  String get privacyData;

  /// No description provided for @privacyAge.
  ///
  /// In en, this message translates to:
  /// **'We ask for a birth year once and keep only an age group on this device. It decides which rows below apply to you.'**
  String get privacyAge;

  /// No description provided for @privacyAds.
  ///
  /// In en, this message translates to:
  /// **'Ads (Google AdMob): players under 18, or who skipped the age question, only see non-personalized ads rated for general audiences. Adults may see personalized ads, after consent where the law requires it.'**
  String get privacyAds;

  /// No description provided for @privacyAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics (Google Firebase Analytics): collected for adults only, to see which levels are too hard. It is switched off for everyone else.'**
  String get privacyAnalytics;

  /// No description provided for @privacyCrash.
  ///
  /// In en, this message translates to:
  /// **'Crash reports (Google Firebase Crashlytics): technical details of a crash, with no user ID attached.'**
  String get privacyCrash;

  /// No description provided for @privacyPurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases (RevenueCat with Google Play or the App Store): handled by the store. We never see your payment details. Players under 18 need a grown-up to approve.'**
  String get privacyPurchases;

  /// No description provided for @privacyNone.
  ///
  /// In en, this message translates to:
  /// **'There is no chat, no free-text names and no social features inside the game. Sharing a result opens your device\'s own share menu; the picture contains only the level and stars, and the game never sees where you post it.'**
  String get privacyNone;

  /// No description provided for @privacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Full privacy policy: {url}'**
  String privacyPolicyLink(String url);

  /// No description provided for @privacyContact.
  ///
  /// In en, this message translates to:
  /// **'Questions: {email}'**
  String privacyContact(String email);

  /// No description provided for @simAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Test ad'**
  String get simAdTitle;

  /// No description provided for @simAdBody.
  ///
  /// In en, this message translates to:
  /// **'Simulated ad for local testing. Real ads appear in store builds.'**
  String get simAdBody;

  /// No description provided for @simAdClose.
  ///
  /// In en, this message translates to:
  /// **'Close ({n})'**
  String simAdClose(int n);

  /// No description provided for @starsLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} of 3 stars'**
  String starsLabel(int n);

  /// No description provided for @livesLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} lives'**
  String livesLabel(int n);

  /// No description provided for @coinsLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} coins'**
  String coinsLabel(int n);

  /// No description provided for @switchLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchLabel;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareLevelText.
  ///
  /// In en, this message translates to:
  /// **'I cleared Level {n} in Flow Sort with {stars} of 3 stars! Can you beat that?'**
  String shareLevelText(int n, int stars);

  /// No description provided for @shareDailyText.
  ///
  /// In en, this message translates to:
  /// **'I cleared today\'s Flow Sort daily challenge with {stars} of 3 stars! Can you beat that?'**
  String shareDailyText(int stars);

  /// No description provided for @shareEventText.
  ///
  /// In en, this message translates to:
  /// **'I cleared event level {n} in Flow Sort with {stars} of 3 stars! Can you beat that?'**
  String shareEventText(int n, int stars);

  /// No description provided for @shareCardTagline.
  ///
  /// In en, this message translates to:
  /// **'Can you sort it faster?'**
  String get shareCardTagline;

  /// No description provided for @shareFlips.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 flip} other{{n} flips}}'**
  String shareFlips(int n);

  /// No description provided for @gateShareNote.
  ///
  /// In en, this message translates to:
  /// **'Sharing opens another app outside the game.'**
  String get gateShareNote;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Sharing is not available right now.'**
  String get shareFailed;

  /// Spoken item or bin colour for screen readers.
  ///
  /// In en, this message translates to:
  /// **'{colour, select, red{Red} blue{Blue} green{Green} yellow{Yellow} purple{Purple} orange{Orange} pink{Pink} other{Hidden colour}}'**
  String a11yColour(String colour);

  /// No description provided for @a11yBoard.
  ///
  /// In en, this message translates to:
  /// **'Game board. Next item: {next}. {lives, plural, =1{1 life} other{{lives} lives}} left. {left, plural, =1{1 item} other{{left} items}} to sort.'**
  String a11yBoard(String next, int lives, int left);

  /// No description provided for @a11yNoItem.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get a11yNoItem;

  /// No description provided for @a11ySwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch {n}, points {dir, select, left{left} other{right}}'**
  String a11ySwitch(int n, String dir);

  /// No description provided for @a11ySwitchHint.
  ///
  /// In en, this message translates to:
  /// **'flip the switch'**
  String get a11ySwitchHint;

  /// No description provided for @a11yBin.
  ///
  /// In en, this message translates to:
  /// **'{colour} bin, {fill} of {capacity}'**
  String a11yBin(String colour, int fill, int capacity);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
