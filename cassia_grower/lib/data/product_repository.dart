import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

/// Reads the product catalog from the Firestore `products` collection.
///
/// The mobile app only ever reads here; the admin web panel (Phase 6) is
/// what writes/edits these documents. Sorting for display is done in the app
/// so we don't need a Firestore composite index for a small catalog.
class ProductRepository {
  ProductRepository({this._firestore});

  // Resolved lazily so screens can be shown with a stand-in catalog (tests,
  // screenshots) without Firebase.
  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      (_firestore ?? FirebaseFirestore.instance).collection('products');

  /// Live stream of every product, already ordered for display:
  /// 1. Available varieties first (not-available ones stay visible, below).
  /// 2. Then by `sortOrder` (lower number = higher up).
  /// 3. Then alphabetically by name.
  Stream<List<Product>> watchProducts() {
    return _col.snapshots().map((snap) {
      final products =
          snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
      sortForDisplay(products);
      return products;
    });
  }

  /// One-time fetch (handy for pull-to-refresh or the admin panel).
  Future<List<Product>> fetchProducts() async {
    final snap = await _col.get();
    final products =
        snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
    sortForDisplay(products);
    return products;
  }

  /// Live stream of a single product (used by the detail screen so a toggle
  /// in the admin panel updates the open page instantly).
  Stream<Product?> watchProduct(String id) {
    return _col.doc(id).snapshots().map(
          (d) => d.exists ? Product.fromMap(d.id, d.data()!) : null,
        );
  }

  /// Sorts a product list in place for display.
  static void sortForDisplay(List<Product> products) {
    products.sort((a, b) {
      if (a.available != b.available) {
        return a.available ? -1 : 1; // available first
      }
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder); // lower = higher up
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }
}
