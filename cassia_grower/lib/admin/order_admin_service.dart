import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_order.dart';

/// Reads and manages the `orders` collection, used only by the admin panel.
///
/// The mobile app only ever creates orders (see OrderRepository). Firestore
/// security rules should restrict reading and changing them to signed-in
/// admins (see lib/admin/ADMIN.md).
class OrderAdminService {
  OrderAdminService({this._firestore});

  // Resolved lazily so the orders screen can be tested with a fake service.
  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      (_firestore ?? FirebaseFirestore.instance).collection('orders');

  /// Live list of the most recent orders, newest first.
  Stream<List<AdminOrder>> watchOrders() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => [
              for (final doc in snap.docs)
                AdminOrder.fromMap(
                  doc.id,
                  doc.data(),
                  createdAt: _date(doc.data()['createdAt']),
                ),
            ]);
  }

  Future<void> setStatus(String id, OrderStatus status) {
    return _col.doc(id).update({
      'status': status.value,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}
