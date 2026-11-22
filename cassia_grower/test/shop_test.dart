// Tests for the Shop's group chips, search box and cards, driven by a
// stand-in catalog (so no Firebase is needed).

import 'dart:async';

import 'package:cassia_grower/data/crop_groups.dart';
import 'package:cassia_grower/data/product_repository.dart';
import 'package:cassia_grower/main.dart';
import 'package:cassia_grower/models/product.dart';
import 'package:cassia_grower/screens/shop_screen.dart';
import 'package:cassia_grower/state/app_settings.dart';
import 'package:cassia_grower/state/cart_controller.dart';
import 'package:cassia_grower/widgets/availability_pill.dart';
import 'package:cassia_grower/widgets/not_available_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _redo = Product(
    id: 'redo', name: 'Redo F1', crop: 'Tomato', cropKey: 'tomato');
const _tomatoSoon = Product(
    id: 'soon',
    name: 'Tomato Soon',
    crop: 'Tomato',
    cropKey: 'tomato',
    available: false);
const _okra =
    Product(id: 'okra', name: 'Green Okra', crop: 'Okra', cropKey: 'okra');
const _chilli = Product(
    id: 'chilli', name: 'Hot Chilli', crop: 'Chilli', cropKey: 'chilli');
const _bitterGourd = Product(
    id: 'bitter',
    name: 'Bitter One',
    crop: 'Bitter gourd',
    cropKey: 'bitter_gourd');
const _roundGourd = Product(
    id: 'round',
    name: 'Round One',
    crop: 'Round gourd',
    cropKey: 'round_gourd');

/// A catalog the test can change while the Shop is open.
class _Catalog extends ProductRepository {
  final _changes = StreamController<List<Product>>();

  void show(List<Product> products) => _changes.add(products);

  @override
  Stream<List<Product>> watchProducts() => _changes.stream;
}

Future<_Catalog> _openShop(
  WidgetTester tester,
  List<Product> products, {
  AppLanguage language = AppLanguage.en,
  ValueNotifier<String?>? cropRequest,
}) async {
  final catalog = _Catalog()..show(products);
  await tester.pumpWidget(CassiaApp(
    settings: AppSettings()..setLanguage(language),
    cart: CartController(),
    home: ShopScreen(repository: catalog, cropRequest: cropRequest),
  ));
  await tester.pumpAndSettle();
  return catalog;
}

Finder _chip(String label) => find.widgetWithText(ShopChip, label);

Future<void> _choose(WidgetTester tester, String label) async {
  await tester.tap(_chip(label));
  await tester.pumpAndSettle();
}

