import 'package:material_ui/material_ui.dart';

import '../state/app_settings.dart';

/// A ready-made Ask Cassia question: the short [label] on its chip, and the
/// full [question] that is asked when the chip is tapped.
typedef AskSuggestion = ({String label, String question});

/// Every piece of text the farmer app shows, in all six languages.
///
/// Each string is written once with its languages side by side, so a
/// translation is easy to review next to its English. English and Urdu are
/// always given; the four regional languages — Sindhi, Punjabi, Pashto and
/// Balochi — fall back to the Urdu wording wherever their own is not yet
/// filled in. Screens read them through `context.s`.
///
/// Not translated here on purpose: product data from Firestore (variety
/// names, crops), the company's name and address, and the order message sent
/// to Cassia Seed's team on WhatsApp.
class AppStrings {
  const AppStrings._(this.lang);

  static const en = AppStrings._(AppLanguage.en);
  static const ur = AppStrings._(AppLanguage.ur);
  static const sd = AppStrings._(AppLanguage.sd);
  static const pa = AppStrings._(AppLanguage.pa);
  static const ps = AppStrings._(AppLanguage.ps);
  static const bal = AppStrings._(AppLanguage.bal);

  /// The strings for the app's current language, taken from the settings.
  static AppStrings of(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    if (settings != null) return _for(settings.language);
    // Bare widgets and tests without settings installed: read the locale.
    return Localizations.maybeLocaleOf(context)?.languageCode == 'ur' ? ur : en;
  }

  static AppStrings _for(AppLanguage language) => switch (language) {
        AppLanguage.en => en,
        AppLanguage.ur => ur,
        AppLanguage.sd => sd,
        AppLanguage.pa => pa,
        AppLanguage.ps => ps,
        AppLanguage.bal => bal,
      };

  final AppLanguage lang;

  /// True for Urdu alone — kept where a check really means "the Urdu wording".
  bool get isUrdu => lang == AppLanguage.ur;

  /// True for every right-to-left language (all but English). Drives layout,
  /// arrows and the connected-script text treatment.
  bool get isRtl => lang.rtl;

  /// The language code — also tells the AI features which language to use.
  String get languageCode => lang.code;

  /// Picks the wording for the current language. English and Urdu are always
  /// given; a regional language falls back to Urdu until its own is filled in.
  String _t(String en, String ur,
          {String? sd, String? pa, String? ps, String? bal}) =>
      switch (lang) {
        AppLanguage.en => en,
        AppLanguage.ur => ur,
        AppLanguage.sd => sd ?? ur,
        AppLanguage.pa => pa ?? ur,
        AppLanguage.ps => ps ?? ur,
        AppLanguage.bal => bal ?? ur,
      };

  /// Letter-spacing for a piece of styled text: [english] in English, none
  /// in a connected right-to-left script, where space between letters breaks
  /// the joins.
  double spacing(double english) => isRtl ? 0 : english;

  /// An arrow pointing the way the language reads: onwards.
  String get arrow => isRtl ? '←' : '→';

  // Invisible Unicode marks that set the reading direction of a stretch of
  // text. Built from their code points so they are visible in this file.
  static final _fsi = String.fromCharCode(0x2068); // direction of its content
  static final _lri = String.fromCharCode(0x2066); // left-to-right
  static final _pdi = String.fromCharCode(0x2069); // end of the stretch

  /// Wraps product data (a pack size, a variety name) so it keeps its own
  /// reading direction inside right-to-left text. Without this "10 g" is
  /// shown as "g 10". Left-to-right English text is returned unchanged.
  String data(String text) => isRtl ? '$_fsi$text$_pdi' : text;

  /// Like [data], but always left-to-right — for phone and order numbers,
  /// which would otherwise have their parts swapped ("1234567 0300").
  String _ltr(String text) => '$_lri$text$_pdi';

  // ------------------------------------------------------------- general

  String get tryAgain => _t('Try again', 'دوبارہ کوشش کریں',
      sd: 'وري ڪوشش ڪريو',
      pa: 'دوبارہ کوشش کرو',
      ps: 'بیا هڅه وکړئ',
      bal: 'پدا کوشش کنیت');
  String get cancel => _t('Cancel', 'منسوخ',
      sd: 'رد ڪريو', pa: 'منسوخ کرو', ps: 'لغوه کړئ', bal: 'منسوخ');
  String get ok => _t('OK', 'ٹھیک ہے',
      sd: 'ٺيڪ آهي', pa: 'ٹھیک اے', ps: 'سمه ده', bal: 'ٹھیک اِنت');
  String get back => _t('Back', 'واپس',
      sd: 'واپس', pa: 'واپس', ps: 'شاته', bal: 'پچ');
  String get done => _t('Done', 'ہو گیا',
      sd: 'ٿي ويو', pa: 'ہو گیا', ps: 'ترسره شو', bal: 'بوت');
  String get close => _t('Close', 'بند کریں',
      sd: 'بند ڪريو', pa: 'بند کرو', ps: 'بند کړئ', bal: 'بند کنیت');
  String get available => _t('Available', 'دستیاب',
      sd: 'موجود', pa: 'دستیاب', ps: 'شته', bal: 'دستیاب');
  String get notAvailableYet => _t('Not available yet', 'ابھی دستیاب نہیں',
      sd: 'اڃا موجود ناهي',
      pa: 'ہلے دستیاب نئیں',
      ps: 'لا تر اوسه نشته',
      bal: 'هنوں دستیاب نیست');
  String get comingSoon => _t('Coming Soon', 'جلد آ رہا ہے',
      sd: 'جلد اچي رهيو آهي',
      pa: 'چھیتی آ ریا اے',
      ps: 'ژر راځي',
      bal: 'زوت کئیت');
  String get newBadge => _t('NEW', 'نیا',
      sd: 'نئون', pa: 'نواں', ps: 'نوی', bal: 'نوکیں');
  String get couldNotOpenWhatsApp => _t(
      'Could not open WhatsApp on this device.',
      'اس فون پر واٹس ایپ نہیں کھل سکا۔',
      sd: 'هن فون تي واٽس ايپ نه کُلي سگهيو.',
      pa: 'ایس فون تے واٹس ایپ نئیں کھل سکیا۔',
      ps: 'په دې فون کې واټساپ پرانیستل ونشو.',
      bal: 'اے فون ءَ واٹس ایپ پچ نہ بوت۔');
  String get somethingWentWrong => _t(
      'Something went wrong. Please try again.',
      'کچھ غلط ہو گیا۔ براہِ کرم دوبارہ کوشش کریں۔',
      sd: 'ڪجهه غلط ٿي ويو. مهرباني ڪري وري ڪوشش ڪريو.',
      pa: 'کجھ غلط ہو گیا۔ مہربانی کرکے دوبارہ کوشش کرو۔',
      ps: 'یو څه خراب شو. مهرباني وکړئ بیا هڅه وکړئ.',
      bal: 'چیزے غلط بوت۔ مہربانی کن اِت پدا کوشش کنیت۔');
  String get noConnectionTitle => _t('No connection', 'انٹرنیٹ دستیاب نہیں',
      sd: 'انٽرنيٽ موجود ناهي',
      pa: 'انٹرنیٹ دستیاب نئیں',
      ps: 'انټرنیټ نشته',
      bal: 'انٹرنیٹ دستیاب نیست');
  String get noConnectionBody => _t(
      'Please check your internet connection and try again.',
      'براہِ کرم اپنا انٹرنیٹ چیک کریں اور دوبارہ کوشش کریں۔',
      sd: 'مهرباني ڪري پنهنجو انٽرنيٽ چيڪ ڪريو ۽ وري ڪوشش ڪريو.',
      pa: 'مہربانی کرکے اپنا انٹرنیٹ چیک کرو تے دوبارہ کوشش کرو۔',
      ps: 'مهرباني وکړئ خپل انټرنیټ وګورئ او بیا هڅه وکړئ.',
      bal: 'مہربانی کن اِت وتی انٹرنیٹ چیک کن اِت ءُ پدا کوشش کنیت۔');
  String get notSetUpBody => _t(
      'This feature has not been switched on yet. Please try again later.',
      'یہ سہولت ابھی شروع نہیں کی گئی۔ براہِ کرم بعد میں کوشش کریں۔',
      sd: 'هيءَ سهولت اڃا شروع نه ٿي آهي. مهرباني ڪري پوءِ ڪوشش ڪريو.',
      pa: 'ایہہ سہولت ہلے شروع نئیں ہوئی۔ مہربانی کرکے بعد وچ کوشش کرو۔',
      ps: 'دا اسانتیا لا تر اوسه نه ده پیل شوې. مهرباني وکړئ وروسته هڅه وکړئ.',
      bal: 'ای سہولت هنوں شروع نہ بوتگ۔ مہربانی کن اِت رند ءَ کوشش کنیت۔');
  String aiComingSoonBody(String feature) => _t(
      "$feature isn't available yet — it's coming very soon.",
      '$feature ابھی دستیاب نہیں — یہ بہت جلد آ رہا ہے۔',
      sd: '$feature اڃا موجود ناهي — اهو تمام جلد اچي رهيو آهي.',
      pa: '$feature ہلے دستیاب نئیں — ایہہ بہت چھیتی آ ریا اے۔',
      ps: '$feature لا تر اوسه نشته — دا ډېر ژر راځي.',
      bal: '$feature هنوں دستیاب نیست — ای زوت کئیت۔');

  String get changeLanguage => _t('Change language', 'زبان تبدیل کریں',
      sd: 'ٻولي تبديل ڪريو',
      pa: 'زبان تبدیل کرو',
      ps: 'ژبه بدله کړئ',
      bal: 'زبان تبدیل کنیت');

  // ---------------------------------------------------------- navigation

  String get navHome => _t('Home', 'ہوم',
      sd: 'هوم', pa: 'ہوم', ps: 'کور', bal: 'هوم');
  String get navShop => _t('Shop', 'دکان',
      sd: 'دُڪان', pa: 'دکان', ps: 'دکان', bal: 'دکان');
  String get navDoctor => _t('Doctor', 'ڈاکٹر',
      sd: 'ڊاڪٽر', pa: 'ڈاکٹر', ps: 'ډاکټر', bal: 'ڈاکٹر');
  String get navAskAi => _t('Ask', 'پوچھیں',
      sd: 'پڇو', pa: 'پُچھو', ps: 'وپوښتئ', bal: 'پُرس اِت');
  String get navOrder => _t('Order', 'آرڈر',
      sd: 'آرڊر', pa: 'آرڈر', ps: 'آرډر', bal: 'آرڈر');

  // ---------------------------------------------------------------- home

  /// [hour] is the hour of the day, 0–23.
  String greeting(int hour) => hour < 12
      ? _t('Good morning', 'صبح بخیر',
          sd: 'صبح بخير', pa: 'صبح بخیر', ps: 'سهار مو پخیر', bal: 'صبح وش')
      : hour < 17
          ? _t('Good afternoon', 'دن بخیر',
              sd: 'ڏينهن بخير',
              pa: 'دوپہر بخیر',
              ps: 'غرمه مو پخیر',
              bal: 'روچ وش')
          : _t('Good evening', 'شام بخیر',
              sd: 'شام بخير',
              pa: 'شام بخیر',
              ps: 'ماښام مو پخیر',
              bal: 'بیگاہ وش');
  String get salam => _t('Assalam o Alaikum', 'السلام علیکم',
      sd: 'السلام عليڪم',
      pa: 'السلام علیکم',
      ps: 'السلام علیکم',
      bal: 'السلام علیکم');
  String get season => _t('SEASON 2026', 'سیزن 2026',
      sd: 'سيزن 2026', pa: 'سیزن 2026', ps: 'سیزن 2026', bal: 'سیزن 2026');
  String get heroTagline => _t(
      'Quality seeds and an AI crop doctor, right in your pocket.',
      'معیاری بیج اور اے آئی کراپ ڈاکٹر، آپ کی جیب میں۔',
      sd: 'معياري ٻج ۽ اي آءِ ڪراپ ڊاڪٽر، اوهان جي کيسي ۾.',
      pa: 'معیاری بیج تے اے آئی کراپ ڈاکٹر، تہاڈی جیب وچ۔',
      ps: 'باکیفیته تخمونه او د اې آی فصل ډاکټر، ستاسو په جیب کې.',
      bal: 'باکیفیتیں تُخم ءُ اے آئی کراپ ڈاکٹر، تئی جیب ءَ۔');
  String get shopSeedsCta => _t('Shop Seeds', 'بیج دیکھیں',
      sd: 'ٻج ڏسو', pa: 'بیج ویکھو', ps: 'تخمونه وګورئ', bal: 'تُخم ءَ گند اِت');
  String get statSeedPacks => _t('Seed packs', 'بیج کے پیک',
      sd: 'ٻج جا پيڪ', pa: 'بیج دے پیک', ps: 'د تخم پاکټونه', bal: 'تُخمانی پیک');
  String get statCrops => _t('Crops', 'فصلیں',
      sd: 'فصلون', pa: 'فصلاں', ps: 'فصلونه', bal: 'فصل');
  String get statYears => _t('2 Yrs', '2 سال',
      sd: '2 سال', pa: '2 سال', ps: '2 کاله', bal: '2 سال');
  String get statTrials => _t('Adapted trials', 'موافق ٹرائلز',
      sd: 'موافق ٽرائل',
      pa: 'موافق ٹرائلز',
      ps: 'موافق ازموینې',
      bal: 'موافق ٹرائلز');
  String get statAi => _t('AI', 'اے آئی',
      sd: 'اي آءِ', pa: 'اے آئی', ps: 'اې آی', bal: 'اے آئی');
  String get askCassia => _t('Ask Cassia', 'کیسیا سے پوچھیں',
      sd: 'ڪيسيا کان پڇو',
      pa: 'کیسیا توں پُچھو',
      ps: 'له کیسیا وپوښتئ',
      bal: 'کیسیا ءَ پُرس اِت');
  String get seedShop => _t('Seed Shop', 'بیج کی دکان',
      sd: 'ٻج جي دُڪان',
      pa: 'بیج دی دکان',
      ps: 'د تخم دکان',
      bal: 'تُخمانی دکان');
  String get seedShopHint =>
      _t('Tap a pack for details.', 'تفصیل کے لیے پیک پر دبائیں۔',
          sd: 'تفصيل لاءِ پيڪ تي دٻايو.',
          pa: 'تفصیل لئی پیک تے دباؤ۔',
          ps: 'د تفصیلاتو لپاره پاکټ کېکاږئ.',
          bal: 'تفصیل ءِ واستہ پیک ءَ دبّ اِت۔');
  String get myOrder => _t('My Order', 'میرا آرڈر',
      sd: 'منهنجو آرڊر', pa: 'میرا آرڈر', ps: 'زما آرډر', bal: 'منی آرڈر');
  String get support => _t('Support', 'مدد',
      sd: 'مدد', pa: 'مدد', ps: 'مرسته', bal: 'مدد');
  String get aboutUs => _t('About Us', 'ہمارے بارے میں',
      sd: 'اسان جي باري ۾',
      pa: 'ساڈے بارے وچ',
      ps: 'زموږ په اړه',
      bal: 'مئی بارہ ءَ');
  String get supportAndAbout => _t('Support & About', 'مدد اور تعارف',
      sd: 'مدد ۽ تعارف',
      pa: 'مدد تے تعارف',
      ps: 'مرسته او پیژندنه',
      bal: 'مدد ءُ تعارف');

  // --------------------------------------------------------- about screen
  // The company's story, straight from cassiaseed.com. English and Urdu are
  // given; the four regional languages fall back to the Urdu wording.
  String get aboutTagline => _t(
      'Seeds That Deliver Trust, Yield, and Growth',
      'ایسے بیج جو بھروسہ، پیداوار اور ترقی دیں');

  String get aboutWhoTitle =>
      _t("Pakistan's trusted seed company", 'پاکستان کی قابلِ اعتماد سیڈ کمپنی');
  String get aboutWhoBody => _t(
      'Cassia Seed (Pvt) Ltd is a professional research, trade and marketing '
          'company dedicated to the seed industry. We focus on high-quality '
          'hybrid and open-pollination seeds, giving farmers higher-yielding, '
          'more reliable varieties. Through our own research and development we '
          'work to improve agricultural productivity across Pakistan.',
      'کیسیا سیڈ (پرائیویٹ) لمیٹڈ ایک پیشہ ور ریسرچ، تجارت اور مارکیٹنگ کمپنی ہے '
          'جو بیجوں کے شعبے کے لیے وقف ہے۔ ہم اعلیٰ معیار کے ہائبرڈ اور اوپن '
          'پولینیشن بیجوں پر توجہ دیتے ہیں تاکہ کسانوں کو زیادہ پیداوار دینے والی '
          'اور قابلِ بھروسہ اقسام مل سکیں۔ اپنی تحقیق و ترقی کے ذریعے ہم پورے '
          'پاکستان میں زرعی پیداوار بہتر بنانے کے لیے کام کرتے ہیں۔');

  String get aboutDoTitle => _t('Research, Trade & Support',
      'تحقیق، تجارت اور معاونت');
  String get aboutResearchTitle => _t('Research & Development', 'تحقیق و ترقی');
  String get aboutResearchBody => _t(
      'Developing high-yielding, disease-resistant and climate-tolerant seed '
          'varieties.',
      'زیادہ پیداوار دینے والی، بیماری سے محفوظ اور موسم کے لحاظ سے مضبوط بیجوں '
          'کی اقسام تیار کرنا۔');
  String get aboutTradingTitle => _t('Seed Trading', 'بیجوں کی تجارت');
  String get aboutTradingBody => _t(
      'Importing, producing locally and distributing premium hybrid and '
          'open-pollination vegetable seeds to farmers and dealers nationwide.',
      'اعلیٰ معیار کے ہائبرڈ اور اوپن پولینیشن سبزیوں کے بیج درآمد کرنا، مقامی '
          'طور پر تیار کرنا اور ملک بھر کے کسانوں اور ڈیلرز تک پہنچانا۔');
  String get aboutMarketingTitle => _t('Marketing & Support', 'مارکیٹنگ اور معاونت');
  String get aboutMarketingBody => _t(
      'Farmer meetings, expert guidance, field demonstrations and marketing '
          'support.',
      'کسانوں کے اجلاس، ماہرانہ رہنمائی، کھیت میں عملی مظاہرے اور مارکیٹنگ میں '
          'مدد۔');

  String get aboutCommitmentTitle =>
      _t('Seeds farmers can trust', 'ایسے بیج جن پر کسان بھروسہ کریں');
  String get aboutCommitmentBody => _t(
      'We are committed to delivering seeds that farmers can trust. With our '
          'research facilities, strict quality control and a nationwide '
          'distribution network, we help farmers raise their productivity and '
          'profitability season after season.',
      'ہم ایسے بیج فراہم کرنے کے لیے پُرعزم ہیں جن پر کسان بھروسہ کر سکیں۔ اپنی '
          'تحقیقی سہولیات، سخت معیار کی جانچ اور ملک گیر ترسیلی نیٹ ورک کے ذریعے '
          'ہم ہر موسم میں کسانوں کی پیداوار اور منافع بڑھانے میں مدد دیتے ہیں۔');

  String get aboutVisionTitle => _t('Our Vision', 'ہمارا وژن');
  String get aboutVisionBody => _t(
      'To be the preferred partner in agriculture — driving growth through '
          'innovation, sustainability and excellence, and creating lasting value '
          'for farmers, communities and stakeholders.',
      'زراعت میں سب سے پسندیدہ ساتھی بننا — جدت، پائیداری اور معیار کے ذریعے ترقی '
          'کو آگے بڑھانا، اور کسانوں، برادریوں اور شراکت داروں کے لیے دیرپا قدر '
          'پیدا کرنا۔');
  String get aboutMissionTitle => _t('Our Mission', 'ہمارا مشن');
  String get aboutMissionBody => _t(
      'Empowering farmers and communities through high-quality seed solutions '
          'and sustainable agricultural growth.',
      'اعلیٰ معیار کے بیجوں اور پائیدار زرعی ترقی کے ذریعے کسانوں اور برادریوں کو '
          'بااختیار بنانا۔');

  String get aboutStoryTitle =>
      _t('From a humble shop to a national seed company',
          'ایک چھوٹی دکان سے ملک گیر سیڈ کمپنی تک');
  String get aboutStoryBody1 => _t(
      'Our journey began in 1985 as a small local agricultural seed shop. Over '
          'more than forty years our founder earned the trust of farmers and '
          'built a reputation for quality, growing the shop into a recognised '
          'regional supplier and distributor.',
      'ہمارا سفر 1985 میں ایک چھوٹی مقامی زرعی بیجوں کی دکان سے شروع ہوا۔ چالیس '
          'سال سے زائد عرصے میں ہمارے بانی نے کسانوں کا اعتماد جیتا اور معیار کی '
          'پہچان بنائی، اور اس دکان کو ایک معتبر علاقائی سپلائر اور ڈسٹری بیوٹر '
          'میں بدل دیا۔');
  String get aboutStoryBody2 => _t(
      'In 2022 the business was formally established as Cassia Seed (Pvt) Ltd. '
          'Today we import and locally produce high-quality vegetable seeds, '
          "supporting the growth of Pakistan's agriculture sector.",
      '2022 میں اس کاروبار کو باقاعدہ طور پر کیسیا سیڈ (پرائیویٹ) لمیٹڈ کے نام سے '
          'قائم کیا گیا۔ آج ہم اعلیٰ معیار کی سبزیوں کے بیج درآمد اور مقامی طور پر '
          'تیار کرتے ہیں، اور پاکستان کے زرعی شعبے کی ترقی میں معاونت کرتے ہیں۔');
  String get aboutStatFounded => _t('Founded', 'آغاز');
  String get aboutStatYears => _t('Years', 'سال');
  String get aboutStatIncorporated => _t('Incorporated', 'کمپنی قائم');

