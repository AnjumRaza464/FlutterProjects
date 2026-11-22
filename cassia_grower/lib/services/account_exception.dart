/// Why a sign-in or sign-up failed, in terms the UI can show the farmer in
/// their own language (the services never build user-facing text themselves).
enum AccountError {
  /// A sign-up where the mobile number is already registered.
  alreadyExists,

  /// A sign-in where the number or the secret number / password was wrong.
  wrongCredentials,

  /// The phone had no internet.
  network,

  /// Anything else — a server error, an unexpected state.
  other,
}

class AccountException implements Exception {
  const AccountException(this.error);

  final AccountError error;

  @override
  String toString() => 'AccountException($error)';
}
