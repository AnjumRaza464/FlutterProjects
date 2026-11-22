import 'package:material_ui/material_ui.dart';

/// A ready-made Ask Cassia question: the short [label] on its chip, and the
/// full [question] that is asked when the chip is tapped.
typedef AskSuggestion = ({String label, String question});

/// Every piece of text the farmer app shows, in English and Urdu.
///
/// Each string is written once with both languages side by side, so a
/// translation can never be missing and is easy to review next to its
/// English. Screens read them through `context.s`.
///
/// Not translated here on purpose: product data from Firestore (variety
/// names, crops), the company's name and address, and the order message sent
/// to Cassia Seed's team on WhatsApp.
class AppStrings {
  const AppStrings._(this.isUrdu);

  static const en = AppStrings._(false);
  static const ur = AppStrings._(true);

  /// The strings for the app's current language.
  static AppStrings of(BuildContext context) {
    return Localizations.maybeLocaleOf(context)?.languageCode == 'ur' ? ur : en;
  }

  final bool isUrdu;

  /// 'en' or 'ur' — also tells the AI features which language to answer in.
  String get languageCode => isUrdu ? 'ur' : 'en';

  String _t(String en, String ur) => isUrdu ? ur : en;

  /// Letter-spacing for a piece of styled text: [english] in English, none
  /// in Urdu, because space between letters breaks the joins of Urdu's
  /// connected script.
  double spacing(double english) => isUrdu ? 0 : english;

  /// An arrow pointing the way the language reads: onwards.
  String get arrow => isUrdu ? '←' : '→';

  // Invisible Unicode marks that set the reading direction of a stretch of
  // text. Built from their code points so they are visible in this file.
  static final _fsi = String.fromCharCode(0x2068); // direction of its content
  static final _lri = String.fromCharCode(0x2066); // left-to-right
  static final _pdi = String.fromCharCode(0x2069); // end of the stretch

  /// Wraps product data (a pack size, a variety name) so it keeps its own
  /// reading direction inside right-to-left Urdu text. Without this "10 g"
  /// is shown as "g 10". English text is returned unchanged.
  String data(String text) => isUrdu ? '$_fsi$text$_pdi' : text;

  /// Like [data], but always left-to-right — for phone and order numbers,
  /// which would otherwise have their parts swapped ("1234567 0300").
  String _ltr(String text) => '$_lri$text$_pdi';

  // ------------------------------------------------------------- general

  String get tryAgain => _t('Try again', 'دوبارہ کوشش کریں');
  String get cancel => _t('Cancel', 'منسوخ');
  String get ok => _t('OK', 'ٹھیک ہے');
  String get back => _t('Back', 'واپس');
  String get done => _t('Done', 'ہو گیا');
  String get close => _t('Close', 'بند کریں');
  String get available => _t('Available', 'دستیاب');
  String get notAvailableYet => _t('Not available yet', 'ابھی دستیاب نہیں');
  String get comingSoon => _t('Coming Soon', 'جلد آ رہا ہے');
  String get newBadge => _t('NEW', 'نیا');
  String get couldNotOpenWhatsApp => _t(
      'Could not open WhatsApp on this device.',
      'اس فون پر واٹس ایپ نہیں کھل سکا۔');
  String get somethingWentWrong => _t(
      'Something went wrong. Please try again.',
      'کچھ غلط ہو گیا۔ براہِ کرم دوبارہ کوشش کریں۔');
  String get noConnectionTitle => _t('No connection', 'انٹرنیٹ دستیاب نہیں');
  String get noConnectionBody => _t(
      'Please check your internet connection and try again.',
      'براہِ کرم اپنا انٹرنیٹ چیک کریں اور دوبارہ کوشش کریں۔');
  String get notSetUpBody => _t(
      'This feature has not been switched on yet. Please try again later.',
      'یہ سہولت ابھی شروع نہیں کی گئی۔ براہِ کرم بعد میں کوشش کریں۔');

  /// The name of the language the toggle switches TO.
  String get otherLanguage => _t('اردو', 'English');
  String get changeLanguage => _t('Change language', 'زبان تبدیل کریں');

  // ---------------------------------------------------------- navigation

  String get navHome => _t('Home', 'ہوم');
  String get navShop => _t('Shop', 'دکان');
  String get navDoctor => _t('Doctor', 'ڈاکٹر');
  String get navAskAi => _t('Ask', 'پوچھیں');
  String get navOrder => _t('Order', 'آرڈر');

  // ---------------------------------------------------------------- home

  /// [hour] is the hour of the day, 0–23.
  String greeting(int hour) => hour < 12
      ? _t('Good morning', 'صبح بخیر')
      : hour < 17
          ? _t('Good afternoon', 'دن بخیر')
          : _t('Good evening', 'شام بخیر');
  String get salam => _t('Assalam o Alaikum', 'السلام علیکم');
  String get season => _t('SEASON 2026', 'سیزن 2026');
  String get heroTagline => _t(
      'Quality seeds and an AI crop doctor, right in your pocket.',
      'معیاری بیج اور اے آئی کراپ ڈاکٹر، آپ کی جیب میں۔');
  String get shopSeedsCta => _t('Shop Seeds', 'بیج دیکھیں');
  String get statSeedPacks => _t('Seed packs', 'بیج کے پیک');
  String get statCrops => _t('Crops', 'فصلیں');
  String get statYears => _t('2 Yrs', '2 سال');
  String get statTrials => _t('Adapted trials', 'موافق ٹرائلز');
  String get statAi => _t('AI', 'اے آئی');
  String get askCassia => _t('Ask Cassia', 'کیسیا سے پوچھیں');
  String get seedShop => _t('Seed Shop', 'بیج کی دکان');
  String get seedShopHint =>
      _t('Tap a pack for details.', 'تفصیل کے لیے پیک پر دبائیں۔');
  String get myOrder => _t('My Order', 'میرا آرڈر');
  String get support => _t('Support', 'مدد');
  String get aboutUs => _t('About Us', 'ہمارے بارے میں');
  String get supportAndAbout => _t('Support & About', 'مدد اور تعارف');
  String get shopByCrop => _t('Shop by Crop', 'فصل کے حساب سے');
  String get spotlight => _t('Spotlight', 'خاص انتخاب');
  String get featuredSeeds => _t('Featured Seeds', 'نمایاں بیج');
  String get viewAndOrder => _t('View & Order', 'دیکھیں اور آرڈر کریں');
  String get newArrivals => _t('New Arrivals', 'نئی آمد');
  String get tomatoChilliPicks =>
      _t('Tomato & Chilli Picks', 'ٹماٹر اور مرچ کا انتخاب');
  String get promoBody => _t('Snap a photo. Get a diagnosis and a cure.',
      'تصویر لیں۔ تشخیص اور علاج پائیں۔');
  String get tryNow => _t('Try now', 'آزمائیں');
  String get commonProblems => _t('Common Problems', 'عام مسائل');