  String get aboutQuote => _t(
      'Grow with confidence. Grow with Cassia Seed.',
      'اعتماد کے ساتھ اگائیں۔ کیسیا سیڈ کے ساتھ اگائیں۔');
  String get aboutVisitWebsite => _t('Visit our website', 'ہماری ویب سائٹ دیکھیں');
  String get shopByCrop => _t('Shop by Crop', 'فصل کے حساب سے',
      sd: 'فصل جي لحاظ کان',
      pa: 'فصل دے حساب نال',
      ps: 'د فصل له مخې',
      bal: 'فصل ئے حساب ءَ');
  String get spotlight => _t('Spotlight', 'خاص انتخاب',
      sd: 'خاص چونڊ', pa: 'خاص چونڈ', ps: 'ځانګړی غوره', bal: 'خاص انتخاب');
  String get featuredSeeds => _t('Featured Seeds', 'نمایاں بیج',
      sd: 'نمايان ٻج', pa: 'نمایاں بیج', ps: 'ځانګړي تخمونه', bal: 'نمایاں تُخم');
  String get viewAndOrder => _t('View & Order', 'دیکھیں اور آرڈر کریں',
      sd: 'ڏسو ۽ آرڊر ڪريو',
      pa: 'ویکھو تے آرڈر کرو',
      ps: 'وګورئ او آرډر وکړئ',
      bal: 'گند اِت ءُ آرڈر کنیت');
  String get newArrivals => _t('New Arrivals', 'نئی آمد',
      sd: 'نئين آمد', pa: 'نویں آمد', ps: 'نوي راغلي', bal: 'نوکیں رسگ');
  String get tomatoChilliPicks =>
      _t('Tomato & Chilli Picks', 'ٹماٹر اور مرچ کا انتخاب',
          sd: 'ٽماٽو ۽ مرچ جي چونڊ',
          pa: 'ٹماٹر تے مرچ دی چونڈ',
          ps: 'د روميانو او مرچو غوره',
          bal: 'ٹماٹر ءُ مرچ ئے انتخاب');
  String get promoBody => _t('Snap a photo. Get a diagnosis and a cure.',
      'تصویر لیں۔ تشخیص اور علاج پائیں۔',
      sd: 'تصوير ڪڍو. تشخيص ۽ علاج حاصل ڪريو.',
      pa: 'تصویر لَوو۔ تشخیص تے علاج لَوو۔',
      ps: 'عکس واخلئ. تشخیص او علاج ترلاسه کړئ.',
      bal: 'عکس ءَ گر اِت۔ تشخیص ءُ علاج هست کن اِت۔');
  String get tryNow => _t('Try now', 'آزمائیں',
      sd: 'آزمايو', pa: 'اجمائو', ps: 'اوس یې وازمایئ', bal: 'آزمات کن اِت');
  String get commonProblems => _t('Common Problems', 'عام مسائل',
      sd: 'عام مسئلا', pa: 'عام مسئلے', ps: 'عام ستونزې', bal: 'عام مسئلہ');

  /// The crop problems offered on Home, as (emoji, name) pairs.
  List<(String, String)> get problems => [
        ('🍂', _t('Yellow leaves', 'پیلے پتے',
            sd: 'پيلا پن', pa: 'پیلے پتے', ps: 'ژیړ پاڼې', bal: 'زرد پان')),
        ('🌀', _t('Leaf curl', 'پتوں کا مڑنا',
            sd: 'پنن جو مڙجڻ',
            pa: 'پتیاں دا مُڑنا',
            ps: 'د پاڼو تاوېدل',
            bal: 'پانّانی تاب')),
        ('🐛', _t('Insects and pests', 'کیڑے مکوڑے',
            sd: 'ڪيڙا مڪوڙا',
            pa: 'کیڑے مکوڑے',
            ps: 'چینجي او زیانکښ',
            bal: 'کِرم ءُ گزک')),
        ('🥀', _t('Wilting plants', 'مرجھاتے پودے',
            sd: 'ڪومائجندڙ ٻوٽا',
            pa: 'مُرجھاندے بوٹے',
            ps: 'وچیدونکي بوټي',
            bal: 'پژمردہ بُنگ')),
        ('⚪', _t('White powder on leaves', 'پتوں پر سفید پاؤڈر',
            sd: 'پنن تي اڇو پائوڊر',
            pa: 'پتیاں تے چِٹا پاؤڈر',
            ps: 'په پاڼو سپین پوډر',
            bal: 'پانّان ءَ سپیت پاؤڈر')),
        ('🍅', _t('Fruit rot or cracking', 'پھل کا گلنا یا پھٹنا',
            sd: 'ميوي جو سڙڻ يا ڦاٽڻ',
            pa: 'پھل دا گلنا یا پھٹنا',
            ps: 'د مېوې خرابېدل یا چاودل',
            bal: 'میوگ ئے پوسگ یا پِرّگ')),
      ];

  /// The question sent to Ask Cassia when a problem is tapped.
  String problemQuestion(String problem) => _t(
      'My crop has this problem: $problem. What are the common causes and '
          'what should I do?',
      'میری فصل میں یہ مسئلہ ہے: $problem۔ اس کی عام وجوہات کیا ہیں اور '
          'مجھے کیا کرنا چاہیے؟',
      sd: 'منهنجي فصل ۾ هي مسئلو آهي: $problem. ان جا عام سبب ڇا آهن ۽ '
          'مون کي ڇا ڪرڻ گهرجي؟',
      pa: 'میری فصل وچ ایہہ مسئلہ اے: $problem۔ ایس دے عام سبب کیہہ نیں تے '
          'میں کیہہ کرنا چاہیدا اے؟',
      ps: 'زما فصل دا ستونزه لري: $problem. د دې عام لاملونه څه دي او ما ته '
          'څه کول پکار دي؟',
      bal: 'منی فصل ءَ ای مسئلہ هست: $problem۔ ائی عام سببّ چے اَنت ءُ منا '
          'چے کنگ لوٹیت؟');

  String get growerTip => _t('Grower tip', 'کاشتکار کے لیے مشورہ',
      sd: 'ڪاشتڪار لاءِ صلاح',
      pa: 'کاشتکار لئی مشورہ',
      ps: 'د بزګر لپاره مشوره',
      bal: 'کشتکار ئے واستہ مشورہ');
  String get tapForNext => _t('tap for next', 'اگلے کے لیے دبائیں',
      sd: 'ايندڙ لاءِ دٻايو',
      pa: 'اگلے لئی دباؤ',
      ps: 'د راتلونکي لپاره کېکاږئ',
      bal: 'بعدی ئے واستہ دبّ اِت');
  List<String> get tips => [
        _t(
            'Buy only sealed packs and check the germination % and expiry '
                'date printed on them.',
            'صرف بند پیک خریدیں اور ان پر چھپی اُگاؤ کی شرح اور میعاد کی '
                'تاریخ دیکھ لیں۔',
            sd: 'رڳو بند پيڪ خريدو ۽ انهن تي ڇپيل اُڀرڻ جي شرح ۽ ميعاد جي '
                'تاريخ ڏسو.',
            pa: 'صرف بند پیک خریدو تے اوہناں تے چھپی اُگن دی شرح تے میعاد دی '
                'تاریخ ویکھو۔',
            ps: 'یوازې بند پاکټونه واخلئ او پرې چاپ شوې د زرغونېدو سلنه او د '
                'پای نیټه وګورئ.',
            bal: 'تها بند پیک ءَ گر اِت ءُ آ ئی سر ءَ چاپ بیتگیں اُجّگ ئے شرح '
                'ءُ میعاد ئے تاریخ ءَ گند اِت۔'),
        _t('Store seed packs in a cool, dry place, away from direct sunlight.',
            'بیج کے پیک ٹھنڈی، خشک جگہ پر رکھیں، سیدھی دھوپ سے دور۔',
            sd: 'ٻج جا پيڪ ٿڌي، سُڪي جاءِ تي رکو، سڌي اُس کان پري.',
            pa: 'بیج دے پیک ٹھنڈی، خشک تھاں تے رکھو، سِدھی دھُپ توں دور۔',
            ps: 'د تخم پاکټونه په یخ او وچ ځای کې کېږدئ، له مستقیمې لمر رڼا '
                'لرې.',
            bal: 'تُخمانی پیک ءَ سردیں، هُشکیں جاہ ءَ ایر اِت، سیدھایں تاب ءَ '
                'دور۔'),
        _t(
            'Walk your field early in the morning. Pests and disease are '
                'easiest to spot then.',
            'صبح سویرے کھیت کا چکر لگائیں۔ کیڑے اور بیماری اسی وقت آسانی '
                'سے نظر آتے ہیں۔',
            sd: 'صبح سوير کھيت جو چڪر لڳايو. ڪيڙا ۽ بيماري ان وقت آساني سان '
                'نظر اچن ٿا.',
            pa: 'صبح سویرے کھیت دا گیڑا لاؤ۔ کیڑے تے بیماری اوسے ویلے سوکھے '
                'نظر آؤندے نیں۔',
            ps: 'سهار وختي خپل پټي ته لاړ شئ. چینجي او ناروغي په همدغه وخت '
                'اسانه لیدل کیږي.',
            bal: 'صبح سحر ءَ وتی بیڑ ءَ چکّر جن اِت۔ کِرم ءُ بیماری ہمے وخت ءَ '
                'آسانی ءَ پدی کَیَنت۔'),
        _t(
            'For Crop Doctor, a clear close-up photo gives far better advice '
                'than a blurry one.',
            'کراپ ڈاکٹر کے لیے صاف اور قریب کی تصویر دھندلی تصویر سے کہیں '
                'بہتر مشورہ دیتی ہے۔',
            sd: 'ڪراپ ڊاڪٽر لاءِ صاف ۽ ويجهي تصوير ڌنڌلي تصوير کان گهڻو بهتر '
                'صلاح ڏئي ٿي.',
            pa: 'کراپ ڈاکٹر لئی صاف تے نیڑے دی تصویر دھندلی تصویر توں بوہت '
                'چنگا مشورہ دیندی اے۔',
            ps: 'د فصل ډاکټر لپاره یو روښانه نږدې عکس له ګونګي عکس څخه ډیر ښه '
                'مشوره ورکوي.',
            bal: 'کراپ ڈاکٹر ئے واستہ صافیں ءُ نزّیکیں عکس دھندلایں عکس ءَ '
                'گیشتر چمّیں مشورہ دنت۔'),
        _t(
            'Sow in the evening or on a cloudy day to reduce stress on young '
                'seedlings.',
            'شام کے وقت یا ابر آلود دن میں کاشت کریں تاکہ ننھے پودوں پر '
                'دباؤ کم ہو۔',
            sd: 'شام جي وقت يا ڪڪريل ڏينهن ۾ پوک ڪريو ته جيئن ننڍن ٻوٽن تي '
                'دٻاءُ گهٽ ٿئي.',
            pa: 'شام ویلے یا بدلواں والے دن کاشت کرو تاں جو نِکے بوٹیاں تے '
                'دباؤ گھٹ ہووے۔',
            ps: 'ماښام یا د ورېځو په ورځ کې کرل وکړئ ترڅو په ځوانو نیالګیو '
                'دباؤ کم شي.',
            bal: 'بیگاہ ئے وخت یا ابرناکیں روچ ءَ کشت کن اِت کہ کسانیں بُنگان '
                'ءَ دباؤ کم بہ بیت۔'),
      ];

  String get whyCassia => _t('Why Cassia', 'کیسیا کیوں',
      sd: 'ڪيسيا ڇو', pa: 'کیسیا کیوں', ps: 'ولې کیسیا', bal: 'کیسیا چیا');

  /// "Why Cassia" points as (title, detail) pairs.
  List<(String, String)> get whyPoints => [
        (
          _t('Two-year adapted trials', 'دو سالہ موافق ٹرائلز',
              sd: 'ٻه سالن جا موافق ٽرائل',
              pa: 'دو سالہ موافق ٹرائلز',
              ps: 'دوه کلن موافق ازموینې',
              bal: 'دو سالیں موافق ٹرائلز'),
          _t('Verified in ARI Tarnab trials, 2023–24',
              'اے آر آئی ترناب ٹرائلز میں تصدیق شدہ، 2023–24',
              sd: 'اي آر آءِ ترناب ٽرائل ۾ تصديق ٿيل، 2023–24',
              pa: 'اے آر آئی ترناب ٹرائلز وچ تصدیق شدہ، 2023–24',
              ps: 'د اې آر آی ترنب په ازموینو کې تایید شوی، 2023–24',
              bal: 'اے آر آئی ترناب ٹرائلز ءَ تصدیق بوتگیں، 2023–24')
        ),
        (
          _t('Company registered', 'کمپنی رجسٹرڈ',
              sd: 'ڪمپني رجسٽرڊ',
              pa: 'کمپنی رجسٹرڈ',
              ps: 'شرکت ثبت شوې',
              bal: 'کمپنی رجسٹرڈ'),
          _t('Cassia Seed (Private) Limited',
              'کیسیا سیڈ (پرائیویٹ) لمیٹڈ')
        ),
        (
          _t('Promise of Quality', 'معیار کا وعدہ',
              sd: 'معيار جو وعدو',
              pa: 'معیار دا وعدہ',
              ps: 'د کیفیت ژمنه',
              bal: 'معیار ئے وعدہ'),
          _t('Every pack made with care for growers',
              'ہر پیک کاشتکاروں کے لیے توجہ سے تیار',
              sd: 'هر پيڪ ڪاشتڪارن لاءِ خيال سان تيار',
              pa: 'ہر پیک کاشتکاراں لئی خیال نال تیار',
              ps: 'هر پاکټ د بزګرانو لپاره په پاملرنې سره جوړ شوی',
              bal: 'هر پیک کشتکاران ئے واستہ توجہ ءَ تیار')
        ),
        (
          _t('AI Crop Doctor', 'اے آئی کراپ ڈاکٹر',
              sd: 'اي آءِ ڪراپ ڊاڪٽر',
              pa: 'اے آئی کراپ ڈاکٹر',
              ps: 'د اې آی فصل ډاکټر',
              bal: 'اے آئی کراپ ڈاکٹر'),
          _t('Photo-based diagnosis and advice', 'تصویر سے تشخیص اور مشورہ',
              sd: 'تصوير سان تشخيص ۽ صلاح',
              pa: 'تصویر نال تشخیص تے مشورہ',
              ps: 'د عکس پر بنسټ تشخیص او مشوره',
              bal: 'عکس ءَ تشخیص ءُ مشورہ')
        ),
        (
          _t('Direct ordering', 'براہِ راست آرڈر',
              sd: 'سڌو سنئون آرڊر',
              pa: 'سِدھا آرڈر',
              ps: 'مستقیم آرډر',
              bal: 'سیدھایں آرڈر'),
          _t('Order straight from the company', 'سیدھا کمپنی سے آرڈر کریں',
              sd: 'سڌو ڪمپني کان آرڊر ڪريو',
              pa: 'سِدھا کمپنی توں آرڈر کرو',
              ps: 'مستقیم له شرکت څخه آرډر وکړئ',
              bal: 'سیدھا کمپنی ءَ آرڈر کنیت')
        ),
      ];

  String get howOrderingWorks => _t('How Ordering Works', 'آرڈر کیسے ہوتا ہے',
      sd: 'آرڊر ڪيئن ٿيندو آهي',
      pa: 'آرڈر کیویں ہوندا اے',
      ps: 'آرډر څنګه کیږي',
      bal: 'آرڈر چۆن بیت');

  /// The ordering steps as (title, detail) pairs.
  List<(String, String)> get orderSteps => [
        (
          _t('Choose your seeds', 'اپنے بیج چنیں',
              sd: 'پنهنجا ٻج چونڊيو',
              pa: 'اپنے بیج چُنو',
              ps: 'خپل تخمونه وټاکئ',
              bal: 'وتی تُخم ءَ چار اِت'),
          _t('Browse packs and add them to your order.',
              'پیک دیکھیں اور اپنے آرڈر میں شامل کریں۔',
              sd: 'پيڪ ڏسو ۽ پنهنجي آرڊر ۾ شامل ڪريو.',
              pa: 'پیک ویکھو تے اپنے آرڈر وچ شامل کرو۔',
              ps: 'پاکټونه وګورئ او خپل آرډر ته یې ورزیات کړئ.',
              bal: 'پیک ءَ گند اِت ءُ وتی آرڈر ءَ شامل کن اِت۔')
        ),
        (
          _t('Send on WhatsApp', 'واٹس ایپ پر بھیجیں',
              sd: 'واٽس ايپ تي موڪليو',
              pa: 'واٹس ایپ تے بھیجو',
              ps: 'په واټساپ ولیږئ',
              bal: 'واٹس ایپ ءَ رئوان کن اِت'),
          _t('Fill in your details and send the order to us.',
              'اپنی تفصیلات لکھیں اور آرڈر ہمیں بھیجیں۔',
              sd: 'پنهنجيون تفصيلون لکو ۽ آرڊر اسان ڏانهن موڪليو.',
              pa: 'اپنی تفصیلاں لکھو تے آرڈر سانوں بھیجو۔',
              ps: 'خپل جزئیات ولیکئ او آرډر موږ ته ولیږئ.',
              bal: 'وتی تفصیلان ءَ نبیس اِت ءُ آرڈر ءَ ما ءَ رئوان کن اِت۔')
        ),
        (
          _t('We confirm with you', 'ہم آپ سے تصدیق کرتے ہیں',
              sd: 'اسان توهان سان تصديق ڪريون ٿا',
              pa: 'اسِیں تہاڈے نال تصدیق کردے آں',
              ps: 'موږ له تاسو سره تایید کوو',
              bal: 'ما تئی گۆن تصدیق کن اَیں'),
          _t('Our team replies with price and delivery details.',
              'ہماری ٹیم قیمت اور ڈیلیوری کی تفصیل کے ساتھ جواب دیتی ہے۔',
              sd: 'اسان جي ٽيم قيمت ۽ ڊليوري جي تفصيل سان جواب ڏئي ٿي.',
              pa: 'ساڈی ٹیم قیمت تے ڈیلیوری دی تفصیل نال جواب دیندی اے۔',
              ps: 'زموږ ټیم د بیې او رسولو جزئیاتو سره ځواب درکوي.',
              bal: 'مئی ٹیم قیمت ءُ ڈیلیوری ئے تفصیل ءِ گۆن جواب دنت۔')
        ),
      ];

  String get questions => _t('Questions', 'سوالات',
      sd: 'سوال', pa: 'سوال', ps: 'پوښتنې', bal: 'سوالات');

  /// Frequently asked questions as (question, answer) pairs.
  List<(String, String)> get faqs => [
        (
          _t('How do I place an order?', 'میں آرڈر کیسے کروں؟',
              sd: 'مان آرڊر ڪيئن ڪريان؟',
              pa: 'میں آرڈر کیویں کراں؟',
              ps: 'زه آرډر څنګه وکړم؟',
              bal: 'من آرڈر چۆن کنان؟'),
          _t(
              'Add seeds to your order, enter your name, phone and city, and '
                  'send it on WhatsApp. Our team will confirm price and '
                  'delivery.',
              'بیج اپنے آرڈر میں شامل کریں، اپنا نام، فون اور شہر لکھیں، اور '
                  'واٹس ایپ پر بھیج دیں۔ ہماری ٹیم قیمت اور ڈیلیوری کی تصدیق '
                  'کرے گی۔',
              sd: 'ٻج پنهنجي آرڊر ۾ شامل ڪريو، پنهنجو نالو، فون ۽ شهر لکو، ۽ '
                  'واٽس ايپ تي موڪليو. اسان جي ٽيم قيمت ۽ ڊليوري جي تصديق ڪندي.',
              pa: 'بیج اپنے آرڈر وچ شامل کرو، اپنا ناں، فون تے شہر لکھو، تے '
                  'واٹس ایپ تے بھیج دیو۔ ساڈی ٹیم قیمت تے ڈیلیوری دی تصدیق کرے '
                  'گی۔',
              ps: 'تخمونه خپل آرډر ته ورزیات کړئ، خپل نوم، تلیفون او ښار '
                  'ولیکئ، او په واټساپ یې ولیږئ. زموږ ټیم به د بیې او رسولو '
                  'تایید وکړي.',
              bal: 'تُخم ءَ وتی آرڈر ءَ شامل کن اِت، وتی نام، فون ءُ شہر ءَ '
                  'نبیس اِت، ءُ واٹس ایپ ءَ رئوان کن اِت۔ مئی ٹیم قیمت ءُ '
                  'ڈیلیوری ئے تصدیق کنت۔')
        ),
        (
          _t('How accurate is Crop Doctor?', 'کراپ ڈاکٹر کتنا درست ہے؟',
              sd: 'ڪراپ ڊاڪٽر ڪيترو درست آهي؟',
              pa: 'کراپ ڈاکٹر کِنا درست اے؟',
              ps: 'د فصل ډاکټر څومره دقیق دی؟',
              bal: 'کراپ ڈاکٹر چنڈ درست اِنت؟'),
          _t(
              'It is an AI guide based on your photo, not a lab test. A clear '
                  'photo gives better results. Always confirm with a local '
                  'agriculture expert before spraying.',
              'یہ آپ کی تصویر پر مبنی اے آئی رہنمائی ہے، لیب ٹیسٹ نہیں۔ صاف '
                  'تصویر سے بہتر نتیجہ ملتا ہے۔ سپرے سے پہلے ہمیشہ مقامی '
                  'ماہرِ زراعت سے تصدیق کریں۔',
              sd: 'هيءَ اوهان جي تصوير تي ٻڌل اي آءِ رهنمائي آهي، ليب ٽيسٽ '
                  'ناهي. صاف تصوير سان بهتر نتيجو ملي ٿو. اسپري کان اڳ هميشه '
                  'مقامي زرعي ماهر سان تصديق ڪريو.',
              pa: 'ایہہ تہاڈی تصویر تے مبنی اے آئی رہنمائی اے، لیب ٹیسٹ نئیں۔ '
                  'صاف تصویر نال چنگا نتیجہ ملدا اے۔ سپرے توں پہلاں ہمیشہ مقامی '
                  'زرعی ماہر نال تصدیق کرو۔',
              ps: 'دا ستاسو د عکس پر بنسټ د اې آی لارښوونه ده، د لابراتوار '
                  'ازموینه نه ده. روښانه عکس ښه پایله ورکوي. له سپري مخکې تل '
                  'له محلي کرنیز ماهر سره تایید وکړئ.',
              bal: 'ای تئی عکس ئے سر ءَ اے آئی رہنمائی اِنت، لیب ٹیسٹ نہ اِنت۔ '
                  'صافیں عکس ءَ چمّیں نتیجہ کَیت۔ سپرے ئے پیسر ہمیشہ مقامی زرعی '
                  'ماہر ءَ تصدیق کن اِت۔')
        ),
        (
          _t('Where is your office?', 'آپ کا دفتر کہاں ہے؟',
              sd: 'اوهان جو آفيس ڪٿي آهي؟',
              pa: 'تہاڈا دفتر کِتھے اے؟',
              ps: 'ستاسو دفتر چیرته دی؟',
              bal: 'تئی دفتر کجا اِنت؟'),
          _t(
              'Office F-201 & 202, 2nd Floor, Gulshan-e-Zealpak Cooperative '
                  'Housing Society, Site Area, Hyderabad, Sindh.',
              'دفتر F-201 اور 202، دوسری منزل، گلشنِ ذیل پاک کوآپریٹو ہاؤسنگ '
                  'سوسائٹی، سائٹ ایریا، حیدرآباد، سندھ۔')
        ),
      ];

