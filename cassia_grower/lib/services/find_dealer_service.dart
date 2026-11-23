import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dealer_listing.dart';

/// Finds the dealers closest to a farmer, reading the public
/// `dealer_directory` collection (approved dealers only — see
/// [DealerAdminService]).
///
/// How "closest" works, without needing GPS:
///  1. Hard filter — only dealers in the farmer's own **district**. This is a
///     canonical, picked-from-a-list value on both sides, so the match is
///     exact and reliable.
///  2. Ranking — within that district, dealers whose **town** matches the
///     farmer's town (e.g. both "Tando Jam") come first; the rest of the
///     district follows as a fallback, so the list is never empty when there
///     is any dealer in the district.
class FindDealerService {
  FindDealerService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _directory =>
      _db.collection('dealer_directory');

  /// Dealers in [district], with those in the same [town] first.
  Future<List<DealerListing>> nearby({
    required String district,
    String town = '',
  }) async {
    if (district.trim().isEmpty) return const [];

    final snap =
        await _directory.where('district', isEqualTo: district).limit(200).get();
    final dealers = [for (final doc in snap.docs) DealerListing.fromDoc(doc)];

    final wantedTown = DealerListing.normalizePlace(town);
    dealers.sort((a, b) {
      if (wantedTown.isNotEmpty) {
        final aSame = DealerListing.normalizePlace(a.town) == wantedTown;
        final bSame = DealerListing.normalizePlace(b.town) == wantedTown;
        if (aSame != bSame) return aSame ? -1 : 1;
      }
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return dealers;
  }
}
