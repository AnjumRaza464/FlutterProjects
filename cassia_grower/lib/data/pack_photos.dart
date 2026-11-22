import '../models/product.dart';

/// The seed-pack photos bundled with the app (from the approved design).
///
/// A product normally shows the photo uploaded for it in the admin panel
/// ([Product.imageUrl]). When it has none, the app looks here for a bundled
/// photo of that same variety.
///
/// Real products only ever get THEIR OWN pack photo — matched by id or by
/// name — so a pack with another variety's name printed on it is never shown
/// against the wrong product. Demo products (ids starting `demo_`) are the
/// exception: they borrow a photo of the same crop, or any photo, purely so
/// the screens can be previewed with pictures.
class PackPhotos {
  PackPhotos._();

  static const _ids = {
    'redo', 'ahmer', 'champa', 'totalhot', 'guru', 'veer', 'mala', 'metro', //
    'zarar', 'kajal', 'h786', 'rani', 'peas', 'shandar', 'comander', 'roopa',
    'carrot', 'lucky', 'shella', 'queen',
  };

  /// Photos cut out from their background; these sit well on a colour.
  static const _cutOut = {'h786', 'peas', 'roopa', 'carrot', 'lucky', 'shella'};

  /// Extra photos of a pack, shown after its front in the product sheet's
  /// gallery: first the close-up, then the showcase.
  static const _extra = {
    'queen': ['queen_p', 'queen_f'],
  };

  /// Packs whose own colours differ from their crop's, as (light, deep):
  /// these cut-outs sit on their pack's colours, not the crop's.
  static const _wash = {
    'roopa': (0xFF4DB6AC, 0xFF0F4F43),
    'lucky': (0xFFFF8A65, 0xFF8E1B1B),
  };

  /// Words in a variety's name that identify its photo. Checked in order, so
  /// "Lucky Shandar" is recognised before plain "Shandar".
  static const _byName = [
    ('lucky shandar', 'lucky'),
    ('shandar', 'shandar'),
    ('comander', 'comander'),
    ('commander', 'comander'),
    ('total hot', 'totalhot'),
    ('h-786', 'h786'),
    ('h786', 'h786'),
    ('zarar', 'zarar'),
    ('champa', 'champa'),
    ('shella', 'shella'),
    ('roopa', 'roopa'),
    ('kajal', 'kajal'),
    ('ahmer', 'ahmer'),
    ('metro', 'metro'),
    ('redo', 'redo'),
    ('rani', 'rani'),
    ('mala', 'mala'),
    ('guru', 'guru'),
    ('veer', 'veer'),
    ('peas', 'peas'),
    ('carrot', 'carrot'),
    ('queen', 'queen'),
  ];

  /// For demo products only: photos of the same crop to borrow.
  static const _demoByCrop = [
    ('tomato', ['lucky', 'redo', 'ahmer', 'metro']),
    ('chilli', ['h786', 'champa', 'totalhot']),
    ('pepper', ['h786', 'champa', 'totalhot']),
    ('okra', ['shella', 'roopa', 'rani', 'mala']),
    ('bitter', ['comander', 'zarar']),
    ('gourd', ['guru', 'comander']),
    ('brinjal', ['kajal']),
    ('cucumber', ['veer']),
    ('pea', ['peas']),
    ('carrot', ['carrot']),
    ('paddy', ['shandar']),
    ('rice', ['shandar']),
  ];

  static const _all = [
    'lucky', 'shella', 'h786', 'roopa', 'peas', 'carrot', 'redo', 'kajal', //
    'veer', 'comander', 'rani', 'metro', 'guru', 'champa',
  ];

  /// The id of the bundled photo for [product], or null if there is none.
  static String? idFor(Product product) {
    if (_ids.contains(product.id)) return product.id;

    final name = ' ${product.name.toLowerCase()} ';
    final demo = product.id.startsWith('demo_');
    if (!demo) {
      for (final (words, id) in _byName) {
        if (RegExp('\\b${RegExp.escape(words)}\\b').hasMatch(name)) return id;
      }
      return null;
    }

    // A steady pick, so a demo product keeps the same photo every time.
    final pick = product.id.codeUnits.fold(0, (sum, c) => sum + c);
    final crop = product.crop.toLowerCase();
    for (final (word, ids) in _demoByCrop) {
      if (crop.contains(word)) return ids[pick % ids.length];
    }
    return _all[pick % _all.length];
  }

  /// The asset path of the bundled photo for [product], or null.
  static String? assetFor(Product product) {
    final id = idFor(product);
    return id == null ? null : 'assets/packs/$id.webp';
  }

  /// Whether [product]'s bundled photo is cut out from its background.
  static bool isCutOut(Product product) => _cutOut.contains(idFor(product));

  /// The asset paths of [product]'s extra photos (close-up, then showcase);
  /// empty for a pack that only has its front photo.
  static List<String> extraAssetsFor(Product product) => [
        for (final id in _extra[idFor(product)] ?? const <String>[])
          'assets/packs/$id.webp',
      ];

  /// The colours (light, deep) of [product]'s own pack, as ARGB values, or
  /// null when its crop's colours suit it.
  static (int, int)? washFor(Product product) => _wash[idFor(product)];
}