  String get needHelp =>
      _t('Need help choosing a seed?', 'بیج چننے میں مدد چاہیے؟',
          sd: 'ٻج چونڊڻ ۾ مدد گهرجي؟',
          pa: 'بیج چُننے وچ مدد چاہیدی اے؟',
          ps: 'د تخم په ټاکلو کې مرسته غواړئ؟',
          bal: 'تُخم چارگ ءَ مدد لوٹیت؟');
  String get needHelpBody => _t(
      'Ask Cassia, our AI advisor, or contact our team directly.',
      'کیسیا (ہمارا اے آئی مشیر) سے پوچھیں، یا براہِ راست ہماری ٹیم سے '
          'رابطہ کریں۔',
      sd: 'ڪيسيا (اسان جو اي آءِ مشير) کان پڇو، يا سڌو اسان جي ٽيم سان رابطو '
          'ڪريو.',
      pa: 'کیسیا (ساڈا اے آئی مشیر) توں پُچھو، یا سِدھا ساڈی ٹیم نال رابطہ کرو۔',
      ps: 'له کیسیا (زموږ د اې آی سلاکار) وپوښتئ، یا مستقیم زموږ له ټیم سره '
          'اړیکه ونیسئ.',
      bal: 'کیسیا (مئی اے آئی مشیر) ءَ پُرس اِت، یا سیدھا مئی ٹیم ءِ گۆن رابطہ '
          'کن اِت۔');
  String get switchTheme => _t('Light / dark', 'روشن / تاریک',
      sd: 'روشن / اونداهو',
      pa: 'روشن / ہنیرا',
      ps: 'روښانه / تیاره',
      bal: 'روشن / تهار');

  // ------------------------------------------------------------- footer
  String get quickLinks => _t('Quick Links', 'فوری روابط',
      sd: 'فوري ڳنڍڻا', pa: 'فوری لنکس', ps: 'ژر اړیکې', bal: 'فوری لنکس');
  String get ourPromise => _t('Our Promise', 'ہمارا وعدہ',
      sd: 'اسان جو وعدو', pa: 'ساڈا وعدہ', ps: 'زموږ ژمنه', bal: 'مئی وعدہ');
  String get headOffice => _t('Head Office', 'مرکزی دفتر',
      sd: 'مرڪزي آفيس',
      pa: 'مرکزی دفتر',
      ps: 'مرکزي دفتر',
      bal: 'مرکزی دفتر');
  String get ourBrands => _t('Our Brands', 'ہمارے برانڈز',
      sd: 'اسان جا برانڊ',
      pa: 'ساڈے برانڈز',
      ps: 'زموږ برانډونه',
      bal: 'مئی برانڈز');
  String get brandsLine =>
      _t('Cassia Seed · Malapine Seeds', 'کیسیا سیڈ · مالاپائن سیڈز');
  String get designedByOwner => _t('Designed by owner', 'مالک کے ذریعے ڈیزائن',
      sd: 'مالڪ پاران ٺاهيل',
      pa: 'مالک ولوں ڈیزائن',
      ps: 'د مالک لخوا ډیزاین',
      bal: 'مالک ئے نیمگ ءَ ڈیزائن');
  String get reachAllPakistan =>
      _t('We reach all over Pakistan', 'ہم پورے پاکستان میں پہنچتے ہیں',
          sd: 'اسان سڄي پاڪستان ۾ پهچون ٿا',
          pa: 'اسِیں سارے پاکستان وچ پہنچدے آں',
          ps: 'موږ ټول پاکستان ته رسیږو',
          bal: 'ما پُریں پاکستان ءَ رسَیں');

  // ------------------------------------------- extra home quick actions
  String get myFarm => _t('My Farm', 'میرا کھیت',
      sd: 'منهنجو کيت', pa: 'میرا کھیت', ps: 'زما پټی', bal: 'منی بیڑ');
  String get findDealer => _t('Find a Dealer', 'ڈیلر تلاش کریں',
      sd: 'ڊيلر ڳوليو',
      pa: 'ڈیلر لبھو',
      ps: 'ډیلر ولټوئ',
      bal: 'ڈیلر ءَ گیچ اِت');
  String get help => _t('Help', 'مدد',
      sd: 'مدد', pa: 'مدد', ps: 'مرسته', bal: 'مدد');
  String get fromOurFields => _t('From Our Fields', 'ہمارے کھیتوں سے',
      sd: 'اسان جي کيتن مان',
      pa: 'ساڈے کھیتاں توں',
      ps: 'زموږ له پټیو څخه',
      bal: 'مئی بیڑان ءَ');
  List<String> get fieldCaptions => [
        _t('Field day with growers', 'کاشتکاروں کے ساتھ فیلڈ ڈے',
            sd: 'ڪاشتڪارن سان فيلڊ ڊي',
            pa: 'کاشتکاراں نال فیلڈ ڈے',
            ps: 'له بزګرانو سره فیلډ ورځ',
            bal: 'کشتکاران ئے گۆن فیلڈ ڈے'),
        _t('Chilli crop', 'مرچ کی فصل',
            sd: 'مرچ جي فصل',
            pa: 'مرچ دی فصل',
            ps: 'د مرچو فصل',
            bal: 'مرچ ئے فصل'),
        _t('Cucumber harvest', 'کھیرے کی فصل',
            sd: 'ڪَڪڙيءَ جي فصل',
            pa: 'کھیرے دی فصل',
            ps: 'د بادرنګو فصل',
            bal: 'کھیرا ئے فصل'),
        _t('Chilli field', 'مرچ کا کھیت',
            sd: 'مرچ جو کيت',
            pa: 'مرچ دا کھیت',
            ps: 'د مرچو پټی',
            bal: 'مرچ ئے بیڑ'),
      ];

  // ------------------------------------------------------------- weather
  String get todaysWeather => _t("Today's weather", 'آج کا موسم',
      sd: 'اڄ جو موسم', pa: 'اَج دا موسم', ps: 'د نن هوا', bal: 'مرۆچی ہوا');
  String get change => _t('Change', 'تبدیل کریں',
      sd: 'تبديل ڪريو', pa: 'تبدیل کرو', ps: 'بدل کړئ', bal: 'تبدیل کن اِت');
  String get humidity => _t('Humidity', 'نمی',
      sd: 'نمي', pa: 'نمی', ps: 'لندوالی', bal: 'نمی');
  String get wind => _t('Wind', 'ہوا',
      sd: 'هوا', pa: 'ہوا', ps: 'باد', bal: 'گوات');
  String get rainChance => _t('Rain chance', 'بارش کا امکان',
      sd: 'برسات جو امڪان',
      pa: 'بارش دا امکان',
      ps: 'د باران امکان',
      bal: 'گوارش ئے امکان');
  String get yourDistrict => _t('Your district / city', 'آپ کا ضلع / شہر',
      sd: 'اوهان جو ضلعو / شهر',
      pa: 'تہاڈا ضلع / شہر',
      ps: 'ستاسو ولسوالي / ښار',
      bal: 'تئی ضلع / شہر');
  String get chooseYourDistrict =>
      _t('Choose your district', 'اپنا ضلع منتخب کریں',
          sd: 'پنهنجو ضلعو چونڊيو',
          pa: 'اپنا ضلع چُنو',
          ps: 'خپله ولسوالي وټاکئ',
          bal: 'وتی ضلع ءَ چار اِت');
  String get weatherUnavailable => _t(
      'Weather is not available right now.', 'موسم ابھی دستیاب نہیں ہے۔',
      sd: 'موسم اڃا موجود ناهي.',
      pa: 'موسم ہلے دستیاب نئیں اے۔',
      ps: 'هوا اوس نشته.',
      bal: 'ہوا هنوں دستیاب نیست۔');
  String get sprayBad => _t('Not a good time to spray: check wind and rain '
      'first.', 'سپرے کا مناسب وقت نہیں: پہلے ہوا اور بارش دیکھ لیں۔',
      sd: 'اسپري جو مناسب وقت ناهي: پهريان هوا ۽ برسات ڏسو.',
      pa: 'سپرے دا مناسب ویلہ نئیں: پہلاں ہوا تے بارش ویکھو۔',
      ps: 'د سپري مناسب وخت نه دی: لومړی باد او باران وګورئ.',
      bal: 'سپرے ئے مناسب وخت نہ اِنت: پیسر گوات ءُ گوارش ءَ گند اِت۔');
  String get sprayOk => _t(
      'Wind and rain are low right now. Still confirm locally before spraying.',
      'ابھی ہوا اور بارش کم ہے۔ پھر بھی سپرے سے پہلے مقامی طور پر تصدیق کریں۔',
      sd: 'هينئر هوا ۽ برسات گهٽ آهي. پوءِ به اسپري کان اڳ مقامي طور تي '
          'تصديق ڪريو.',
      pa: 'ہُنے ہوا تے بارش گھٹ اے۔ فیر وی سپرے توں پہلاں مقامی طور تے تصدیق '
          'کرو۔',
      ps: 'اوس باد او باران کم دی. بیا هم له سپري مخکې په محلي توګه تایید '
          'وکړئ.',
      bal: 'هنوں گوات ءُ گوارش کم اِنت۔ بله هم سپرے ئے پیسر مقامی طور ءَ تصدیق '
          'کن اِت۔');

  String get motto => _t('Grow with Cassia', 'کیسیا کے ساتھ اُگائیں',
      sd: 'ڪيسيا سان گڏ پوکيو',
      pa: 'کیسیا نال اُگاؤ',
      ps: 'له کیسیا سره کرل',
      bal: 'کیسیا ئے گۆن کشت کن اِت');
  String get cropDoctor => _t('Crop Doctor', 'کراپ ڈاکٹر',
      sd: 'ڪراپ ڊاڪٽر', pa: 'کراپ ڈاکٹر', ps: 'د فصل ډاکټر', bal: 'کراپ ڈاکٹر');
  String get cropDoctorTagline => _t(
      'Photograph a sick plant → get the problem & cure',
      'بیمار پودے کی تصویر لیں، مسئلہ اور علاج جانیں',
      sd: 'بيمار ٻوٽي جي تصوير ڪڍو، مسئلو ۽ علاج ڄاڻو',
      pa: 'بیمار بوٹے دی تصویر لَوو، مسئلہ تے علاج جانو',
      ps: 'د ناروغ بوټي عکس واخلئ، ستونزه او علاج ومومئ',
      bal: 'نزوریں بُنگ ئے عکس ءَ گر اِت، مسئلہ ءُ علاج ءَ زان اِت');
  String get shopSeeds => _t('Shop seeds', 'بیج خریدیں',
      sd: 'ٻج خريدو', pa: 'بیج خریدو', ps: 'تخمونه واخلئ', bal: 'تُخم ءَ گر اِت');
  String get askCassiaAi => _t('Ask Cassia AI', 'کیسیا اے آئی',
      sd: 'ڪيسيا اي آءِ', pa: 'کیسیا اے آئی', ps: 'کیسیا اې آی', bal: 'کیسیا اے آئی');
  String get featuredVarieties => _t('Featured varieties', 'نمایاں اقسام',
      sd: 'نمايان قسمون',
      pa: 'نمایاں قسماں',
      ps: 'ځانګړي ډولونه',
      bal: 'نمایاں قسمان');
  String get seeAll => _t('See all', 'سب دیکھیں',
      sd: 'سڀ ڏسو', pa: 'سارے ویکھو', ps: 'ټول وګورئ', bal: 'پُریں گند اِت');
  String get noVarietiesYet =>
      _t('No varieties yet.', 'ابھی کوئی قسم موجود نہیں۔',
          sd: 'اڃا ڪا به قسم موجود ناهي.',
          pa: 'ہلے کوئی قسم موجود نئیں۔',
          ps: 'لا تر اوسه کوم ډول نشته.',
          bal: 'هنوں ہچ قسم دستیاب نیست۔');

  // ---------------------------------------------------------------- shop

  String get shop => _t('Shop', 'دکان',
      sd: 'دُڪان', pa: 'دکان', ps: 'دکان', bal: 'دکان');
  String get allCrops => _t('All', 'تمام',
      sd: 'سڀ', pa: 'سارے', ps: 'ټول', bal: 'پُریں');
  String get searchSeeds => _t('Search seeds…', 'بیج تلاش کریں…',
      sd: 'ٻج ڳوليو…', pa: 'بیج لبھو…', ps: 'تخمونه ولټوئ…', bal: 'تُخم ءَ گیچ اِت…');

  // The Shop's filter groups.
  String get groupTomato => _t('Tomato', 'ٹماٹر',
      sd: 'ٽماٽو', pa: 'ٹماٹر', ps: 'رومي', bal: 'ٹماٹر');
  String get groupPepper => _t('Hot Pepper', 'مرچ',
      sd: 'مرچ', pa: 'مرچ', ps: 'مرچ', bal: 'مرچ');
  String get groupGourds => _t('Gourds', 'کدو',
      sd: 'ڏودهي', pa: 'کدو', ps: 'کدو', bal: 'کدو');
  String get groupOkra => _t('Okra', 'بھنڈی',
      sd: 'ڀينڊي', pa: 'بھنڈی', ps: 'بامیه', bal: 'بھنڈی');
  String get groupOtherVeg => _t('Other Veg', 'دیگر سبزیاں',
      sd: 'ٻيون ڀاڄيون',
      pa: 'ہور سبزیاں',
      ps: 'نورې سابه',
      bal: 'دگہ سبزی');
  String get groupFieldCrops => _t('Field Crops', 'کھیت کی فصلیں',
      sd: 'کيت جون فصلون',
      pa: 'کھیت دیاں فصلاں',
      ps: 'د پټي فصلونه',
      bal: 'بیڑ ئے فصل');
  String get clearSearch => _t('Clear search', 'تلاش صاف کریں',
      sd: 'ڳولا صاف ڪريو',
      pa: 'تلاش صاف کرو',
      ps: 'لټون پاک کړئ',
      bal: 'گیچ ءَ صاف کن اِت');
  String noMatches(String query) => _t(
      'No varieties match "$query"',
      '"${data(query)}" سے ملتی کوئی قسم نہیں ملی',
      sd: '"${data(query)}" سان ملندڙ ڪا قسم نه ملي',
      pa: '"${data(query)}" نال ملدی کوئی قسم نئیں ملی',
      ps: 'له "${data(query)}" سره سمون لرونکی ډول ونه موندل شو',
      bal: '"${data(query)}" ئے گۆن مننگیں ہچ قسم نہ کپت');
  String get showAllVarieties =>
      _t('Show all varieties', 'تمام اقسام دکھائیں',
          sd: 'سڀ قسمون ڏيکاريو',
          pa: 'ساریاں قسماں ویکھاؤ',
          ps: 'ټول ډولونه وښیئ',
          bal: 'پُریں قسمان ءَ پیش کن اِت');
  String get noProductsYet => _t('No products yet', 'ابھی کوئی پروڈکٹ نہیں',
      sd: 'اڃا ڪو پراڊڪٽ ناهي',
      pa: 'ہلے کوئی پروڈکٹ نئیں',
      ps: 'لا تر اوسه محصول نشته',
      bal: 'هنوں ہچ پروڈکٹ نیست');
  String get noProductsBody => _t(
      'Varieties will appear here once they are added from the admin panel.',
      'ایڈمن پینل سے شامل ہونے کے بعد اقسام یہاں نظر آئیں گی۔',
      sd: 'ايڊمن پينل مان شامل ٿيڻ کان پوءِ قسمون هتي نظر اينديون.',
      pa: 'ایڈمن پینل توں شامل ہون توں بعد قسماں ایتھے نظر آؤن گیاں۔',
      ps: 'د اډمن پینل څخه د ورزیاتولو وروسته ډولونه به دلته ښکاره شي.',
      bal: 'ایڈمن پینل ءَ شامل بئگ ئے رند قسمان ادان ءَ پدی بَنت۔');
  String get couldNotLoadProducts =>
      _t('Could not load products', 'پروڈکٹس لوڈ نہیں ہو سکیں',
          sd: 'پراڊڪٽ لوڊ نه ٿي سگهيا',
          pa: 'پروڈکٹس لوڈ نئیں ہو سکے',
          ps: 'محصولات بار نشو',
          bal: 'پروڈکٹس لوڈ نہ بوتنت');
  String get seedPlaceholder => _t('Seed', 'بیج',
      sd: 'ٻج', pa: 'بیج', ps: 'تخم', bal: 'تُخم');

  // -------------------------------------------- crop names & pack sizes
  // Product data (the crop and the pack size) is stored in English in
  // Firestore. These map the common crops and the weight units into the
  // farmer's language wherever that data is shown — the Home crop band and
  // crop circles, the Spotlight, product cards and a variety's details.

  /// A crop's name in the current language. English — the language the data
  /// is written in — is returned unchanged; a crop with no known translation
  /// keeps its English name.
  String cropName(String crop) {
    if (lang == AppLanguage.en) return crop;
    final n = crop.toLowerCase();
    // Order matters: "bitter gourd" and "sponge gourd" before plain "gourd".
    if (n.contains('tomato') || n.contains('tomoto')) {
      return _t('Tomato', 'ٹماٹر',
          sd: 'ٽماٽو', pa: 'ٹماٹر', ps: 'رومي', bal: 'ٹماٹر');
    }
    if (n.contains('bitter') || n.contains('karela')) {
      return _t('Bitter gourd', 'کریلا',
          sd: 'ڪريلو', pa: 'کریلا', ps: 'کاریلا', bal: 'کریلا');
    }
    if (n.contains('sponge') ||
        n.contains('ridge') ||
        n.contains('tori') ||
        n.contains('turai') ||
        n.contains('luffa')) {
      return _t('Sponge gourd', 'توری',
          sd: 'توري', pa: 'توری', ps: 'توری', bal: 'توری');
    }
    if (n.contains('gourd') ||
        n.contains('kadu') ||
        n.contains('lauki') ||
        n.contains('pumpkin')) {
      return _t('Gourd', 'کدو',
          sd: 'ڏودهي', pa: 'کدو', ps: 'کدو', bal: 'کدو');
    }
    if (n.contains('okra') || n.contains('bhindi') || n.contains('lady')) {
      return _t('Okra', 'بھنڈی',
          sd: 'ڀينڊي', pa: 'بھنڈی', ps: 'بامیه', bal: 'بھنڈی');
    }
    if (n.contains('pepper') ||
        n.contains('chilli') ||
        n.contains('chili') ||
        n.contains('capsicum') ||
        n.contains('mirch')) {
      return _t('Chilli', 'مرچ', sd: 'مرچ', pa: 'مرچ', ps: 'مرچ', bal: 'مرچ');
    }
    if (n.contains('cucumber') || n.contains('kheera') || n.contains('khira')) {
      return _t('Cucumber', 'کھیرا',
          sd: 'ڪَڪڙي', pa: 'کھیرا', ps: 'بادرنګ', bal: 'کھیرا');
    }
    if (n.contains('brinjal') ||
        n.contains('eggplant') ||
        n.contains('aubergine') ||
        n.contains('baingan')) {
      return _t('Brinjal', 'بینگن',
          sd: 'وانڱڻ', pa: 'بینگن', ps: 'بانجن', bal: 'بینگن');
    }
    if (n.contains('pea')) {
      return _t('Peas', 'مٹر', sd: 'مٽر', pa: 'مٹر', ps: 'مټر', bal: 'مٹر');
    }
    if (n.contains('carrot') || n.contains('gajar')) {
      return _t('Carrot', 'گاجر',
          sd: 'گاجر', pa: 'گاجر', ps: 'ګازره', bal: 'گاجر');
    }
    if (n.contains('paddy') || n.contains('rice') || n.contains('dhan')) {
      return _t('Paddy', 'دھان',
          sd: 'چانور', pa: 'جھونا', ps: 'وریژې', bal: 'برنج');
    }
    if (n.contains('onion') || n.contains('pyaz')) {
      return _t('Onion', 'پیاز',
          sd: 'بصر', pa: 'پیاز', ps: 'پیاز', bal: 'پیاز');
    }
    if (n.contains('cauliflower')) {
      return _t('Cauliflower', 'پھول گوبھی',
          sd: 'گل گوبي', pa: 'پھول گوبھی', ps: 'ګل بندګوبي', bal: 'پُل گوبھی');
    }
    if (n.contains('cabbage')) {
      return _t('Cabbage', 'بند گوبھی',
          sd: 'بند گوبي', pa: 'بند گوبھی', ps: 'بندګوبي', bal: 'بند گوبھی');
    }
    if (n.contains('spinach') || n.contains('palak')) {
      return _t('Spinach', 'پالک',
          sd: 'پالڪ', pa: 'پالک', ps: 'پالک', bal: 'پالک');
    }
    if (n.contains('coriander') || n.contains('dhania')) {
      return _t('Coriander', 'دھنیا',
          sd: 'ڌڻا', pa: 'دھنیا', ps: 'دانیوال', bal: 'دھنیا');
    }
    // A crop with no translation: keep its own (English) name.
    return crop;
  }

