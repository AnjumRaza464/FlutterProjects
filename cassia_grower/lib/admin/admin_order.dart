import '../models/cart_item.dart';
import '../models/seed_order.dart';

/// Where an order stands. Stored in the order document's `status` field.
enum OrderStatus {
  /// Just placed by a farmer; nobody has handled it yet.
  placed('new', 'New'),
  confirmed('confirmed', 'Confirmed'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.value, this.label);

  /// The text stored in Firestore.
  final String value;

  /// The text shown in the panel.
  final String label;

  /// Anything unrecognised counts as new, so it still gets looked at.
  static OrderStatus parse(Object? value) {
    return values.firstWhere((s) => s.value == value, orElse: () => placed);
  }
}

/// An order as the admin panel sees it: what the farmer sent (see
/// [SeedOrder]) plus its document id, status and when it arrived.
class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.order,
    this.status = OrderStatus.placed,
    this.createdAt,
  });

  /// Builds an order from a Firestore document.
  ///
  /// Orders are written by the public app, so this never trusts their shape:
  /// a missing or wrongly-typed field becomes empty rather than breaking the
  /// whole orders list.
  factory AdminOrder.fromMap(
    String id,
    Map<String, dynamic> map, {
    DateTime? createdAt,
  }) {
    final customer = map['customer'];
    final items = map['items'];
    return AdminOrder(
      id: id,
      status: OrderStatus.parse(map['status']),
      createdAt: createdAt,
      order: SeedOrder(
        ref: _text(map['ref']),
        customer: customer is Map
            ? CustomerDetails(
                name: _text(customer['name']),
                phone: _text(customer['phone']),
                city: _text(customer['city']),
                note: _text(customer['note']),
              )
            : const CustomerDetails(),
        items: [
          if (items is List)
            for (final item in items)
              if (item is Map)
                CartItem(
                  productId: _text(item['productId']),
                  name: _text(item['name']),
                  crop: _text(item['crop']),
                  packSize: _text(item['packSize']),
                  quantity: CartItem.clampQuantity(
                      item['quantity'] is num
                          ? (item['quantity'] as num).toInt()
                          : 1),
                ),
        ],
      ),
    );
  }

  final String id;
  final SeedOrder order;
  final OrderStatus status;

  /// When the server received the order.
  final DateTime? createdAt;

  /// The customer's number in the international form a WhatsApp link needs
  /// ("0300 1234567" → "923001234567"), or '' if it isn't a usable number.
  /// Numbers without a country code are taken to be Pakistani.
  String get whatsAppNumber {
    final digits = order.customer.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return '';
    if (digits.startsWith('00')) return digits.substring(2);
    if (digits.startsWith('0')) return '92${digits.substring(1)}';
    if (digits.length == 10) return '92$digits';
    return digits;
  }

  static String _text(Object? value) => value is String ? value : '';
}
