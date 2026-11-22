import 'package:cloud_firestore/cloud_firestore.dart';

/// Where a dealer application stands. A dealer creates their account as
/// `pending`; a company admin moves it to `approved` or `rejected`. Only an
/// admin can change the status (enforced by the Firestore rules).
enum DealerStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  const DealerStatus(this.value, this.label);

  final String value;
  final String label;

  static DealerStatus parse(Object? value) =>
      values.firstWhere((s) => s.value == value, orElse: () => pending);
}

/// A dealer's account, stored at `dealers/{uid}`.
///
/// The dealer writes only their own application details and may read (never
/// change) their balance, tier and awards — those are set by the company's
/// admin / accountant. This mirrors the reference design, where balances live
/// behind admin-only writes.
class DealerAccount {
  const DealerAccount({
    required this.uid,
    required this.ownerName,
    required this.phone,
    this.businessName = '',
    this.city = '',
    this.district = '',
    this.shopAddress = '',
    this.products = '',
    this.notes = '',
    this.status = DealerStatus.pending,
    this.tier = '',
    this.outstandingBalance = 0,
    this.totalPurchases = 0,
    this.awards = const [],
    this.perks = const [],
    this.createdAt,
    this.reviewedAt,
  });

  factory DealerAccount.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    List<String> list(Object? v) => [
          if (v is List)
            for (final e in v)
              if (e is String && e.isNotEmpty) e,
        ];
    return DealerAccount(
      uid: doc.id,
      ownerName: _text(m['ownerName']),
      phone: _text(m['phone']),
      businessName: _text(m['businessName']),
      city: _text(m['city']),
      district: _text(m['district']),
      shopAddress: _text(m['shopAddress']),
      products: _text(m['products']),
      notes: _text(m['notes']),
      status: DealerStatus.parse(m['status']),
      tier: _text(m['tier']),
      outstandingBalance: _num(m['outstandingBalance']),
      totalPurchases: _num(m['totalPurchases']),
      awards: list(m['awards']),
      perks: list(m['perks']),
      createdAt: _date(m['createdAt']),
      reviewedAt: _date(m['reviewedAt']),
    );
  }

  final String uid;
  final String ownerName;
  final String phone;
  final String businessName;
  final String city;
  final String district;
  final String shopAddress;

  /// Free text: what the shop sells.
  final String products;

  /// Anything else the dealer wrote on the application.
  final String notes;

  final DealerStatus status;

  /// A label the admin may set (e.g. "Gold"). Empty when none.
  final String tier;

  /// Money the dealer still owes, and their lifetime purchases. Set only by
  /// the company; shown read-only on the dealer's dashboard.
  final num outstandingBalance;
  final num totalPurchases;

  /// Awards and tier perks the admin added.
  final List<String> awards;
  final List<String> perks;

  final DateTime? createdAt;
  final DateTime? reviewedAt;

  bool get isApproved => status == DealerStatus.approved;
  bool get isPending => status == DealerStatus.pending;

  /// The details the dealer writes when they apply. Balances start at zero and
  /// the status at `pending`; the rules reject anything else from a dealer.
  Map<String, Object?> toApplicationMap() => {
        'ownerName': ownerName,
        'phone': phone,
        'businessName': businessName,
        'city': city,
        'district': district,
        'shopAddress': shopAddress,
        'products': products,
        'notes': notes,
        'status': DealerStatus.pending.value,
        'tier': '',
        'outstandingBalance': 0,
        'totalPurchases': 0,
        'awards': <String>[],
        'perks': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      };

  static String _text(Object? v) => v is String ? v : '';
  static num _num(Object? v) => v is num ? v : 0;
  static DateTime? _date(Object? v) =>
      v is Timestamp ? v.toDate() : null;
}