  /// The crop problems offered on Home, as (emoji, name) pairs.
  List<(String, String)> get problems => [
        ('🍂', _t('Yellow leaves', 'پیلے پتے')),
        ('🌀', _t('Leaf curl', 'پتوں کا مڑنا')),
        ('🐛', _t('Insects and pests', 'کیڑے مکوڑے')),
        ('🥀', _t('Wilting plants', 'مرجھاتے پودے')),
        ('⚪', _t('White powder on leaves', 'پتوں پر سفید پاؤڈر')),
        ('🍅', _t('Fruit rot or cracking', 'پھل کا گلنا یا پھٹنا')),
      ];

  /// The question sent to Ask Cassia when a problem is tapped.
  String problemQuestion(String problem) => _t(
      'My crop has this problem: $problem. What are the common causes and '
          'what should I do?',
      'میری فصل میں یہ مسئلہ ہے: $problem۔ اس کی عام وجوہات کیا ہیں اور '
          'مجھے کیا کرنا چاہیے؟');

  String get growerTip => _t('Grower tip', 'کاشتکار کے لیے مشورہ');
  String get tapForNext => _t('tap for next', 'اگلے کے لیے دبائیں');
  List<String> get tips => [
        _t(
            'Buy only sealed packs and check the germination % and expiry '
                'date printed on them.',
            'صرف بند پیک خریدیں اور ان پر چھپی اُگاؤ کی شرح اور میعاد کی '
                'تاریخ دیکھ لیں۔'),
        _t('Store seed packs in a cool, dry place, away from direct sunlight.',
            'بیج کے پیک ٹھنڈی، خشک جگہ پر رکھیں، سیدھی دھوپ سے دور۔'),
        _t(
            'Walk your field early in the morning. Pests and disease are '
                'easiest to spot then.',
            'صبح سویرے کھیت کا چکر لگائیں۔ کیڑے اور بیماری اسی وقت آسانی '
                'سے نظر آتے ہیں۔'),
        _t(
            'For Crop Doctor, a clear close-up photo gives far better advice '
                'than a blurry one.',
            'کراپ ڈاکٹر کے لیے صاف اور قریب کی تصویر دھندلی تصویر سے کہیں '
                'بہتر مشورہ دیتی ہے۔'),
        _t(
            'Sow in the evening or on a cloudy day to reduce stress on young '
                'seedlings.',
            'شام کے وقت یا ابر آلود دن میں کاشت کریں تاکہ ننھے پودوں پر '
                'دباؤ کم ہو۔'),
      ];

  String get whyCassia => _t('Why Cassia', 'کیسیا کیوں');

  /// "Why Cassia" points as (title, detail) pairs.
  List<(String, String)> get whyPoints => [
        (
          _t('Two-year adapted trials', 'دو سالہ موافق ٹرائلز'),
          _t('Verified in ARI Tarnab trials, 2023–24',
              'اے آر آئی ترناب ٹرائلز میں تصدیق شدہ، 2023–24')
        ),
        (
          _t('Company registered', 'کمپنی رجسٹرڈ'),
          _t('Cassia Seed (Private) Limited',
              'کیسیا سیڈ (پرائیویٹ) لمیٹڈ')
        ),
        (
          _t('Promise of Quality', 'معیار کا وعدہ'),
          _t('Every pack made with care for growers',
              'ہر پیک کاشتکاروں کے لیے توجہ سے تیار')
        ),
        (
          _t('AI Crop Doctor', 'اے آئی کراپ ڈاکٹر'),
          _t('Photo-based diagnosis and advice', 'تصویر سے تشخیص اور مشورہ')
        ),
        (
          _t('Direct ordering', 'براہِ راست آرڈر'),
          _t('Order straight from the company', 'سیدھا کمپنی سے آرڈر کریں')
        ),
      ];

  String get howOrderingWorks => _t('How Ordering Works', 'آرڈر کیسے ہوتا ہے');

  /// The ordering steps as (title, detail) pairs.
  List<(String, String)> get orderSteps => [
        (
          _t('Choose your seeds', 'اپنے بیج چنیں'),
          _t('Browse packs and add them to your order.',
              'پیک دیکھیں اور اپنے آرڈر میں شامل کریں۔')
        ),
        (
          _t('Send on WhatsApp', 'واٹس ایپ پر بھیجیں'),
          _t('Fill in your details and send the order to us.',
              'اپنی تفصیلات لکھیں اور آرڈر ہمیں بھیجیں۔')
        ),
        (
          _t('We confirm with you', 'ہم آپ سے تصدیق کرتے ہیں'),
          _t('Our team replies with price and delivery details.',
              'ہماری ٹیم قیمت اور ڈیلیوری کی تفصیل کے ساتھ جواب دیتی ہے۔')
        ),
      ];

  String get questions => _t('Questions', 'سوالات');

  /// Frequently asked questions as (question, answer) pairs.
  List<(String, String)> get faqs => [
        (
          _t('How do I place an order?', 'میں آرڈر کیسے کروں؟'),
          _t(
              'Add seeds to your order, enter your name, phone and city, and '
                  'send it on WhatsApp. Our team will confirm price and '
                  'delivery.',
              'بیج اپنے آرڈر میں شامل کریں، اپنا نام، فون اور شہر لکھیں، اور '
                  'واٹس ایپ پر بھیج دیں۔ ہماری ٹیم قیمت اور ڈیلیوری کی تصدیق '
                  'کرے گی۔')
        ),
        (
          _t('How accurate is Crop Doctor?', 'کراپ ڈاکٹر کتنا درست ہے؟'),
          _t(
              'It is an AI guide based on your photo, not a lab test. A clear '
                  'photo gives better results. Always confirm with a local '
                  'agriculture expert before spraying.',
              'یہ آپ کی تصویر پر مبنی اے آئی رہنمائی ہے، لیب ٹیسٹ نہیں۔ صاف '
                  'تصویر سے بہتر نتیجہ ملتا ہے۔ سپرے سے پہلے ہمیشہ مقامی '
                  'ماہرِ زراعت سے تصدیق کریں۔')
        ),
        (
          _t('Where is your office?', 'آپ کا دفتر کہاں ہے؟'),
          _t(
              'Office F-201 & 202, 2nd Floor, Gulshan-e-Zealpak Cooperative '
                  'Housing Society, Site Area, Hyderabad, Sindh.',
              'دفتر F-201 اور 202، دوسری منزل، گلشنِ ذیل پاک کوآپریٹو ہاؤسنگ '
                  'سوسائٹی، سائٹ ایریا، حیدرآباد، سندھ۔')
        ),
      ];