  /// A pack size in the current language: the number is kept as is and only
  /// the weight unit is translated ("10 g" → "10 گرام", "1 kg" → "1 کلو").
  /// An empty or unusual value is returned unchanged.
  String packSize(String raw) {
    final text = raw.trim();
    if (text.isEmpty || lang == AppLanguage.en) return text;
    final match = RegExp(r'^([\d.,]+)\s*([A-Za-z]+)$').firstMatch(text);
    if (match == null) return text;
    final number = match.group(1)!;
    final unit = match.group(2)!.toLowerCase();
    final String word;
    if (unit == 'kg' || unit == 'kgs' || unit.startsWith('kilo')) {
      word = _t('kg', 'کلو', sd: 'ڪلو', pa: 'کلو', ps: 'کیلو', bal: 'کلو');
    } else if (unit == 'g' ||
        unit == 'gm' ||
        unit == 'gms' ||
        unit.startsWith('gram')) {
      word = _t('g', 'گرام', sd: 'گرام', pa: 'گرام', ps: 'ګرامه', bal: 'گرام');
    } else if (unit == 'mg') {
      word = _t('mg', 'ملی گرام',
          sd: 'ملي گرام', pa: 'ملی گرام', ps: 'ملي ګرامه', bal: 'ملی گرام');
    } else {
      return text;
    }
    return '$number $word';
  }

  // ------------------------------------------------------ product detail

  // The three photos in the gallery.
  String get photoFront => _t('Front', 'سامنے',
      sd: 'سامهون', pa: 'سامنے', ps: 'مخ', bal: 'دیم');
  String get photoCloseUp => _t('Close-up', 'قریب سے',
      sd: 'ويجهو', pa: 'نیڑیوں', ps: 'نږدې', bal: 'نزّیک ءَ');
  String get photoShowcase => _t('Showcase', 'نمائش',
      sd: 'نمائش', pa: 'نمائش', ps: 'ښودنه', bal: 'نمائش');

  String get tabDetails => _t('Details', 'تفصیلات',
      sd: 'تفصيلون', pa: 'تفصیلاں', ps: 'جزئیات', bal: 'تفصیلات');
  String get tabFeatures => _t('Features', 'خصوصیات',
      sd: 'خاصيتون', pa: 'خصوصیات', ps: 'ځانګړتیاوې', bal: 'خصوصیات');
  String get brandLabel => _t('Brand', 'برانڈ',
      sd: 'برانڊ', pa: 'برانڈ', ps: 'برانډ', bal: 'برانڈ');
  String get cassiaBrand => _t('Cassia', 'کیسیا',
      sd: 'ڪيسيا', pa: 'کیسیا', ps: 'کیسیا', bal: 'کیسیا');
  String get cropLabel => _t('Crop', 'فصل',
      sd: 'فصل', pa: 'فصل', ps: 'فصل', bal: 'فصل');
  String get typeLabel => _t('Type', 'قسم',
      sd: 'قسم', pa: 'قسم', ps: 'ډول', bal: 'قسم');
  String get packSizeLabel => _t('Pack size', 'پیک سائز',
      sd: 'پيڪ سائيز', pa: 'پیک سائز', ps: 'د پاکټ کچه', bal: 'پیک سائز');
  String get priceLabel => _t('Price', 'قیمت',
      sd: 'قيمت', pa: 'قیمت', ps: 'بیه', bal: 'قیمت');
  String get onRequest => _t('On request', 'پوچھنے پر',
      sd: 'پڇڻ تي', pa: 'پُچھن تے', ps: 'په غوښتنه', bal: 'پُرسگ ءَ');
  String get askCompany => _t('Ask company', 'کمپنی سے پوچھیں',
      sd: 'ڪمپني کان پڇو',
      pa: 'کمپنی توں پُچھو',
      ps: 'له شرکت وپوښتئ',
      bal: 'کمپنی ءَ پُرس اِت');
  String get printedOnPack => _t('Printed on pack', 'پیک پر درج',
      sd: 'پيڪ تي ڇپيل',
      pa: 'پیک تے چھپیا',
      ps: 'په پاکټ چاپ شوی',
      bal: 'پیک ءَ چاپ بوتگ');
  String get featuresToCome => _t(
      'Official variety features (maturity, yield, resistance and more) '
          'will be added by the Cassia team.',
      'قسم کی سرکاری خصوصیات (پکنے کا وقت، پیداوار، قوتِ مدافعت وغیرہ) '
          'کیسیا ٹیم شامل کرے گی۔',
      sd: 'قسم جون سرڪاري خاصيتون (پچڻ جو وقت، پيداوار، قوتِ مدافعت وغيره) '
          'ڪيسيا ٽيم شامل ڪندي.',
      pa: 'قسم دیاں سرکاری خصوصیات (پکن دا ویلہ، پیداوار، قوتِ مدافعت وغیرہ) '
          'کیسیا ٹیم شامل کرے گی۔',
      ps: 'د ډول رسمي ځانګړتیاوې (د پخیدو وخت، حاصل، مقاومت او نور) به د '
          'کیسیا ټیم ورزیات کړي.',
      bal: 'قسم ئے سرکاری خصوصیات (پَچّگ ئے وخت، پیداوار، قوتِ مدافعت ءُ دگہ) '
          'کیسیا ٹیم شامل کنت۔');
  String get cropGuideButton =>
      _t('🌿 General crop guide (AI)', '🌿 فصل کی عمومی رہنمائی (اے آئی)',
          sd: '🌿 فصل جي عام رهنمائي (اي آءِ)',
          pa: '🌿 فصل دی عام رہنمائی (اے آئی)',
          ps: '🌿 د فصل عمومي لارښوونه (اې آی)',
          bal: '🌿 فصل ئے عمومی رہنمائی (اے آئی)');
  String get cropGuideNote => _t(
      '(General crop guidance, not official Cassia variety data.)',
      '(یہ فصل کی عمومی رہنمائی ہے، کیسیا کی قسم کا سرکاری ڈیٹا نہیں۔)',
      sd: '(هيءَ فصل جي عام رهنمائي آهي، ڪيسيا جي قسم جو سرڪاري ڊيٽا ناهي.)',
      pa: '(ایہہ فصل دی عام رہنمائی اے، کیسیا دی قسم دا سرکاری ڈیٹا نئیں۔)',
      ps: '(دا د فصل عمومي لارښوونه ده، د کیسیا د ډول رسمي معلومات نه دي.)',
      bal: '(ای فصل ئے عمومی رہنمائی اِنت، کیسیا ئے قسم ئے سرکاری ڈیٹا نہ اِنت۔)');
  String get quantityPacks => _t('Quantity (packs)', 'تعداد (پیکٹ)',
      sd: 'تعداد (پيڪ)', pa: 'تعداد (پیک)', ps: 'شمیر (پاکټ)', bal: 'تعداد (پیک)');
  String addToOrder(int packs) =>
      _t('Add $packs to Order', 'آرڈر میں $packs شامل کریں',
          sd: 'آرڊر ۾ $packs شامل ڪريو',
          pa: 'آرڈر وچ $packs شامل کرو',
          ps: 'آرډر ته $packs ورزیات کړئ',
          bal: 'آرڈر ءَ $packs شامل کن اِت');
  String addedToOrder(int packs, String name) => _t(
      '$packs × $name added to your order ✓',
      '${data('$packs × $name')} آپ کے آرڈر میں شامل ہو گیا ✓',
      sd: '${data('$packs × $name')} اوهان جي آرڊر ۾ شامل ٿي ويو ✓',
      pa: '${data('$packs × $name')} تہاڈے آرڈر وچ شامل ہو گیا ✓',
      ps: '${data('$packs × $name')} ستاسو آرډر ته ورزیات شو ✓',
      bal: '${data('$packs × $name')} تئی آرڈر ءَ شامل بوت ✓');
  String get askAboutThisSeed => _t(
      'Ask Cassia about this seed', 'اس بیج کے بارے میں کیسیا سے پوچھیں',
      sd: 'هن ٻج بابت ڪيسيا کان پڇو',
      pa: 'ایس بیج بارے کیسیا توں پُچھو',
      ps: 'د دې تخم په اړه له کیسیا وپوښتئ',
      bal: 'اے تُخم ئے بارہ ءَ کیسیا ءَ پُرس اِت');

  /// The question "Ask Cassia about this seed" asks.
  String growingQuestion(String crop, String name) => _t(
      'Tell me about growing $crop ($name): sowing time, spacing, '
          'fertiliser and common problems in Pakistan.',
      '${data('$crop ($name)')} اگانے کے بارے میں بتائیں: بوائی کا وقت، '
          'فاصلہ، کھاد اور پاکستان میں عام مسائل۔',
      sd: '${data('$crop ($name)')} پوکڻ بابت ٻڌايو: پوکڻ جو وقت، فاصلو، '
          'ڀاڻ ۽ پاڪستان ۾ عام مسئلا.',
      pa: '${data('$crop ($name)')} اُگان بارے دسو: بوائی دا ویلہ، فاصلہ، '
          'کھاد تے پاکستان وچ عام مسئلے۔',
      ps: 'د ${data('$crop ($name)')} د کرلو په اړه راته ووایئ: د کرلو وخت، '
          'فاصله، سره او په پاکستان کې عام ستونزې.',
      bal: '${data('$crop ($name)')} کشت کنگ ئے بارہ ءَ بہ گوش اِت: کشت ئے '
          'وخت، فاصلہ، سرین ءُ پاکستان ءَ عام مسئلہ۔');
  String get saveToFavourites =>
      _t('♡ Save to favourites', '♡ پسندیدہ میں محفوظ کریں',
          sd: '♡ پسنديده ۾ محفوظ ڪريو',
          pa: '♡ پسندیدہ وچ محفوظ کرو',
          ps: '♡ خوښو ته خوندي کړئ',
          bal: '♡ پسندیدہ ءَ محفوظ کن اِت');
  String get savedFavourite => _t('♥ Saved', '♥ محفوظ ہے',
      sd: '♥ محفوظ آهي', pa: '♥ محفوظ اے', ps: '♥ خوندي شو', bal: '♥ محفوظ اِنت');
  String get savedToFavourites =>
      _t('Saved to favourites', 'پسندیدہ میں محفوظ ہو گیا',
          sd: 'پسنديده ۾ محفوظ ٿي ويو',
          pa: 'پسندیدہ وچ محفوظ ہو گیا',
          ps: 'خوښو ته خوندي شو',
          bal: 'پسندیدہ ءَ محفوظ بوت');
  String get removedFromFavourites =>
      _t('Removed from favourites', 'پسندیدہ سے نکال دیا گیا',
          sd: 'پسنديده مان ڪڍي ڇڏيو',
          pa: 'پسندیدہ توں کڈھ دتا',
          ps: 'له خوښو لرې شو',
          bal: 'پسندیدہ ءَ در کُشّگ بوت');
  String get yourFavourites => _t('Your Favourites', 'آپ کے پسندیدہ',
      sd: 'اوهان جا پسنديده',
      pa: 'تہاڈے پسندیدہ',
      ps: 'ستاسو خوښې',
      bal: 'تئی پسندیدہ');

  // ---------------------------------------------------------------- cart

  String get cart => _t('Cart', 'کارٹ',
      sd: 'ڪارٽ', pa: 'کارٹ', ps: 'کارټ', bal: 'کارٹ');
  String get remove => _t('Remove', 'نکالیں',
      sd: 'ڪڍو', pa: 'کڈھو', ps: 'لرې کړئ', bal: 'در کُش اِت');
  String get decrease => _t('Decrease', 'کم کریں',
      sd: 'گهٽايو', pa: 'گھٹاؤ', ps: 'کم کړئ', bal: 'کم کن اِت');
  String get increase => _t('Increase', 'بڑھائیں',
      sd: 'وڌايو', pa: 'ودھاؤ', ps: 'زیات کړئ', bal: 'گیش کن اِت');
  String get quantity => _t('Quantity', 'تعداد',
      sd: 'تعداد', pa: 'تعداد', ps: 'شمیر', bal: 'تعداد');
  String get numberOfPacks => _t('Number of packs', 'پیکٹوں کی تعداد',
      sd: 'پيڪن جو تعداد',
      pa: 'پیکاں دی تعداد',
      ps: 'د پاکټونو شمیر',
      bal: 'پیکان ئے تعداد');
  String upTo(int max) => _t('Up to $max', '$max تک',
      sd: '$max تائين', pa: '$max تک', ps: 'تر $max پورې', bal: '$max تاں');
  String get dismiss => _t('Dismiss', 'بند کریں',
      sd: 'بند ڪريو', pa: 'بند کرو', ps: 'بند کړئ', bal: 'بند کن اِت');
  String removedFromCart(String names) => _t(
      'Not available yet, so removed from your cart: $names',
      'ابھی دستیاب نہیں، اس لیے کارٹ سے نکال دی گئیں: ${data(names)}',
      sd: 'اڃا موجود ناهي، تنهنڪري ڪارٽ مان ڪڍي ڇڏيون: ${data(names)}',
      pa: 'ہلے دستیاب نئیں، ایس لئی کارٹ توں کڈھ دتیاں: ${data(names)}',
      ps: 'لا نشته، نو ستاسو له کارټ لرې شوې: ${data(names)}',
      bal: 'هنوں دستیاب نیست، پمیشکا کارٹ ءَ در کُشّگ بوتنت: ${data(names)}');
  String get yourCart => _t('Your cart', 'آپ کا کارٹ',
      sd: 'اوهان جو ڪارٽ', pa: 'تہاڈا کارٹ', ps: 'ستاسو کارټ', bal: 'تئی کارٹ');
  String get cartEmpty => _t('Your cart is empty', 'آپ کا کارٹ خالی ہے',
      sd: 'اوهان جو ڪارٽ خالي آهي',
      pa: 'تہاڈا کارٹ خالی اے',
      ps: 'ستاسو کارټ خالي دی',
      bal: 'تئی کارٹ خالی اِنت');
  String get cartEmptyHint => _t(
      'Open a variety in the Shop and tap "Add to Order".',
      'دکان میں کوئی قسم کھولیں اور "آرڈر میں شامل کریں" دبائیں۔',
      sd: 'دُڪان ۾ ڪا قسم کوليو ۽ "آرڊر ۾ شامل ڪريو" دٻايو.',
      pa: 'دکان وچ کوئی قسم کھولو تے "آرڈر وچ شامل کرو" دباؤ۔',
      ps: 'په دکان کې یو ډول پرانیزئ او "آرډر ته ورزیات کړئ" کېکاږئ.',
      bal: 'دکان ءَ ہچ قسم ءَ پچ کن اِت ءُ "آرڈر ءَ شامل کن اِت" ءَ دبّ اِت۔');
  String cartSummary(int varieties, int packs) => _t(
      '$varieties ${varieties == 1 ? 'variety' : 'varieties'} • '
          '$packs ${packs == 1 ? 'pack' : 'packs'}',
      '$varieties ${varieties == 1 ? 'قسم' : 'اقسام'} • $packs پیکٹ',
      sd: '$varieties ${varieties == 1 ? 'قسم' : 'قسمون'} • $packs پيڪ',
      pa: '$varieties ${varieties == 1 ? 'قسم' : 'قسماں'} • $packs پیک',
      ps: '$varieties ${varieties == 1 ? 'ډول' : 'ډولونه'} • $packs پاکټ',
      bal: '$varieties ${varieties == 1 ? 'قسم' : 'قسمان'} • $packs پیک');
  String get priceConfirmedOnWhatsApp => _t(
      'Cassia Seed confirms the price on WhatsApp.',
      'قیمت کیسیا سیڈ واٹس ایپ پر بتائے گا۔',
      sd: 'قيمت ڪيسيا سيڊ واٽس ايپ تي ٻڌائيندو.',
      pa: 'قیمت کیسیا سیڈ واٹس ایپ تے دسے گا۔',
      ps: 'بیه به کیسیا سیډ په واټساپ ووایي.',
      bal: 'قیمت ءَ کیسیا سیڈ واٹس ایپ ءَ گوشیت۔');
  String get continueLabel => _t('Continue', 'آگے بڑھیں',
      sd: 'اڳتي وڌو', pa: 'اگے ودھو', ps: 'مخکې لاړ شئ', bal: 'پیسر رو اِت');

  // ------------------------------------------------------------ checkout

  String get yourDetails => _t('Your details', 'آپ کی تفصیلات',
      sd: 'اوهان جون تفصيلون',
      pa: 'تہاڈیاں تفصیلاں',
      ps: 'ستاسو جزئیات',
      bal: 'تئی تفصیلات');
  String get yourName => _t('Your name', 'آپ کا نام',
      sd: 'اوهان جو نالو', pa: 'تہاڈا ناں', ps: 'ستاسو نوم', bal: 'تئی نام');
  String get phoneNumber => _t('Phone number', 'فون نمبر',
      sd: 'فون نمبر', pa: 'فون نمبر', ps: 'د تلیفون شمیره', bal: 'فون نمبر');
  String get cityOrVillage => _t('City or village', 'شہر یا گاؤں',
      sd: 'شهر يا ڳوٺ', pa: 'شہر یا پِنڈ', ps: 'ښار یا کلی', bal: 'شہر یا هلک');
  String get noteOptional => _t('Note (optional)', 'نوٹ (اختیاری)',
      sd: 'نوٽ (اختياري)',
      pa: 'نوٹ (اختیاری)',
      ps: 'یادښت (اختیاري)',
      bal: 'نوٹ (اختیاری)');
  String get enterName =>
      _t('Please enter your name', 'براہِ کرم اپنا نام لکھیں',
          sd: 'مهرباني ڪري پنهنجو نالو لکو',
          pa: 'مہربانی کرکے اپنا ناں لکھو',
          ps: 'مهرباني وکړئ خپل نوم ولیکئ',
          bal: 'مہربانی کن اِت وتی نام ءَ نبیس اِت');
  String get enterValidPhone => _t(
      'Please enter a valid phone number', 'براہِ کرم درست فون نمبر لکھیں',
      sd: 'مهرباني ڪري صحيح فون نمبر لکو',
      pa: 'مہربانی کرکے درست فون نمبر لکھو',
      ps: 'مهرباني وکړئ سم د تلیفون شمیره ولیکئ',
      bal: 'مہربانی کن اِت درستیں فون نمبر نبیس اِت');
  String get enterCity => _t('Please enter your city or village',
      'براہِ کرم اپنا شہر یا گاؤں لکھیں',
      sd: 'مهرباني ڪري پنهنجو شهر يا ڳوٺ لکو',
      pa: 'مہربانی کرکے اپنا شہر یا پِنڈ لکھو',
      ps: 'مهرباني وکړئ خپل ښار یا کلی ولیکئ',
      bal: 'مہربانی کن اِت وتی شہر یا هلک ءَ نبیس اِت');
  String get yourOrder => _t('Your order', 'آپ کا آرڈر',
      sd: 'اوهان جو آرڊر', pa: 'تہاڈا آرڈر', ps: 'ستاسو آرډر', bal: 'تئی آرڈر');
  String get checkoutInfo => _t(
      'Your order and these details go to Cassia Seed. WhatsApp will open '
          'with your order — press send there, and Cassia Seed will reply '
          'with the price.',
      'آپ کا آرڈر اور یہ تفصیلات کیسیا سیڈ کو جائیں گی۔ واٹس ایپ آپ کے آرڈر '
          'کے ساتھ کھلے گا — وہاں سینڈ دبائیں، کیسیا سیڈ قیمت کے ساتھ جواب '
          'دے گا۔',
      sd: 'اوهان جو آرڊر ۽ هي تفصيلون ڪيسيا سيڊ ڏانهن وينديون. واٽس ايپ '
          'اوهان جي آرڊر سان کلندو — اتي سينڊ دٻايو، ڪيسيا سيڊ قيمت سان جواب '
          'ڏيندو.',
      pa: 'تہاڈا آرڈر تے ایہہ تفصیلاں کیسیا سیڈ نوں جان گیاں۔ واٹس ایپ تہاڈے '
          'آرڈر نال کھلے گا — اوتھے سینڈ دباؤ، کیسیا سیڈ قیمت نال جواب دے گا۔',
      ps: 'ستاسو آرډر او دا جزئیات کیسیا سیډ ته ځي. واټساپ به ستاسو د آرډر '
          'سره پرانیزي — هلته سیند کېکاږئ، کیسیا سیډ به د بیې سره ځواب '
          'درکړي.',
      bal: 'تئی آرڈر ءُ ای تفصیلات کیسیا سیڈ ءَ رئوَنت۔ واٹس ایپ تئی آرڈر ئے '
          'گۆن پچ بیت — اۆدان ءَ سینڈ دبّ اِت، کیسیا سیڈ قیمت ئے گۆن جواب '
          'دنت۔');
  String get sending => _t('Sending…', 'بھیجا جا رہا ہے…',
      sd: 'موڪليو پيو وڃي…',
      pa: 'بھیجیا جا ریا اے…',
      ps: 'لیږل کیږي…',
      bal: 'رئوان بوگ ءَ اِنت…');
  String get sendOrderOnWhatsApp =>
      _t('Send order on WhatsApp', 'واٹس ایپ پر آرڈر بھیجیں',
          sd: 'واٽس ايپ تي آرڊر موڪليو',
          pa: 'واٹس ایپ تے آرڈر بھیجو',
          ps: 'آرډر په واټساپ ولیږئ',
          bal: 'واٹس ایپ ءَ آرڈر رئوان کن اِت');
  String orderNotSent(String phone) => _t(
      'Your order could not be sent. Check your internet connection and try '
          'again, or call $phone.',
      'آپ کا آرڈر نہیں بھیجا جا سکا۔ اپنا انٹرنیٹ چیک کر کے دوبارہ کوشش '
          'کریں، یا ${_ltr(phone)} پر کال کریں۔',
      sd: 'اوهان جو آرڊر نه موڪلجي سگهيو. پنهنجو انٽرنيٽ چيڪ ڪري وري ڪوشش '
          'ڪريو، يا ${_ltr(phone)} تي ڪال ڪريو.',
      pa: 'تہاڈا آرڈر نئیں بھیجیا جا سکیا۔ اپنا انٹرنیٹ چیک کرکے دوبارہ کوشش '
          'کرو، یا ${_ltr(phone)} تے کال کرو۔',
      ps: 'ستاسو آرډر ونه لیږل شو. خپل انټرنیټ وګورئ او بیا هڅه وکړئ، یا '
          '${_ltr(phone)} ته زنګ ووهئ.',
      bal: 'تئی آرڈر رئوان نہ بوت۔ وتی انٹرنیٹ چیک کن اِت ءُ پدا کوشش کنیت، یا '
          '${_ltr(phone)} ءَ کال کن اِت۔');
  String get nothingLeftToOrder =>
      _t('Nothing left to order', 'آرڈر کے لیے کچھ باقی نہیں',
          sd: 'آرڊر لاءِ ڪجهه باقي ناهي',
          pa: 'آرڈر لئی کجھ باقی نئیں',
          ps: 'د آرډر لپاره څه پاتې نشته',
          bal: 'آرڈر ئے واستہ ہچ باقی نیست');
  String get backToCart => _t('Back to cart', 'کارٹ پر واپس',
      sd: 'ڪارٽ ڏانهن واپس',
      pa: 'کارٹ تے واپس',
      ps: 'بیرته کارټ ته',
      bal: 'کارٹ ءَ پچ');

