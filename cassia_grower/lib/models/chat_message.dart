/// Who wrote a message in an Ask Cassia conversation.
enum ChatRole { user, assistant }

/// One message in an Ask Cassia conversation.
class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  const ChatMessage.user(this.text) : role = ChatRole.user;
  const ChatMessage.assistant(this.text) : role = ChatRole.assistant;

  final ChatRole role;
  final String text;

  bool get isUser => role == ChatRole.user;

  /// True when the message is mostly Urdu / Arabic script, so it should be
  /// laid out right-to-left. A stray English word in an Urdu answer (or the
  /// other way round) doesn't flip the direction.
  bool get isRtl {
    final rtl = _rtlLetters.allMatches(text).length;
    if (rtl == 0) return false;
    return rtl >= _latinLetters.allMatches(text).length;
  }

  /// The shape the `askCassia` Cloud Function expects.
  Map<String, dynamic> toMap() => {'role': role.name, 'text': text};

  static final _rtlLetters =
      RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');
  static final _latinLetters = RegExp(r'[A-Za-z]');
}