  String get needHelp =>
      _t('Need help choosing a seed?', 'بیج چننے میں مدد چاہیے؟');
  String get needHelpBody => _t(
      'Ask Cassia, our AI advisor, or contact our team directly.',
      'کیسیا (ہمارا اے آئی مشیر) سے پوچھیں، یا براہِ راست ہماری ٹیم سے '
          'رابطہ کریں۔');
  String get switchTheme => _t('Light / dark', 'روشن / تاریک');

  // ------------------------------------------------------------- footer
  String get quickLinks => _t('Quick Links', 'فوری روابط');
  String get ourPromise => _t('Our Promise', 'ہمارا وعدہ');
  String get headOffice => _t('Head Office', 'مرکزی دفتر');
  String get ourBrands => _t('Our Brands', 'ہمارے برانڈز');
  String get brandsLine =>
      _t('Cassia Seed · Malapine Seeds', 'کیسیا سیڈ · مالاپائن سیڈز');
  String get designedByOwner => _t('Designed by owner', 'مالک کے ذریعے ڈیزائن');
  String get reachAllPakistan =>
      _t('We reach all over Pakistan', 'ہم پورے پاکستان میں پہنچتے ہیں');

  // ------------------------------------------- extra home quick actions
  String get myFarm => _t('My Farm', 'میرا کھیت');
  String get findDealer => _t('Find a Dealer', 'ڈیلر تلاش کریں');
  String get help => _t('Help', 'مدد');
  String get fromOurFields => _t('From Our Fields', 'ہمارے کھیتوں سے');
  List<String> get fieldCaptions => [
        _t('Field day with growers', 'کاشتکاروں کے ساتھ فیلڈ ڈے'),
        _t('Chilli crop', 'مرچ کی فصل'),
        _t('Cucumber harvest', 'کھیرے کی فصل'),
        _t('Chilli field', 'مرچ کا کھیت'),
      ];

  // ------------------------------------------------------------- weather
  String get todaysWeather => _t("Today's weather", 'آج کا موسم');
  String get change => _t('Change', 'تبدیل کریں');
  String get humidity => _t('Humidity', 'نمی');
  String get wind => _t('Wind', 'ہوا');
  String get rainChance => _t('Rain chance', 'بارش کا امکان');
  String get yourDistrict => _t('Your district / city', 'آپ کا ضلع / شہر');
  String get chooseYourDistrict =>
      _t('Choose your district', 'اپنا ضلع منتخب کریں');
  String get weatherUnavailable => _t(
      'Weather is not available right now.', 'موسم ابھی دستیاب نہیں ہے۔');
  String get sprayBad => _t('Not a good time to spray: check wind and rain '
      'first.', 'سپرے کا مناسب وقت نہیں: پہلے ہوا اور بارش دیکھ لیں۔');
  String get sprayOk => _t(
      'Wind and rain are low right now. Still confirm locally before spraying.',
      'ابھی ہوا اور بارش کم ہے۔ پھر بھی سپرے سے پہلے مقامی طور پر تصدیق کریں۔');

  String get motto => _t('Grow with Cassia', 'کیسیا کے ساتھ اُگائیں');
  String get cropDoctor => _t('Crop Doctor', 'کراپ ڈاکٹر');
  String get cropDoctorTagline => _t(
      'Photograph a sick plant → get the problem & cure',
      'بیمار پودے کی تصویر لیں، مسئلہ اور علاج جانیں');
  String get shopSeeds => _t('Shop seeds', 'بیج خریدیں');
  String get askCassiaAi => _t('Ask Cassia AI', 'کیسیا اے آئی');
  String get featuredVarieties => _t('Featured varieties', 'نمایاں اقسام');
  String get seeAll => _t('See all', 'سب دیکھیں');
  String get noVarietiesYet =>
      _t('No varieties yet.', 'ابھی کوئی قسم موجود نہیں۔');

  // ---------------------------------------------------------------- shop

  String get shop => _t('Shop', 'دکان');
  String get allCrops => _t('All', 'تمام');
  String get searchSeeds => _t('Search seeds…', 'بیج تلاش کریں…');

  // The Shop's filter groups.
  String get groupTomato => _t('Tomato', 'ٹماٹر');
  String get groupPepper => _t('Hot Pepper', 'مرچ');
  String get groupGourds => _t('Gourds', 'کدو');
  String get groupOkra => _t('Okra', 'بھنڈی');
  String get groupOtherVeg => _t('Other Veg', 'دیگر سبزیاں');
  String get groupFieldCrops => _t('Field Crops', 'کھیت کی فصلیں');
  String get clearSearch => _t('Clear search', 'تلاش صاف کریں');
  String noMatches(String query) => _t(
      'No varieties match "$query"',
      '"${data(query)}" سے ملتی کوئی قسم نہیں ملی');
  String get showAllVarieties =>
      _t('Show all varieties', 'تمام اقسام دکھائیں');
  String get noProductsYet => _t('No products yet', 'ابھی کوئی پروڈکٹ نہیں');
  String get noProductsBody => _t(
      'Varieties will appear here once they are added from the admin panel.',
      'ایڈمن پینل سے شامل ہونے کے بعد اقسام یہاں نظر آئیں گی۔');
  String get couldNotLoadProducts =>
      _t('Could not load products', 'پروڈکٹس لوڈ نہیں ہو سکیں');
  String get seedPlaceholder => _t('Seed', 'بیج');

  // ------------------------------------------------------ product detail

  // The three photos in the gallery.
  String get photoFront => _t('Front', 'سامنے');
  String get photoCloseUp => _t('Close-up', 'قریب سے');
  String get photoShowcase => _t('Showcase', 'نمائش');

