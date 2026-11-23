import 'package:cloud_firestore/cloud_firestore.dart';

/// A farmer's own account, stored at `farmers/{uid}` (uid = their Firebase
/// Auth id). The farmer reads and writes only their own document.
class FarmerProfile {
  const FarmerProfile({
    required this.uid,
    required this.name,
    required this.phone,
    this.district = '',
    this.town = '',
    this.village = '',
    this.crops = const [],
    this.createdAt,
  });

  factory FarmerProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final crops = m['crops'];
    return FarmerProfile(
      uid: doc.id,
      name: _text(m['name']),
      phone: _text(m['phone']),
      district: _text(m['district']),
      town: _text(m['town']),
      village: _text(m['village']),
      crops: [
        if (crops is List)
          for (final c in crops)
            if (c is String && c.isNotEmpty) c,
      ],
      createdAt: m['createdAt'] is Timestamp
          ? (m['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  final String uid;
  final String name;
  final String phone;
  final String district;

  /// The farmer's nearest city / town (e.g. "Hyderabad", "Tando Jam"). Used
  /// with [district] to find the dealers closest to them.
  final String town;
  final String village;
  final List<String> crops;
  final DateTime? createdAt;

  /// The fields written to Firestore when the farmer registers. `createdAt`
  /// is filled in by the server.
  Map<String, Object?> toCreateMap() => {
        'name': name,
        'phone': phone,
        'district': district,
        'town': town,
        'village': village,
        'crops': crops,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static String _text(Object? value) => value is String ? value : '';
}
