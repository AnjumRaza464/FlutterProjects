// Tests for the admin panel's Orders view: reading order documents written by
// the public app, and the orders screen driven by a fake service.

import 'package:cassia_grower/admin/admin_order.dart';
import 'package:cassia_grower/admin/order_admin_service.dart';
import 'package:cassia_grower/admin/orders_screen.dart';
import 'package:cassia_grower/models/cart_item.dart';
import 'package:cassia_grower/models/seed_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

AdminOrder _order(
  String id, {
  required String ref,
  required String name,
  String phone = '0300 1234567',
  OrderStatus status = OrderStatus.placed,
}) {
  return AdminOrder(
    id: id,
    status: status,
    createdAt: DateTime(2026, 11, 21, 18, 45),
    order: SeedOrder(
      ref: ref,
      customer: CustomerDetails(
          name: name, phone: phone, city: 'Hyderabad', note: 'Before Friday'),
      items: const [
        CartItem(
            productId: 'tomato',
            name: 'Redo F1',
            crop: 'Tomato',
            packSize: '10 g',
            quantity: 2),
      ],
    ),
  );
}

/// Serves a fixed list of orders and records what the screen changes.
class _FakeOrders extends OrderAdminService {
  _FakeOrders(this.orders);

  final List<AdminOrder> orders;
  final Map<String, OrderStatus> statusChanges = {};
  final List<String> deleted = [];

  @override
  Stream<List<AdminOrder>> watchOrders() => Stream.value(orders);

  @override
  Future<void> setStatus(String id, OrderStatus status) async {
    statusChanges[id] = status;
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

Future<void> _show(WidgetTester tester, _FakeOrders service) async {
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: OrdersScreen(service: service)));
  await tester.pumpAndSettle();
}

