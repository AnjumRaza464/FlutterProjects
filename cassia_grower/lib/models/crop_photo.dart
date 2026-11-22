import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// One photo the farmer added for Crop Doctor: its bytes (shown in the photo
/// slot, then sent for diagnosis) and what kind of image it is.
class CropPhoto {
  const CropPhoto({required this.bytes, this.mimeType = 'image/jpeg'});

  final Uint8List bytes;
  final String mimeType;

  /// Reads a photo that came from the camera or the gallery.
  static Future<CropPhoto> fromFile(XFile file) async {
    return CropPhoto(bytes: await file.readAsBytes(), mimeType: _mimeOf(file));
  }

  static String _mimeOf(XFile file) {
    // The browser knows the type; a phone only gives a file name.
    final given = file.mimeType ?? '';
    if (given.startsWith('image/')) return given;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
