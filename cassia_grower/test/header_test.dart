// Tests for the header above the tabs: the back button, the profile button,
// the light/dark switch and the language menu.

import 'package:cassia_grower/data/product_repository.dart';
import 'package:cassia_grower/main.dart';
import 'package:cassia_grower/models/product.dart';
import 'package:cassia_grower/screens/more_screen.dart';
import 'package:cassia_grower/screens/root_nav.dart';
import 'package:cassia_grower/state/app_settings.dart';
import 'package:cassia_grower/state/cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A catalog that needs no Firebase.
class _FakeCatalog extends ProductRepository {
  static const _products = [
    Product(id: 'tomato', name: 'Redo F1', crop: 'Tomato', cropKey: 'tomato'),
  ];

  @override
  Stream<List<Product>> watchProducts() => Stream.value(_products);

  @override
  Stream<Product?> watchProduct(String id) => Stream.value(_products.first);
}

Future<AppSettings> _open(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.en,
}) async {
  // Home has things that move for ever; with animations off (as a phone's
  // accessibility setting does) a test can wait for the screen to settle.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final settings = AppSettings()..setLanguage(language);
  await tester.pumpWidget(CassiaApp(
    settings: settings,
    cart: CartController(),
    home: RootNav(repository: _FakeCatalog()),
  ));
  await tester.pumpAndSettle();
  return settings;
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the header carries the motto under the logo', (tester) async {
    await _open(tester);

    expect(find.text('GROW WITH CASSIA 🌱'), findsOneWidget);
  });

  testWidgets('there is no back button on Home', (tester) async {
    await _open(tester);

    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('the back button retraces the tabs, all the way to Home',
      (tester) async {
    await _open(tester);

    await _tap(tester, find.text('Doctor'));
    expect(find.text('Which crop?'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await _tap(tester, find.text('Order'));
    expect(find.text('Which crop?'), findsNothing);

    // Back from Order is Crop Doctor, where the farmer came from…
    await _tap(tester, find.byTooltip('Back'));
    expect(find.text('Which crop?'), findsOneWidget);

    // …and back again is Home, where the button goes away.
    await _tap(tester, find.byTooltip('Back'));
    expect(find.text('Which crop?'), findsNothing);
    expect(find.text('Assalam o Alaikum 👋'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('tapping the tab that is already open adds nothing to go back to',
      (tester) async {
    await _open(tester);

    await _tap(tester, find.text('Doctor'));
    await _tap(tester, find.text('Doctor'));
    await _tap(tester, find.byTooltip('Back'));

    expect(find.byTooltip('Back'), findsNothing); // straight back on Home
  });

  testWidgets('in Urdu the back arrow points the other way', (tester) async {
    await _open(tester, language: AppLanguage.ur);

    await _tap(tester, find.text('ڈاکٹر'));

    expect(find.text('→'), findsOneWidget);
    expect(find.text('←'), findsNothing);
  });

  testWidgets('the profile button opens settings and support',
      (tester) async {
    await _open(tester);

    await _tap(tester, find.text('👤'));

    expect(find.byType(MoreScreen), findsOneWidget);
  });

  testWidgets('the round switch turns dark mode on and off', (tester) async {
    final settings = await _open(tester);

    await _tap(tester, find.byTooltip('Light / dark'));
    expect(settings.themeMode, ThemeMode.dark);

    await _tap(tester, find.byTooltip('Light / dark'));
    expect(settings.themeMode, ThemeMode.light);
  });

  testWidgets('the language button names the language and lists the choices',
      (tester) async {
    final settings = await _open(tester);

    expect(find.text('🌐 EN'), findsOneWidget);

    await _tap(tester, find.text('🌐 EN'));
    expect(find.text('English'), findsOneWidget);
    expect(find.text('اردو'), findsOneWidget);

    await _tap(tester, find.text('اردو'));
    expect(settings.language, AppLanguage.ur);
    expect(find.text('🌐 اردو'), findsOneWidget);
  });

  testWidgets('closing the language menu without choosing changes nothing',
      (tester) async {
    final settings = await _open(tester);

    await _tap(tester, find.text('🌐 EN'));
    await tester.tapAt(const Offset(10, 500)); // outside the menu
    await tester.pumpAndSettle();

    expect(settings.language, AppLanguage.en);
    expect(find.text('English'), findsNothing);
  });

  testWidgets('the header fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester);

    await _tap(tester, find.text('Doctor')); // back button showing too

    expect(tester.takeException(), isNull); // nothing overflows
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('🌐 EN'), findsOneWidget);
  });
}
