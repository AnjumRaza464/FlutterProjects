// Unit tests for the Cassia Grower app.
//
// The app initialises Firebase in main(), so full widget/integration tests
// need the Firebase test setup. Here we test the pure display-sort logic,
// which needs no Firebase and guards the core catalog ordering rule.

import 'package:cassia_grower/data/product_repository.dart';
import 'package:cassia_grower/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductRepository.sortForDisplay', () {
    test('available items come before not-available items', () {
      final products = [
        const Product(
            id: 'a', name: 'A', crop: 'x', cropKey: 'x', available: false),
        const Product(
            id: 'b', name: 'B', crop: 'x', cropKey: 'x', available: true),
      ];

      ProductRepository.sortForDisplay(products);

      expect(products.first.id, 'b'); // available first
      expect(products.last.id, 'a'); // not-available below
    });

    test('within the same availability, lower sortOrder is higher up', () {
      final products = [
        const Product(
            id: 'late',
            name: 'Late',
            crop: 'x',
            cropKey: 'x',
            available: true,
            sortOrder: 30),
        const Product(
            id: 'early',
            name: 'Early',
            crop: 'x',
            cropKey: 'x',
            available: true,
            sortOrder: 10),
      ];

      ProductRepository.sortForDisplay(products);

      expect(products.map((p) => p.id).toList(), ['early', 'late']);
    });

    test('equal availability and sortOrder falls back to name', () {
      final products = [
        const Product(
            id: 'z', name: 'Zucchini', crop: 'x', cropKey: 'x', available: true),
        const Product(
            id: 'o', name: 'Okra', crop: 'x', cropKey: 'x', available: true),
      ];

      ProductRepository.sortForDisplay(products);

      expect(products.map((p) => p.id).toList(), ['o', 'z']);
    });
  });
}
