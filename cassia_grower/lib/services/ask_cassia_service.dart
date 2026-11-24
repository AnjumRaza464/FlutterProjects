import 'package:cloud_functions/cloud_functions.dart';

import '../models/chat_message.dart';
import '../models/product.dart';
import 'ai_failure.dart';

/// Sends an Ask Cassia conversation to the `askCassia` Cloud Function, which
/// runs the AI chat server-side (keeping the API key off the device).
class AskCassiaService {
  AskCassiaService({this._functions});

  // Resolved lazily so the screen can be built (and tested with a fake
  // service) without Firebase being initialised.
  final FirebaseFunctions? _functions;

  /// How many of the most recent messages are sent as context. The server
  /// enforces the same cap.
  static const int maxHistory = 12;

  /// Builds the request for the Cloud Function.
  ///
  /// Only the product's id, name and crop are sent: the server looks the
  /// product up itself, so whether it can be ordered always comes from
  /// Firestore, never from the app.
  static Map<String, dynamic> buildPayload(
    List<ChatMessage> history, {
    String language = 'en',
    Product? product,
  }) {
    final recent = history.length > maxHistory
        ? history.sublist(history.length - maxHistory)
        : history;
    return {
      'messages': [for (final m in recent) m.toMap()],
      // The server answers in English or Urdu only; the regional languages
      // (Sindhi, Punjabi, Pashto, Balochi) are answered in Urdu, which their
      // speakers read, rather than English.
      'language': language == 'en' ? 'en' : 'ur',
      if (product != null)
        'product': {
          'id': product.id,
          'name': product.name,
          'crop': product.crop,
        },
    };
  }

  /// Asks for the next reply. [history] is the whole conversation so far and
  /// must end with the farmer's latest question. [language] is 'en' or 'ur'.
  /// [product] is set when the chat was opened from a product page.
  ///
  /// Throws an [AiFailure] if no answer could be had.
  Future<String> ask(
    List<ChatMessage> history, {
    String language = 'en',
    Product? product,
  }) async {
    final callable = (_functions ?? FirebaseFunctions.instance).httpsCallable(
      'askCassia',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    try {
      final result = await callable.call(
        buildPayload(history, language: language, product: product),
      );
      final data = Map<String, dynamic>.from(result.data as Map);
      final reply = ((data['reply'] ?? '') as String).trim();
      if (reply.isEmpty) throw const AiFailure(AiFailureKind.other);
      return reply;
    } on AiFailure {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      throw AiFailure.fromFunctions(e);
    } catch (_) {
      throw const AiFailure(AiFailureKind.other);
    }
  }
}
