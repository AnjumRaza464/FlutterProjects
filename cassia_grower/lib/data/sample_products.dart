import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

/// DEMO products used only to preview and test the app before the real
/// catalog is provided.
///
/// Every name is suffixed "(demo)" and every `printedInfo` says "sample data"
/// so these can never be mistaken for the real Cassia Seed catalog — replace
/// them with real varieties via the admin panel (Phase 6) or a proper import.
///
/// A mix of available / not-available items is included so the auto-sorting
/// and the "Not available yet" overlay can both be seen.
const String _sample = 'Sample data — replace before launch';

const List<Product> kSampleProducts = [
  Product(
    id: 'demo_tomato_hybrid',
    name: 'Tomato Hybrid F1 (demo)',
    crop: 'Tomato',
    cropKey: 'tomato',
    type: 'Hybrid',
    packSize: '10 g',
    printedInfo: 'Germination 85% • Purity 98% • $_sample',
    available: true,
    sortOrder: 10,
    isNew: true,
  ),
  Product(
    id: 'demo_chilli_desi',
    name: 'Hot Chilli Desi (demo)',
    crop: 'Chilli',
    cropKey: 'chilli',
    type: 'Selection',
    packSize: '50 g',
    printedInfo: 'Germination 80% • Purity 97% • $_sample',
    available: true,
    sortOrder: 20,
  ),
  Product(
    id: 'demo_okra_green',
    name: 'Green Okra F1 (demo)',
    crop: 'Okra',
    cropKey: 'okra',
    type: 'Hybrid',
    packSize: '250 g',
    printedInfo: 'Germination 82% • Purity 98% • $_sample',
    available: true,
    sortOrder: 30,
  ),
  Product(
    id: 'demo_brinjal_round',
    name: 'Round Brinjal (demo)',
    crop: 'Brinjal',
    cropKey: 'brinjal',
    type: 'Hybrid',
    packSize: '25 g',
    printedInfo: 'Germination 83% • Purity 98% • $_sample',
    available: true,
    sortOrder: 40,
  ),
  Product(
    id: 'demo_bitter_gourd',
    name: 'Bitter Gourd Long (demo)',
    crop: 'Bitter Gourd',
    cropKey: 'bitter_gourd',
    type: 'Hybrid',
    packSize: '100 g',
    printedInfo: 'Germination 78% • Purity 96% • $_sample',
    available: true,
    sortOrder: 50,
  ),
  Product(
    id: 'demo_bottle_gourd',
    name: 'Bottle Gourd (demo)',
    crop: 'Bottle Gourd',
    cropKey: 'bottle_gourd',
    type: 'Hybrid',
    packSize: '100 g',
    printedInfo: 'Germination 80% • Purity 97% • $_sample',
    available: true,
    sortOrder: 60,
  ),
  Product(
    id: 'demo_watermelon',
    name: 'Watermelon Sugar Baby (demo)',
    crop: 'Watermelon',
    cropKey: 'watermelon',
    type: 'Hybrid',
    packSize: '50 g',
    brandLine: 'MalaPine',
    printedInfo: 'Germination 85% • Purity 98% • $_sample',
    available: true,
    sortOrder: 70,
    isNew: true,
  ),
  Product(
    id: 'demo_muskmelon',
    name: 'Muskmelon Honeydew (demo)',
    crop: 'Muskmelon',
    cropKey: 'muskmelon',
    type: 'Hybrid',
    packSize: '50 g',
    printedInfo: 'Germination 84% • Purity 97% • $_sample',
    available: true,
    sortOrder: 80,
  ),
  Product(
    id: 'demo_cucumber_hybrid',
    name: 'Cucumber Hybrid F1 (demo)',
    crop: 'Cucumber',
    cropKey: 'cucumber',
    type: 'Hybrid',
    packSize: '25 g',
    printedInfo: 'Germination 86% • Purity 98% • $_sample',
    available: true,
    sortOrder: 90,
  ),
  Product(
    id: 'demo_onion_red',
    name: 'Onion Red (demo)',
    crop: 'Onion',
    cropKey: 'onion',
    type: 'Selection',
    packSize: '500 g',
    printedInfo: 'Germination 78% • Purity 96% • $_sample',
    available: true,
    sortOrder: 100,
  ),
  Product(
    id: 'demo_cabbage',
    name: 'Cabbage Drumhead (demo)',
    crop: 'Cabbage',
    cropKey: 'cabbage',
    type: 'Hybrid',
    packSize: '25 g',
    printedInfo: 'Germination 82% • Purity 97% • $_sample',
    available: true,
    sortOrder: 110,
  ),
  Product(
    id: 'demo_cauliflower',
    name: 'Cauliflower Snowball (demo)',
    crop: 'Cauliflower',
    cropKey: 'cauliflower',
    type: 'Hybrid',
    packSize: '25 g',
    printedInfo: 'Not yet registered — coming soon • $_sample',
    available: false, // shows the "Not available yet" overlay
    sortOrder: 120,
  ),
  Product(
    id: 'demo_carrot',
    name: 'Carrot Red Long (demo)',
    crop: 'Carrot',
    cropKey: 'carrot',
    type: 'Selection',
    packSize: '500 g',
    printedInfo: 'Not yet registered — coming soon • $_sample',
    available: false,
    sortOrder: 130,
  ),
  Product(
    id: 'demo_spinach',
    name: 'Spinach Desi (demo)',
    crop: 'Spinach',
    cropKey: 'spinach',
    type: 'Selection',
    packSize: '1 kg',
    printedInfo: 'Not yet registered — coming soon • $_sample',
    available: false,
    sortOrder: 140,
  ),
  Product(
    id: 'demo_coriander',
    name: 'Coriander Local (demo)',
    crop: 'Coriander',
    cropKey: 'coriander',
    type: 'Selection',
    packSize: '1 kg',
    printedInfo: 'Not yet registered — coming soon • $_sample',
    available: false,
    sortOrder: 150,
    isNew: true,
  ),
];

/// Writes the demo products to Firestore. Triggered only by an explicit
/// developer action in the app (the Shop empty-state button), never
/// automatically — so nothing is written to the live project unless asked.
Future<void> seedSampleProducts() async {
  final col = FirebaseFirestore.instance.collection('products');
  final batch = FirebaseFirestore.instance.batch();
  for (final p in kSampleProducts) {
    batch.set(col.doc(p.id), p.toMap());
  }
  await batch.commit();
}
