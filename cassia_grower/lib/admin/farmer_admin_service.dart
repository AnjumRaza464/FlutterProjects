import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/farmer_profile.dart';
import '../services/account_service.dart';

/// Reads the `farmers` collection for the admin panel's Farmers list.
///
/// Farmers write only their own profile; the Firestore rules let an admin
/// read them all but never change them (see lib/admin/ADMIN.md).
class FarmerAdminService {
  FarmerAdminService({this._firestore});

  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      (_firestore ?? FirebaseFirestore.instance)
          .collection(CassiaAccounts.farmersCollection);

  /// Live list of registered farmers, newest first.
  Stream<List<FarmerProfile>> watchFarmers() {
    return _col.limit(500).snapshots().map((snap) {
      final list = [for (final doc in snap.docs) FarmerProfile.fromDoc(doc)];
      list.sort((a, b) {
        final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
      return list;
    });
  }
}
