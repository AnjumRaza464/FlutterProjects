/// A seed variety / product in the Cassia catalog.
///
/// Each product is stored as one document in the Firestore `products`
/// collection. The admin web panel edits these documents; the mobile app
/// only reads them.
class Product {
  final String id; // document id, e.g. "redo"
  final String name; // e.g. "Redo F1"
  final String crop; // e.g. "Tomato"
  final String cropKey; // filter key, e.g. "tomato"
  final String type; // e.g. "Hybrid" / "Selection"
  final String packSize; // e.g. "10 g" (may be empty)
  final String brandLine; // e.g. "MalaPine" (optional sub-brand)
  final String printedInfo; // germination/purity text printed on pack
  final String imageUrl; // Firebase Storage image URL

  /// Whether the variety can be ordered.
  /// When false, the app shows a "Not available yet" overlay and hides the
  /// order button (legal safety for unregistered varieties).
  final bool available;

  /// Controls list position. Lower number = higher up.
  /// Available items are shown above not-available ones.
  final int sortOrder;

  final bool isNew; // show a "NEW" badge

  /// Selling points of the variety, one short line each, shown under
  /// "Features" on its page. Empty until Cassia supplies them.
  final List<String> features;

  const Product({
    required this.id,
    required this.name,
    required this.crop,
    required this.cropKey,
    this.type = '',
    this.packSize = '',
    this.brandLine = '',
    this.printedInfo = '',
    this.imageUrl = '',
    this.available = true,
    this.sortOrder = 0,
    this.isNew = false,
    this.features = const [],
  });

  /// Build a Product from a Firestore document map.
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: (map['name'] ?? '') as String,
      crop: (map['crop'] ?? '') as String,
      cropKey: (map['cropKey'] ?? '') as String,
      type: (map['type'] ?? '') as String,
      packSize: (map['packSize'] ?? '') as String,
      brandLine: (map['brandLine'] ?? '') as String,
      printedInfo: (map['printedInfo'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
      available: (map['available'] ?? true) as bool,
      sortOrder: (map['sortOrder'] ?? 0) as int,
      isNew: (map['isNew'] ?? false) as bool,
      features: [
        for (final line in (map['features'] as List?) ?? const [])
          if (line is String && line.trim().isNotEmpty) line.trim(),
      ],
    );
  }

  /// Whether this product matches what a farmer typed in the Shop's search
  /// box. Every word of [query] must appear somewhere in the name, crop,
  /// type, sub-brand or pack size; upper/lower case doesn't matter. An empty
  /// query matches everything.
  bool matchesSearch(String query) {
    final text = [name, crop, type, brandLine, packSize].join(' ').toLowerCase();
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .every(text.contains);
  }

  /// Convert to a map for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'crop': crop,
      'cropKey': cropKey,
      'type': type,
      'packSize': packSize,
      'brandLine': brandLine,
      'printedInfo': printedInfo,
      'imageUrl': imageUrl,
      'available': available,
      'sortOrder': sortOrder,
      'isNew': isNew,
      'features': features,
    };
  }
}