void main() {
  group('CropGroup', () {
    test('sorts each crop into its group, by name or by key', () {
      expect(CropGroup.ofCrop('Tomato'), CropGroup.tomato);
      expect(CropGroup.ofCrop('Hot pepper'), CropGroup.pepper);
      expect(CropGroup.ofCrop('hot_pepper'), CropGroup.pepper);
      expect(CropGroup.ofCrop('Chilli'), CropGroup.pepper);
      expect(CropGroup.ofCrop('Bitter gourd'), CropGroup.gourd);
      expect(CropGroup.ofCrop('round_gourd'), CropGroup.gourd);
      expect(CropGroup.ofCrop('Sponge gourd'), CropGroup.gourd);
      expect(CropGroup.ofCrop('Okra'), CropGroup.okra);
      expect(CropGroup.ofCrop('Paddy'), CropGroup.field);
    });

    test('a crop that fits no other group is a vegetable', () {
      expect(CropGroup.ofCrop('Brinjal'), CropGroup.veg);
      expect(CropGroup.ofCrop('Peas'), CropGroup.veg);
      expect(CropGroup.ofCrop('Carrot'), CropGroup.veg);
      expect(CropGroup.ofCrop('Cucumber'), CropGroup.veg);
    });

    test('a product saved without a crop key is grouped by its crop', () {
      const noKey =
          Product(id: 'x', name: 'Zarar F1', crop: 'Bitter gourd', cropKey: '');

      expect(CropGroup.of(noKey), CropGroup.gourd);
    });
  });

  testWidgets('offers "All" and then the groups, in the design\'s order',
      (tester) async {
    // Given out of order, to show the chips don't follow the catalog.
    await _openShop(tester, [_okra, _chilli, _redo, _tomatoSoon]);

    final positions = [
      for (final label in ['All', 'Tomato', 'Hot Pepper', 'Okra'])
        tester.getTopLeft(_chip(label)).dx,
    ];

    expect(find.byType(ShopChip), findsNWidgets(4));
    expect(positions, orderedEquals([...positions]..sort()));
  });

  testWidgets('crops of one kind share a chip', (tester) async {
    await _openShop(tester, [_redo, _bitterGourd, _roundGourd]);

    expect(_chip('Bitter gourd'), findsNothing);
    await _choose(tester, 'Gourds');

    expect(find.text('Bitter One'), findsOneWidget);
    expect(find.text('Round One'), findsOneWidget);
    expect(find.text('Redo F1'), findsNothing);
  });

  testWidgets('choosing a group shows only that group\'s varieties',
      (tester) async {
    await _openShop(tester, [_redo, _tomatoSoon, _okra, _chilli]);

    await _choose(tester, 'Okra');

    expect(find.text('Green Okra'), findsOneWidget);
    expect(find.text('Redo F1'), findsNothing);
    expect(find.text('Hot Chilli'), findsNothing);
  });

  testWidgets('"All" brings every variety back', (tester) async {
    await _openShop(tester, [_redo, _tomatoSoon, _okra, _chilli]);
    await _choose(tester, 'Okra');

    await _choose(tester, 'All');

    expect(find.text('Green Okra'), findsOneWidget);
    expect(find.text('Redo F1'), findsOneWidget);
    expect(find.text('Hot Chilli'), findsOneWidget);
  });

  testWidgets(
      'a not-available variety stays in its group\'s list, still stamped',
      (tester) async {
    await _openShop(tester, [_redo, _tomatoSoon, _okra, _chilli]);

    await _choose(tester, 'Tomato');

    expect(find.text('Redo F1'), findsOneWidget);
    expect(find.text('Tomato Soon'), findsOneWidget);
    expect(find.byType(NotAvailableBadge), findsOneWidget);
  });

  testWidgets('a group with only not-available varieties can still be chosen',
      (tester) async {
    await _openShop(tester, [_tomatoSoon, _okra]);

    await _choose(tester, 'Tomato');

    expect(find.text('Tomato Soon'), findsOneWidget);
    expect(find.byType(NotAvailableBadge), findsOneWidget);
    expect(find.text('Green Okra'), findsNothing);
  });

  testWidgets('with a single group there is no filter', (tester) async {
    await _openShop(tester, [_redo, _tomatoSoon]);

    expect(find.byType(ShopChip), findsNothing);
    expect(find.text('Redo F1'), findsOneWidget);
  });

  testWidgets('if the chosen group leaves the catalog, everything is shown',
      (tester) async {
    final catalog = await _openShop(tester, [_redo, _okra, _chilli]);
    await _choose(tester, 'Okra');

    catalog.show([_redo, _chilli]);
    await tester.pumpAndSettle();

    expect(find.text('Redo F1'), findsOneWidget);
    expect(find.text('Hot Chilli'), findsOneWidget);
    expect(_chip('Okra'), findsNothing);
  });

  testWidgets('a crop that fits no other group is listed under "Other Veg"',
      (tester) async {
    const melon =
        Product(id: 'x', name: 'Sweet Melon', crop: 'Melon', cropKey: '');
    await _openShop(tester, [_redo, melon]);

    await _choose(tester, 'Other Veg');

    expect(find.text('Sweet Melon'), findsOneWidget);
    expect(find.text('Redo F1'), findsNothing);
  });

  testWidgets('a crop asked for from Home opens on that crop\'s group',
      (tester) async {
    final request = ValueNotifier<String?>(null);
    addTearDown(request.dispose);
    await _openShop(tester, [_redo, _bitterGourd, _roundGourd],
        cropRequest: request);

    request.value = 'bitter_gourd';
    await tester.pumpAndSettle();

    expect(find.text('Bitter One'), findsOneWidget);
    expect(find.text('Round One'), findsOneWidget);
    expect(find.text('Redo F1'), findsNothing);
  });

  testWidgets('in Urdu the chips are translated', (tester) async {
    await _openShop(tester, [_redo, _okra], language: AppLanguage.ur);

    expect(_chip('تمام'), findsOneWidget);
    expect(_chip('ٹماٹر'), findsOneWidget);
    expect(_chip('All'), findsNothing);
  });

  group('Cards', () {
    testWidgets('each card says whether its variety can be ordered',
        (tester) async {
      await _openShop(tester, [_redo, _tomatoSoon, _okra]);

      final pills = tester
          .widgetList<AvailabilityPill>(find.byType(AvailabilityPill))
          .map((pill) => pill.available);

      expect(pills, [true, false, true]);
      expect(find.text('Available'), findsNWidgets(2));
    });

    testWidgets(
        'a not-available variety carries the stamp on its photo as well as '
        'the pill', (tester) async {
      await _openShop(tester, [_redo, _tomatoSoon]);

      expect(find.byType(NotAvailableBadge), findsOneWidget);
      // Once on the stamp, once on the pill.
      expect(find.text('Not available yet'), findsNWidgets(2));
    });
  });

  group('Product.matchesSearch', () {
    const p = Product(
      id: 'redo',
      name: 'Redo F1',
      crop: 'Tomato',
      cropKey: 'tomato',
      type: 'Hybrid',
      packSize: '10 g',
      brandLine: 'MalaPine',
    );

    test('matches part of the name, whatever the letter case', () {
      expect(p.matchesSearch('red'), isTrue);
      expect(p.matchesSearch('REDO'), isTrue);
    });

    test('matches the crop, type, sub-brand and pack size too', () {
      expect(p.matchesSearch('tomato'), isTrue);
      expect(p.matchesSearch('hybrid'), isTrue);
      expect(p.matchesSearch('malapine'), isTrue);
      expect(p.matchesSearch('10 g'), isTrue);
    });

    test('needs every word typed to match, in any order', () {
      expect(p.matchesSearch('tomato redo'), isTrue);
      expect(p.matchesSearch('hybrid   tomato'), isTrue);
      expect(p.matchesSearch('tomato okra'), isFalse);
    });

    test('nothing typed matches everything', () {
      expect(p.matchesSearch(''), isTrue);
      expect(p.matchesSearch('   '), isTrue);
    });

    test('something else does not match', () {
      expect(p.matchesSearch('chilli'), isFalse);
    });
  });

  group('Search', () {
    Future<void> search(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pumpAndSettle();
    }

    testWidgets('typing shows only the varieties that match', (tester) async {
      await _openShop(tester, [_redo, _tomatoSoon, _okra, _chilli]);

      await search(tester, 'green');

      expect(find.text('Green Okra'), findsOneWidget);
      expect(find.text('Redo F1'), findsNothing);
      expect(find.text('Hot Chilli'), findsNothing);
    });

    testWidgets('a crop name finds every variety of that crop',
        (tester) async {
      await _openShop(tester, [_redo, _tomatoSoon, _okra, _chilli]);

      await search(tester, 'TOMATO');

      expect(find.text('Redo F1'), findsOneWidget);
      expect(find.text('Tomato Soon'), findsOneWidget);
      expect(find.text('Green Okra'), findsNothing);
    });

    testWidgets('a not-available variety is found, still stamped',
        (tester) async {
      await _openShop(tester, [_redo, _tomatoSoon, _okra, _chilli]);

      await search(tester, 'soon');

      expect(find.text('Tomato Soon'), findsOneWidget);
      expect(find.byType(NotAvailableBadge), findsOneWidget);
    });

    testWidgets('search works inside the chosen group', (tester) async {
      await _openShop(tester, [_redo, _tomatoSoon, _okra, _chilli]);
      await _choose(tester, 'Tomato');

      await search(tester, 'f1');

      expect(find.text('Redo F1'), findsOneWidget);
      expect(find.text('Tomato Soon'), findsNothing);
    });

    testWidgets('the clear button brings the list back', (tester) async {
      await _openShop(tester, [_redo, _tomatoSoon, _okra, _chilli]);
      await search(tester, 'green');

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('Redo F1'), findsOneWidget);
      expect(find.text('Hot Chilli'), findsOneWidget);
      expect(find.byTooltip('Clear search'), findsNothing);
    });

    testWidgets(
        'when nothing matches it says so, and one tap shows everything again',
        (tester) async {
      await _openShop(tester, [_redo, _tomatoSoon, _okra, _chilli]);
      // Okra is chosen, so even a real variety of another crop finds nothing.
      await _choose(tester, 'Okra');
      await search(tester, 'redo');

      expect(find.text('No varieties match "redo"'), findsOneWidget);
      expect(find.text('Redo F1'), findsNothing);

      await tester.tap(find.text('Show all varieties'));
      await tester.pumpAndSettle();

      expect(find.text('Redo F1'), findsOneWidget);
      expect(find.text('Green Okra'), findsOneWidget);
      expect(find.text('Hot Chilli'), findsOneWidget);
    });

    testWidgets('the search box is there even with a single group',
        (tester) async {
      await _openShop(tester, [_redo, _tomatoSoon]);

      await search(tester, 'soon');

      expect(find.text('Tomato Soon'), findsOneWidget);
      expect(find.text('Redo F1'), findsNothing);
    });

    testWidgets('in Urdu the search box is labelled in Urdu', (tester) async {
      await _openShop(tester, [_redo, _okra], language: AppLanguage.ur);

      expect(find.text('بیج تلاش کریں…'), findsOneWidget);
      expect(find.text('Search seeds…'), findsNothing);
    });
  });
}
