// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Flow Sort';

  @override
  String get play => 'खेलें';

  @override
  String levelN(int n) {
    return 'लेवल $n';
  }

  @override
  String get levels => 'लेवल';

  @override
  String get album => 'एल्बम';

  @override
  String get daily => 'डेली';

  @override
  String get shop => 'दुकान';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get event => 'इवेंट';

  @override
  String get ok => 'ठीक है';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get close => 'बंद करें';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get errorGeneric => 'कुछ गड़बड़ हो गई।';

  @override
  String get ageTitle => 'आपका जन्म किस साल हुआ था?';

  @override
  String get ageBody => 'इससे गेम आपके लिए सेट होता है। हम इस डिवाइस पर सिर्फ़ उम्र का समूह रखते हैं, साल कभी नहीं।';

  @override
  String get ageSelectYear => 'साल चुनें';

  @override
  String get ageContinue => 'आगे बढ़ें';

  @override
  String get ageSkip => 'छोड़ें';

  @override
  String get resumeTitle => 'जहाँ छोड़ा था वहीं से जारी रखें?';

  @override
  String resumeBody(String name) {
    return 'आपने $name अधूरा छोड़ा था।';
  }

  @override
  String get resume => 'जारी रखें';

  @override
  String get discard => 'हटा दें';

  @override
  String get tutTapSwitch => 'हर चीज़ को उसी रंग के डिब्बे में भेजने के लिए स्विच पर टैप करें।';

  @override
  String get tutLookAhead => 'बेल्ट पर नज़र रखें। अगली चीज़ गिरने से पहले स्विच पलटें।';

  @override
  String get tutSecondSwitch => 'अब दो स्विच हैं। चमकता रास्ता दिखाता है कि अगली चीज़ कहाँ जाएगी।';

  @override
  String get tutLockedTitle => 'बंद डिब्बे';

  @override
  String get tutLockedBody => 'बंद डिब्बा तब खुलता है जब आप ताले पर लिखी संख्या जितनी चीज़ें पहुँचा देते हैं। खुलने से पहले वहाँ कुछ न भेजें।';

  @override
  String get tutGateTitle => 'रंग के गेट';

  @override
  String get tutGateBody => 'गेट से गुज़रने वाली हर चीज़ का रंग बदल जाता है। जिन चीज़ों का अपना डिब्बा नहीं है, उन्हें गेट से भेजें।';

  @override
  String get gotIt => 'समझ गया';

  @override
  String get paused => 'रुका हुआ';

  @override
  String get pause => 'रोकें';

  @override
  String get restart => 'फिर से शुरू करें';

  @override
  String get quitLevel => 'लेवल छोड़ें';

  @override
  String itemsLeft(int n) {
    return '$n बाकी';
  }

  @override
  String get go => 'शुरू!';

  @override
  String get boosterUndo => 'वापस';

  @override
  String get boosterLife => '+1 जान';

  @override
  String get boosterSlow => 'धीमा';

  @override
  String get notEnoughCoins => 'सिक्के कम हैं';

  @override
  String get getCoins => 'सिक्के पाएँ';

  @override
  String get watchAd => 'विज्ञापन देखें';

  @override
  String get adUnavailable => 'अभी कोई विज्ञापन उपलब्ध नहीं है। थोड़ी देर में फिर कोशिश करें।';

  @override
  String get adOfferTitle => 'मुफ़्त में इस्तेमाल करें?';

  @override
  String get adOfferBody => 'सिक्के खर्च किए बिना यह बूस्टर इस्तेमाल करने के लिए एक छोटा वीडियो देखें।';

  @override
  String useCoins(int n) {
    return '$n सिक्के इस्तेमाल करें';
  }

  @override
  String get levelComplete => 'लेवल पूरा!';

  @override
  String coinsEarned(int n) {
    return '+$n सिक्के';
  }

  @override
  String get doubleCoins => 'सिक्के दोगुने करें';

  @override
  String get next => 'अगला';

  @override
  String get replay => 'दोबारा खेलें';

  @override
  String get levelMap => 'लेवल मैप';

  @override
  String get newSticker => 'नया स्टिकर!';

  @override
  String setCompleteBonus(int n) {
    return 'सेट पूरा! +$n सिक्के';
  }

  @override
  String get outOfLives => 'जानें खत्म';

  @override
  String get failWrongBin => 'वह चीज़ गलत डिब्बे में चली गई।';

  @override
  String get failOverflow => 'वह डिब्बा पहले से भरा था।';

  @override
  String get failLocked => 'वह डिब्बा अभी बंद था।';

  @override
  String get undoLastItem => 'आखिरी चीज़ वापस लें';

  @override
  String get extraLife => 'एक और जान';

  @override
  String get free => 'मुफ़्त';

  @override
  String get hard => 'कठिन';

  @override
  String setN(int n) {
    return 'सेट $n';
  }

  @override
  String get allLevelsDone => 'आपने सारे लेवल पूरे कर लिए! और लेवल आ रहे हैं।';

  @override
  String get albumTitle => 'स्टिकर एल्बम';

  @override
  String get albumHint => 'स्टिकर पाने के लिए नया लेवल पूरा करें।';

  @override
  String countOf(int have, int total) {
    return '$have/$total';
  }

  @override
  String get dailyTitle => 'डेली चैलेंज';

  @override
  String get dailyBody => 'हर दिन एक नया लेवल, सबके लिए एक जैसा।';

  @override
  String dailyStreak(int n) {
    return '$n दिन की स्ट्रीक';
  }

  @override
  String dailyReward(int n) {
    return 'इनाम: $n सिक्के';
  }

  @override
  String get dailyDone => 'आज का पूरा हुआ। कल फिर आइए!';

  @override
  String get dailyPlay => 'आज का लेवल खेलें';

  @override
  String get dailyName => 'डेली चैलेंज';

  @override
  String eventReward(int count, int n) {
    return 'सभी $count लेवल पूरे करें और $n सिक्के पाएँ';
  }

  @override
  String get eventDone => 'इवेंट पूरा!';

  @override
  String eventLevel(int n) {
    return 'इवेंट लेवल $n';
  }

  @override
  String get shopTitle => 'दुकान';

  @override
  String get removeAds => 'विज्ञापन हटाएँ';

  @override
  String get removeAdsDesc => 'लेवल के बीच अब कोई विज्ञापन नहीं। इनाम वाले वीडियो आपकी मर्ज़ी पर रहेंगे।';

  @override
  String coinPack(int n) {
    return '$n सिक्के';
  }

  @override
  String get starterPack => 'स्टार्टर पैक';

  @override
  String starterDesc(int n) {
    return '$n सिक्के, सिर्फ़ एक बार';
  }

  @override
  String get restorePurchases => 'खरीदारी वापस लाएँ';

  @override
  String get purchaseDone => 'धन्यवाद! आपकी खरीदारी पूरी हुई।';

  @override
  String get purchaseFailed => 'खरीदारी पूरी नहीं हुई। आपसे कोई पैसा नहीं लिया गया।';

  @override
  String get storeUnavailable => 'दुकान अभी उपलब्ध नहीं है।';

  @override
  String get owned => 'खरीदा हुआ';

  @override
  String get restored => 'खरीदारी वापस आ गई।';

  @override
  String get nothingToRestore => 'वापस लाने के लिए कुछ नहीं है।';

  @override
  String get realMoney => 'असली पैसे लगते हैं';

  @override
  String get gateTitle => 'किसी बड़े से पूछें';

  @override
  String get gateBody => 'आगे बढ़ने के लिए माता-पिता या अभिभावक को इसका जवाब देना होगा:';

  @override
  String gateQuestion(int a, int b) {
    return '$a × $b = ?';
  }

  @override
  String get gateAnswer => 'जवाब';

  @override
  String get gateWrong => 'यह सही नहीं है। फिर कोशिश करें।';

  @override
  String gatePrice(String price) {
    return 'इस खरीदारी में $price असली पैसे लगेंगे।';
  }

  @override
  String get confirm => 'पक्का करें';

  @override
  String get sound => 'साउंड इफ़ेक्ट';

  @override
  String get music => 'संगीत';

  @override
  String get haptics => 'वाइब्रेशन';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम की भाषा';

  @override
  String get privacy => 'निजता';

  @override
  String get ageReset => 'उम्र का समूह बदलें';

  @override
  String get ageResetBody => 'आपसे जन्म का साल दोबारा पूछा जाएगा।';

  @override
  String version(String v) {
    return 'वर्शन $v';
  }

  @override
  String get updateTitle => 'अपडेट ज़रूरी है';

  @override
  String get updateBody => 'खेलते रहने के लिए Flow Sort अपडेट करें।';

  @override
  String get privacyTitle => 'आपकी निजता';

  @override
  String get privacyData => 'Flow Sort आपका नाम, ईमेल, फ़ोटो, कॉन्टैक्ट या लोकेशन नहीं माँगता। आपकी प्रोग्रेस, सिक्के और स्टिकर सिर्फ़ इसी डिवाइस पर रहते हैं।';

  @override
  String get privacyAge => 'हम एक बार जन्म का साल पूछते हैं और इस डिवाइस पर सिर्फ़ उम्र का समूह रखते हैं। उसी से तय होता है कि नीचे की कौन-सी बातें आप पर लागू होती हैं।';

  @override
  String get privacyAds => 'विज्ञापन (Google AdMob): 18 से कम उम्र के या उम्र का सवाल छोड़ने वाले खिलाड़ियों को सिर्फ़ गैर-निजी, सबके लिए उपयुक्त विज्ञापन दिखते हैं। वयस्कों को निजी विज्ञापन दिख सकते हैं, जहाँ कानून माँगे वहाँ सहमति के बाद।';

  @override
  String get privacyAnalytics => 'एनालिटिक्स (Google Firebase Analytics): सिर्फ़ वयस्कों के लिए, यह देखने के लिए कि कौन-से लेवल बहुत कठिन हैं। बाकी सबके लिए यह बंद रहता है।';

  @override
  String get privacyCrash => 'क्रैश रिपोर्ट (Google Firebase Crashlytics): क्रैश की तकनीकी जानकारी, बिना किसी यूज़र आईडी के।';

  @override
  String get privacyPurchases => 'खरीदारी (RevenueCat, Google Play या App Store के साथ): स्टोर सँभालता है। हम आपकी भुगतान जानकारी कभी नहीं देखते। 18 से कम उम्र के खिलाड़ियों को किसी बड़े की मंज़ूरी चाहिए।';

  @override
  String get privacyNone => 'गेम के अंदर कोई चैट, अपने से लिखे नाम या सोशल फ़ीचर नहीं हैं। नतीजा शेयर करने पर आपके डिवाइस का अपना शेयर मेन्यू खुलता है; तस्वीर में सिर्फ़ लेवल और स्टार होते हैं, और गेम को कभी पता नहीं चलता कि आपने इसे कहाँ पोस्ट किया।';

  @override
  String privacyPolicyLink(String url) {
    return 'पूरी निजता नीति: $url';
  }

  @override
  String privacyContact(String email) {
    return 'सवाल: $email';
  }

  @override
  String get simAdTitle => 'टेस्ट विज्ञापन';

  @override
  String get simAdBody => 'लोकल टेस्टिंग के लिए नकली विज्ञापन। स्टोर बिल्ड में असली विज्ञापन दिखेंगे।';

  @override
  String simAdClose(int n) {
    return 'बंद करें ($n)';
  }

  @override
  String starsLabel(int n) {
    return '3 में से $n स्टार';
  }

  @override
  String livesLabel(int n) {
    return '$n जानें';
  }

  @override
  String coinsLabel(int n) {
    return '$n सिक्के';
  }

  @override
  String get switchLabel => 'स्विच';

  @override
  String get share => 'शेयर करें';

  @override
  String shareLevelText(int n, int stars) {
    return 'मैंने Flow Sort का लेवल $n 3 में से $stars स्टार के साथ पूरा किया! क्या आप इससे बेहतर कर सकते हैं?';
  }

  @override
  String shareDailyText(int stars) {
    return 'मैंने आज का Flow Sort डेली चैलेंज 3 में से $stars स्टार के साथ पूरा किया! क्या आप इससे बेहतर कर सकते हैं?';
  }

  @override
  String shareEventText(int n, int stars) {
    return 'मैंने Flow Sort का इवेंट लेवल $n 3 में से $stars स्टार के साथ पूरा किया! क्या आप इससे बेहतर कर सकते हैं?';
  }

  @override
  String get shareCardTagline => 'क्या आप इसे और तेज़ सुलझा सकते हैं?';

  @override
  String shareFlips(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n बार स्विच पलटा',
    );
    return '$_temp0';
  }

  @override
  String get gateShareNote => 'शेयर करने पर गेम के बाहर कोई दूसरा ऐप खुलेगा।';

  @override
  String get shareFailed => 'अभी शेयर नहीं किया जा सकता।';

  @override
  String a11yColour(String colour) {
    String _temp0 = intl.Intl.selectLogic(
      colour,
      {
        'red': 'लाल',
        'blue': 'नीला',
        'green': 'हरा',
        'yellow': 'पीला',
        'purple': 'बैंगनी',
        'orange': 'नारंगी',
        'pink': 'गुलाबी',
        'other': 'छिपा हुआ रंग',
      },
    );
    return '$_temp0';
  }

  @override
  String a11yBoard(String next, int lives, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      lives,
      locale: localeName,
      other: '$lives जानें',
      one: '1 जान',
    );
    String _temp1 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left चीज़ें',
      one: '1 चीज़',
    );
    return 'गेम बोर्ड। अगली चीज़: $next। $_temp0 बाकी। $_temp1 छाँटनी हैं।';
  }

  @override
  String get a11yNoItem => 'कोई नहीं';

  @override
  String a11ySwitch(int n, String dir) {
    String _temp0 = intl.Intl.selectLogic(
      dir,
      {
        'left': 'बाईं',
        'other': 'दाईं',
      },
    );
    return 'स्विच $n, $_temp0 ओर';
  }

  @override
  String get a11ySwitchHint => 'स्विच पलटें';

  @override
  String a11yBin(String colour, int fill, int capacity) {
    return '$colour डिब्बा, $capacity में से $fill';
  }
}