void main() {
  group('AdminOrder.fromMap', () {
    test('reads an order the way the app writes it', () {
      // The same document SeedOrder.toMap() + OrderRepository produce.
      final written = const SeedOrder(
        ref: 'CS-261121-7K2M',
        customer: CustomerDetails(
            name: 'Ali Khan', phone: '0300 1234567', city: 'Hyderabad'),
        items: [CartItem(productId: 'tomato', name: 'Redo F1', quantity: 3)],
      ).toMap()
        ..['status'] = 'confirmed';

      final order = AdminOrder.fromMap('doc1', written,
          createdAt: DateTime(2026, 11, 21));

      expect(order.id, 'doc1');
      expect(order.status, OrderStatus.confirmed);
      expect(order.order.ref, 'CS-261121-7K2M');
      expect(order.order.customer.name, 'Ali Khan');
      expect(order.order.items.single.name, 'Redo F1');
      expect(order.order.totalQuantity, 3);
    });

    test('a malformed document becomes an empty order instead of crashing',
        () {
      final order = AdminOrder.fromMap('junk', {
        'ref': 42,
        'status': 'whatever',
        'customer': 'not a map',
        'items': [
          'not a map',
          {'name': 7, 'quantity': 'lots'},
        ],
      });

      expect(order.order.ref, '');
      expect(order.status, OrderStatus.placed);
      expect(order.order.customer.name, '');
      expect(order.order.items.single.name, '');
      expect(order.order.items.single.quantity, 1);
    });

    test('a document with no fields at all still loads', () {
      final order = AdminOrder.fromMap('empty', const {});

      expect(order.order.items, isEmpty);
      expect(order.status, OrderStatus.placed);
    });
  });

  group('AdminOrder.whatsAppNumber', () {
    String numberFor(String phone) =>
        _order('x', ref: 'r', name: 'n', phone: phone).whatsAppNumber;

    test('turns Pakistani local numbers into international ones', () {
      expect(numberFor('0300 1234567'), '923001234567');
      expect(numberFor('0300-1234567'), '923001234567');
      expect(numberFor('3001234567'), '923001234567');
    });

    test('keeps numbers that already have a country code', () {
      expect(numberFor('+92 300 1234567'), '923001234567');
      expect(numberFor('0092 300 1234567'), '923001234567');
    });

    test('is empty for something that is not a phone number', () {
      expect(numberFor('12345'), '');
      expect(numberFor(''), '');
    });
  });

  group('OrdersScreen', () {
    testWidgets('shows who ordered what, and when', (tester) async {
      await _show(
        tester,
        _FakeOrders([_order('a', ref: 'CS-1', name: 'Ali Khan')]),
      );

      expect(find.text('CS-1'), findsOneWidget);
      expect(find.text('21 Nov 2026, 6:45 PM'), findsOneWidget);
      expect(find.text('Ali Khan • Hyderabad'), findsOneWidget);
      expect(find.text('0300 1234567'), findsOneWidget);
      expect(find.text('Redo F1 (10 g), Tomato'), findsOneWidget);
      expect(find.text('× 2'), findsOneWidget);
      expect(find.text('Note: Before Friday'), findsOneWidget);
    });

    testWidgets('says so when there are no orders', (tester) async {
      await _show(tester, _FakeOrders([]));

      expect(find.textContaining('No orders yet'), findsOneWidget);
    });

    testWidgets('filters by status', (tester) async {
      await _show(
        tester,
        _FakeOrders([
          _order('a', ref: 'CS-NEW', name: 'Ali'),
          _order('b',
              ref: 'CS-DONE', name: 'Sara', status: OrderStatus.delivered),
        ]),
      );

      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('New (1)'), findsOneWidget);

      await tester.tap(find.text('Delivered (1)'));
      await tester.pumpAndSettle();

      expect(find.text('CS-DONE'), findsOneWidget);
      expect(find.text('CS-NEW'), findsNothing);

      await tester.tap(find.text('Cancelled (0)'));
      await tester.pumpAndSettle();

      expect(find.text('No cancelled orders.'), findsOneWidget);
    });

    testWidgets('the status pill changes an order\'s status', (tester) async {
      final service = _FakeOrders([_order('a', ref: 'CS-1', name: 'Ali')]);
      await _show(tester, service);

      await tester.tap(find.byTooltip('Change status'));
      await tester.pumpAndSettle();

      // The order's current status isn't offered.
      expect(find.text('Mark as New'), findsNothing);

      await tester.tap(find.text('Mark as Confirmed'));
      await tester.pumpAndSettle();

      expect(service.statusChanges, {'a': OrderStatus.confirmed});
    });

    testWidgets('deleting asks first', (tester) async {
      final service = _FakeOrders([_order('a', ref: 'CS-1', name: 'Ali')]);
      await _show(tester, service);

      await tester.tap(find.byTooltip('Delete order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(service.deleted, isEmpty);

      await tester.tap(find.byTooltip('Delete order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(service.deleted, ['a']);
    });

    testWidgets('a read failure points at the Firestore rules',
        (tester) async {
      final service = _FailingOrders();
      await _show(tester, service);

      expect(find.textContaining('Could not load orders'), findsOneWidget);
      expect(find.textContaining('Firestore rules'), findsOneWidget);
    });
  });

  group('OrdersButton', () {
    testWidgets('counts the orders nobody has handled yet', (tester) async {
      final service = _FakeOrders([
        _order('a', ref: 'CS-1', name: 'Ali'),
        _order('b', ref: 'CS-2', name: 'Sara'),
        _order('c', ref: 'CS-3', name: 'Omar', status: OrderStatus.confirmed),
      ]);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [OrdersButton(service: service)]),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byTooltip('Orders'));
      await tester.pumpAndSettle();

      expect(find.text('CS-1'), findsOneWidget);
    });
  });
}

class _FailingOrders extends _FakeOrders {
  _FailingOrders() : super([]);

  @override
  Stream<List<AdminOrder>> watchOrders() =>
      Stream.error(StateError('permission-denied'));
}
