// Tests for the app-wide settings: language (English / Urdu, with
// right-to-left layout) and light / dark theme.

import 'package:cassia_grower/data/local_store.dart';
import 'package:cassia_grower/data/product_repository.dart';
import 'package:cassia_grower/l10n/app_strings.dart';
import 'package:cassia_grower/main.dart';
import 'package:cassia_grower/models/product.dart';
import 'package:cassia_grower/screens/more_screen.dart';
import 'package:cassia_grower/screens/root_nav.dart';
import 'package:cassia_grower/state/app_settings.dart';
import 'package:cassia_grower/state/cart_controller.dart';
import 'package:cassia_grower/theme/app_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A catalog that needs no Firebase.
class _FakeCatalog extends ProductRepository {
  static const _products = [
    Product(id: 'tomato', name: 'Redo F1', crop: 'Tomato', cropKey: 'tomato'),
    Product(
        id: 'carrot',
        name: 'Carrot Red',
        crop: 'Carrot',
        cropKey: 'carrot',
        available: false),
  ];

  @override
  Stream<List<Product>> watchProducts() => Stream.value(_products);

  @override
  Stream<Product?> watchProduct(String id) =>
      Stream.value(_products.firstWhere((p) => p.id == id));
}

Widget _app(AppSettings settings, Widget home) {
  return CassiaApp(settings: settings, cart: CartController(), home: home);
}

/// Home has things that move for ever (the sliding crop band, the changing
/// banner). Turning animations off, as a phone's accessibility setting does,
/// lets a test wait for the screen to settle.
void _stillScreen(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  group('AppSettings', () {
    test('starts in English, following the phone\'s light or dark setting',
        () {
      final settings = AppSettings();

      expect(settings.language, AppLanguage.en);
      expect(settings.themeMode, ThemeMode.system);
    });

    test('starts in Urdu on a phone that is set to Urdu', () {
      final settings = AppSettings(deviceLocale: const Locale('ur', 'PK'));

      expect(settings.language, AppLanguage.ur);
    });

    test('remembers the farmer\'s choices across restarts', () {
      final store = MemoryStore();
      AppSettings(store: store)
        ..setLanguage(AppLanguage.ur)
        ..setThemeMode(ThemeMode.dark);

      final restarted = AppSettings(store: store);

      expect(restarted.language, AppLanguage.ur);
      expect(restarted.themeMode, ThemeMode.dark);
    });

    test('a language the farmer chose wins over the phone\'s language', () {
      const urduPhone = Locale('ur');
      final store = MemoryStore();
      AppSettings(store: store, deviceLocale: urduPhone)
          .setLanguage(AppLanguage.en);

      final restarted = AppSettings(store: store, deviceLocale: urduPhone);

      expect(restarted.language, AppLanguage.en);
    });

    test('toggling switches between the two languages', () {
      final settings = AppSettings();

      settings.toggleLanguage();
      expect(settings.language, AppLanguage.ur);

      settings.toggleLanguage();
      expect(settings.language, AppLanguage.en);
    });
  });

  group('Language', () {
    testWidgets('choosing Urdu translates the app and lays it out right to '
        'left', (tester) async {
      final settings = AppSettings();
      await tester.pumpWidget(_app(settings, const MoreScreen()));

      expect(find.text('Contact'), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(MoreScreen))),
          TextDirection.ltr);

      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();

      expect(settings.language, AppLanguage.ur);
      expect(find.text('رابطہ'), findsOneWidget);
      expect(find.text('Contact'), findsNothing);
      expect(Directionality.of(tester.element(find.byType(MoreScreen))),
          TextDirection.rtl);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Contact'), findsOneWidget);
    });

    testWidgets('the tabs are named in the chosen language', (tester) async {
      _stillScreen(tester);
      final settings = AppSettings()..setLanguage(AppLanguage.ur);
      await tester
          .pumpWidget(_app(settings, RootNav(repository: _FakeCatalog())));
      await tester.pumpAndSettle();

      expect(find.text('دکان'), findsWidgets); // Shop
      expect(find.text('آرڈر'), findsWidgets); // Order
      expect(find.text('Shop'), findsNothing);
    });

    testWidgets('the header switches the whole app to Urdu and back',
        (tester) async {
      _stillScreen(tester);
      final settings = AppSettings();
      await tester
          .pumpWidget(_app(settings, RootNav(repository: _FakeCatalog())));
      await tester.pumpAndSettle();

      expect(find.text('Assalam o Alaikum 👋'), findsOneWidget);

      // The header's button names the language the app is in, and opens a
      // menu of the languages to choose from.
      await tester.tap(find.text('🌐 EN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();

      expect(settings.language, AppLanguage.ur);
      expect(find.text('السلام علیکم 👋'), findsOneWidget);

      await tester.tap(find.text('🌐 اردو'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Assalam o Alaikum 👋'), findsOneWidget);
    });

    testWidgets('the Order tab is the cart, and counts what is in it',
        (tester) async {
      _stillScreen(tester);
      final cart = CartController()
        ..add(const Product(
            id: 'tomato', name: 'Redo F1', crop: 'Tomato', cropKey: 'tomato'));
      await tester.pumpWidget(CassiaApp(
        settings: AppSettings(),
        cart: cart,
        home: RootNav(repository: _FakeCatalog()),
      ));
      await tester.pumpAndSettle();

      // The badge on the Order tab.
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Order'));
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('1 variety • 1 pack'), findsOneWidget);
    });

    testWidgets('a not-available variety is labelled in Urdu too',
        (tester) async {
      _stillScreen(tester);
      final settings = AppSettings()..setLanguage(AppLanguage.ur);
      await tester
          .pumpWidget(_app(settings, RootNav(repository: _FakeCatalog())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('دکان').last);
      await tester.pumpAndSettle();

      expect(find.text('Carrot Red'), findsOneWidget);
      // On the stamp over the photo, and on the pill under the name.
      expect(find.text('ابھی دستیاب نہیں'), findsNWidgets(2));
      expect(find.text('Not available yet'), findsNothing);
    });

    test('every string has its own Urdu wording', () {
      // Spot-check across screens that Urdu isn't falling back to English.
      const en = AppStrings.en;
      const ur = AppStrings.ur;

      expect(ur.addToOrder(2), isNot(en.addToOrder(2)));
      expect(ur.takePhoto, isNot(en.takePhoto));
      expect(ur.sendOrderOnWhatsApp, isNot(en.sendOrderOnWhatsApp));
      expect(ur.cartSummary(2, 3), isNot(en.cartSummary(2, 3)));
      expect(ur.generalSuggestions, hasLength(en.generalSuggestions.length));
      expect(en.languageCode, 'en');
      expect(ur.languageCode, 'ur');
    });
  });

  group('Theme', () {
    testWidgets('choosing Dark repaints the app with the dark colours',
        (tester) async {
      final settings = AppSettings();
      await tester.pumpWidget(_app(settings, const MoreScreen()));

      BuildContext context() => tester.element(find.byType(MoreScreen));
      expect(Theme.of(context()).brightness, Brightness.light);
      expect(context().colors.background, AppPalette.light.background);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.dark);
      expect(Theme.of(context()).brightness, Brightness.dark);
      expect(context().colors.background, AppPalette.dark.background);
      expect(context().colors.ink, AppPalette.dark.ink);
    });

    testWidgets('Auto follows the phone\'s dark mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(_app(AppSettings(), const MoreScreen()));

      final context = tester.element(find.byType(MoreScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });
}
