import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/seed_order.dart';

/// The farmer's cart, shared by the whole app through `CartScope`.
///
/// The cart (and the farmer's contact details from their last order) are kept
/// on the phone, so they survive the app being closed.
///
/// Legal safety: a variety that is not available can never be in the cart.
/// [add] refuses one, and [syncWithCatalog] takes a line out as soon as its
/// variety stops being available.
class CartController extends ChangeNotifier {
  CartController({LocalStore? store}) : _store = store ?? MemoryStore() {
    _restore();
  }

  static const _itemsKey = 'cart.items.v1';
  static const _customerKey = 'cart.customer.v1';

  final LocalStore _store;
  final List<CartItem> _items = [];
  CustomerDetails _customer = const CustomerDetails();
  List<String> _removedNotice = const [];
  StreamSubscription<List<Product>>? _catalog;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  /// Total packs across every line.
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  /// The contact details from the farmer's last order, to pre-fill the next.
  CustomerDetails get customer => _customer;

  /// Names of varieties that were taken out of the cart because they stopped
  /// being available, until the farmer dismisses the notice.
  List<String> get removedNotice => _removedNotice;

  /// How many of this product are in the cart (0 if none).
  int quantityOf(String productId) {
    for (final item in _items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  /// Adds [quantity] packs of [product]. Returns false — and adds nothing —
  /// if the variety is not available to order.
  bool add(Product product, {int quantity = 1}) {
    if (!product.available) return false;
    final i = _indexOf(product.id);
    if (i < 0) {
      _items.add(CartItem.fromProduct(product, quantity: quantity));
    } else {
      _items[i] = _items[i].withQuantity(_items[i].quantity + quantity);
    }
    _changed();
    return true;
  }

  /// Sets how many of a product are in the cart; 0 or less removes the line.
  void setQuantity(String productId, int quantity) {
    final i = _indexOf(productId);
    if (i < 0) return;
    if (quantity <= 0) {
      _items.removeAt(i);
    } else {
      _items[i] = _items[i].withQuantity(quantity);
    }
    _changed();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    _changed();
  }

  void rememberCustomer(CustomerDetails details) {
    _customer = details;
    unawaited(_store.write(_customerKey, jsonEncode(details.toMap())));
    notifyListeners();
  }

  void dismissRemovedNotice() {
    if (_removedNotice.isEmpty) return;
    _removedNotice = const [];
    notifyListeners();
  }

  /// Keeps the cart in step with the catalog for as long as the app runs.
  void watchCatalog(Stream<List<Product>> catalog) {
    _catalog?.cancel();
    // A failed read (offline, say) tells us nothing new, so it's ignored.
    _catalog = catalog.listen(syncWithCatalog, onError: (Object _) {});
  }

  /// Brings the cart in line with the live catalog: a line whose variety is
  /// no longer available (or has been deleted) is removed, and the rest pick
  /// up any change of name or pack size. Returns the names removed.
  List<String> syncWithCatalog(List<Product> products) {
    // An empty catalog means it hasn't loaded (first launch offline, say),
    // not that every variety was withdrawn — so there's nothing to check.
    if (products.isEmpty || _items.isEmpty) return const [];

    final live = {for (final p in products) p.id: p};
    final removed = <String>[];
    var changed = false;

    for (var i = _items.length - 1; i >= 0; i--) {
      final item = _items[i];
      final product = live[item.productId];
      if (product == null || !product.available) {
        removed.add(item.name);
        _items.removeAt(i);
        changed = true;
      } else if (product.name != item.name ||
          product.crop != item.crop ||
          product.packSize != item.packSize) {
        _items[i] = CartItem.fromProduct(product, quantity: item.quantity);
        changed = true;
      }
    }

    if (removed.isNotEmpty) {
      _removedNotice = [..._removedNotice, ...removed.reversed];
    }
    if (changed) _changed();
    return removed.reversed.toList();
  }

  @override
  void dispose() {
    _catalog?.cancel();
    super.dispose();
  }

  int _indexOf(String productId) =>
      _items.indexWhere((item) => item.productId == productId);

  void _changed() {
    final saved = jsonEncode([for (final item in _items) item.toMap()]);
    unawaited(_store.write(_itemsKey, saved));
    notifyListeners();
  }

  /// Loads what was saved last time. Anything unreadable is dropped rather
  /// than stopping the app from starting.
  void _restore() {
    try {
      final saved = _store.read(_itemsKey);
      if (saved != null) {
        for (final entry in jsonDecode(saved) as List) {
          _items.add(CartItem.fromMap(Map<String, dynamic>.from(entry as Map)));
        }
      }
    } catch (_) {
      _items.clear();
    }
    try {
      final saved = _store.read(_customerKey);
      if (saved != null) {
        _customer = CustomerDetails.fromMap(
            Map<String, dynamic>.from(jsonDecode(saved) as Map));
      }
    } catch (_) {
      _customer = const CustomerDetails();
    }
  }
}