  // ---------------------------------------------------------- order sent

  String get order => _t('Order', 'آرڈر',
      sd: 'آرڊر', pa: 'آرڈر', ps: 'آرډر', bal: 'آرڈر');
  String get pressSendInWhatsApp =>
      _t('Press send in WhatsApp', 'واٹس ایپ میں سینڈ دبائیں',
          sd: 'واٽس ايپ ۾ سينڊ دٻايو',
          pa: 'واٹس ایپ وچ سینڈ دباؤ',
          ps: 'په واټساپ کې سیند کېکاږئ',
          bal: 'واٹس ایپ ءَ سینڈ دبّ اِت');
  String get orderReceived => _t('Order received', 'آرڈر موصول ہو گیا',
      sd: 'آرڊر مليو', pa: 'آرڈر مل گیا', ps: 'آرډر ترلاسه شو', bal: 'آرڈر رسِت');
  String get whatsAppOpenedBody => _t(
      'WhatsApp opened with your order written out. Press send there to '
          'complete it. Cassia Seed will reply with the price and '
          'availability.',
      'واٹس ایپ آپ کے آرڈر کے ساتھ کھل گیا ہے۔ آرڈر مکمل کرنے کے لیے وہاں '
          'سینڈ دبائیں۔ کیسیا سیڈ قیمت اور دستیابی کے ساتھ جواب دے گا۔',
      sd: 'واٽس ايپ اوهان جي آرڊر سان کلي ويو آهي. آرڊر مڪمل ڪرڻ لاءِ اتي '
          'سينڊ دٻايو. ڪيسيا سيڊ قيمت ۽ دستيابي سان جواب ڏيندو.',
      pa: 'واٹس ایپ تہاڈے آرڈر نال کھل گیا اے۔ آرڈر مکمل کرن لئی اوتھے سینڈ '
          'دباؤ۔ کیسیا سیڈ قیمت تے دستیابی نال جواب دے گا۔',
      ps: 'واټساپ ستاسو د آرډر سره پرانیستل شو. د آرډر د بشپړولو لپاره هلته '
          'سیند کېکاږئ. کیسیا سیډ به د بیې او شتون سره ځواب درکړي.',
      bal: 'واٹس ایپ تئی آرڈر ئے گۆن پچ بوتگ۔ آرڈر پورا کنگ ئے واستہ اۆدان ءَ '
          'سینڈ دبّ اِت۔ کیسیا سیڈ قیمت ءُ دستیابی ئے گۆن جواب دنت۔');
  String orderReceivedBody(String customerPhone, String companyPhone) => _t(
      'WhatsApp could not be opened on this phone, but your order reached '
          'Cassia Seed. They will contact you on $customerPhone. You can '
          'also call $companyPhone.',
      'اس فون پر واٹس ایپ نہیں کھل سکا، لیکن آپ کا آرڈر کیسیا سیڈ تک پہنچ '
          'گیا ہے۔ وہ آپ سے ${_ltr(customerPhone)} پر رابطہ کریں گے۔ آپ '
          '${_ltr(companyPhone)} پر کال بھی کر سکتے ہیں۔',
      sd: 'هن فون تي واٽس ايپ نه کُلي سگهيو، پر اوهان جو آرڊر ڪيسيا سيڊ تائين '
          'پهچي ويو آهي. اهي اوهان سان ${_ltr(customerPhone)} تي رابطو ڪندا. '
          'اوهان ${_ltr(companyPhone)} تي ڪال به ڪري سگهو ٿا.',
      pa: 'ایس فون تے واٹس ایپ نئیں کھل سکیا، پر تہاڈا آرڈر کیسیا سیڈ تک پہنچ '
          'گیا اے۔ اوہ تہاڈے نال ${_ltr(customerPhone)} تے رابطہ کرن گے۔ تُسیں '
          '${_ltr(companyPhone)} تے کال وی کر سکدے او۔',
      ps: 'په دې فون کې واټساپ پرانیستل ونشو، خو ستاسو آرډر کیسیا سیډ ته '
          'ورسید. هغوی به له تاسو سره ${_ltr(customerPhone)} اړیکه ونیسي. '
          'تاسو ${_ltr(companyPhone)} ته زنګ هم وهلی شئ.',
      bal: 'اے فون ءَ واٹس ایپ پچ نہ بوت، بله تئی آرڈر کیسیا سیڈ ءَ رسِت۔ آ '
          'تئی گۆن ${_ltr(customerPhone)} ءَ رابطہ کَنت۔ تها '
          '${_ltr(companyPhone)} ءَ کال هم کُت کن اِت۔');
  String orderNo(String ref) =>
      _t('Order no: $ref', 'آرڈر نمبر: ${_ltr(ref)}',
          sd: 'آرڊر نمبر: ${_ltr(ref)}',
          pa: 'آرڈر نمبر: ${_ltr(ref)}',
          ps: 'د آرډر شمیره: ${_ltr(ref)}',
          bal: 'آرڈر نمبر: ${_ltr(ref)}');
  String get openWhatsAppAgain =>
      _t('Open WhatsApp again', 'واٹس ایپ دوبارہ کھولیں',
          sd: 'واٽس ايپ وري کوليو',
          pa: 'واٹس ایپ دوبارہ کھولو',
          ps: 'واټساپ بیا پرانیزئ',
          bal: 'واٹس ایپ پدا پچ کن اِت');
  String get tryWhatsAppAgain =>
      _t('Try WhatsApp again', 'واٹس ایپ دوبارہ آزمائیں',
          sd: 'واٽس ايپ وري آزمايو',
          pa: 'واٹس ایپ دوبارہ اجمائو',
          ps: 'واټساپ بیا وازمایئ',
          bal: 'واٹس ایپ پدا آزمات کن اِت');

  // --------------------------------------------------------- crop doctor

  String get doctorHeader => _t(
      'Your AI plant doctor. Add 2–3 clear photos for the best accuracy.',
      'آپ کا اے آئی پودوں کا ڈاکٹر۔ بہترین نتیجے کے لیے 2–3 صاف تصاویر '
          'شامل کریں۔',
      sd: 'اوهان جو اي آءِ ٻوٽن جو ڊاڪٽر. بهترين نتيجي لاءِ 2–3 صاف تصويرون '
          'شامل ڪريو.',
      pa: 'تہاڈا اے آئی بوٹیاں دا ڈاکٹر۔ چنگے نتیجے لئی 2–3 صاف تصویراں شامل '
          'کرو۔',
      ps: 'ستاسو د اې آی د بوټو ډاکټر. د غوره دقت لپاره 2–3 روښانه عکسونه '
          'ورزیات کړئ.',
      bal: 'تئی اے آئی بُنگانی ڈاکٹر۔ چمّیں نتیجہ ئے واستہ 2–3 صافیں عکس شامل '
          'کن اِت۔');
  String get stepPhotos => _t('Photos', 'تصاویر',
      sd: 'تصويرون', pa: 'تصویراں', ps: 'عکسونه', bal: 'عکس');
  String get stepDetails => _t('Details', 'تفصیل',
      sd: 'تفصيل', pa: 'تفصیل', ps: 'جزئیات', bal: 'تفصیل');
  String get stepDiagnosis => _t('Diagnosis', 'تشخیص',
      sd: 'تشخيص', pa: 'تشخیص', ps: 'تشخیص', bal: 'تشخیص');

  String get whichCrop => _t('Which crop?', 'کون سی فصل؟',
      sd: 'ڪهڙي فصل؟', pa: 'کیہڑی فصل؟', ps: 'کوم فصل؟', bal: 'کُجام فصل؟');

  /// The crops in the "Which crop?" list, as (value, name) pairs. The value
  /// is what is sent for diagnosis: always English, whatever the language.
  List<(String, String)> get doctorCrops => [
        ('Okra', _t('Okra', 'بھنڈی',
            sd: 'ڀينڊي', pa: 'بھنڈی', ps: 'بامیه', bal: 'بھنڈی')),
        ('Tomato', _t('Tomato', 'ٹماٹر',
            sd: 'ٽماٽو', pa: 'ٹماٹر', ps: 'رومي', bal: 'ٹماٹر')),
        ('Hot pepper / Chilli', _t('Hot pepper / Chilli', 'مرچ',
            sd: 'مرچ', pa: 'مرچ', ps: 'مرچ', bal: 'مرچ')),
        ('Bitter gourd', _t('Bitter gourd', 'کریلا',
            sd: 'ڪريلو', pa: 'کریلا', ps: 'کاریلا', bal: 'کریلا')),
        ('Brinjal', _t('Brinjal', 'بینگن',
            sd: 'وانڱڻ', pa: 'بینگن', ps: 'بانجن', bal: 'بینگن')),
        ('Cucumber', _t('Cucumber', 'کھیرا',
            sd: 'ڪَڪڙي', pa: 'کھیرا', ps: 'بادرنګ', bal: 'کھیرا')),
        ('Gourd', _t('Gourd', 'کدو',
            sd: 'ڏودهي', pa: 'کدو', ps: 'کدو', bal: 'کدو')),
        ('Paddy / Rice', _t('Paddy / Rice', 'دھان / چاول',
            sd: 'چانور', pa: 'جھونا / چول', ps: 'وریژې', bal: 'برنج')),
        ('Peas', _t('Peas', 'مٹر',
            sd: 'مٽر', pa: 'مٹر', ps: 'مټر', bal: 'مٹر')),
        ('Carrot', _t('Carrot', 'گاجر',
            sd: 'گاجر', pa: 'گاجر', ps: 'ګازره', bal: 'گاجر')),
        ('Other', _t('Other', 'دیگر',
            sd: 'ٻيو', pa: 'ہور', ps: 'نور', bal: 'دگہ')),
      ];

  /// The one-tap crops above the list, as (emoji, value, short name). Each
  /// value is one of [doctorCrops].
  List<(String, String, String)> get doctorCropChips => [
        ('🍅', 'Tomato', _t('Tomato', 'ٹماٹر',
            sd: 'ٽماٽو', pa: 'ٹماٹر', ps: 'رومي', bal: 'ٹماٹر')),
        ('🌶️', 'Hot pepper / Chilli', _t('Hot pepper', 'مرچ',
            sd: 'مرچ', pa: 'مرچ', ps: 'مرچ', bal: 'مرچ')),
        ('🌿', 'Okra', _t('Okra', 'بھنڈی',
            sd: 'ڀينڊي', pa: 'بھنڈی', ps: 'بامیه', bal: 'بھنڈی')),
        ('🥒', 'Cucumber', _t('Cucumber', 'کھیرا',
            sd: 'ڪَڪڙي', pa: 'کھیرا', ps: 'بادرنګ', bal: 'کھیرا')),
        ('🍆', 'Brinjal', _t('Brinjal', 'بینگن',
            sd: 'وانڱڻ', pa: 'بینگن', ps: 'بانجن', bal: 'بینگن')),
        ('🫛', 'Peas', _t('Peas', 'مٹر',
            sd: 'مٽر', pa: 'مٹر', ps: 'مټر', bal: 'مٹر')),
        ('🥕', 'Carrot', _t('Carrot', 'گاجر',
            sd: 'گاجر', pa: 'گاجر', ps: 'ګازره', bal: 'گاجر')),
        ('🌾', 'Paddy / Rice', _t('Paddy', 'دھان',
            sd: 'چانور', pa: 'جھونا', ps: 'وریژې', bal: 'برنج')),
        ('🥬', 'Gourd', _t('Gourd', 'کدو',
            sd: 'ڏودهي', pa: 'کدو', ps: 'کدو', bal: 'کدو')),
      ];

  String get growthStage => _t('Growth stage?', 'بڑھوتری کا مرحلہ؟',
      sd: 'واڌ جو مرحلو؟',
      pa: 'ودھن دا مرحلہ؟',
      ps: 'د ودې پړاو؟',
      bal: 'بُرز بئگ ئے مرحلہ؟');

  /// The growth stages, as (value, name) pairs; the value is always English.
  List<(String, String)> get growthStages => [
        ('Seedling', _t('Seedling', 'نئے پودے',
            sd: 'نوان ٻوٽا', pa: 'نویں بوٹے', ps: 'نیالګی', bal: 'نوکیں بُنگ')),
        ('Vegetative', _t('Vegetative', 'نشوونما',
            sd: 'واڌ', pa: 'ودھ', ps: 'شینه کیدل', bal: 'نشوونما')),
        ('Flowering', _t('Flowering', 'پھول',
            sd: 'گل', pa: 'پھُل', ps: 'ګل', bal: 'پُل')),
        ('Fruiting', _t('Fruiting', 'پھل',
            sd: 'ميوو', pa: 'پھل', ps: 'مېوه', bal: 'میوگ')),
        ('Harvest', _t('Harvest', 'کٹائی',
            sd: 'لڻائي', pa: 'وڈھائی', ps: 'رېبنه', bal: 'درئگ')),
      ];

  String get sinceHowManyDays => _t(
      'Since how many days? (optional)', 'کتنے دنوں سے؟ (اختیاری)',
      sd: 'ڪيترن ڏينهن کان؟ (اختياري)',
      pa: 'کِنے دناں توں؟ (اختیاری)',
      ps: 'له څو ورځو راهیسې؟ (اختیاري)',
      bal: 'چنڈ روچان ءَ؟ (اختیاری)');
  String get doctorNotesHint => _t(
      'Recent sprays, irrigation, weather… (optional)',
      'حالیہ سپرے، آبپاشی، موسم… (اختیاری)',
      sd: 'تازيون اسپري، آبپاشي، موسم… (اختياري)',
      pa: 'حالیہ سپرے، آبپاشی، موسم… (اختیاری)',
      ps: 'وروستي سپري، اوبه ورکول، هوا… (اختیاري)',
      bal: 'تازگیں سپرے، آبپاشی، ہوا… (اختیاری)');

  /// What each of the three photo slots is for.
  List<String> get photoSlots => [
        _t('Affected leaf', 'متاثرہ پتا',
            sd: 'متاثر پن',
            pa: 'متاثرہ پتا',
            ps: 'اغیزمنه پاڼه',
            bal: 'اثر بوتگیں پان'),
        _t('Underside', 'پتے کا نچلا حصہ',
            sd: 'پن جو هيٺيون حصو',
            pa: 'پتے دا تھلا حصہ',
            ps: 'لاندینۍ خوا',
            bal: 'پان ئے چیریگیں حصہ'),
        _t('Whole plant', 'پورا پودا',
            sd: 'پورو ٻوٽو',
            pa: 'سارا بوٹا',
            ps: 'ټول بوټی',
            bal: 'پوریں بُنگ'),
      ];
  String get removePhoto => _t('Remove photo', 'تصویر ہٹائیں',
      sd: 'تصوير هٽايو',
      pa: 'تصویر ہٹاؤ',
      ps: 'عکس لرې کړئ',
      bal: 'عکس ءَ در کُش اِت');
  String photoLimit(int max) => _t(
      'You can add up to $max photos.', 'آپ زیادہ سے زیادہ $max تصاویر لگا سکتے ہیں۔',
      sd: 'اوهان وڌ ۾ وڌ $max تصويرون لڳائي سگهو ٿا.',
      pa: 'تُسیں ودھ توں ودھ $max تصویراں لا سکدے او۔',
      ps: 'تاسو تر $max پورې عکسونه اضافه کولی شئ.',
      bal: 'تها گیشتریں $max عکس لگّ کُت کن اِت۔');
  String get couldNotAddPhoto => _t(
      'Could not add the photo. Please try again.',
      'تصویر شامل نہیں ہو سکی۔ دوبارہ کوشش کریں۔',
      sd: 'تصوير شامل نه ٿي سگهي. وري ڪوشش ڪريو.',
      pa: 'تصویر شامل نئیں ہو سکی۔ دوبارہ کوشش کرو۔',
      ps: 'عکس اضافه نشو. بیا هڅه وکړئ.',
      bal: 'عکس شامل نہ بوت۔ پدا کوشش کنیت۔');

  String get takePhoto => _t('Take Photo', 'تصویر کھینچیں',
      sd: 'تصوير ڪڍو', pa: 'تصویر کھچو', ps: 'عکس واخلئ', bal: 'عکس ءَ گر اِت');
  String get chooseFromGallery => _t('Choose from Gallery', 'گیلری سے چنیں',
      sd: 'گيلري مان چونڊيو',
      pa: 'گیلری توں چُنو',
      ps: 'له ګالري وټاکئ',
      bal: 'گیلری ءَ چار اِت');
  String get diagnoseMyCrop =>
      _t('Diagnose My Crop', 'میری فصل کی تشخیص کریں',
          sd: 'منهنجي فصل جي تشخيص ڪريو',
          pa: 'میری فصل دی تشخیص کرو',
          ps: 'زما د فصل تشخیص وکړئ',
          bal: 'منی فصل ئے تشخیص کن اِت');
  String get analysing => _t('Analysing…', 'تجزیہ ہو رہا ہے…',
      sd: 'تجزيو ٿي رهيو آهي…',
      pa: 'تجزیہ ہو ریا اے…',
      ps: 'شننه کیږي…',
      bal: 'تجزیہ بوگ ءَ اِنت…');

  // The diagnosis cards, in the order they are shown.
  String get whatISee => _t('What I see', 'جو نظر آ رہا ہے',
      sd: 'جيڪو نظر اچي رهيو آهي',
      pa: 'جو نظر آ ریا اے',
      ps: 'څه چې زه ګورم',
      bal: 'چے پدی بوگ ءَ اِنت');
  String get mostLikelyProblem =>
      _t('Most likely problem', 'سب سے ممکنہ مسئلہ',
          sd: 'سڀ کان ممڪن مسئلو',
          pa: 'سب توں ممکنہ مسئلہ',
          ps: 'ترټولو احتمالي ستونزه',
          bal: 'پُریں ممکنیں مسئلہ');
  String get otherPossibilities => _t('Other possibilities', 'دیگر امکانات',
      sd: 'ٻيا امڪان', pa: 'ہور امکان', ps: 'نور احتمالات', bal: 'دگہ امکانات');
  String get whatIsLacking =>
      _t('What is lacking / the cause', 'کس چیز کی کمی ہے / وجہ',
          sd: 'ڪهڙي شيءِ جي ڪمي آهي / سبب',
          pa: 'کیہڑی شے دی کمی اے / وجہ',
          ps: 'د څه کمی شته / لامل',
          bal: 'کُجام چیز ئے کمی هست / سببّ');
  String get treatmentSteps => _t('Treatment steps', 'علاج کے اقدامات',
      sd: 'علاج جا قدم',
      pa: 'علاج دے قدم',
      ps: 'د علاج ګامونه',
      bal: 'علاج ئے قدم');
  String get preventionNextTime =>
      _t('Prevention for next time', 'آئندہ کے لیے بچاؤ',
          sd: 'ايندڙ ڀيري لاءِ بچاءُ',
          pa: 'اگلی واری لئی بچاؤ',
          ps: 'د راتلونکي ځل لپاره مخنیوی',
          bal: 'بعدی باری ئے واستہ بچاؤ');
  String get forSurerDiagnosis =>
      _t('For a surer diagnosis', 'مزید یقینی تشخیص کے لیے',
          sd: 'وڌيڪ يقيني تشخيص لاءِ',
          pa: 'ودھ یقینی تشخیص لئی',
          ps: 'د ډاډمن تشخیص لپاره',
          bal: 'گیشتر یقینیں تشخیص ئے واستہ');

