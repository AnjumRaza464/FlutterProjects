// Tests for which bundled pack photo a product is shown with. The rule that
// matters: a real product only ever gets its OWN pack's photo.

import 'package:cassia_grower/data/pack_photos.dart';
import 'package:cassia_grower/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product(String id, String name, String crop) =>
    Product(id: id, name: name, crop: crop, cropKey: crop.toLowerCase());

void main() {
  group('a real product', () {
    test('with a known id gets that pack\'s photo', () {
      expect(PackPhotos.assetFor(_product('redo', 'Redo F1', 'Tomato')),
          'assets/packs/redo.webp');
    });

    test('added under another id is recognised by its name', () {
      expect(PackPhotos.idFor(_product('a1', 'Shella F1', 'Okra')), 'shella');
      expect(PackPhotos.idFor(_product('a2', 'H-786 F1', 'Hot pepper')), 'h786');
      expect(PackPhotos.idFor(_product('a3', 'Total Hot F1', 'Hot pepper')),
          'totalhot');
    });

    test('"Lucky Shandar" and "Shandar" are told apart', () {
      expect(
          PackPhotos.idFor(_product('a1', 'Lucky Shandar CS-5454', 'Tomato')),
          'lucky');
      expect(PackPhotos.idFor(_product('a2', 'Shandar KS-85', 'Paddy')),
          'shandar');
    });

    test('is matched on whole words only', () {
      // "Malabar" is not the variety "Mala".
      expect(PackPhotos.idFor(_product('a1', 'Malabar Spinach', 'Spinach')),
          isNull);
      expect(PackPhotos.idFor(_product('a2', 'Mala F1', 'Okra')), 'mala');
    });

    test('with no photo of its own gets none — never another variety\'s', () {
      final unknown = _product('a1', 'Sweet Star', 'Tomato');

      expect(PackPhotos.assetFor(unknown), isNull);
      expect(PackPhotos.isCutOut(unknown), isFalse);
    });
  });

  group('a demo product', () {
    test('borrows a photo of the same crop', () {
      final demo = _product('demo_okra_green', 'Green Okra F1 (demo)', 'Okra');

      expect(PackPhotos.idFor(demo),
          isIn(['shella', 'roopa', 'rani', 'mala']));
    });

    test('keeps the same photo every time', () {
      final demo = _product('demo_tomato_hybrid', 'Tomato (demo)', 'Tomato');

      expect(PackPhotos.idFor(demo), PackPhotos.idFor(demo));
    });

    test('of a crop with no pack photo still gets a picture', () {
      final demo = _product('demo_onion_red', 'Onion Red (demo)', 'Onion');

      expect(PackPhotos.assetFor(demo), startsWith('assets/packs/'));
    });
  });

  test('cut-out photos are told apart from photos with a background', () {
    expect(PackPhotos.isCutOut(_product('lucky', 'Lucky Shandar', 'Tomato')),
        isTrue);
    expect(PackPhotos.isCutOut(_product('redo', 'Redo F1', 'Tomato')), isFalse);
  });
}
