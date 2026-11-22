import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';

import '../models/crop_diagnosis.dart';
import '../models/crop_photo.dart';
import 'ai_failure.dart';

/// Picks crop photos and sends them to the `diagnoseCrop` Cloud Function,
/// which runs the OpenAI vision diagnosis server-side (keeping the API key
/// off the device).
class CropDoctorService {
  CropDoctorService({this._functions, ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  /// The most photos one diagnosis takes: the affected leaf, its underside
  /// and the whole plant.
  static const int maxPhotos = 3;

  // Photos are shrunk before upload, so three of them stay a small request.
  static const double _maxSide = 1024;
  static const int _quality = 85;

  // Resolved lazily so the screen can be built without Firebase.
  final FirebaseFunctions? _functions;
  final ImagePicker _picker;

  /// Opens the camera (or, with [ImageSource.gallery], the gallery for one
  /// photo). Returns null if the farmer cancels.
  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _quality,
    );
  }

  /// Opens the gallery to choose up to [limit] photos at once. Returns an
  /// empty list if the farmer cancels.
  Future<List<XFile>> pickFromGallery(int limit) async {
    if (limit < 1) return const [];
    final picked = await _picker.pickMultiImage(
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _quality,
      limit: limit,
    );
    // Not every phone's gallery enforces the limit.
    return picked.take(limit).toList();
  }

  /// Builds the request for the Cloud Function.
  ///
  /// [crop] and [stage] are sent as their English names whatever the app's
  /// language, so the server always reads the same words.
  static Map<String, dynamic> buildPayload(
    List<CropPhoto> photos, {
    String language = 'en',
    String crop = '',
    String stage = '',
    String days = '',
    String notes = '',
  }) {
    return {
      'images': [
        for (final photo in photos.take(maxPhotos))
          {'base64': base64Encode(photo.bytes), 'mimeType': photo.mimeType},
      ],
      'language': language == 'ur' ? 'ur' : 'en',
      'crop': crop.trim(),
      'stage': stage.trim(),
      'days': days.trim(),
      'notes': notes.trim(),
    };
  }

  /// Sends [photos] (one to three) for diagnosis. [language] is 'en' or
  /// 'ur'. The rest is optional detail from the farmer that makes the
  /// diagnosis more reliable: the [crop], its growth [stage], for how many
  /// [days] the problem has shown, and [notes] on sprays, water and weather.
  ///
  /// Throws an [AiFailure] if the diagnosis can't be completed.
  Future<CropDiagnosis> diagnose(
    List<CropPhoto> photos, {
    String language = 'en',
    String crop = '',
    String stage = '',
    String days = '',
    String notes = '',
  }) async {
    final callable = (_functions ?? FirebaseFunctions.instance).httpsCallable(
      'diagnoseCrop',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    try {
      final result = await callable.call(buildPayload(
        photos,
        language: language,
        crop: crop,
        stage: stage,
        days: days,
        notes: notes,
      ));
      final data = Map<String, dynamic>.from(result.data as Map);
      return CropDiagnosis.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      throw AiFailure.fromFunctions(e);
    } catch (_) {
      throw const AiFailure(AiFailureKind.other);
    }
  }
}
