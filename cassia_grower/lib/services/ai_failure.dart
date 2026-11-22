import 'package:cloud_functions/cloud_functions.dart';

/// Why a request to one of the AI Cloud Functions failed.
enum AiFailureKind {
  /// The function isn't deployed yet.
  notSetUp,

  /// The phone couldn't reach the server.
  offline,

  /// Anything else; the server may have said why.
  other,
}

/// Thrown by the Crop Doctor and Ask Cassia services. Screens turn it into a
/// message in the farmer's language.
class AiFailure implements Exception {
  const AiFailure(this.kind, {this.serverMessage});

  /// Sorts a Cloud Functions error into a kind the screens can explain.
  factory AiFailure.fromFunctions(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
        return const AiFailure(AiFailureKind.notSetUp);
      case 'unavailable':
      case 'deadline-exceeded':
        return const AiFailure(AiFailureKind.offline);
    }
    // A crash on the server arrives with just the code as its message
    // ("INTERNAL"), which is no use to a farmer.
    final message = e.message ?? '';
    final meaningful = message.isNotEmpty &&
        message.toLowerCase() != e.code.replaceAll('-', '_') &&
        message.toLowerCase() != e.code;
    return AiFailure(
      AiFailureKind.other,
      serverMessage: meaningful ? message : null,
    );
  }

  final AiFailureKind kind;

  /// The server's own explanation (in English), when it gave one — for
  /// example "Image is too large. Please use a smaller photo."
  final String? serverMessage;

  @override
  String toString() => 'AiFailure(${kind.name}, $serverMessage)';
}