  /// [percent] is how sure the diagnosis is, 0–100.
  String confidencePercent(int percent) =>
      _t('Confidence: $percent%', 'اعتماد: ${_ltr('$percent%')}',
          sd: 'اعتماد: ${_ltr('$percent%')}',
          pa: 'اعتماد: ${_ltr('$percent%')}',
          ps: 'ډاډ: ${_ltr('$percent%')}',
          bal: 'اعتماد: ${_ltr('$percent%')}');
  String get looksHealthy => _t('Looks healthy', 'صحت مند لگ رہا ہے',
      sd: 'صحتمند لڳي ٿو',
      pa: 'صحت مند لگدا اے',
      ps: 'روغ ښکاري',
      bal: 'جوڑیں پدی بیت');
  String get notSure => _t('Not sure yet', 'ابھی یقینی نہیں',
      sd: 'اڃا يقيني ناهي',
      pa: 'ہلے یقینی نئیں',
      ps: 'لا ډاډه نه یم',
      bal: 'هنوں یقینی نیست');

  String get notACropTitle =>
      _t('That doesn\'t look like a crop', 'یہ فصل کی تصویر نہیں لگتی',
          sd: 'هيءَ فصل جي تصوير نه ٿي لڳي',
          pa: 'ایہہ فصل دی تصویر نئیں لگدی',
          ps: 'دا د فصل عکس نه ښکاري',
          bal: 'ای فصل ئے عکس نہ پدی بیت');
  String get notACropBody => _t(
      'Please take a clear photo of the plant or affected leaf.',
      'براہِ کرم پودے یا متاثرہ پتے کی صاف تصویر لیں۔',
      sd: 'مهرباني ڪري ٻوٽي يا متاثر پن جي صاف تصوير ڪڍو.',
      pa: 'مہربانی کرکے بوٹے یا متاثرہ پتے دی صاف تصویر لَوو۔',
      ps: 'مهرباني وکړئ د بوټي یا اغیزمنې پاڼې روښانه عکس واخلئ.',
      bal: 'مہربانی کن اِت بُنگ یا اثر بوتگیں پان ئے صافیں عکس ءَ گر اِت۔');

  String get copy => _t('Copy', 'کاپی',
      sd: 'ڪاپي', pa: 'کاپی', ps: 'کاپي', bal: 'کاپی');
  String get diagnosisCopied => _t('Diagnosis copied', 'تشخیص کاپی ہو گئی',
      sd: 'تشخيص ڪاپي ٿي وئي',
      pa: 'تشخیص کاپی ہو گئی',
      ps: 'تشخیص کاپي شو',
      bal: 'تشخیص کاپی بوت');
  String get askFollowUp => _t('Ask follow-up', 'مزید پوچھیں',
      sd: 'وڌيڪ پڇو', pa: 'ہور پُچھو', ps: 'نور وپوښتئ', bal: 'گیشتر پُرس اِت');

  /// How the follow-up chat opens: the diagnosis, and Cassia's reply to it.
  String followUpIntro(String diagnosis) => _t(
      'My crop diagnosis from Crop Doctor:\n$diagnosis',
      'کراپ ڈاکٹر سے میری فصل کی تشخیص:\n$diagnosis',
      sd: 'ڪراپ ڊاڪٽر کان منهنجي فصل جي تشخيص:\n$diagnosis',
      pa: 'کراپ ڈاکٹر توں میری فصل دی تشخیص:\n$diagnosis',
      ps: 'د فصل ډاکټر څخه زما د فصل تشخیص:\n$diagnosis',
      bal: 'کراپ ڈاکٹر ءَ منی فصل ئے تشخیص:\n$diagnosis');
  String get followUpReply => _t(
      'Understood. What would you like to know?',
      'سمجھ گیا۔ آپ کیا جاننا چاہتے ہیں؟',
      sd: 'سمجهي ويس. اوهان ڇا ڄاڻڻ چاهيو ٿا؟',
      pa: 'سمجھ گیا۔ تُسیں کیہہ جاننا چاہندے او؟',
      ps: 'پوه شوم. تاسو څه غواړئ پوه شئ؟',
      bal: 'سرپد بوتوں۔ تها چے زانگ لوٹ اِت؟');

  String get recentScans => _t('Recent scans', 'حالیہ اسکین',
      sd: 'تازا اسڪين', pa: 'حالیہ اسکین', ps: 'وروستي سکینونه', bal: 'تازگیں اسکین');
  String get cropFallback => _t('Crop', 'فصل',
      sd: 'فصل', pa: 'فصل', ps: 'فصل', bal: 'فصل');

  String get doctorNote => _t(
      'AI advice is a guide, not a lab test. Before spraying any chemical, '
          'confirm with a local agriculture expert or dealer.',
      'اے آئی کا مشورہ صرف رہنمائی ہے، لیبارٹری ٹیسٹ نہیں۔ کوئی بھی دوا '
          'سپرے کرنے سے پہلے مقامی زرعی ماہر یا ڈیلر سے تصدیق کریں۔',
      sd: 'اي آءِ جو مشورو رڳو رهنمائي آهي، ليبارٽري ٽيسٽ ناهي. ڪابه دوا اسپري '
          'ڪرڻ کان اڳ مقامي زرعي ماهر يا ڊيلر سان تصديق ڪريو.',
      pa: 'اے آئی دا مشورہ صرف رہنمائی اے، لیبارٹری ٹیسٹ نئیں۔ کوئی وی دوا '
          'سپرے کرن توں پہلاں مقامی زرعی ماہر یا ڈیلر نال تصدیق کرو۔',
      ps: 'د اې آی مشوره یوازې لارښوونه ده، د لابراتوار ازموینه نه ده. د هر '
          'درمل له شیندلو مخکې له محلي کرنیز ماهر یا ډیلر سره تایید وکړئ.',
      bal: 'اے آئی ئے مشورہ تها رہنمائی اِنت، لیبارٹری ٹیسٹ نہ اِنت۔ ہر دوا ئے '
          'سپرے کنگ ئے پیسر مقامی زرعی ماہر یا ڈیلر ءَ تصدیق کن اِت۔');

  String get cropDoctorNotSetUp =>
      _t('Crop Doctor not set up yet', 'کراپ ڈاکٹر ابھی شروع نہیں ہوا',
          sd: 'ڪراپ ڊاڪٽر اڃا شروع نه ٿيو',
          pa: 'کراپ ڈاکٹر ہلے شروع نئیں ہویا',
          ps: 'د فصل ډاکټر لا پیل شوی نه دی',
          bal: 'کراپ ڈاکٹر هنوں شروع نہ بوتگ');
  String get diagnosisFailed => _t('Diagnosis failed', 'تشخیص نہیں ہو سکی',
      sd: 'تشخيص نه ٿي سگهي',
      pa: 'تشخیص نئیں ہو سکی',
      ps: 'تشخیص پاتې راغی',
      bal: 'تشخیص نہ بوت');

  // ---------------------------------------------------------- ask cassia

  String get newChat => _t('New chat', 'نئی گفتگو',
      sd: 'نئين ڳالهه ٻولهه',
      pa: 'نویں گل بات',
      ps: 'نوې خبرې اترې',
      bal: 'نوکیں گپ');
  String askingAbout(String name) =>
      _t('Asking about $name', '${data(name)} کے بارے میں سوال',
          sd: '${data(name)} بابت سوال',
          pa: '${data(name)} بارے سوال',
          ps: 'د ${data(name)} په اړه پوښتنه',
          bal: '${data(name)} ئے بارہ ءَ سوال');

  /// The name Cassia's messages are signed with.
  String get cassiaName => _t('Cassia', 'کیسیا',
      sd: 'ڪيسيا', pa: 'کیسیا', ps: 'کیسیا', bal: 'کیسیا');

  /// Cassia's greeting, shown as the first message of every chat.
  String get cassiaWelcome => _t(
      'Assalam o Alaikum! I am Cassia \u{1F331} Ask me anything about your '
          'crop.',
      'السلام علیکم! میں کیسیا ہوں \u{1F331} اپنی فصل کے بارے میں کچھ بھی '
          'پوچھیں۔',
      sd: 'السلام عليڪم! مان ڪيسيا آهيان \u{1F331} پنهنجي فصل بابت ڪجهه به '
          'پڇو.',
      pa: 'السلام علیکم! میں کیسیا آں \u{1F331} اپنی فصل بارے کجھ وی پُچھو۔',
      ps: 'السلام علیکم! زه کیسیا یم \u{1F331} د خپل فصل په اړه هر څه وپوښتئ.',
      bal: 'السلام علیکم! من کیسیا اُوں \u{1F331} وتی فصل ئے بارہ ءَ ہرچی '
          'پُرس اِت۔');
  String cassiaWelcomeAbout(String name) => _t(
      'Assalam o Alaikum! I am Cassia \u{1F331} Ask me anything about $name.',
      'السلام علیکم! میں کیسیا ہوں \u{1F331} ${data(name)} کے بارے میں کچھ '
          'بھی پوچھیں۔',
      sd: 'السلام عليڪم! مان ڪيسيا آهيان \u{1F331} ${data(name)} بابت ڪجهه '
          'به پڇو.',
      pa: 'السلام علیکم! میں کیسیا آں \u{1F331} ${data(name)} بارے کجھ وی '
          'پُچھو۔',
      ps: 'السلام علیکم! زه کیسیا یم \u{1F331} د ${data(name)} په اړه هر څه '
          'وپوښتئ.',
      bal: 'السلام علیکم! من کیسیا اُوں \u{1F331} ${data(name)} ئے بارہ ءَ '
          'ہرچی پُرس اِت۔');

  String get askVarietyIntro => _t(
      'Get growing tips, spacing, season and care advice for this variety.',
      'اس قسم کی کاشت، فاصلے، موسم اور دیکھ بھال کے بارے میں مشورہ لیں۔',
      sd: 'هن قسم جي پوک، فاصلي، موسم ۽ سنڀال بابت صلاح وٺو.',
      pa: 'ایس قسم دی کاشت، فاصلے، موسم تے سنبھال بارے مشورہ لَوو۔',
      ps: 'د دې ډول د کرلو، فاصلې، موسم او ساتنې په اړه مشوره واخلئ.',
      bal: 'اے قسم ئے کشت، فاصلہ، موسم ءُ سنبالی ئے بارہ ءَ مشورہ گر اِت۔');
  String get askGeneralIntro => _t(
      'Ask about sowing time, spacing, fertiliser, irrigation, pests, or our '
          'seeds.',
      'بوائی کے وقت، فاصلے، کھاد، آبپاشی، کیڑوں یا ہمارے بیجوں کے بارے میں '
          'پوچھیں۔',
      sd: 'پوکڻ جي وقت، فاصلي، ڀاڻ، آبپاشي، ڪيڙن يا اسان جي ٻجن بابت پڇو.',
      pa: 'بوائی دے ویلے، فاصلے، کھاد، آبپاشی، کیڑیاں یا ساڈے بیجاں بارے پُچھو۔',
      ps: 'د کرلو وخت، فاصلې، سرې، اوبو، چینجیو یا زموږ د تخمونو په اړه وپوښتئ.',
      bal: 'کشت ئے وخت، فاصلہ، سرین، آبپاشی، کِرمان یا مئی تُخمان ئے بارہ ءَ '
          'پُرس اِت۔');

  /// Ready-made questions for a chat opened from a product page.
  List<AskSuggestion> get varietySuggestions => [
        (
          label: _t('Sowing time', 'کاشت کا وقت',
              sd: 'پوک جو وقت',
              pa: 'کاشت دا ویلہ',
              ps: 'د کرلو وخت',
              bal: 'کشت ئے وخت'),
          question:
              _t('When is the best sowing time?', 'کاشت کا بہترین وقت کیا ہے؟',
                  sd: 'پوک جو بهترين وقت ڪهڙو آهي؟',
                  pa: 'کاشت دا چنگا ویلہ کیہڑا اے؟',
                  ps: 'د کرلو غوره وخت کوم دی؟',
                  bal: 'کشت ئے چمّیں وخت کُجام اِنت؟'),
        ),
        (
          label: _t('Spacing & seed rate', 'فاصلہ اور بیج کی مقدار',
              sd: 'فاصلو ۽ ٻج جي مقدار',
              pa: 'فاصلہ تے بیج دی مقدار',
              ps: 'فاصله او د تخم اندازه',
              bal: 'فاصلہ ءُ تُخم ئے مقدار'),
          question: _t('What spacing and seed rate should I use?',
              'پودوں کا فاصلہ اور بیج کی مقدار کتنی رکھیں؟',
              sd: 'ٻوٽن جو فاصلو ۽ ٻج جي مقدار ڪيتري رکان؟',
              pa: 'بوٹیاں دا فاصلہ تے بیج دی مقدار کِنی رکھاں؟',
              ps: 'د بوټو فاصله او د تخم اندازه څومره وي؟',
              bal: 'بُنگانی فاصلہ ءُ تُخم ئے مقدار چنڈ بہ ایر کنان؟'),
        ),
        (
          label: _t('Water & fertiliser', 'پانی اور کھاد',
              sd: 'پاڻي ۽ ڀاڻ',
              pa: 'پانی تے کھاد',
              ps: 'اوبه او سره',
              bal: 'آپ ءُ سرین'),
          question: _t('How much water and fertiliser does it need?',
              'اسے کتنا پانی اور کھاد چاہیے؟',
              sd: 'ان کي ڪيترو پاڻي ۽ ڀاڻ گهرجي؟',
              pa: 'ایہنوں کِنا پانی تے کھاد چاہیدا اے؟',
              ps: 'دې ته څومره اوبه او سره پکار دي؟',
              bal: 'آ ءَ چنڈ آپ ءُ سرین لوٹیت؟'),
        ),
        (
          label: _t('Diseases', 'بیماریاں',
              sd: 'بيماريون', pa: 'بیماریاں', ps: 'ناروغۍ', bal: 'بیماریان'),
          question: _t('Which diseases should I watch for?',
              'کن بیماریوں کا خیال رکھنا چاہیے؟',
              sd: 'ڪهڙين بيمارين جو خيال رکڻ گهرجي؟',
              pa: 'کیہڑیاں بیماریاں دا خیال رکھنا چاہیدا اے؟',
              ps: 'د کومو ناروغیو خیال باید وساتم؟',
              bal: 'کُجام بیماریان ئے خیال دارگ لوٹیت؟'),
        ),
      ];

  /// Ready-made questions for a chat opened from the tab.
  List<AskSuggestion> get generalSuggestions => [
        (
          label: _t('Okra sowing time', 'بھنڈی کی بوائی کا وقت',
              sd: 'ڀينڊيءَ جي پوک جو وقت',
              pa: 'بھنڈی دی بوائی دا ویلہ',
              ps: 'د بامیې د کرلو وخت',
              bal: 'بھنڈی ئے کشت ئے وخت'),
          question: _t('Best sowing time for okra in Sindh?',
              'سندھ میں بھنڈی کی بوائی کا بہترین وقت کیا ہے؟',
              sd: 'سنڌ ۾ ڀينڊيءَ جي پوک جو بهترين وقت ڪهڙو آهي؟',
              pa: 'سندھ وچ بھنڈی دی بوائی دا چنگا ویلہ کیہڑا اے؟',
              ps: 'په سند کې د بامیې د کرلو غوره وخت کوم دی؟',
              bal: 'سندھ ءَ بھنڈی ئے کشت ئے چمّیں وخت کُجام اِنت؟'),
        ),
        (
          label: _t('Tomato cracking', 'ٹماٹر کا پھٹنا',
              sd: 'ٽماٽي جو ڦاٽڻ',
              pa: 'ٹماٹر دا پھٹنا',
              ps: 'د رومي چاودل',
              bal: 'ٹماٹر ئے پِرّگ'),
          question: _t('Tomato fruit cracking, what to do?',
              'ٹماٹر کا پھل پھٹ رہا ہے، کیا کروں؟',
              sd: 'ٽماٽي جو ميوو ڦاٽي رهيو آهي، ڇا ڪريان؟',
              pa: 'ٹماٹر دا پھل پھٹ ریا اے، کیہہ کراں؟',
              ps: 'د رومي مېوه چوي، څه وکړم؟',
              bal: 'ٹماٹر ئے میوگ پِرّگ ءَ اِنت، چے کنان؟'),
        ),
        (
          label: _t('Chilli leaf curl', 'مرچ کا پتا مروڑ',
              sd: 'مرچ جو پن مروڙ',
              pa: 'مرچ دا پتا مروڑ',
              ps: 'د مرچو د پاڼو تاوېدل',
              bal: 'مرچ ئے پان ئے تاب'),
          question: _t('Leaf curl in chilli, how to control?',
              'مرچ میں پتا مروڑ، کیسے قابو کریں؟',
              sd: 'مرچ ۾ پن مروڙ، ڪيئن قابو ڪريان؟',
              pa: 'مرچ وچ پتا مروڑ، کیویں قابو کراں؟',
              ps: 'په مرچو کې د پاڼو تاوېدل، څنګه یې کنټرول کړم؟',
              bal: 'مرچ ءَ پان ئے تاب، چۆن قابو کنان؟'),
        ),
      ];

  String get aiDisclaimer => _t(
      'AI answers can be wrong. Confirm with a local agriculture expert '
          'before applying anything.',
      'اے آئی کے جوابات غلط ہو سکتے ہیں۔ کچھ بھی استعمال کرنے سے پہلے '
          'مقامی ماہرِ زراعت سے تصدیق کریں۔',
      sd: 'اي آءِ جا جواب غلط ٿي سگهن ٿا. ڪجهه به استعمال ڪرڻ کان اڳ مقامي '
          'زرعي ماهر سان تصديق ڪريو.',
      pa: 'اے آئی دے جواب غلط ہو سکدے نیں۔ کجھ وی استعمال کرن توں پہلاں مقامی '
          'زرعی ماہر نال تصدیق کرو۔',
      ps: 'د اې آی ځوابونه کیدای شي غلط وي. له هر څه کارولو مخکې له محلي '
          'کرنیز ماهر سره تایید وکړئ.',
      bal: 'اے آئی ئے جواب غلط بہ بَنت۔ ہرچی استعمال کنگ ئے پیسر مقامی زرعی '
          'ماہر ءَ تصدیق کن اِت۔');
  String get thinking => _t('Thinking…', 'سوچ رہا ہے…',
      sd: 'سوچي رهيو آهي…',
      pa: 'سوچ ریا اے…',
      ps: 'فکر کوي…',
      bal: 'سوچ ءَ اِنت…');
  String get askCassiaNotSetUp =>
      _t('Ask Cassia not set up yet', 'کیسیا اے آئی ابھی شروع نہیں ہوا',
          sd: 'ڪيسيا اي آءِ اڃا شروع نه ٿيو',
          pa: 'کیسیا اے آئی ہلے شروع نئیں ہویا',
          ps: 'کیسیا اې آی لا پیل شوی نه دی',
          bal: 'کیسیا اے آئی هنوں شروع نہ بوتگ');
  String get couldNotGetAnswer =>
      _t('Could not get an answer', 'جواب نہیں مل سکا',
          sd: 'جواب نه ملي سگهيو',
          pa: 'جواب نئیں مل سکیا',
          ps: 'ځواب ترلاسه نشو',
          bal: 'جواب نہ کپت');
  String get typeYourQuestion =>
      _t('Type your question…', 'اپنا سوال لکھیں…',
          sd: 'پنهنجو سوال لکو…',
          pa: 'اپنا سوال لکھو…',
          ps: 'خپله پوښتنه ولیکئ…',
          bal: 'وتی سوال نبیس اِت…');
  String get send => _t('Send', 'بھیجیں',
      sd: 'موڪليو', pa: 'بھیجو', ps: 'ولیږئ', bal: 'رئوان کن اِت');

  // ---------------------------------------------------------------- more

  String get more => _t('More', 'مزید',
      sd: 'وڌيڪ', pa: 'ہور', ps: 'نور', bal: 'گیشتر');
  String get settings => _t('Settings', 'ترتیبات',
      sd: 'ترتيبون', pa: 'ترتیباں', ps: 'امستنې', bal: 'ترتیبات');
  String get language => _t('Language', 'زبان',
      sd: 'ٻولي', pa: 'زبان', ps: 'ژبه', bal: 'زبان');
  String get appearance => _t('Appearance', 'ظاہری شکل',
      sd: 'ظاهري شڪل', pa: 'ظاہری شکل', ps: 'بڼه', bal: 'ظاہری شکل');
  String get themeSystem => _t('Auto', 'خودکار',
      sd: 'خودڪار', pa: 'خودکار', ps: 'اتومات', bal: 'خودکار');
  String get themeLight => _t('Light', 'روشن',
      sd: 'روشن', pa: 'روشن', ps: 'روښانه', bal: 'روشن');
  String get themeDark => _t('Dark', 'تاریک',
      sd: 'اونداهو', pa: 'ہنیرا', ps: 'تیاره', bal: 'تهار');
  String get contact => _t('Contact', 'رابطہ',
      sd: 'رابطو', pa: 'رابطہ', ps: 'اړیکه', bal: 'رابطہ');
  String get whatsApp => _t('WhatsApp', 'واٹس ایپ',
      sd: 'واٽس ايپ', pa: 'واٹس ایپ', ps: 'واټساپ', bal: 'واٹس ایپ');
  String get call => _t('Call', 'کال',
      sd: 'ڪال', pa: 'کال', ps: 'زنګ', bal: 'کال');
  String get landline => _t('Landline', 'لینڈ لائن',
      sd: 'لينڊ لائن', pa: 'لینڈ لائن', ps: 'لینډلاین', bal: 'لینڈ لائن');
  String get email => _t('Email', 'ای میل',
      sd: 'اي ميل', pa: 'ای میل', ps: 'ایمیل', bal: 'ای میل');
  String get online => _t('Online', 'آن لائن',
      sd: 'آن لائن', pa: 'آن لائن', ps: 'آنلاین', bal: 'آن لائن');
  String get website => _t('Website', 'ویب سائٹ',
      sd: 'ويب سائيٽ', pa: 'ویب سائٹ', ps: 'ویبپاڼه', bal: 'ویب سائٹ');
  String get facebook => _t('Facebook', 'فیس بک',
      sd: 'فيس بُڪ', pa: 'فیس بک', ps: 'فیسبوک', bal: 'فیس بک');
  String get instagram => _t('Instagram', 'انسٹاگرام',
      sd: 'انسٽاگرام', pa: 'انسٹاگرام', ps: 'انستاګرام', bal: 'انسٹاگرام');
  String get followUs => _t('Follow us', 'ہمیں فالو کریں',
      sd: 'اسان کي فالو ڪريو',
      pa: 'سانوں فالو کرو',
      ps: 'موږ تعقیب کړئ',
      bal: 'ما ءَ فالو کن اِت');
  String get address => _t('Address', 'پتہ',
      sd: 'پتو', pa: 'پتہ', ps: 'پته', bal: 'پتہ');

