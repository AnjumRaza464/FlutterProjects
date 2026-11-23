import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dealer_account.dart';
import '../models/dealer_listing.dart';

/// Reads and manages the `dealers` collection from the admin panel: reviewing
/// applications and setting each dealer's balance, tier and awards.
///
/// Dealers themselves can only create their application and read their own
/// account; every change here is admin-only, enforced by the Firestore rules
/// (see lib/admin/ADMIN.md).
class DealerAdminService {
  DealerAdminService({this._firestore});

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('dealers');

  /// The public listing a farmer sees in "Find a Dealer". Mirrored from an
  /// approved dealer; holds no private balance / ledger data.
  CollectionReference<Map<String, dynamic>> get _directory =>
      _db.collection('dealer_directory');

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

  /// Approves a dealer and publishes their public listing so farmers can find
  /// them. Takes the full account so the listing can be built without an extra
  /// read.
  Future<void> approve(DealerAccount dealer) async {
    await _col.doc(dealer.uid).update({
      'status': DealerStatus.approved.value,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    await _publishListing(dealer);
  }

  /// (Re)writes an approved dealer's public listing in `dealer_directory`.
  /// Called on approve and again whenever their details are saved — this also
  /// backfills dealers that were approved before the directory existed.
  Future<void> relist(DealerAccount dealer) => _publishListing(dealer);

  Future<void> _publishListing(DealerAccount dealer) =>
      _directory.doc(dealer.uid).set(DealerListing.fromAccount(dealer).toMap());

  /// Rejects a dealer and removes any public listing they had.
  Future<void> reject(String uid) async {
    await _col.doc(uid).update({
      'status': DealerStatus.rejected.value,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    await _directory.doc(uid).delete();
  }

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

  Future<void> delete(String uid) async {
    await _col.doc(uid).delete();
    await _directory.doc(uid).delete();
  }
}