  String get tabDetails => _t('Details', 'تفصیلات');
  String get tabFeatures => _t('Features', 'خصوصیات');
  String get brandLabel => _t('Brand', 'برانڈ');
  String get cassiaBrand => _t('Cassia', 'کیسیا');
  String get cropLabel => _t('Crop', 'فصل');
  String get typeLabel => _t('Type', 'قسم');
  String get packSizeLabel => _t('Pack size', 'پیک سائز');
  String get priceLabel => _t('Price', 'قیمت');
  String get onRequest => _t('On request', 'پوچھنے پر');
  String get askCompany => _t('Ask company', 'کمپنی سے پوچھیں');
  String get printedOnPack => _t('Printed on pack', 'پیک پر درج');
  String get featuresToCome => _t(
      'Official variety features (maturity, yield, resistance and more) '
          'will be added by the Cassia team.',
      'قسم کی سرکاری خصوصیات (پکنے کا وقت، پیداوار، قوتِ مدافعت وغیرہ) '
          'کیسیا ٹیم شامل کرے گی۔');
  String get cropGuideButton =>
      _t('🌿 General crop guide (AI)', '🌿 فصل کی عمومی رہنمائی (اے آئی)');
  String get cropGuideNote => _t(
      '(General crop guidance, not official Cassia variety data.)',
      '(یہ فصل کی عمومی رہنمائی ہے، کیسیا کی قسم کا سرکاری ڈیٹا نہیں۔)');
  String get quantityPacks => _t('Quantity (packs)', 'تعداد (پیکٹ)');
  String addToOrder(int packs) =>
      _t('Add $packs to Order', 'آرڈر میں $packs شامل کریں');
  String addedToOrder(int packs, String name) => _t(
      '$packs × $name added to your order ✓',
      '${data('$packs × $name')} آپ کے آرڈر میں شامل ہو گیا ✓');
  String get askAboutThisSeed => _t(
      'Ask Cassia about this seed', 'اس بیج کے بارے میں کیسیا سے پوچھیں');

  /// The question "Ask Cassia about this seed" asks.
  String growingQuestion(String crop, String name) => _t(
      'Tell me about growing $crop ($name): sowing time, spacing, '
          'fertiliser and common problems in Pakistan.',
      '${data('$crop ($name)')} اگانے کے بارے میں بتائیں: بوائی کا وقت، '
          'فاصلہ، کھاد اور پاکستان میں عام مسائل۔');
  String get saveToFavourites =>
      _t('♡ Save to favourites', '♡ پسندیدہ میں محفوظ کریں');
  String get savedFavourite => _t('♥ Saved', '♥ محفوظ ہے');
  String get savedToFavourites =>
      _t('Saved to favourites', 'پسندیدہ میں محفوظ ہو گیا');
  String get removedFromFavourites =>
      _t('Removed from favourites', 'پسندیدہ سے نکال دیا گیا');
  String get yourFavourites => _t('Your Favourites', 'آپ کے پسندیدہ');

  // ---------------------------------------------------------------- cart

  String get cart => _t('Cart', 'کارٹ');
  String get remove => _t('Remove', 'نکالیں');
  String get decrease => _t('Decrease', 'کم کریں');
  String get increase => _t('Increase', 'بڑھائیں');
  String get quantity => _t('Quantity', 'تعداد');
  String get numberOfPacks => _t('Number of packs', 'پیکٹوں کی تعداد');
  String upTo(int max) => _t('Up to $max', '$max تک');
  String get dismiss => _t('Dismiss', 'بند کریں');
  String removedFromCart(String names) => _t(
      'Not available yet, so removed from your cart: $names',
      'ابھی دستیاب نہیں، اس لیے کارٹ سے نکال دی گئیں: ${data(names)}');
  String get yourCart => _t('Your cart', 'آپ کا کارٹ');
  String get cartEmpty => _t('Your cart is empty', 'آپ کا کارٹ خالی ہے');
  String get cartEmptyHint => _t(
      'Open a variety in the Shop and tap "Add to Order".',
      'دکان میں کوئی قسم کھولیں اور "آرڈر میں شامل کریں" دبائیں۔');
  String cartSummary(int varieties, int packs) => _t(
      '$varieties ${varieties == 1 ? 'variety' : 'varieties'} • '
          '$packs ${packs == 1 ? 'pack' : 'packs'}',
      '$varieties ${varieties == 1 ? 'قسم' : 'اقسام'} • $packs پیکٹ');
  String get priceConfirmedOnWhatsApp => _t(
      'Cassia Seed confirms the price on WhatsApp.',
      'قیمت کیسیا سیڈ واٹس ایپ پر بتائے گا۔');
  String get continueLabel => _t('Continue', 'آگے بڑھیں');

  // ------------------------------------------------------------ checkout

  String get yourDetails => _t('Your details', 'آپ کی تفصیلات');
  String get yourName => _t('Your name', 'آپ کا نام');
  String get phoneNumber => _t('Phone number', 'فون نمبر');
  String get cityOrVillage => _t('City or village', 'شہر یا گاؤں');
  String get noteOptional => _t('Note (optional)', 'نوٹ (اختیاری)');
  String get enterName =>
      _t('Please enter your name', 'براہِ کرم اپنا نام لکھیں');
  String get enterValidPhone => _t(
      'Please enter a valid phone number', 'براہِ کرم درست فون نمبر لکھیں');
  String get enterCity => _t('Please enter your city or village',
      'براہِ کرم اپنا شہر یا گاؤں لکھیں');
  String get yourOrder => _t('Your order', 'آپ کا آرڈر');
  String get checkoutInfo => _t(
      'Your order and these details go to Cassia Seed. WhatsApp will open '
          'with your order — press send there, and Cassia Seed will reply '
          'with the price.',
      'آپ کا آرڈر اور یہ تفصیلات کیسیا سیڈ کو جائیں گی۔ واٹس ایپ آپ کے آرڈر '
          'کے ساتھ کھلے گا — وہاں سینڈ دبائیں، کیسیا سیڈ قیمت کے ساتھ جواب '
          'دے گا۔');
  String get sending => _t('Sending…', 'بھیجا جا رہا ہے…');
  String get sendOrderOnWhatsApp =>
      _t('Send order on WhatsApp', 'واٹس ایپ پر آرڈر بھیجیں');
  String orderNotSent(String phone) => _t(
      'Your order could not be sent. Check your internet connection and try '
          'again, or call $phone.',
      'آپ کا آرڈر نہیں بھیجا جا سکا۔ اپنا انٹرنیٹ چیک کر کے دوبارہ کوشش '
          'کریں، یا ${_ltr(phone)} پر کال کریں۔');
  String get nothingLeftToOrder =>
      _t('Nothing left to order', 'آرڈر کے لیے کچھ باقی نہیں');
  String get backToCart => _t('Back to cart', 'کارٹ پر واپس');