  // -------------------------------------------- accounts (dealer + farmer)

  // The two cards at the top of Home.
  String get forDealers => _t('FOR DEALERS', 'ڈیلرز کے لیے',
      sd: 'ڊيلرن لاءِ',
      pa: 'ڈیلراں لئی',
      ps: 'د ډیلرانو لپاره',
      bal: 'ڈیلران ئے واستہ');
  String get forFarmers => _t('FOR FARMERS', 'کسانوں کے لیے',
      sd: 'هارين لاءِ',
      pa: 'کساناں لئی',
      ps: 'د بزګرانو لپاره',
      bal: 'کسانان ئے واستہ');
  String get dealership => _t('Dealership', 'ڈیلرشپ',
      sd: 'ڊيلرشپ', pa: 'ڈیلرشپ', ps: 'ډیلرشپ', bal: 'ڈیلرشپ');
  String get dealershipSub =>
      _t('Ledger · Balance · Awards', 'کھاتہ · بقایا · ایوارڈز',
          sd: 'کھاتو · بقايا · ايوارڊز',
          pa: 'کھاتہ · بقایا · ایوارڈز',
          ps: 'دفتر · پاتوی · جایزې',
          bal: 'کھاتہ · بقایا · ایوارڈز');
  String get farmerLogin => _t('Farmer Login', 'کسان لاگ اِن',
      sd: 'هاري لاگ اِن',
      pa: 'کسان لاگ اِن',
      ps: 'د بزګر ننوتل',
      bal: 'کسان لاگ اِن');
  String get farmerLoginSub =>
      _t('Sign in or create account', 'لاگ اِن کریں یا نیا اکاؤنٹ بنائیں',
          sd: 'لاگ اِن ڪريو يا نئون اڪائونٽ ٺاهيو',
          pa: 'لاگ اِن کرو یا نواں اکاؤنٹ بناؤ',
          ps: 'ننوځئ یا نوی حساب جوړ کړئ',
          bal: 'لاگ اِن کن اِت یا نوکیں اکاؤنٹ جوڑ کن اِت');
  String get myFarmerAccount => _t('My Farmer Account', 'میرا کسان اکاؤنٹ',
      sd: 'منهنجو هاري اڪائونٽ',
      pa: 'میرا کسان اکاؤنٹ',
      ps: 'زما د بزګر حساب',
      bal: 'منی کسان اکاؤنٹ');
  String get viewDashboard => _t('View your dashboard', 'اپنا ڈیش بورڈ دیکھیں',
      sd: 'پنهنجو ڊيش بورڊ ڏسو',
      pa: 'اپنا ڈیش بورڈ ویکھو',
      ps: 'خپل ډشبورډ وګورئ',
      bal: 'وتی ڈیش بورڈ ءَ گند اِت');

  // Dealer portal.
  String get dealerPortal => _t('DEALER PORTAL', 'ڈیلر پورٹل',
      sd: 'ڊيلر پورٽل', pa: 'ڈیلر پورٹل', ps: 'د ډیلر پورټل', bal: 'ڈیلر پورٹل');
  String get cassiaDealership => _t('Cassia Dealership', 'کیسیا ڈیلرشپ',
      sd: 'ڪيسيا ڊيلرشپ',
      pa: 'کیسیا ڈیلرشپ',
      ps: 'کیسیا ډیلرشپ',
      bal: 'کیسیا ڈیلرشپ');
  String get dealershipTagline => _t(
      'Your account, ledger and rewards in one place.',
      'آپ کا اکاؤنٹ، کھاتہ اور انعامات ایک ہی جگہ۔',
      sd: 'اوهان جو اڪائونٽ، کھاتو ۽ انعام هڪ ئي جاءِ تي.',
      pa: 'تہاڈا اکاؤنٹ، کھاتہ تے انعام اِکو تھاں تے۔',
      ps: 'ستاسو حساب، دفتر او انعامونه په یوه ځای کې.',
      bal: 'تئی اکاؤنٹ، کھاتہ ءُ انعام یک جاہ ءَ۔');
  String get signInLabel => _t('Sign in', 'لاگ اِن',
      sd: 'لاگ اِن', pa: 'لاگ اِن', ps: 'ننوتل', bal: 'لاگ اِن');
  String get applyAsDealer =>
      _t('Apply as dealer', 'ڈیلر کے لیے درخواست دیں',
          sd: 'ڊيلر لاءِ درخواست ڏيو',
          pa: 'ڈیلر لئی درخواست دیو',
          ps: 'د ډیلر لپاره غوښتنلیک ورکړئ',
          bal: 'ڈیلر ئے واستہ درخواست دیہ اِت');
  String get welcomeBack => _t('Welcome back', 'خوش آمدید',
      sd: 'ڀليڪار', pa: 'جی آیاں نوں', ps: 'بیا هرکلی', bal: 'وش آتکہ');
  String get signInDealerAccount => _t(
      'Sign in to your dealer account.',
      'اپنے ڈیلر اکاؤنٹ میں لاگ اِن کریں۔',
      sd: 'پنهنجي ڊيلر اڪائونٽ ۾ لاگ اِن ڪريو.',
      pa: 'اپنے ڈیلر اکاؤنٹ وچ لاگ اِن کرو۔',
      ps: 'خپل د ډیلر حساب ته ننوځئ.',
      bal: 'وتی ڈیلر اکاؤنٹ ءَ لاگ اِن کن اِت۔');
  String get mobileNumber => _t('Mobile number', 'موبائل نمبر',
      sd: 'موبائل نمبر',
      pa: 'موبائل نمبر',
      ps: 'د موبایل شمیره',
      bal: 'موبائل نمبر');
  String get mobileHint => _ltr('03XX XXXXXXX');
  String get password => _t('Password', 'پاس ورڈ',
      sd: 'پاسورڊ', pa: 'پاس ورڈ', ps: 'پټنوم', bal: 'پاس ورڈ');
  String get yourPassword => _t('Your password', 'آپ کا پاس ورڈ',
      sd: 'اوهان جو پاسورڊ',
      pa: 'تہاڈا پاس ورڈ',
      ps: 'ستاسو پټنوم',
      bal: 'تئی پاس ورڈ');
  String get notDealerYet => _t('Not a dealer yet?', 'ابھی ڈیلر نہیں ہیں؟',
      sd: 'اڃا ڊيلر ناهيو؟',
      pa: 'ہلے ڈیلر نئیں او؟',
      ps: 'لا ډیلر نه یاست؟',
      bal: 'هنوں ڈیلر نہ اِت؟');
  String get applyNow => _t('Apply now', 'ابھی درخواست دیں',
      sd: 'هاڻي درخواست ڏيو',
      pa: 'ہُنے درخواست دیو',
      ps: 'اوس غوښتنلیک ورکړئ',
      bal: 'هنوں درخواست دیہ اِت');
  String get secureAccessDealers => _t(
      'Secure access for Cassia Seed authorized dealers',
      'کیسیا سیڈ کے مجاز ڈیلرز کے لیے محفوظ رسائی',
      sd: 'ڪيسيا سيڊ جي مجاز ڊيلرن لاءِ محفوظ رسائي',
      pa: 'کیسیا سیڈ دے مجاز ڈیلراں لئی محفوظ رسائی',
      ps: 'د کیسیا سیډ د مجازو ډیلرانو لپاره خوندي لاسرسی',
      bal: 'کیسیا سیڈ ئے مجازیں ڈیلران ئے واستہ محفوظیں رسائی');
  String get backToFarmerApp =>
      _t('Back to farmer app', 'کسان ایپ پر واپس',
          sd: 'هاري ايپ ڏانهن واپس',
          pa: 'کسان ایپ تے واپس',
          ps: 'بیرته د بزګر اپلیکیشن ته',
          bal: 'کسان ایپ ءَ پچ');
  String get createYourAccount =>
      _t('Create your account', 'اپنا اکاؤنٹ بنائیں',
          sd: 'پنهنجو اڪائونٽ ٺاهيو',
          pa: 'اپنا اکاؤنٹ بناؤ',
          ps: 'خپل حساب جوړ کړئ',
          bal: 'وتی اکاؤنٹ جوڑ کن اِت');
  String get dealerStep1 => _t('Step 1 of 2 · Your sign-in details',
      'مرحلہ 1 از 2 · لاگ اِن کی تفصیل',
      sd: 'مرحلو 1 از 2 · لاگ اِن جي تفصيل',
      pa: 'مرحلہ 1 از 2 · لاگ اِن دی تفصیل',
      ps: 'پړاو 1 له 2 · د ننوتلو جزئیات',
      bal: 'مرحلہ 1 از 2 · لاگ اِن ئے تفصیل');
  String get dealerStep2 => _t('Step 2 of 2 · Tell us about your shop',
      'مرحلہ 2 از 2 · اپنی دکان کے بارے میں بتائیں',
      sd: 'مرحلو 2 از 2 · پنهنجي دُڪان بابت ٻڌايو',
      pa: 'مرحلہ 2 از 2 · اپنی دکان بارے دسو',
      ps: 'پړاو 2 له 2 · د خپل دکان په اړه راته ووایئ',
      bal: 'مرحلہ 2 از 2 · وتی دکان ئے بارہ ءَ بہ گوش اِت');
  String get ownerName => _t('Owner name', 'مالک کا نام',
      sd: 'مالڪ جو نالو', pa: 'مالک دا ناں', ps: 'د مالک نوم', bal: 'مالک ئے نام');
  String get fullName => _t('Full name', 'پورا نام',
      sd: 'پورو نالو', pa: 'پورا ناں', ps: 'بشپړ نوم', bal: 'پوریں نام');
  String get atLeast8 => _t('At least 8 characters', 'کم از کم 8 حروف',
      sd: 'گهٽ ۾ گهٽ 8 اکر',
      pa: 'گھٹ توں گھٹ 8 حرف',
      ps: 'لږ تر لږه 8 توري',
      bal: 'کم از کم 8 حرف');
  String get confirmPassword =>
      _t('Confirm password', 'پاس ورڈ دوبارہ لکھیں',
          sd: 'پاسورڊ وري لکو',
          pa: 'پاس ورڈ دوبارہ لکھو',
          ps: 'پټنوم بیا ولیکئ',
          bal: 'پاس ورڈ پدا نبیس اِت');
  String get repeatPassword => _t('Repeat password', 'پاس ورڈ دہرائیں',
      sd: 'پاسورڊ ورجايو',
      pa: 'پاس ورڈ دہراؤ',
      ps: 'پټنوم تکرار کړئ',
      bal: 'پاس ورڈ پدا گوش اِت');
  String get alreadyDealer => _t('Already a dealer?', 'پہلے سے ڈیلر ہیں؟',
      sd: 'اڳ ۾ ئي ڊيلر آهيو؟',
      pa: 'پہلاں توں ڈیلر او؟',
      ps: 'دمخه ډیلر یاست؟',
      bal: 'پیسر ءَ ڈیلر اِت؟');
  String get businessName =>
      _t('Business / shop name', 'کاروبار / دکان کا نام',
          sd: 'ڪاروبار / دُڪان جو نالو',
          pa: 'کاروبار / دکان دا ناں',
          ps: 'د سوداګرۍ / دکان نوم',
          bal: 'کاروبار / دکان ئے نام');
  String get city => _t('City', 'شہر',
      sd: 'شهر', pa: 'شہر', ps: 'ښار', bal: 'شہر');
  String get districtLabel => _t('District', 'ضلع',
      sd: 'ضلعو', pa: 'ضلع', ps: 'ولسوالي', bal: 'ضلع');
  String get shopAddress => _t('Shop address', 'دکان کا پتہ',
      sd: 'دُڪان جو پتو',
      pa: 'دکان دا پتہ',
      ps: 'د دکان پته',
      bal: 'دکان ئے پتہ');
  String get productsYouSell =>
      _t('Products you sell', 'آپ کیا فروخت کرتے ہیں',
          sd: 'اوهان ڇا وڪرو ڪريو ٿا',
          pa: 'تُسیں کیہہ ویچدے او',
          ps: 'تاسو څه خرڅوئ',
          bal: 'تها چے پروش کن اِت');
  String get notesOptional => _t('Notes (optional)', 'نوٹس (اختیاری)',
      sd: 'نوٽس (اختياري)',
      pa: 'نوٹس (اختیاری)',
      ps: 'یادښتونه (اختیاري)',
      bal: 'نوٹس (اختیاری)');
  String get submitApplication =>
      _t('Submit application', 'درخواست جمع کرائیں',
          sd: 'درخواست جمع ڪرايو',
          pa: 'درخواست جمع کراؤ',
          ps: 'غوښتنلیک وسپارئ',
          bal: 'درخواست جمع کن اِت');

  // Dealer dashboard.
  String get dealerDashboard => _t('Dealer dashboard', 'ڈیلر ڈیش بورڈ',
      sd: 'ڊيلر ڊيش بورڊ',
      pa: 'ڈیلر ڈیش بورڈ',
      ps: 'د ډیلر ډشبورډ',
      bal: 'ڈیلر ڈیش بورڈ');
  String get applicationReceivedTitle =>
      _t('Application received', 'درخواست موصول ہو گئی',
          sd: 'درخواست ملي',
          pa: 'درخواست مل گئی',
          ps: 'غوښتنلیک ترلاسه شو',
          bal: 'درخواست رسِت');
  String get applicationReceivedBody => _t(
      'Thank you. Our team will review your application and contact you on WhatsApp.',
      'شکریہ۔ ہماری ٹیم آپ کی درخواست کا جائزہ لے کر آپ سے واٹس ایپ پر رابطہ کرے گی۔',
      sd: 'مهرباني. اسان جي ٽيم اوهان جي درخواست جو جائزو وٺي اوهان سان واٽس '
          'ايپ تي رابطو ڪندي.',
      pa: 'شکریہ۔ ساڈی ٹیم تہاڈی درخواست دا جائزہ لے کے تہاڈے نال واٹس ایپ تے '
          'رابطہ کرے گی۔',
      ps: 'مننه. زموږ ټیم به ستاسو غوښتنلیک وڅیړي او په واټساپ به درسره اړیکه '
          'ونیسي.',
      bal: 'منتوار۔ مئی ٹیم تئی درخواست ئے جائزہ گپت ءُ تئی گۆن واٹس ایپ ءَ '
          'رابطہ کنت۔');
  String get applicationPending =>
      _t('Your application is under review.', 'آپ کی درخواست زیرِ جائزہ ہے۔',
          sd: 'اوهان جي درخواست جائزي هيٺ آهي.',
          pa: 'تہاڈی درخواست جائزے ہیٹھ اے۔',
          ps: 'ستاسو غوښتنلیک د کتنې لاندې دی.',
          bal: 'تئی درخواست جائزہ ءَ اِنت۔');
  String get applicationRejected => _t(
      'Your application was not approved. Please contact our team.',
      'آپ کی درخواست منظور نہیں ہوئی۔ براہِ کرم ہماری ٹیم سے رابطہ کریں۔',
      sd: 'اوهان جي درخواست منظور نه ٿي. مهرباني ڪري اسان جي ٽيم سان رابطو '
          'ڪريو.',
      pa: 'تہاڈی درخواست منظور نئیں ہوئی۔ مہربانی کرکے ساڈی ٹیم نال رابطہ کرو۔',
      ps: 'ستاسو غوښتنلیک ونه منل شو. مهرباني وکړئ زموږ له ټیم سره اړیکه '
          'ونیسئ.',
      bal: 'تئی درخواست منظور نہ بوت۔ مہربانی کن اِت مئی ٹیم ءِ گۆن رابطہ کن '
          'اِت۔');
  String get outstandingBalance => _t('Outstanding balance', 'بقایا رقم',
      sd: 'باقي رقم', pa: 'بقایا رقم', ps: 'پاتې بیلانس', bal: 'بقایا رقم');
  String get totalPurchases => _t('Total purchases', 'کل خریداری',
      sd: 'ڪل خريداري', pa: 'کل خریداری', ps: 'ټول پیرودنې', bal: 'کل خریداری');
  String get tierLabel => _t('Tier', 'درجہ',
      sd: 'درجو', pa: 'درجہ', ps: 'کچه', bal: 'درجہ');
  String get awardsLabel => _t('Awards', 'ایوارڈز',
      sd: 'ايوارڊز', pa: 'ایوارڈز', ps: 'جایزې', bal: 'ایوارڈز');
  String get perksLabel => _t('Benefits', 'مراعات',
      sd: 'مراعتون', pa: 'مراعات', ps: 'ګټې', bal: 'مراعات');
  String get requestStatement =>
      _t('Request statement on WhatsApp', 'واٹس ایپ پر گوشوارہ منگوائیں',
          sd: 'واٽس ايپ تي گوشوارو گهرايو',
          pa: 'واٹس ایپ تے گوشوارہ منگواؤ',
          ps: 'په واټساپ د حساب ورقه وغواړئ',
          bal: 'واٹس ایپ ءَ گوشوارہ لوٹ اِت');
  String get noBalanceYet =>
      _t('No balance recorded yet.', 'ابھی کوئی بقایا درج نہیں۔',
          sd: 'اڃا ڪو بقايا درج ناهي.',
          pa: 'ہلے کوئی بقایا درج نئیں۔',
          ps: 'لا کوم بیلانس نه دی ثبت شوی.',
          bal: 'هنوں ہچ بقایا درج نیست۔');
  String get signOut => _t('Sign out', 'سائن آؤٹ',
      sd: 'سائن آئوٽ', pa: 'سائن آؤٹ', ps: 'وتل', bal: 'سائن آؤٹ');

