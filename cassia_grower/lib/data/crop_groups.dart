import '../models/product.dart';

/// The Shop's filter groups, as in the approved design: a few broad groups
/// ("Gourds", "Other Veg") rather than one chip for every crop.
///
/// Listed in the order their chips are shown.
enum CropGroup {
  tomato,
  pepper,
  gourd,
  okra,
  veg,
  field;

  /// Crops grown by the field rather than the vegetable bed.
  static const _fieldCrops = [
    'paddy', 'rice', 'wheat', 'maize', 'corn', 'cotton', 'sorghum', //
    'millet', 'sunflower', 'mustard', 'canola', 'barley', 'sugarcane',
  ];

  /// The group [product] is listed under.
  static CropGroup of(Product product) =>
      ofCrop('${product.cropKey} ${product.crop}');

  /// The group for a crop, from its name or its key ("Bitter gourd",
  /// "hot_pepper"). A crop that fits no other group is a vegetable.
  static CropGroup ofCrop(String crop) {
    final text = crop.toLowerCase();
    if (text.contains('tomato')) return tomato;
    if (['pepper', 'chilli', 'chili', 'capsicum'].any(text.contains)) {
      return pepper;
    }
    if (text.contains('gourd')) return gourd;
    if (text.contains('okra')) return okra;
    if (_fieldCrops.any(text.contains)) return field;
    return veg;
  }
}