  // ---------------------------------------------------------- order sent

  String get order => _t('Order', 'آرڈر');
  String get pressSendInWhatsApp =>
      _t('Press send in WhatsApp', 'واٹس ایپ میں سینڈ دبائیں');
  String get orderReceived => _t('Order received', 'آرڈر موصول ہو گیا');
  String get whatsAppOpenedBody => _t(
      'WhatsApp opened with your order written out. Press send there to '
          'complete it. Cassia Seed will reply with the price and '
          'availability.',
      'واٹس ایپ آپ کے آرڈر کے ساتھ کھل گیا ہے۔ آرڈر مکمل کرنے کے لیے وہاں '
          'سینڈ دبائیں۔ کیسیا سیڈ قیمت اور دستیابی کے ساتھ جواب دے گا۔');
  String orderReceivedBody(String customerPhone, String companyPhone) => _t(
      'WhatsApp could not be opened on this phone, but your order reached '
          'Cassia Seed. They will contact you on $customerPhone. You can '
          'also call $companyPhone.',
      'اس فون پر واٹس ایپ نہیں کھل سکا، لیکن آپ کا آرڈر کیسیا سیڈ تک پہنچ '
          'گیا ہے۔ وہ آپ سے ${_ltr(customerPhone)} پر رابطہ کریں گے۔ آپ '
          '${_ltr(companyPhone)} پر کال بھی کر سکتے ہیں۔');
  String orderNo(String ref) =>
      _t('Order no: $ref', 'آرڈر نمبر: ${_ltr(ref)}');
  String get openWhatsAppAgain =>
      _t('Open WhatsApp again', 'واٹس ایپ دوبارہ کھولیں');
  String get tryWhatsAppAgain =>
      _t('Try WhatsApp again', 'واٹس ایپ دوبارہ آزمائیں');

  // --------------------------------------------------------- crop doctor

  String get doctorHeader => _t(
      'Your AI plant doctor. Add 2–3 clear photos for the best accuracy.',
      'آپ کا اے آئی پودوں کا ڈاکٹر۔ بہترین نتیجے کے لیے 2–3 صاف تصاویر '
          'شامل کریں۔');
  String get stepPhotos => _t('Photos', 'تصاویر');
  String get stepDetails => _t('Details', 'تفصیل');
  String get stepDiagnosis => _t('Diagnosis', 'تشخیص');

  String get whichCrop => _t('Which crop?', 'کون سی فصل؟');

  /// The crops in the "Which crop?" list, as (value, name) pairs. The value
  /// is what is sent for diagnosis: always English, whatever the language.
  List<(String, String)> get doctorCrops => [
        ('Okra', _t('Okra', 'بھنڈی')),
        ('Tomato', _t('Tomato', 'ٹماٹر')),
        ('Hot pepper / Chilli', _t('Hot pepper / Chilli', 'مرچ')),
        ('Bitter gourd', _t('Bitter gourd', 'کریلا')),
        ('Brinjal', _t('Brinjal', 'بینگن')),
        ('Cucumber', _t('Cucumber', 'کھیرا')),
        ('Gourd', _t('Gourd', 'کدو')),
        ('Paddy / Rice', _t('Paddy / Rice', 'دھان / چاول')),
        ('Peas', _t('Peas', 'مٹر')),
        ('Carrot', _t('Carrot', 'گاجر')),
        ('Other', _t('Other', 'دیگر')),
      ];

  /// The one-tap crops above the list, as (emoji, value, short name). Each
  /// value is one of [doctorCrops].
  List<(String, String, String)> get doctorCropChips => [
        ('🍅', 'Tomato', _t('Tomato', 'ٹماٹر')),
        ('🌶️', 'Hot pepper / Chilli', _t('Hot pepper', 'مرچ')),
        ('🌿', 'Okra', _t('Okra', 'بھنڈی')),
        ('🥒', 'Cucumber', _t('Cucumber', 'کھیرا')),
        ('🍆', 'Brinjal', _t('Brinjal', 'بینگن')),
        ('🫛', 'Peas', _t('Peas', 'مٹر')),
        ('🥕', 'Carrot', _t('Carrot', 'گاجر')),
        ('🌾', 'Paddy / Rice', _t('Paddy', 'دھان')),
        ('🥬', 'Gourd', _t('Gourd', 'کدو')),
      ];

  String get growthStage => _t('Growth stage?', 'بڑھوتری کا مرحلہ؟');

  /// The growth stages, as (value, name) pairs; the value is always English.
  List<(String, String)> get growthStages => [
        ('Seedling', _t('Seedling', 'نئے پودے')),
        ('Vegetative', _t('Vegetative', 'نشوونما')),
        ('Flowering', _t('Flowering', 'پھول')),
        ('Fruiting', _t('Fruiting', 'پھل')),
        ('Harvest', _t('Harvest', 'کٹائی')),
      ];

  String get sinceHowManyDays => _t(
      'Since how many days? (optional)', 'کتنے دنوں سے؟ (اختیاری)');
  String get doctorNotesHint => _t(
      'Recent sprays, irrigation, weather… (optional)',
      'حالیہ سپرے، آبپاشی، موسم… (اختیاری)');

  /// What each of the three photo slots is for.
  List<String> get photoSlots => [
        _t('Affected leaf', 'متاثرہ پتا'),
        _t('Underside', 'پتے کا نچلا حصہ'),
        _t('Whole plant', 'پورا پودا'),
      ];
  String get removePhoto => _t('Remove photo', 'تصویر ہٹائیں');
  String photoLimit(int max) => _t(
      'You can add up to $max photos.', 'آپ زیادہ سے زیادہ $max تصاویر لگا سکتے ہیں۔');
  String get couldNotAddPhoto => _t(
      'Could not add the photo. Please try again.',
      'تصویر شامل نہیں ہو سکی۔ دوبارہ کوشش کریں۔');

