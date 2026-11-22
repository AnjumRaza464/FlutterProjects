import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/seed_order.dart';

/// Writes order requests to the Firestore `orders` collection.
///
/// The mobile app only ever creates orders here; the admin web panel
/// (Phase 6) is what reads them and updates their status.
class OrderRepository {
  OrderRepository({this._firestore});

  // Resolved lazily so screens can be tested without Firebase.
  final FirebaseFirestore? _firestore;

  /// Saves [order] as a new document. Completes once the server has accepted
  /// it; while the phone is offline the write waits in Firestore's local
  /// queue and is sent when the connection returns.
  Future<void> save(SeedOrder order) {
    final db = _firestore ?? FirebaseFirestore.instance;
    return db.collection('orders').doc().set({
      ...order.toMap(),
      'status': 'new',
      'channel': 'whatsapp',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
