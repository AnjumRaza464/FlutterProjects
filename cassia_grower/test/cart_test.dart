// Tests for the cart and order flow: the order that gets sent, the cart's
// rules (above all, that a not-available variety can never be ordered), and
// the cart / checkout screens driven by a fake order service.

import 'dart:async';
import 'dart:math';

import 'package:cassia_grower/data/local_store.dart';
import 'package:cassia_grower/models/cart_item.dart';
import 'package:cassia_grower/models/product.dart';
import 'package:cassia_grower/models/seed_order.dart';
import 'package:cassia_grower/screens/cart_screen.dart';
import 'package:cassia_grower/services/order_service.dart';
import 'package:cassia_grower/state/cart_controller.dart';
import 'package:cassia_grower/state/cart_scope.dart';
import 'package:cassia_grower/widgets/cart_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _tomato = Product(
  id: 'tomato',
  name: 'Redo F1',
  crop: 'Tomato',
  cropKey: 'tomato',
  packSize: '10 g',
);
const _okra = Product(
  id: 'okra',
  name: 'Green Okra',
  crop: 'Okra',
  cropKey: 'okra',
);
const _carrot = Product(
  id: 'carrot',
  name: 'Carrot Red',
  crop: 'Carrot',
  cropKey: 'carrot',
  available: false,
);

/// The same product after an admin marks it not available.
Product _withdrawn(Product p) => Product(
      id: p.id,
      name: p.name,
      crop: p.crop,
      cropKey: p.cropKey,
      packSize: p.packSize,
      available: false,
    );

/// Records what checkout sends, and succeeds or fails on demand.
class _FakeOrders extends OrderService {
  SaveOutcome saveOutcome = SaveOutcome.saved;
  bool whatsAppOpens = true;
  final List<SeedOrder> saved = [];
  final List<SeedOrder> opened = [];

  @override
  Future<SaveOutcome> save(SeedOrder order) async {
    saved.add(order);
    return saveOutcome;
  }

  @override
  Future<bool> openWhatsApp(SeedOrder order) async {
    opened.add(order);
    return whatsAppOpens;
  }
}

Widget _app(CartController cart, Widget home) {
  return CartScope(cart: cart, child: MaterialApp(home: home));
}

/// Opens checkout from the cart on a screen tall enough to show the whole
/// form, and fills in the farmer's details.
Future<void> _openCheckout(
  WidgetTester tester,
  CartController cart,
  _FakeOrders orders, {
  String name = 'Ali Khan',
  String phone = '0300 1234567',
  String city = 'Tando Allahyar',
}) async {
  await tester.binding.setSurfaceSize(const Size(480, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(cart, CartScreen(orderService: orders)));
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Your name'), name);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone number'), phone);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'City or village'), city);
}

Future<void> _tapSend(WidgetTester tester) async {
  await tester.tap(find.text('Send order on WhatsApp'));
  await tester.pumpAndSettle();
}