  String get takePhoto => _t('Take Photo', 'تصویر کھینچیں');
  String get chooseFromGallery => _t('Choose from Gallery', 'گیلری سے چنیں');
  String get diagnoseMyCrop =>
      _t('Diagnose My Crop', 'میری فصل کی تشخیص کریں');
  String get analysing => _t('Analysing…', 'تجزیہ ہو رہا ہے…');

  // The diagnosis cards, in the order they are shown.
  String get whatISee => _t('What I see', 'جو نظر آ رہا ہے');
  String get mostLikelyProblem =>
      _t('Most likely problem', 'سب سے ممکنہ مسئلہ');
  String get otherPossibilities => _t('Other possibilities', 'دیگر امکانات');
  String get whatIsLacking =>
      _t('What is lacking / the cause', 'کس چیز کی کمی ہے / وجہ');
  String get treatmentSteps => _t('Treatment steps', 'علاج کے اقدامات');
  String get preventionNextTime =>
      _t('Prevention for next time', 'آئندہ کے لیے بچاؤ');
  String get forSurerDiagnosis =>
      _t('For a surer diagnosis', 'مزید یقینی تشخیص کے لیے');

  /// [percent] is how sure the diagnosis is, 0–100.
  String confidencePercent(int percent) =>
      _t('Confidence: $percent%', 'اعتماد: ${_ltr('$percent%')}');
  String get looksHealthy => _t('Looks healthy', 'صحت مند لگ رہا ہے');
  String get notSure => _t('Not sure yet', 'ابھی یقینی نہیں');

  String get notACropTitle =>
      _t('That doesn\'t look like a crop', 'یہ فصل کی تصویر نہیں لگتی');
  String get notACropBody => _t(
      'Please take a clear photo of the plant or affected leaf.',
      'براہِ کرم پودے یا متاثرہ پتے کی صاف تصویر لیں۔');

  String get copy => _t('Copy', 'کاپی');
  String get diagnosisCopied => _t('Diagnosis copied', 'تشخیص کاپی ہو گئی');
  String get askFollowUp => _t('Ask follow-up', 'مزید پوچھیں');

  /// How the follow-up chat opens: the diagnosis, and Cassia's reply to it.
  String followUpIntro(String diagnosis) => _t(
      'My crop diagnosis from Crop Doctor:\n$diagnosis',
      'کراپ ڈاکٹر سے میری فصل کی تشخیص:\n$diagnosis');
  String get followUpReply => _t(
      'Understood. What would you like to know?',
      'سمجھ گیا۔ آپ کیا جاننا چاہتے ہیں؟');

  String get recentScans => _t('Recent scans', 'حالیہ اسکین');
  String get cropFallback => _t('Crop', 'فصل');

  String get doctorNote => _t(
      'AI advice is a guide, not a lab test. Before spraying any chemical, '
          'confirm with a local agriculture expert or dealer.',
      'اے آئی کا مشورہ صرف رہنمائی ہے، لیبارٹری ٹیسٹ نہیں۔ کوئی بھی دوا '
          'سپرے کرنے سے پہلے مقامی زرعی ماہر یا ڈیلر سے تصدیق کریں۔');

  String get cropDoctorNotSetUp =>
      _t('Crop Doctor not set up yet', 'کراپ ڈاکٹر ابھی شروع نہیں ہوا');
  String get diagnosisFailed => _t('Diagnosis failed', 'تشخیص نہیں ہو سکی');

  // ---------------------------------------------------------- ask cassia

  String get newChat => _t('New chat', 'نئی گفتگو');
  String askingAbout(String name) =>
      _t('Asking about $name', '${data(name)} کے بارے میں سوال');

  /// The name Cassia's messages are signed with.
  String get cassiaName => _t('Cassia', 'کیسیا');

  /// Cassia's greeting, shown as the first message of every chat.
  String get cassiaWelcome => _t(
      'Assalam o Alaikum! I am Cassia \u{1F331} Ask me anything about your '
          'crop.',
      'السلام علیکم! میں کیسیا ہوں \u{1F331} اپنی فصل کے بارے میں کچھ بھی '
          'پوچھیں۔');
  String cassiaWelcomeAbout(String name) => _t(
      'Assalam o Alaikum! I am Cassia \u{1F331} Ask me anything about $name.',
      'السلام علیکم! میں کیسیا ہوں \u{1F331} ${data(name)} کے بارے میں کچھ '
          'بھی پوچھیں۔');

  String get askVarietyIntro => _t(
      'Get growing tips, spacing, season and care advice for this variety.',
      'اس قسم کی کاشت، فاصلے، موسم اور دیکھ بھال کے بارے میں مشورہ لیں۔');
  String get askGeneralIntro => _t(
      'Ask about sowing time, spacing, fertiliser, irrigation, pests, or our '
          'seeds.',
      'بوائی کے وقت، فاصلے، کھاد، آبپاشی، کیڑوں یا ہمارے بیجوں کے بارے میں '
          'پوچھیں۔');

  /// Ready-made questions for a chat opened from a product page.
  List<AskSuggestion> get varietySuggestions => [
        (
          label: _t('Sowing time', 'کاشت کا وقت'),
          question:
              _t('When is the best sowing time?', 'کاشت کا بہترین وقت کیا ہے؟'),
        ),
        (
          label: _t('Spacing & seed rate', 'فاصلہ اور بیج کی مقدار'),
          question: _t('What spacing and seed rate should I use?',
              'پودوں کا فاصلہ اور بیج کی مقدار کتنی رکھیں؟'),
        ),
        (
          label: _t('Water & fertiliser', 'پانی اور کھاد'),
          question: _t('How much water and fertiliser does it need?',
              'اسے کتنا پانی اور کھاد چاہیے؟'),
        ),
        (
          label: _t('Diseases', 'بیماریاں'),
          question: _t('Which diseases should I watch for?',
              'کن بیماریوں کا خیال رکھنا چاہیے؟'),
        ),
      ];