  // Farmer login / register.
  String get growWithCassiaTitle =>
      _t('Grow with Cassia', 'کیسیا کے ساتھ اگائیں',
          sd: 'ڪيسيا سان گڏ پوکيو',
          pa: 'کیسیا نال اُگاؤ',
          ps: 'له کیسیا سره کرل',
          bal: 'کیسیا ئے گۆن کشت کن اِت');
  String get loginLabel => _t('Login', 'لاگ اِن',
      sd: 'لاگ اِن', pa: 'لاگ اِن', ps: 'ننوتل', bal: 'لاگ اِن');
  String get registerLabel => _t('Register', 'رجسٹر کریں',
      sd: 'رجسٽر ڪريو', pa: 'رجسٹر کرو', ps: 'راجستر کړئ', bal: 'رجسٹر کن اِت');
  String get loginFarmerHint => _t(
      'Login with your mobile number and secret number (PIN).',
      'اپنے موبائل نمبر اور خفیہ نمبر (پن) سے لاگ اِن کریں۔',
      sd: 'پنهنجي موبائل نمبر ۽ ڳجهي نمبر (پِن) سان لاگ اِن ڪريو.',
      pa: 'اپنے موبائل نمبر تے خفیہ نمبر (پن) نال لاگ اِن کرو۔',
      ps: 'د خپل موبایل شمیرې او پټ شمیرې (پین) سره ننوځئ.',
      bal: 'وتی موبائل نمبر ءُ پۆشتگیں نمبر (پن) ئے گۆن لاگ اِن کن اِت۔');
  String get secretNumberPin => _t('Secret number (PIN)', 'خفیہ نمبر (پن)',
      sd: 'ڳجهو نمبر (پِن)',
      pa: 'خفیہ نمبر (پن)',
      ps: 'پټ شمیر (پین)',
      bal: 'پۆشتگیں نمبر (پن)');
  String get sixNumbers => _t('6 numbers', '6 نمبر',
      sd: '6 انگ', pa: '6 نمبر', ps: '6 شمیرې', bal: '6 نمبر');
  String get newFarmer => _t('New farmer?', 'نئے کسان؟',
      sd: 'نئون هاري؟', pa: 'نواں کسان؟', ps: 'نوی بزګر؟', bal: 'نوکیں کسان؟');
  String get alreadyRegistered =>
      _t('Already registered?', 'پہلے سے رجسٹرڈ ہیں؟',
          sd: 'اڳ ۾ ئي رجسٽرڊ آهيو؟',
          pa: 'پہلاں توں رجسٹرڈ او؟',
          ps: 'دمخه راجستر یاست؟',
          bal: 'پیسر ءَ رجسٹرڈ اِت؟');
  String get accountProtectedPin => _t(
      'Your account is protected with your secret number',
      'آپ کا اکاؤنٹ آپ کے خفیہ نمبر سے محفوظ ہے',
      sd: 'اوهان جو اڪائونٽ اوهان جي ڳجهي نمبر سان محفوظ آهي',
      pa: 'تہاڈا اکاؤنٹ تہاڈے خفیہ نمبر نال محفوظ اے',
      ps: 'ستاسو حساب ستاسو د پټ شمیرې سره خوندي دی',
      bal: 'تئی اکاؤنٹ تئی پۆشتگیں نمبر ئے گۆن محفوظ اِنت');
  String get requiredLabel => _t('Required', 'ضروری',
      sd: 'ضروري', pa: 'ضروری', ps: 'اړین', bal: 'ضروری');
  String get nextLabel => _t('Next', 'آگے',
      sd: 'اڳتي', pa: 'اگے', ps: 'بل', bal: 'پیسر');
  String get createAccount => _t('Create account', 'اکاؤنٹ بنائیں',
      sd: 'اڪائونٽ ٺاهيو',
      pa: 'اکاؤنٹ بناؤ',
      ps: 'حساب جوړ کړئ',
      bal: 'اکاؤنٹ جوڑ کن اِت');
  String get whatIsYourName => _t('What is your name?', 'آپ کا نام کیا ہے؟',
      sd: 'اوهان جو نالو ڇا آهي؟',
      pa: 'تہاڈا ناں کیہہ اے؟',
      ps: 'ستاسو نوم څه دی؟',
      bal: 'تئی نام چے اِنت؟');
  String get exampleName => _t('Example: Ali Khan', 'مثال: علی خان',
      sd: 'مثال: علي خان',
      pa: 'مثال: علی خان',
      ps: 'بیلګه: علي خان',
      bal: 'مثال: علی خان');
  String get whatIsYourMobile =>
      _t('What is your mobile number?', 'آپ کا موبائل نمبر کیا ہے؟',
          sd: 'اوهان جو موبائل نمبر ڇا آهي؟',
          pa: 'تہاڈا موبائل نمبر کیہہ اے؟',
          ps: 'ستاسو د موبایل شمیره څه ده؟',
          bal: 'تئی موبائل نمبر چے اِنت؟');
  String get choosePin => _t(
      'Choose a 6-digit secret number (PIN)', '6 ہندسوں کا خفیہ نمبر (پن) چنیں',
      sd: '6 انگن جو ڳجهو نمبر (پِن) چونڊيو',
      pa: '6 ہندسیاں دا خفیہ نمبر (پن) چُنو',
      ps: 'د 6 عددو پټ شمیر (پین) وټاکئ',
      bal: '6 ہندسہ ئے پۆشتگیں نمبر (پن) چار اِت');
  String get confirmPin =>
      _t('Confirm your secret number', 'اپنا خفیہ نمبر دوبارہ لکھیں',
          sd: 'پنهنجو ڳجهو نمبر وري لکو',
          pa: 'اپنا خفیہ نمبر دوبارہ لکھو',
          ps: 'خپل پټ شمیر بیا ولیکئ',
          bal: 'وتی پۆشتگیں نمبر پدا نبیس اِت');
  String get whichDistrict =>
      _t('Which district are you from?', 'آپ کس ضلع سے ہیں؟',
          sd: 'اوهان ڪهڙي ضلعي مان آهيو؟',
          pa: 'تُسیں کیہڑے ضلع توں او؟',
          ps: 'تاسو د کومې ولسوالۍ یاست؟',
          bal: 'تها کُجام ضلع ءَ اِت؟');
  String get whichTown => _t(
      'Which city or town are you near?', 'آپ کس شہر یا قصبے کے قریب ہیں؟',
      sd: 'اوهان ڪهڙي شهر يا ڳوٺ جي ويجهو آهيو؟',
      pa: 'تُسیں کیہڑے شہر یا قصبے دے نیڑے او؟',
      ps: 'تاسو د کوم ښار یا کلي نږدې یاست؟',
      bal: 'تها کُجام شہر یا قصبہ ئے نزّیک اِت؟');
  String get whichVillage =>
      _t('Which village do you live in?', 'آپ کس گاؤں میں رہتے ہیں؟',
          sd: 'اوهان ڪهڙي ڳوٺ ۾ رهو ٿا؟',
          pa: 'تُسیں کیہڑے پِنڈ وچ رہندے او؟',
          ps: 'تاسو په کوم کلي کې اوسیږئ؟',
          bal: 'تها کُجام هلک ءَ نند اِت؟');
  String get whichCrops =>
      _t('Which crops do you grow?', 'آپ کون سی فصلیں اگاتے ہیں؟',
          sd: 'اوهان ڪهڙيون فصلون پوکيو ٿا؟',
          pa: 'تُسیں کیہڑیاں فصلاں اُگاؤندے او؟',
          ps: 'تاسو کوم فصلونه کرئ؟',
          bal: 'تها کُجام فصلان کشت کن اِت؟');
  String get optionalLabel => _t('Optional', 'اختیاری',
      sd: 'اختياري', pa: 'اختیاری', ps: 'اختیاري', bal: 'اختیاری');

  // City / town field (farmer register, dealer apply, Find a Dealer).
  String get cityTown => _t('City / town', 'شہر / قصبہ',
      sd: 'شهر / ڳوٺ', pa: 'شہر / قصبہ', ps: 'ښار / کلی', bal: 'شہر / قصبہ');
  String get cityTownHint =>
      _t('e.g. Hyderabad, Tando Jam', 'مثال: حیدرآباد، ٹنڈوجام',
          sd: 'مثال: حيدرآباد، ٽنڊوڄام',
          pa: 'مثال: حیدرآباد، ٹنڈوجام',
          ps: 'بیلګه: حیدراباد، ټنډوجام',
          bal: 'مثال: حیدرآباد، ٹنڈوجام');
  String get chooseDistrictError =>
      _t('Please choose your district.', 'براہِ کرم اپنا ضلع منتخب کریں۔',
          sd: 'مهرباني ڪري پنهنجو ضلعو چونڊيو.',
          pa: 'مہربانی کرکے اپنا ضلع چُنو۔',
          ps: 'مهرباني وکړئ خپله ولسوالي وټاکئ.',
          bal: 'مہربانی کن اِت وتی ضلع ءَ چار اِت۔');
  String get enterCityTown => _t(
      'Please enter your city or town.', 'براہِ کرم اپنا شہر یا قصبہ درج کریں۔',
      sd: 'مهرباني ڪري پنهنجو شهر يا ڳوٺ لکو.',
      pa: 'مہربانی کرکے اپنا شہر یا قصبہ لکھو۔',
      ps: 'مهرباني وکړئ خپل ښار یا کلی ولیکئ.',
      bal: 'مہربانی کن اِت وتی شہر یا قصبہ نبیس اِت۔');
  String get enterBusinessName => _t(
      'Please enter your business name.', 'براہِ کرم اپنے کاروبار کا نام درج کریں۔',
      sd: 'مهرباني ڪري پنهنجي ڪاروبار جو نالو لکو.',
      pa: 'مہربانی کرکے اپنے کاروبار دا ناں لکھو۔',
      ps: 'مهرباني وکړئ د خپلې سوداګرۍ نوم ولیکئ.',
      bal: 'مہربانی کن اِت وتی کاروبار ئے نام نبیس اِت۔');

  // ----------------------------------------------------- find a dealer
  String get findDealerSubtitle =>
      _t('Seed dealers near you', 'آپ کے قریب بیج ڈیلر',
          sd: 'اوهان جي ويجهو ٻج ڊيلر',
          pa: 'تہاڈے نیڑے بیج ڈیلر',
          ps: 'ستاسو نږدې د تخم ډیلران',
          bal: 'تئی نزّیک تُخم ڈیلر');
  String get loginToFindDealersTitle =>
      _t('Login to find dealers', 'ڈیلر تلاش کرنے کے لیے لاگ اِن کریں',
          sd: 'ڊيلر ڳولڻ لاءِ لاگ اِن ڪريو',
          pa: 'ڈیلر لبھن لئی لاگ اِن کرو',
          ps: 'د ډیلرانو موندلو لپاره ننوځئ',
          bal: 'ڈیلر گیچ کنگ ئے واستہ لاگ اِن کن اِت');
  String get loginToFindDealersBody => _t(
      'Login to your farmer account so we can show the dealers closest to you.',
      'اپنے کسان اکاؤنٹ میں لاگ اِن کریں تاکہ ہم آپ کے قریب ترین ڈیلر دکھا سکیں۔',
      sd: 'پنهنجي هاري اڪائونٽ ۾ لاگ اِن ڪريو ته جيئن اسان اوهان جي ويجهي ترين '
          'ڊيلر ڏيکاري سگهون.',
      pa: 'اپنے کسان اکاؤنٹ وچ لاگ اِن کرو تاں جو اسِیں تہاڈے سب توں نیڑے ڈیلر '
          'ویکھا سکیے۔',
      ps: 'خپل د بزګر حساب ته ننوځئ ترڅو موږ ستاسو ترټولو نږدې ډیلران وښیو.',
      bal: 'وتی کسان اکاؤنٹ ءَ لاگ اِن کن اِت کہ ما تئی نزّیک تریں ڈیلران ءَ '
          'پیش کُت کنیں۔');
  String get farmerLoginLabel => _t('Farmer login', 'کسان لاگ اِن',
      sd: 'هاري لاگ اِن',
      pa: 'کسان لاگ اِن',
      ps: 'د بزګر ننوتل',
      bal: 'کسان لاگ اِن');
  String get setYourAreaTitle => _t('Set your area', 'اپنا علاقہ منتخب کریں',
      sd: 'پنهنجو علائقو چونڊيو',
      pa: 'اپنا علاقہ چُنو',
      ps: 'خپله سیمه وټاکئ',
      bal: 'وتی علاقہ چار اِت');
  String get setYourAreaBody => _t(
      'Choose your district and town to see the dealers closest to you.',
      'اپنے قریب ترین ڈیلر دیکھنے کے لیے اپنا ضلع اور شہر منتخب کریں۔',
      sd: 'پنهنجي ويجهي ترين ڊيلر ڏسڻ لاءِ پنهنجو ضلعو ۽ شهر چونڊيو.',
      pa: 'اپنے سب توں نیڑے ڈیلر ویکھن لئی اپنا ضلع تے شہر چُنو۔',
      ps: 'د خپلو نږدې ډیلرانو لیدلو لپاره خپله ولسوالي او ښار وټاکئ.',
      bal: 'وتی نزّیک تریں ڈیلران گندگ ئے واستہ وتی ضلع ءُ شہر چار اِت۔');
  String get setYourArea => _t('Set your area', 'علاقہ منتخب کریں',
      sd: 'علائقو چونڊيو',
      pa: 'علاقہ چُنو',
      ps: 'سیمه وټاکئ',
      bal: 'علاقہ چار اِت');
  String get yourAreaLabel => _t('Your area', 'آپ کا علاقہ',
      sd: 'اوهان جو علائقو',
      pa: 'تہاڈا علاقہ',
      ps: 'ستاسو سیمه',
      bal: 'تئی علاقہ');
  String get dealersNearYou => _t('Dealers near you', 'آپ کے قریب ڈیلر',
      sd: 'اوهان جي ويجهو ڊيلر',
      pa: 'تہاڈے نیڑے ڈیلر',
      ps: 'ستاسو نږدې ډیلران',
      bal: 'تئی نزّیک ڈیلر');
  String get yourTownBadge => _t('Your town', 'آپ کا شہر',
      sd: 'اوهان جو شهر', pa: 'تہاڈا شہر', ps: 'ستاسو ښار', bal: 'تئی شہر');
  String get callLabel => _t('Call', 'کال',
      sd: 'ڪال', pa: 'کال', ps: 'زنګ', bal: 'کال');
  String get whatsAppLabel => _t('WhatsApp', 'واٹس ایپ',
      sd: 'واٽس ايپ', pa: 'واٹس ایپ', ps: 'واټساپ', bal: 'واٹس ایپ');
  String get saveLabel => _t('Save', 'محفوظ کریں',
      sd: 'محفوظ ڪريو',
      pa: 'محفوظ کرو',
      ps: 'خوندي کړئ',
      bal: 'محفوظ کن اِت');
  String get askOurTeam => _t('Ask our team', 'ہماری ٹیم سے پوچھیں',
      sd: 'اسان جي ٽيم کان پڇو',
      pa: 'ساڈی ٹیم توں پُچھو',
      ps: 'زموږ له ټیم وپوښتئ',
      bal: 'مئی ٹیم ءَ پُرس اِت');
  String get couldNotLoadDealers => _t(
      'Could not load dealers. Please try again.',
      'ڈیلر لوڈ نہیں ہو سکے۔ براہِ کرم دوبارہ کوشش کریں۔',
      sd: 'ڊيلر لوڊ نه ٿي سگهيا. مهرباني ڪري وري ڪوشش ڪريو.',
      pa: 'ڈیلر لوڈ نئیں ہو سکے۔ مہربانی کرکے دوبارہ کوشش کرو۔',
      ps: 'ډیلران بار نشو. مهرباني وکړئ بیا هڅه وکړئ.',
      bal: 'ڈیلر لوڈ نہ بوتنت۔ مہربانی کن اِت پدا کوشش کنیت۔');
  String get noDealersNearbyTitle =>
      _t('No dealers here yet', 'یہاں ابھی کوئی ڈیلر نہیں',
          sd: 'هتي اڃا ڪو ڊيلر ناهي',
          pa: 'ایتھے ہلے کوئی ڈیلر نئیں',
          ps: 'دلته لا کوم ډیلر نشته',
          bal: 'ادان هنوں ہچ ڈیلر نیست');
  String noDealersNearbyBody(String district) => _t(
      'There are no dealers in $district yet. Our team can help you get seeds.',
      '${data(district)} میں ابھی کوئی ڈیلر نہیں ہے۔ ہماری ٹیم آپ کو بیج دلانے میں مدد کر سکتی ہے۔',
      sd: '${data(district)} ۾ اڃا ڪو ڊيلر ناهي. اسان جي ٽيم اوهان کي ٻج '
          'وٺرائڻ ۾ مدد ڪري سگهي ٿي.',
      pa: '${data(district)} وچ ہلے کوئی ڈیلر نئیں اے۔ ساڈی ٹیم تہانوں بیج '
          'دوان وچ مدد کر سکدی اے۔',
      ps: 'په ${data(district)} کې لا کوم ډیلر نشته. زموږ ټیم کولی شي تاسو '
          'سره د تخم په ترلاسه کولو کې مرسته وکړي.',
      bal: '${data(district)} ءَ هنوں ہچ ڈیلر نیست۔ مئی ٹیم تئی گۆن تُخم '
          'رسینگ ءَ مدد کُت کنت۔');
  String get dealerWhatsAppIntro => _t(
      'Assalam-o-Alaikum! I found your shop on the Cassia Seed app. I would like to ask about seeds.',
      'السلام علیکم! مجھے آپ کی دکان کیسیا سیڈ ایپ پر ملی۔ میں بیج کے بارے میں پوچھنا چاہتا ہوں۔',
      sd: 'السلام عليڪم! مون کي اوهان جي دُڪان ڪيسيا سيڊ ايپ تي ملي. مان ٻج '
          'بابت پڇڻ چاهيان ٿو.',
      pa: 'السلام علیکم! مینوں تہاڈی دکان کیسیا سیڈ ایپ تے لبھی۔ میں بیج بارے '
          'پُچھنا چاہنا واں۔',
      ps: 'السلام علیکم! ستاسو دکان مې د کیسیا سیډ اپلیکیشن کې وموند. غواړم د '
          'تخم په اړه وپوښتم.',
      bal: 'السلام علیکم! منا تئی دکان کیسیا سیڈ ایپ ءَ کپت۔ من تُخم ئے بارہ '
          'ءَ پُرسگ لوٹان۔');

  // The farmer's own account page.
  String get myAccount => _t('My account', 'میرا اکاؤنٹ',
      sd: 'منهنجو اڪائونٽ',
      pa: 'میرا اکاؤنٹ',
      ps: 'زما حساب',
      bal: 'منی اکاؤنٹ');
  String get myVillage => _t('Village', 'گاؤں',
      sd: 'ڳوٺ', pa: 'پِنڈ', ps: 'کلی', bal: 'هلک');
  String get myDistrict => _t('District', 'ضلع',
      sd: 'ضلعو', pa: 'ضلع', ps: 'ولسوالي', bal: 'ضلع');
  String get myCrops => _t('My crops', 'میری فصلیں',
      sd: 'منهنجيون فصلون',
      pa: 'میریاں فصلاں',
      ps: 'زما فصلونه',
      bal: 'منی فصلان');
  String get memberSince => _t('Member', 'رکن',
      sd: 'ميمبر', pa: 'ممبر', ps: 'غړی', bal: 'رکن');

  // Validation and result messages.
  String get enterYourName =>
      _t('Please enter your name.', 'براہِ کرم اپنا نام درج کریں۔',
          sd: 'مهرباني ڪري پنهنجو نالو لکو.',
          pa: 'مہربانی کرکے اپنا ناں لکھو۔',
          ps: 'مهرباني وکړئ خپل نوم ولیکئ.',
          bal: 'مہربانی کن اِت وتی نام نبیس اِت۔');
  String get enterValidMobile =>
      _t('Enter a valid mobile number.', 'درست موبائل نمبر درج کریں۔',
          sd: 'صحيح موبائل نمبر لکو.',
          pa: 'درست موبائل نمبر لکھو۔',
          ps: 'سم د موبایل شمیره ولیکئ.',
          bal: 'درستیں موبائل نمبر نبیس اِت۔');
  String get pinMustBe6 => _t(
      'The secret number must be 6 digits.', 'خفیہ نمبر 6 ہندسوں کا ہونا چاہیے۔',
      sd: 'ڳجهو نمبر 6 انگن جو هجڻ گهرجي.',
      pa: 'خفیہ نمبر 6 ہندسیاں دا ہونا چاہیدا اے۔',
      ps: 'پټ شمیر باید 6 عدده وي.',
      bal: 'پۆشتگیں نمبر 6 ہندسہ ئے بئگ لوٹیت۔');
  String get pinsDontMatch =>
      _t('The secret numbers do not match.', 'خفیہ نمبر آپس میں نہیں ملتے۔',
          sd: 'ڳجها نمبر پاڻ ۾ نٿا ملن.',
          pa: 'خفیہ نمبر آپس وچ نئیں ملدے۔',
          ps: 'پټ شمیرې سره نه ورته کیږي.',
          bal: 'پۆشتگیں نمبر یکدگہ ءَ نہ مننت۔');
  String get passwordTooShort => _t(
      'The password must be at least 8 characters.',
      'پاس ورڈ کم از کم 8 حروف کا ہونا چاہیے۔',
      sd: 'پاسورڊ گهٽ ۾ گهٽ 8 اکرن جو هجڻ گهرجي.',
      pa: 'پاس ورڈ گھٹ توں گھٹ 8 حرفاں دا ہونا چاہیدا اے۔',
      ps: 'پټنوم باید لږ تر لږه 8 توري وي.',
      bal: 'پاس ورڈ کم از کم 8 حرف ئے بئگ لوٹیت۔');
  String get passwordsDontMatch =>
      _t('The passwords do not match.', 'پاس ورڈ آپس میں نہیں ملتے۔',
          sd: 'پاسورڊ پاڻ ۾ نٿا ملن.',
          pa: 'پاس ورڈ آپس وچ نئیں ملدے۔',
          ps: 'پټنومونه سره نه ورته کیږي.',
          bal: 'پاس ورڈ یکدگہ ءَ نہ مننت۔');
  String get pickAtLeastOneCrop =>
      _t('Pick at least one crop.', 'کم از کم ایک فصل منتخب کریں۔',
          sd: 'گهٽ ۾ گهٽ هڪ فصل چونڊيو.',
          pa: 'گھٹ توں گھٹ اِک فصل چُنو۔',
          ps: 'لږ تر لږه یو فصل وټاکئ.',
          bal: 'کم از کم یک فصل چار اِت۔');
  String get accountExistsError => _t(
      'An account with this mobile number already exists.',
      'اس موبائل نمبر سے اکاؤنٹ پہلے سے موجود ہے۔',
      sd: 'هن موبائل نمبر سان اڪائونٽ اڳ ۾ ئي موجود آهي.',
      pa: 'ایس موبائل نمبر نال اکاؤنٹ پہلاں توں موجود اے۔',
      ps: 'په دې موبایل شمیره حساب دمخه شته.',
      bal: 'اے موبائل نمبر ئے گۆن اکاؤنٹ پیسر ءَ هست۔');
  String get wrongMobileOrPin => _t(
      'Wrong mobile number or secret number.',
      'موبائل نمبر یا خفیہ نمبر غلط ہے۔',
      sd: 'موبائل نمبر يا ڳجهو نمبر غلط آهي.',
      pa: 'موبائل نمبر یا خفیہ نمبر غلط اے۔',
      ps: 'د موبایل شمیره یا پټ شمیر غلط دی.',
      bal: 'موبائل نمبر یا پۆشتگیں نمبر غلط اِنت۔');
  String get wrongMobileOrPassword => _t(
      'Wrong mobile number or password.', 'موبائل نمبر یا پاس ورڈ غلط ہے۔',
      sd: 'موبائل نمبر يا پاسورڊ غلط آهي.',
      pa: 'موبائل نمبر یا پاس ورڈ غلط اے۔',
      ps: 'د موبایل شمیره یا پټنوم غلط دی.',
      bal: 'موبائل نمبر یا پاس ورڈ غلط اِنت۔');
  String get welcomeReady =>
      _t('Welcome! Your account is ready.', 'خوش آمدید! آپ کا اکاؤنٹ تیار ہے۔',
          sd: 'ڀليڪار! اوهان جو اڪائونٽ تيار آهي.',
          pa: 'جی آیاں نوں! تہاڈا اکاؤنٹ تیار اے۔',
          ps: 'ښه راغلاست! ستاسو حساب چمتو دی.',
          bal: 'وش آتکہ! تئی اکاؤنٹ تیار اِنت۔');
  String get signedOut => _t('Signed out.', 'سائن آؤٹ ہو گیا۔',
      sd: 'سائن آئوٽ ٿي ويو.',
      pa: 'سائن آؤٹ ہو گیا۔',
      ps: 'وتل وشو.',
      bal: 'سائن آؤٹ بوت۔');

  /// How much space the name uses in a short greeting, e.g. "Hi, Ali".
  String hiName(String name) =>
      _t('Hi, ', 'ہیلو، ', sd: 'هيلو، ', pa: 'ہیلو، ', ps: 'سلام، ', bal: 'هیلو، ') +
      name;
}

extension AppStringsContext on BuildContext {
  /// The app's text in the current language.
  AppStrings get s => AppStrings.of(this);
}
