import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/product.dart';

/// Write access to the `products` catalog, used only by the admin panel.
///
/// The mobile app never calls this — it only reads (see ProductRepository).
/// Firestore security rules should restrict these writes to signed-in admins
/// (see lib/admin/ADMIN.md).
class ProductAdminService {
  ProductAdminService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _col = (firestore ?? FirebaseFirestore.instance).collection('products'),
        _storage = storage ?? FirebaseStorage.instance;

  final CollectionReference<Map<String, dynamic>> _col;
  final FirebaseStorage _storage;

  /// A fresh document id for a new product, so its image can be uploaded under
  /// the same id before the document itself is written.
  String newId() => _col.doc().id;

  /// Creates or overwrites the product document at [id].
  Future<void> save(String id, Product product) => _col.doc(id).set(product.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Quick availability flip from the dashboard.
  Future<void> setAvailable(String id, bool value) =>
      _col.doc(id).update({'available': value});

  /// Uploads a product image to Storage and returns its download URL.
  Future<String> uploadImage(
    String id,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref('products/$id');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
