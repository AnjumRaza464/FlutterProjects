import 'dart:async';

import '../data/order_repository.dart';
import '../models/seed_order.dart';
import 'launchers.dart';

/// What happened when an order was written to Firestore.
enum SaveOutcome {
  /// The server accepted it.
  saved,

  /// No answer yet (slow or no connection); Firestore keeps it queued on the
  /// phone and sends it when the connection returns.
  pending,

  /// The server rejected it.
  failed,
}

/// Sends a finished order to Cassia Seed: a record in Firestore for the admin
/// panel, and a WhatsApp message for the conversation about price.
class OrderService {
  OrderService({this._orders});

  // Resolved lazily so screens can be tested with a fake service.
  final OrderRepository? _orders;

  /// How long to wait for Firestore before moving on to WhatsApp, so a weak
  /// connection never leaves the farmer stuck on a spinner.
  static const saveTimeout = Duration(seconds: 5);

  Future<SaveOutcome> save(SeedOrder order) async {
    try {
      await (_orders ?? OrderRepository()).save(order).timeout(saveTimeout);
      return SaveOutcome.saved;
    } on TimeoutException {
      return SaveOutcome.pending;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }

  /// Opens WhatsApp with the order ready to send. Returns false if neither
  /// WhatsApp nor a browser could be opened.
  Future<bool> openWhatsApp(SeedOrder order) async {
    try {
      return await Launchers.sendOnWhatsApp(order.toWhatsAppMessage());
    } catch (_) {
      return false;
    }
  }
}
