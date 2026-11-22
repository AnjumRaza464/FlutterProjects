// Tests for the product sheet — the page that slides up when a variety is
// tapped — and for favourites. Driven by a stand-in catalog and a fake AI
// service, so no Firebase is needed.
//
// The rule that matters most: a variety that is not available can be read
// about, asked about and saved, but never ordered.

import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:cassia_grower/data/local_store.dart';
import 'package:cassia_grower/data/pack_photos.dart';
import 'package:cassia_grower/data/product_repository.dart';
import 'package:cassia_grower/main.dart';
import 'package:cassia_grower/models/chat_message.dart';
import 'package:cassia_grower/models/product.dart';
import 'package:cassia_grower/screens/ask_cassia_screen.dart';
import 'package:cassia_grower/screens/product_sheet.dart';
import 'package:cassia_grower/services/ai_failure.dart';
import 'package:cassia_grower/services/ask_cassia_service.dart';
import 'package:cassia_grower/state/app_settings.dart';
import 'package:cassia_grower/state/cart_controller.dart';
import 'package:cassia_grower/state/favourites.dart';
import 'package:cassia_grower/widgets/not_available_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _redo = Product(
  id: 'redo',
  name: 'Redo F1',
  crop: 'Tomato',
  cropKey: 'tomato',
  type: 'Hybrid',
  packSize: '10 g',
);
const _soon = Product(
  id: 'soon',
  name: 'Soon F1',
  crop: 'Tomato',
  cropKey: 'tomato',
  available: false,
);

/// The same variety after an admin marks it not available.
Product _withdrawn(Product p) => Product(
      id: p.id,
      name: p.name,
      crop: p.crop,
      cropKey: p.cropKey,
      available: false,
    );

/// A catalog of one variety that the test can change while its sheet is open.
class _Catalog extends ProductRepository {
  final _changes = StreamController<Product?>.broadcast();

  void change(Product product) => _changes.add(product);

  @override
  Stream<Product?> watchProduct(String id) => _changes.stream;
}

/// Records what the crop guide asks for and answers (or fails) on demand.
class _FakeAi extends AskCassiaService {
  final List<List<ChatMessage>> histories = [];
  String? language;
  Product? product;
  AiFailure? failWith;

  @override
  Future<String> ask(
    List<ChatMessage> history, {
    String language = 'en',
    Product? product,
  }) async {
    histories.add(history);
    this.language = language;
    this.product = product;
    final failure = failWith;
    if (failure != null) throw failure;
    return 'Sow in early spring.';
  }
}

