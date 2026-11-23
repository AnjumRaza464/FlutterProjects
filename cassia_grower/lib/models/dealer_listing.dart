import 'package:cloud_firestore/cloud_firestore.dart';

import 'dealer_account.dart';

/// A dealer as a farmer sees them in "Find a Dealer" — a public, read-only
/// listing stored at `dealer_directory/{uid}`.
///
/// This is deliberately separate from `dealers/{uid}`: the dealer document
/// holds private business data (outstanding balance, lifetime purchases, tier,
/// awards). The directory carries only what is safe to show every signed-in
/// farmer — the shop's name, where it is, and how to reach it. An admin writes
/// a directory entry when they approve a dealer and removes it on rejection,
/// so farmers only ever see approved dealers.
class DealerListing {
  const DealerListing({
    required this.uid,
    this.businessName = '',
    this.ownerName = '',
    this.phone = '',
    this.district = '',
    this.town = '',
    this.shopAddress = '',
    this.products = '',
  });

  factory DealerListing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return DealerListing(
      uid: doc.id,
      businessName: _text(m['businessName']),
      ownerName: _text(m['ownerName']),
      phone: _text(m['phone']),
      district: _text(m['district']),
      town: _text(m['town']),
      shopAddress: _text(m['shopAddress']),
      products: _text(m['products']),
    );
  }

  /// Builds the public listing from a full dealer account (used by the admin
  /// panel when a dealer is approved). The dealer's "city" field is the
  /// town-level location used for matching.
  factory DealerListing.fromAccount(DealerAccount a) => DealerListing(
        uid: a.uid,
        businessName: a.businessName,
        ownerName: a.ownerName,
        phone: a.phone,
        district: a.district,
        town: a.city,
        shopAddress: a.shopAddress,
        products: a.products,
      );

  final String uid;
  final String businessName;
  final String ownerName;
  final String phone;
  final String district;
  final String town;
  final String shopAddress;
  final String products;

  /// A friendly name to show: the shop name, else the owner's name.
  String get displayName =>
      businessName.isNotEmpty ? businessName : ownerName;

  Map<String, Object?> toMap() => {
        'businessName': businessName,
        'ownerName': ownerName,
        'phone': phone,
        'district': district,
        'town': town,
        'shopAddress': shopAddress,
        'products': products,
        'listedAt': FieldValue.serverTimestamp(),
      };

  /// Normalises a place name so two spellings of the same town compare equal:
  /// lower-cased, trimmed, with spaces and punctuation removed. "Tando Jam",
  /// "tando jam" and "Tandojam" all become "tandojam".
  static String normalizePlace(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String _text(Object? v) => v is String ? v : '';
}