  /// Ready-made questions for a chat opened from the tab.
  List<AskSuggestion> get generalSuggestions => [
        (
          label: _t('Okra sowing time', 'بھنڈی کی بوائی کا وقت'),
          question: _t('Best sowing time for okra in Sindh?',
              'سندھ میں بھنڈی کی بوائی کا بہترین وقت کیا ہے؟'),
        ),
        (
          label: _t('Tomato cracking', 'ٹماٹر کا پھٹنا'),
          question: _t('Tomato fruit cracking, what to do?',
              'ٹماٹر کا پھل پھٹ رہا ہے، کیا کروں؟'),
        ),
        (
          label: _t('Chilli leaf curl', 'مرچ کا پتا مروڑ'),
          question: _t('Leaf curl in chilli, how to control?',
              'مرچ میں پتا مروڑ، کیسے قابو کریں؟'),
        ),
      ];

  String get aiDisclaimer => _t(
      'AI answers can be wrong. Confirm with a local agriculture expert '
          'before applying anything.',
      'اے آئی کے جوابات غلط ہو سکتے ہیں۔ کچھ بھی استعمال کرنے سے پہلے '
          'مقامی ماہرِ زراعت سے تصدیق کریں۔');
  String get thinking => _t('Thinking…', 'سوچ رہا ہے…');
  String get askCassiaNotSetUp =>
      _t('Ask Cassia not set up yet', 'کیسیا اے آئی ابھی شروع نہیں ہوا');
  String get couldNotGetAnswer =>
      _t('Could not get an answer', 'جواب نہیں مل سکا');
  String get typeYourQuestion =>
      _t('Type your question…', 'اپنا سوال لکھیں…');
  String get send => _t('Send', 'بھیجیں');

  // ---------------------------------------------------------------- more

  String get more => _t('More', 'مزید');
  String get settings => _t('Settings', 'ترتیبات');
  String get language => _t('Language', 'زبان');
  String get appearance => _t('Appearance', 'ظاہری شکل');
  String get themeSystem => _t('Auto', 'خودکار');
  String get themeLight => _t('Light', 'روشن');
  String get themeDark => _t('Dark', 'تاریک');
  String get contact => _t('Contact', 'رابطہ');
  String get whatsApp => _t('WhatsApp', 'واٹس ایپ');
  String get call => _t('Call', 'کال');
  String get landline => _t('Landline', 'لینڈ لائن');
  String get email => _t('Email', 'ای میل');
  String get online => _t('Online', 'آن لائن');
  String get website => _t('Website', 'ویب سائٹ');
  String get facebook => _t('Facebook', 'فیس بک');
  String get instagram => _t('Instagram', 'انسٹاگرام');
  String get followUs => _t('Follow us', 'ہمیں فالو کریں');
  String get address => _t('Address', 'پتہ');

  // -------------------------------------------- accounts (dealer + farmer)

  // The two cards at the top of Home.
  String get forDealers => _t('FOR DEALERS', 'ڈیلرز کے لیے');
  String get forFarmers => _t('FOR FARMERS', 'کسانوں کے لیے');
  String get dealership => _t('Dealership', 'ڈیلرشپ');
  String get dealershipSub =>
      _t('Ledger · Balance · Awards', 'کھاتہ · بقایا · ایوارڈز');
  String get farmerLogin => _t('Farmer Login', 'کسان لاگ اِن');
  String get farmerLoginSub =>
      _t('Sign in or create account', 'لاگ اِن کریں یا نیا اکاؤنٹ بنائیں');
  String get myFarmerAccount => _t('My Farmer Account', 'میرا کسان اکاؤنٹ');
  String get viewDashboard => _t('View your dashboard', 'اپنا ڈیش بورڈ دیکھیں');

  // Dealer portal.
  String get dealerPortal => _t('DEALER PORTAL', 'ڈیلر پورٹل');
  String get cassiaDealership => _t('Cassia Dealership', 'کیسیا ڈیلرشپ');
  String get dealershipTagline => _t(
      'Your account, ledger and rewards in one place.',
      'آپ کا اکاؤنٹ، کھاتہ اور انعامات ایک ہی جگہ۔');
  String get signInLabel => _t('Sign in', 'لاگ اِن');
  String get applyAsDealer =>
      _t('Apply as dealer', 'ڈیلر کے لیے درخواست دیں');
  String get welcomeBack => _t('Welcome back', 'خوش آمدید');
  String get signInDealerAccount => _t(
      'Sign in to your dealer account.',
      'اپنے ڈیلر اکاؤنٹ میں لاگ اِن کریں۔');
  String get mobileNumber => _t('Mobile number', 'موبائل نمبر');
  String get mobileHint => _ltr('03XX XXXXXXX');
  String get password => _t('Password', 'پاس ورڈ');
  String get yourPassword => _t('Your password', 'آپ کا پاس ورڈ');
  String get notDealerYet => _t('Not a dealer yet?', 'ابھی ڈیلر نہیں ہیں؟');
  String get applyNow => _t('Apply now', 'ابھی درخواست دیں');
  String get secureAccessDealers => _t(
      'Secure access for Cassia Seed authorized dealers',
      'کیسیا سیڈ کے مجاز ڈیلرز کے لیے محفوظ رسائی');
  String get backToFarmerApp =>
      _t('Back to farmer app', 'کسان ایپ پر واپس');
  String get createYourAccount =>
      _t('Create your account', 'اپنا اکاؤنٹ بنائیں');
  String get dealerStep1 => _t('Step 1 of 2 · Your sign-in details',
      'مرحلہ 1 از 2 · لاگ اِن کی تفصیل');
  String get dealerStep2 => _t('Step 2 of 2 · Tell us about your shop',
      'مرحلہ 2 از 2 · اپنی دکان کے بارے میں بتائیں');
  String get ownerName => _t('Owner name', 'مالک کا نام');
  String get fullName => _t('Full name', 'پورا نام');
  String get atLeast8 => _t('At least 8 characters', 'کم از کم 8 حروف');
  String get confirmPassword =>
      _t('Confirm password', 'پاس ورڈ دوبارہ لکھیں');
  String get repeatPassword => _t('Repeat password', 'پاس ورڈ دہرائیں');
  String get alreadyDealer => _t('Already a dealer?', 'پہلے سے ڈیلر ہیں؟');
  String get businessName =>
      _t('Business / shop name', 'کاروبار / دکان کا نام');
  String get city => _t('City', 'شہر');
  String get districtLabel => _t('District', 'ضلع');
  String get shopAddress => _t('Shop address', 'دکان کا پتہ');
  String get productsYouSell =>
      _t('Products you sell', 'آپ کیا فروخت کرتے ہیں');
  String get notesOptional => _t('Notes (optional)', 'نوٹس (اختیاری)');
  String get submitApplication =>
      _t('Submit application', 'درخواست جمع کرائیں');

