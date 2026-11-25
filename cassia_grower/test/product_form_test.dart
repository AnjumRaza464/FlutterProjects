// Tests for the admin "Add / Edit product" form's photo gallery editor.
//
// The form lets the admin attach several photos to one product. These tests
// pump the form directly (no Firebase — ProductAdminService is created lazily,
// only when a save actually runs) and check that each existing photo shows as
// a thumbnail, the first one is marked "Main", every photo has a remove
// button, and an "Add" tile appears while under the limit.

import 'package:cassia_grower/admin/product_form_screen.dart';
import 'package:cassia_grower/models/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pumpForm(WidgetTester tester, Product? existing) async {
  tester.view
    ..physicalSize = const Size(900, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: ProductFormScreen(existing: existing),
  ));
  await tester.pump();
}

void main() {
  testWidgets('shows a thumbnail for each uploaded photo, first one is "Main"',
      (tester) async {
    await _pumpForm(
      tester,
      const Product(
        id: 'multi',
        name: 'Multi F1',
        crop: 'Tomato',
        cropKey: 'tomato',
        imageUrls: [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
          'https://example.com/c.jpg',
        ],
      ),
    );

    // Three photos, under the limit of six.
    expect(find.text('Product photos (3/6)'), findsOneWidget);
    // Only the first photo carries the "Main" badge.
    expect(find.text('Main'), findsOneWidget);
    // Every photo has a remove (✕) button.
    expect(find.byIcon(Icons.close), findsNWidgets(3));
    // And there is an "Add" tile to pick more.
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
  });

  testWidgets('a new product starts with no photos and only the Add tile',
      (tester) async {
    await _pumpForm(tester, null);

    expect(find.text('Product photos (0/6)'), findsOneWidget);
    expect(find.text('Main'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
  });

  testWidgets('a legacy single imageUrl is carried into the gallery',
      (tester) async {
    await _pumpForm(
      tester,
      const Product(
        id: 'legacy',
        name: 'Legacy F1',
        crop: 'Okra',
        cropKey: 'okra',
        imageUrl: 'https://example.com/old.jpg',
      ),
    );

    // The old single-image product shows one photo in the new gallery.
    expect(find.text('Product photos (1/6)'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