/// Opens [product]'s sheet over a blank page, on a screen tall enough to
/// show all of it, with animations off so the swaying pack lets the screen
/// settle.
Future<_Catalog> _open(
  WidgetTester tester,
  Product product, {
  CartController? cart,
  FavouritesController? favourites,
  AskCassiaService? ai,
  AppLanguage language = AppLanguage.en,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view
    ..physicalSize = const Size(480, 1400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final catalog = _Catalog();
  await tester.pumpWidget(CassiaApp(
    settings: AppSettings()..setLanguage(language),
    cart: cart ?? CartController(),
    favourites: favourites,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showProductSheet(context, product,
              repository: catalog, askService: ai),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return catalog;
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  group('Details', () {
    testWidgets('shows the variety, its facts and that it can be ordered',
        (tester) async {
      await _open(tester, _redo);

      expect(find.text('Redo F1'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Cassia'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);
      expect(find.text('10 g'), findsOneWidget);
      expect(find.text('On request'), findsOneWidget);
      expect(find.text('Add 1 to Order'), findsOneWidget);
    });

    testWidgets('a sub-brand is shown as the brand', (tester) async {
      await _open(
        tester,
        const Product(
          id: 'metro',
          name: 'Metro F1',
          crop: 'Tomato',
          cropKey: 'tomato',
          brandLine: 'Malapine',
        ),
      );

      expect(find.text('Malapine'), findsOneWidget);
      expect(find.text('Cassia'), findsNothing);
    });

    testWidgets('a pack with no size on record says to ask the company',
        (tester) async {
      await _open(
        tester,
        const Product(
            id: 'mala', name: 'Mala F1', crop: 'Okra', cropKey: 'okra'),
      );

      expect(find.text('Ask company'), findsOneWidget);
    });

    testWidgets('has the three photos: front, close-up and showcase',
        (tester) async {
      await _open(tester, _redo);

      expect(find.text('Front'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Close-up'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Showcase'), findsOneWidget);
    });

    testWidgets('the photos can be changed with a mouse or by their dots',
        (tester) async {
      await _open(tester, _redo);

      // Dragged with a mouse, as in a desktop browser.
      await tester.drag(find.byType(PageView), const Offset(-400, 0),
          kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(find.text('Close-up'), findsOneWidget);

      // The dots sit just under the photos; the last one is the showcase.
      final photos = tester.getRect(find.byType(PageView));
      await tester.tapAt(Offset(photos.center.dx + 26, photos.bottom + 11));
      await tester.pumpAndSettle();
      expect(find.text('Showcase'), findsOneWidget);
    });

    testWidgets('the ✕ closes the sheet', (tester) async {
      await _open(tester, _redo);

      await _tap(tester, find.byTooltip('Close'));

      expect(find.byType(ProductSheet), findsNothing);
    });

    testWidgets('in Urdu the sheet is in Urdu', (tester) async {
      await _open(tester, _redo, language: AppLanguage.ur);

      expect(find.text('تفصیلات'), findsOneWidget); // Details
      expect(find.text('دستیاب'), findsOneWidget); // Available
      expect(find.text('Details'), findsNothing);
    });
  });

  group('Features', () {
    testWidgets('lists what Cassia says about the variety', (tester) async {
      await _open(
        tester,
        const Product(
          id: 'queen',
          name: 'Queen F1',
          crop: 'Sponge gourd',
          cropKey: 'sponge_gourd',
          printedInfo: 'Germination 90%',
          features: ['Uniform germination', 'Green and glossy color'],
        ),
      );

      await _tap(tester, find.text('Features'));

      expect(find.text('Printed on pack'), findsOneWidget);
      expect(find.text('Germination 90%'), findsOneWidget);
      expect(find.text('✅ Uniform germination'), findsOneWidget);
      expect(find.text('✅ Green and glossy color'), findsOneWidget);
      // The facts belong to the other tab.
      expect(find.text('On request'), findsNothing);
    });

    testWidgets('with none on record, says the Cassia team will add them',
        (tester) async {
      await _open(tester, _redo);

      await _tap(tester, find.text('Features'));

      expect(find.textContaining('will be added by the Cassia team'),
          findsOneWidget);
    });

    testWidgets('the crop guide is general advice about the crop, and says so',
        (tester) async {
      final ai = _FakeAi();
      await _open(tester, _redo, ai: ai);
      await _tap(tester, find.text('Features'));

      await _tap(tester, find.text('🌿 General crop guide (AI)'));

      expect(
          find.text('Sow in early spring.\n\n'
              '(General crop guidance, not official Cassia variety data.)'),
          findsOneWidget);
      final question = ai.histories.single.single.text;
      expect(question, contains('growing guide for Tomato'));
      expect(question, contains('do not claim variety traits'));
      // Asked about the crop only: the variety is not sent.
      expect(ai.product, isNull);
      expect(question, isNot(contains('Redo')));
    });

    testWidgets('the crop guide is asked for in the app\'s language',
        (tester) async {
      final ai = _FakeAi();
      await _open(tester, _redo, ai: ai, language: AppLanguage.ur);
      await _tap(tester, find.text('خصوصیات'));

      await _tap(tester, find.text('🌿 فصل کی عمومی رہنمائی (اے آئی)'));

      expect(ai.language, 'ur');
    });

    testWidgets('says so when the AI has not been switched on',
        (tester) async {
      final ai = _FakeAi()..failWith = const AiFailure(AiFailureKind.notSetUp);
      await _open(tester, _redo, ai: ai);
      await _tap(tester, find.text('Features'));

      await _tap(tester, find.text('🌿 General crop guide (AI)'));

      expect(
          find.text('This feature has not been switched on yet. '
              'Please try again later.'),
          findsOneWidget);
    });
  });

  group('Ordering', () {
    testWidgets('adds the chosen number of packs and closes', (tester) async {
      final cart = CartController();
      await _open(tester, _redo, cart: cart);

      await tester.tap(find.byTooltip('Increase'));
      await tester.tap(find.byTooltip('Increase'));
      await tester.pump();
      expect(find.text('Add 3 to Order'), findsOneWidget);

      await tester.tap(find.byTooltip('Decrease'));
      await tester.pump();
      await tester.tap(find.text('Add 2 to Order'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(cart.quantityOf('redo'), 2);
      expect(find.text('2 × Redo F1 added to your order ✓'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(ProductSheet), findsNothing);
      // The message goes away by itself.
      expect(find.text('2 × Redo F1 added to your order ✓'), findsNothing);
    });

    testWidgets('never goes below one pack', (tester) async {
      await _open(tester, _redo);

      await tester.tap(find.byTooltip('Decrease'));
      await tester.pump();

      expect(find.text('Add 1 to Order'), findsOneWidget);
    });

    testWidgets('adding again adds to what is already in the order',
        (tester) async {
      final cart = CartController()..add(_redo, quantity: 4);
      await _open(tester, _redo, cart: cart);

      await _tap(tester, find.text('Add 1 to Order'));

      expect(cart.quantityOf('redo'), 5);
    });

    testWidgets('a not-available variety cannot be ordered', (tester) async {
      final cart = CartController();
      await _open(tester, _soon, cart: cart);

      // Stamped on the photo, labelled under the name.
      expect(find.byType(NotAvailableBadge), findsOneWidget);
      expect(find.text('Not available yet'), findsNWidgets(2));
      expect(find.text('Available'), findsNothing);
      // Nothing to choose, nothing to add.
      expect(find.text('Quantity (packs)'), findsNothing);
      expect(find.textContaining('to Order'), findsNothing);

      await _tap(tester, find.text('Coming Soon'));

      expect(cart.isEmpty, isTrue);
      expect(find.byType(ProductSheet), findsOneWidget);
    });

    testWidgets(
        'if it stops being available while open, ordering is switched off',
        (tester) async {
      final cart = CartController();
      final catalog = await _open(tester, _redo, cart: cart);
      expect(find.text('Add 1 to Order'), findsOneWidget);

      catalog.change(_withdrawn(_redo));
      await tester.pumpAndSettle();

      expect(find.text('Add 1 to Order'), findsNothing);
      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.byType(NotAvailableBadge), findsOneWidget);
      expect(find.text('Quantity (packs)'), findsNothing);
    });
  });

  group('Ask Cassia about this seed', () {
    testWidgets('opens the chat about the variety, with a first question',
        (tester) async {
      await _open(tester, _soon);

      await tester.tap(find.text('Ask Cassia about this seed'));
      // The sheet slides away and the chat slides in.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final chat =
          tester.widget<AskCassiaScreen>(find.byType(AskCassiaScreen));
      expect(find.byType(ProductSheet), findsNothing);
      expect(chat.product?.id, 'soon');
      expect(
          chat.initialQuestion,
          'Tell me about growing Tomato (Soon F1): sowing time, spacing, '
          'fertiliser and common problems in Pakistan.');
    });
  });

  group('Favourites', () {
    testWidgets('saving and un-saving a variety', (tester) async {
      final favourites = FavouritesController();
      await _open(tester, _redo, favourites: favourites);

      await tester.tap(find.text('♡ Save to favourites'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(favourites.contains('redo'), isTrue);
      expect(find.text('♥ Saved'), findsOneWidget);
      expect(find.text('Saved to favourites'), findsOneWidget);

      await _tap(tester, find.text('♥ Saved'));

      expect(favourites.contains('redo'), isFalse);
      expect(find.text('♡ Save to favourites'), findsOneWidget);
    });

    testWidgets('a not-available variety can be saved, but not ordered',
        (tester) async {
      final cart = CartController();
      final favourites = FavouritesController();
      await _open(tester, _soon, cart: cart, favourites: favourites);

      await _tap(tester, find.text('♡ Save to favourites'));

      expect(favourites.contains('soon'), isTrue);
      expect(cart.isEmpty, isTrue);
    });

    test('are remembered across restarts, in the order they were saved', () {
      final store = MemoryStore();
      FavouritesController(store: store)
        ..toggle('redo')
        ..toggle('queen')
        ..toggle('rani')
        ..toggle('queen'); // saved, then taken out again

      final restarted = FavouritesController(store: store);

      expect(restarted.ids, ['redo', 'rani']);
      expect(restarted.contains('queen'), isFalse);
    });

    test('something unreadable on the phone is dropped, not a crash', () {
      final store = MemoryStore()..write('favourites.v1', 'not json');

      expect(FavouritesController(store: store).ids, isEmpty);
    });
  });

  group('Product', () {
    test('reads its features from Firestore, skipping blank lines', () {
      final product = Product.fromMap('queen', {
        'name': 'Queen F1',
        'crop': 'Sponge gourd',
        'features': ['Uniform germination', '  ', 'Glossy color '],
      });

      expect(product.features, ['Uniform germination', 'Glossy color']);
      expect(product.toMap()['features'],
          ['Uniform germination', 'Glossy color']);
    });

    test('has no features until they are added', () {
      final product = Product.fromMap('redo', {'name': 'Redo F1'});

      expect(product.features, isEmpty);
    });
  });

  group('Queen F1', () {
    const queen = Product(
        id: 'queen',
        name: 'Queen F1',
        crop: 'Sponge gourd',
        cropKey: 'sponge_gourd');

    test('has its own pack photo and two more for the gallery', () {
      expect(PackPhotos.assetFor(queen), 'assets/packs/queen.webp');
      expect(PackPhotos.extraAssetsFor(queen),
          ['assets/packs/queen_p.webp', 'assets/packs/queen_f.webp']);
    });

    test('other packs have only their front photo', () {
      expect(PackPhotos.extraAssetsFor(_redo), isEmpty);
    });
  });
}