  // Dealer dashboard.
  String get dealerDashboard => _t('Dealer dashboard', 'ڈیلر ڈیش بورڈ');
  String get applicationReceivedTitle =>
      _t('Application received', 'درخواست موصول ہو گئی');
  String get applicationReceivedBody => _t(
      'Thank you. Our team will review your application and contact you on WhatsApp.',
      'شکریہ۔ ہماری ٹیم آپ کی درخواست کا جائزہ لے کر آپ سے واٹس ایپ پر رابطہ کرے گی۔');
  String get applicationPending =>
      _t('Your application is under review.', 'آپ کی درخواست زیرِ جائزہ ہے۔');
  String get applicationRejected => _t(
      'Your application was not approved. Please contact our team.',
      'آپ کی درخواست منظور نہیں ہوئی۔ براہِ کرم ہماری ٹیم سے رابطہ کریں۔');
  String get outstandingBalance => _t('Outstanding balance', 'بقایا رقم');
  String get totalPurchases => _t('Total purchases', 'کل خریداری');
  String get tierLabel => _t('Tier', 'درجہ');
  String get awardsLabel => _t('Awards', 'ایوارڈز');
  String get perksLabel => _t('Benefits', 'مراعات');
  String get requestStatement =>
      _t('Request statement on WhatsApp', 'واٹس ایپ پر گوشوارہ منگوائیں');
  String get noBalanceYet =>
      _t('No balance recorded yet.', 'ابھی کوئی بقایا درج نہیں۔');
  String get signOut => _t('Sign out', 'سائن آؤٹ');

  // Farmer login / register.
  String get growWithCassiaTitle =>
      _t('Grow with Cassia', 'کیسیا کے ساتھ اگائیں');
  String get loginLabel => _t('Login', 'لاگ اِن');
  String get registerLabel => _t('Register', 'رجسٹر کریں');
  String get loginFarmerHint => _t(
      'Login with your mobile number and secret number (PIN).',
      'اپنے موبائل نمبر اور خفیہ نمبر (پن) سے لاگ اِن کریں۔');
  String get secretNumberPin => _t('Secret number (PIN)', 'خفیہ نمبر (پن)');
  String get sixNumbers => _t('6 numbers', '6 نمبر');
  String get newFarmer => _t('New farmer?', 'نئے کسان؟');
  String get alreadyRegistered =>
      _t('Already registered?', 'پہلے سے رجسٹرڈ ہیں؟');
  String get accountProtectedPin => _t(
      'Your account is protected with your secret number',
      'آپ کا اکاؤنٹ آپ کے خفیہ نمبر سے محفوظ ہے');
  String get requiredLabel => _t('Required', 'ضروری');
  String get nextLabel => _t('Next', 'آگے');
  String get createAccount => _t('Create account', 'اکاؤنٹ بنائیں');
  String get whatIsYourName => _t('What is your name?', 'آپ کا نام کیا ہے؟');
  String get exampleName => _t('Example: Ali Khan', 'مثال: علی خان');
  String get whatIsYourMobile =>
      _t('What is your mobile number?', 'آپ کا موبائل نمبر کیا ہے؟');
  String get choosePin => _t(
      'Choose a 6-digit secret number (PIN)', '6 ہندسوں کا خفیہ نمبر (پن) چنیں');
  String get confirmPin =>
      _t('Confirm your secret number', 'اپنا خفیہ نمبر دوبارہ لکھیں');
  String get whichDistrict =>
      _t('Which district are you from?', 'آپ کس ضلع سے ہیں؟');
  String get whichVillage =>
      _t('Which village do you live in?', 'آپ کس گاؤں میں رہتے ہیں؟');
  String get whichCrops =>
      _t('Which crops do you grow?', 'آپ کون سی فصلیں اگاتے ہیں؟');
  String get optionalLabel => _t('Optional', 'اختیاری');

  // The farmer's own account page.
  String get myAccount => _t('My account', 'میرا اکاؤنٹ');
  String get myVillage => _t('Village', 'گاؤں');
  String get myDistrict => _t('District', 'ضلع');
  String get myCrops => _t('My crops', 'میری فصلیں');
  String get memberSince => _t('Member', 'رکن');

  // Validation and result messages.
  String get enterYourName =>
      _t('Please enter your name.', 'براہِ کرم اپنا نام درج کریں۔');
  String get enterValidMobile =>
      _t('Enter a valid mobile number.', 'درست موبائل نمبر درج کریں۔');
  String get pinMustBe6 => _t(
      'The secret number must be 6 digits.', 'خفیہ نمبر 6 ہندسوں کا ہونا چاہیے۔');
  String get pinsDontMatch =>
      _t('The secret numbers do not match.', 'خفیہ نمبر آپس میں نہیں ملتے۔');
  String get passwordTooShort => _t(
      'The password must be at least 8 characters.',
      'پاس ورڈ کم از کم 8 حروف کا ہونا چاہیے۔');
  String get passwordsDontMatch =>
      _t('The passwords do not match.', 'پاس ورڈ آپس میں نہیں ملتے۔');
  String get pickAtLeastOneCrop =>
      _t('Pick at least one crop.', 'کم از کم ایک فصل منتخب کریں۔');
  String get accountExistsError => _t(
      'An account with this mobile number already exists.',
      'اس موبائل نمبر سے اکاؤنٹ پہلے سے موجود ہے۔');
  String get wrongMobileOrPin => _t(
      'Wrong mobile number or secret number.',
      'موبائل نمبر یا خفیہ نمبر غلط ہے۔');
  String get wrongMobileOrPassword => _t(
      'Wrong mobile number or password.', 'موبائل نمبر یا پاس ورڈ غلط ہے۔');
  String get welcomeReady =>
      _t('Welcome! Your account is ready.', 'خوش آمدید! آپ کا اکاؤنٹ تیار ہے۔');
  String get signedOut => _t('Signed out.', 'سائن آؤٹ ہو گیا۔');

  /// How much space the name uses in a short greeting, e.g. "Hi, Ali".
  String hiName(String name) => _t('Hi, ', 'ہیلو، ') + name;
}

extension AppStringsContext on BuildContext {
  /// The app's text in the current language.
  AppStrings get s => AppStrings.of(this);
}
