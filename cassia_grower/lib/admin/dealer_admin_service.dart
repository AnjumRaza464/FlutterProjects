import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dealer_account.dart';

/// Reads and manages the `dealers` collection from the admin panel: reviewing
/// applications and setting each dealer's balance, tier and awards.
///
/// Dealers themselves can only create their application and read their own
/// account; every change here is admin-only, enforced by the Firestore rules
/// (see lib/admin/ADMIN.md).
class DealerAdminService {
  DealerAdminService({this._firestore});

  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      (_firestore ?? FirebaseFirestore.instance).collection('dealers');

  /// Live list of dealers, applications waiting for review first, then the
  /// rest by newest.
  Stream<List<DealerAccount>> watchDealers() {
    return _col.limit(400).snapshots().map((snap) {
      final list = [for (final doc in snap.docs) DealerAccount.fromDoc(doc)];
      list.sort((a, b) {
        // Pending first.
        if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
        final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Future<void> approve(String uid) => _col.doc(uid).update({
        'status': DealerStatus.approved.value,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

  Future<void> reject(String uid) => _col.doc(uid).update({
        'status': DealerStatus.rejected.value,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

  /// Updates the dealer's ledger, tier, awards and perks in one write.
  Future<void> setAccount(
    String uid, {
    required num outstandingBalance,
    required num totalPurchases,
    required String tier,
    required List<String> awards,
    required List<String> perks,
  }) {
    return _col.doc(uid).update({
      'outstandingBalance': outstandingBalance,
      'totalPurchases': totalPurchases,
      'tier': tier,
      'awards': awards,
      'perks': perks,
      'ledgerUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String uid) => _col.doc(uid).delete();
}
