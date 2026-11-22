import 'dart:math';

import 'cart_item.dart';

/// Who is ordering, so Cassia Seed can confirm the order with them.
class CustomerDetails {
  const CustomerDetails({
    this.name = '',
    this.phone = '',
    this.city = '',
    this.note = '',
  });

  factory CustomerDetails.fromMap(Map<String, dynamic> map) {
    return CustomerDetails(
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      note: (map['note'] ?? '') as String,
    );
  }

  final String name;
  final String phone;
  final String city; // city or village
  final String note; // optional message from the farmer

  /// True for a plausible phone number: 10–13 digits, with an optional
  /// leading "+". Spaces, dashes and brackets are ignored, so "0300-1234567"
  /// and "+92 300 1234567" both pass.
  static bool isValidPhone(String input) {
    final compact = input.replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^\+?\d{10,13}$').hasMatch(compact);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'city': city,
        'note': note,
      };
}

/// An order request: the cart plus the farmer's details.
///
/// It is saved to the Firestore `orders` collection (for the admin panel) and
/// sent to Cassia Seed as a WhatsApp message, tied together by [ref].
class SeedOrder {
  const SeedOrder({
    required this.ref,
    required this.customer,
    required this.items,
  });

  /// A short order number the farmer and Cassia Seed can both quote, e.g.
  /// "CS-261121-7K2M" (date, then four random characters).
  static String newRef({DateTime? now, Random? random}) {
    // No 0/O or 1/I, so the code can be read out over the phone.
    const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final at = now ?? DateTime.now();
    final rng = random ?? Random();
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(at.year % 100)}${two(at.month)}${two(at.day)}';
    final code = [
      for (var i = 0; i < 4; i++) alphabet[rng.nextInt(alphabet.length)],
    ].join();
    return 'CS-$date-$code';
  }

  final String ref;
  final CustomerDetails customer;
  final List<CartItem> items;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// The Firestore document, minus the server-side fields (`createdAt` and
  /// `status`) that the repository adds when saving.
  Map<String, dynamic> toMap() => {
        'ref': ref,
        'customer': customer.toMap(),
        'items': [for (final item in items) item.toMap()],
        'totalQuantity': totalQuantity,
      };

  /// The message pre-filled in WhatsApp for the farmer to send.
  String toWhatsAppMessage() {
    final lines = <String>[
      'Assalam-o-Alaikum! I would like to order from Cassia Seed.',
      '',
      'Order no: $ref',
      '',
    ];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final pack = item.packSize.isNotEmpty ? ' (${item.packSize})' : '';
      final crop = item.crop.isNotEmpty ? ', ${item.crop}' : '';
      lines.add('${i + 1}. ${item.name}$pack$crop × ${item.quantity}');
    }
    lines
      ..add('')
      ..add('Name: ${customer.name}')
      ..add('Phone: ${customer.phone}')
      ..add('City / village: ${customer.city}');
    if (customer.note.isNotEmpty) lines.add('Note: ${customer.note}');
    lines
      ..add('')
      ..add('Please confirm price and availability. Thank you.');
    return lines.join('\n');
  }
}
