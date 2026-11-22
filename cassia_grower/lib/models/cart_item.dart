import 'product.dart';

/// One line in the cart: a variety and how many packs of it.
///
/// The name, crop and pack size are copied from the product so the cart can
/// be shown — and restored after the app restarts — without waiting for
/// Firestore. There is no price: Cassia Seed confirms prices on WhatsApp.
class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    this.crop = '',
    this.packSize = '',
    this.quantity = 1,
  });

  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      productId: product.id,
      name: product.name,
      crop: product.crop,
      packSize: product.packSize,
      quantity: clampQuantity(quantity),
    );
  }

  /// Rebuilds a line saved by [toMap]. Throws if the product id is missing.
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as String,
      name: (map['name'] ?? '') as String,
      crop: (map['crop'] ?? '') as String,
      packSize: (map['packSize'] ?? '') as String,
      quantity: clampQuantity((map['quantity'] as num?)?.toInt() ?? 1),
    );
  }

  /// The most of one variety a single order can hold.
  static const int maxQuantity = 999;

  static int clampQuantity(int quantity) => quantity.clamp(1, maxQuantity);

  final String productId;
  final String name;
  final String crop;
  final String packSize;
  final int quantity;

  CartItem withQuantity(int quantity) => CartItem(
        productId: productId,
        name: name,
        crop: crop,
        packSize: packSize,
        quantity: clampQuantity(quantity),
      );

  /// Used both for saving the cart on the device and for the Firestore order.
  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'crop': crop,
        'packSize': packSize,
        'quantity': quantity,
      };
}