void main() {
  group('SeedOrder', () {
    const order = SeedOrder(
      ref: 'CS-261121-7K2M',
      customer: CustomerDetails(
        name: 'Ali Khan',
        phone: '0300 1234567',
        city: 'Tando Allahyar',
        note: 'Need it by Friday',
      ),
      items: [
        CartItem(
            productId: 'tomato',
            name: 'Redo F1',
            crop: 'Tomato',
            packSize: '10 g',
            quantity: 2),
        CartItem(productId: 'okra', name: 'Green Okra', quantity: 5),
      ],
    );

    test('the WhatsApp message lists every line and the farmer\'s details',
        () {
      expect(
        order.toWhatsAppMessage(),
        'Assalam-o-Alaikum! I would like to order from Cassia Seed.\n'
        '\n'
        'Order no: CS-261121-7K2M\n'
        '\n'
        '1. Redo F1 (10 g), Tomato × 2\n'
        '2. Green Okra × 5\n'
        '\n'
        'Name: Ali Khan\n'
        'Phone: 0300 1234567\n'
        'City / village: Tando Allahyar\n'
        'Note: Need it by Friday\n'
        '\n'
        'Please confirm price and availability. Thank you.',
      );
    });

    test('an empty note is left out of the message', () {
      const noNote = SeedOrder(
        ref: 'CS-1',
        customer: CustomerDetails(name: 'A', phone: '1', city: 'C'),
        items: [CartItem(productId: 'okra', name: 'Green Okra')],
      );

      expect(noNote.toWhatsAppMessage(), isNot(contains('Note:')));
    });

    test('the Firestore document carries the lines, customer and total', () {
      final map = order.toMap();

      expect(map['ref'], 'CS-261121-7K2M');
      expect(map['totalQuantity'], 7);
      expect((map['customer'] as Map)['phone'], '0300 1234567');
      expect(map['items'], [
        {
          'productId': 'tomato',
          'name': 'Redo F1',
          'crop': 'Tomato',
          'packSize': '10 g',
          'quantity': 2,
        },
        {
          'productId': 'okra',
          'name': 'Green Okra',
          'crop': '',
          'packSize': '',
          'quantity': 5,
        },
      ]);
    });

    test('an order number is the date plus four unambiguous characters', () {
      final ref =
          SeedOrder.newRef(now: DateTime(2026, 11, 21), random: Random(1));

      expect(ref, matches(RegExp(r'^CS-261121-[2-9A-HJ-NP-Z]{4}$')));
    });
  });

  group('CustomerDetails.isValidPhone', () {
    test('accepts local and international formats', () {
      expect(CustomerDetails.isValidPhone('03001234567'), isTrue);
      expect(CustomerDetails.isValidPhone('0300-1234567'), isTrue);
      expect(CustomerDetails.isValidPhone('+92 300 1234567'), isTrue);
      expect(CustomerDetails.isValidPhone('022-3400398'), isTrue);
    });

    test('rejects numbers that are too short or not numbers', () {
      expect(CustomerDetails.isValidPhone(''), isFalse);
      expect(CustomerDetails.isValidPhone('12345'), isFalse);
      expect(CustomerDetails.isValidPhone('call me later'), isFalse);
    });
  });

  group('CartController', () {
    test('adding the same variety again raises its quantity', () {
      final cart = CartController()
        ..add(_tomato)
        ..add(_tomato, quantity: 2)
        ..add(_okra);

      expect(cart.items, hasLength(2));
      expect(cart.quantityOf('tomato'), 3);
      expect(cart.totalQuantity, 4);
    });

    test('a not-available variety is refused', () {
      final cart = CartController();

      expect(cart.add(_carrot), isFalse);
      expect(cart.isEmpty, isTrue);
    });

    test('setting a quantity to zero removes the line', () {
      final cart = CartController()..add(_tomato, quantity: 3);

      cart.setQuantity('tomato', 0);

      expect(cart.isEmpty, isTrue);
    });

    test('a quantity is capped at the maximum', () {
      final cart = CartController()..add(_tomato);

      cart.setQuantity('tomato', 5000);

      expect(cart.quantityOf('tomato'), CartItem.maxQuantity);
    });

    test('the cart and the farmer\'s details survive a restart', () {
      final store = MemoryStore();
      CartController(store: store)
        ..add(_tomato, quantity: 4)
        ..rememberCustomer(const CustomerDetails(
            name: 'Ali Khan', phone: '03001234567', city: 'Hyderabad'));

      final restarted = CartController(store: store);

      expect(restarted.quantityOf('tomato'), 4);
      expect(restarted.items.single.name, 'Redo F1');
      expect(restarted.customer.name, 'Ali Khan');
      expect(restarted.customer.city, 'Hyderabad');
    });

    test('unreadable saved data starts an empty cart instead of crashing',
        () async {
      final store = MemoryStore();
      await store.write('cart.items.v1', 'not json');
      await store.write('cart.customer.v1', '[1, 2]');

      final cart = CartController(store: store);

      expect(cart.isEmpty, isTrue);
      expect(cart.customer.name, '');
    });

    group('syncWithCatalog', () {
      test('removes a variety that stopped being available, and says so', () {
        final cart = CartController()
          ..add(_tomato)
          ..add(_okra);

        final removed = cart.syncWithCatalog([_withdrawn(_tomato), _okra]);

        expect(removed, ['Redo F1']);
        expect(cart.items.single.productId, 'okra');
        expect(cart.removedNotice, ['Redo F1']);
      });

      test('removes a variety that was deleted from the catalog', () {
        final cart = CartController()
          ..add(_tomato)
          ..add(_okra);

        cart.syncWithCatalog([_okra]);

        expect(cart.items.single.productId, 'okra');
        expect(cart.removedNotice, ['Redo F1']);
      });

      test('leaves the cart alone while the catalog has not loaded', () {
        final cart = CartController()..add(_tomato);

        final removed = cart.syncWithCatalog(const []);

        expect(removed, isEmpty);
        expect(cart.quantityOf('tomato'), 1);
      });

      test('picks up a renamed variety and keeps its quantity', () {
        final cart = CartController()..add(_tomato, quantity: 3);

        cart.syncWithCatalog(const [
          Product(
              id: 'tomato',
              name: 'Redo F1 Plus',
              crop: 'Tomato',
              cropKey: 'tomato',
              packSize: '25 g'),
        ]);

        expect(cart.items.single.name, 'Redo F1 Plus');
        expect(cart.items.single.packSize, '25 g');
        expect(cart.items.single.quantity, 3);
        expect(cart.removedNotice, isEmpty);
      });

      test('the notice stays until it is dismissed', () {
        final cart = CartController()..add(_tomato);
        cart.syncWithCatalog([_withdrawn(_tomato), _okra]);

        cart.dismissRemovedNotice();

        expect(cart.removedNotice, isEmpty);
      });
    });

    test('watchCatalog applies catalog changes as they arrive', () async {
      final catalog = StreamController<List<Product>>();
      addTearDown(catalog.close);
      final cart = CartController()
        ..add(_tomato)
        ..watchCatalog(catalog.stream);
      addTearDown(cart.dispose);

      catalog.add([_withdrawn(_tomato)]);
      await Future<void>.delayed(Duration.zero);

      expect(cart.isEmpty, isTrue);
    });

    test('a failed catalog read leaves the cart as it was', () async {
      final catalog = StreamController<List<Product>>();
      addTearDown(catalog.close);
      final cart = CartController()
        ..add(_tomato)
        ..watchCatalog(catalog.stream);
      addTearDown(cart.dispose);

      catalog.addError(StateError('offline'));
      await Future<void>.delayed(Duration.zero);

      expect(cart.quantityOf('tomato'), 1);
    });
  });

  // Adding to the order from a variety's page is covered in
  // product_sheet_test.dart.

  group('CartButton', () {
    testWidgets('shows how many packs are in the cart', (tester) async {
      final cart = CartController();
      await tester.pumpWidget(_app(
        cart,
        Scaffold(appBar: AppBar(actions: const [CartButton()])),
      ));

      cart
        ..add(_tomato, quantity: 2)
        ..add(_okra);
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('opens the cart', (tester) async {
      final cart = CartController()..add(_tomato);
      await tester.pumpWidget(_app(
        cart,
        Scaffold(appBar: AppBar(actions: const [CartButton()])),
      ));

      await tester.tap(find.byTooltip('Cart'));
      await tester.pumpAndSettle();

      expect(find.text('Your cart'), findsOneWidget);
      expect(find.text('Redo F1'), findsOneWidget);
    });
  });

  group('CartScreen', () {
    testWidgets('an empty cart says so and offers no checkout',
        (tester) async {
      await tester.pumpWidget(_app(CartController(), const CartScreen()));

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('lists each variety with its details and a total',
        (tester) async {
      final cart = CartController()
        ..add(_tomato, quantity: 2)
        ..add(_okra);
      await tester.pumpWidget(_app(cart, const CartScreen()));

      expect(find.text('Redo F1'), findsOneWidget);
      expect(find.text('Tomato • 10 g'), findsOneWidget);
      expect(find.text('Green Okra'), findsOneWidget);
      expect(find.text('2 varieties • 3 packs'), findsOneWidget);
    });

    testWidgets('a quantity can be typed for a large order', (tester) async {
      final cart = CartController()..add(_tomato);
      await tester.pumpWidget(_app(cart, const CartScreen()));

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '50');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(cart.quantityOf('tomato'), 50);
      expect(find.text('1 variety • 50 packs'), findsOneWidget);
    });

    testWidgets('a withdrawn variety disappears and the farmer is told why',
        (tester) async {
      final cart = CartController()
        ..add(_tomato)
        ..add(_okra);
      await tester.pumpWidget(_app(cart, const CartScreen()));

      cart.syncWithCatalog([_withdrawn(_tomato), _okra]);
      await tester.pump();

      expect(find.text('Redo F1'), findsNothing);
      expect(
        find.text('Not available yet, so removed from your cart: Redo F1'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();

      expect(find.textContaining('removed from your cart'), findsNothing);
    });
  });

  group('Checkout', () {
    testWidgets('sending saves the order, opens WhatsApp and empties the cart',
        (tester) async {
      final cart = CartController()
        ..add(_tomato, quantity: 2)
        ..add(_okra);
      final orders = _FakeOrders();
      await _openCheckout(tester, cart, orders);

      await _tapSend(tester);

      final sent = orders.saved.single;
      expect(sent.customer.name, 'Ali Khan');
      expect(sent.customer.phone, '0300 1234567');
      expect(sent.items.map((i) => '${i.name} x${i.quantity}'),
          ['Redo F1 x2', 'Green Okra x1']);
      expect(orders.opened.single.ref, sent.ref);

      expect(find.text('Press send in WhatsApp'), findsOneWidget);
      expect(find.text('Order no: ${sent.ref}'), findsOneWidget);
      expect(cart.isEmpty, isTrue);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('missing or invalid details stop the order', (tester) async {
      final cart = CartController()..add(_tomato);
      final orders = _FakeOrders();
      await _openCheckout(tester, cart, orders,
          name: '', phone: '12345', city: ' ');

      await _tapSend(tester);

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter a valid phone number'), findsOneWidget);
      expect(find.text('Please enter your city or village'), findsOneWidget);
      expect(orders.saved, isEmpty);
      expect(orders.opened, isEmpty);
      expect(cart.quantityOf('tomato'), 1);
    });

    testWidgets('the farmer\'s details are filled in for their next order',
        (tester) async {
      final cart = CartController()..add(_tomato);
      final orders = _FakeOrders();
      await _openCheckout(tester, cart, orders);
      await _tapSend(tester);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      cart.add(_okra);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Ali Khan'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, '0300 1234567'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Tando Allahyar'), findsOneWidget);
    });

    testWidgets('without WhatsApp, a saved order is still confirmed',
        (tester) async {
      final cart = CartController()..add(_tomato);
      final orders = _FakeOrders()..whatsAppOpens = false;
      await _openCheckout(tester, cart, orders);

      await _tapSend(tester);

      expect(find.text('Order received'), findsOneWidget);
      expect(find.textContaining('0300 1234567'), findsOneWidget);
      expect(cart.isEmpty, isTrue);
    });

    testWidgets('an offline order still goes out through WhatsApp',
        (tester) async {
      final cart = CartController()..add(_tomato);
      final orders = _FakeOrders()..saveOutcome = SaveOutcome.pending;
      await _openCheckout(tester, cart, orders);

      await _tapSend(tester);

      expect(find.text('Press send in WhatsApp'), findsOneWidget);
      expect(cart.isEmpty, isTrue);
    });

    testWidgets(
        'if nothing got through, the cart is kept and a retry reuses the '
        'order number', (tester) async {
      final cart = CartController()..add(_tomato);
      final orders = _FakeOrders()
        ..saveOutcome = SaveOutcome.failed
        ..whatsAppOpens = false;
      await _openCheckout(tester, cart, orders);

      await _tapSend(tester);

      expect(find.textContaining('could not be sent'), findsOneWidget);
      expect(cart.quantityOf('tomato'), 1);

      orders
        ..saveOutcome = SaveOutcome.saved
        ..whatsAppOpens = true;
      await _tapSend(tester);

      expect(find.text('Press send in WhatsApp'), findsOneWidget);
      expect(orders.saved, hasLength(2));
      expect(orders.saved.last.ref, orders.saved.first.ref);
    });

    testWidgets('an unsaved order with no WhatsApp is not called received',
        (tester) async {
      final cart = CartController()..add(_tomato);
      final orders = _FakeOrders()
        ..saveOutcome = SaveOutcome.pending
        ..whatsAppOpens = false;
      await _openCheckout(tester, cart, orders);

      await _tapSend(tester);

      expect(find.text('Order received'), findsNothing);
      expect(find.textContaining('could not be sent'), findsOneWidget);
      expect(cart.quantityOf('tomato'), 1);
    });

    testWidgets('a variety withdrawn during checkout cannot be ordered',
        (tester) async {
      final cart = CartController()..add(_tomato);
      final orders = _FakeOrders();
      await _openCheckout(tester, cart, orders);

      cart.syncWithCatalog([_withdrawn(_tomato), _okra]);
      await tester.pump();

      expect(find.text('Nothing left to order'), findsOneWidget);
      expect(find.text('Send order on WhatsApp'), findsNothing);
      expect(
        find.text('Not available yet, so removed from your cart: Redo F1'),
        findsOneWidget,
      );
    });
  });
}
