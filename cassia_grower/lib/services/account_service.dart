import 'package:firebase_auth/firebase_auth.dart';

/// Which kind of account is signed in on this device.
///
/// The farmer app and the dealer portal both sign in through the same
/// Firebase Auth project, so only one person is signed in at a time. We tell
/// a farmer from a dealer by the synthetic e-mail the app gave them: a real
/// e-mail (or none) means neither — a company admin, or signed out.
enum AccountRole { none, farmer, dealer }

/// Shared helpers for the mobile-number + PIN / password sign-in used by the
/// farmer login and the dealer portal.
///
/// The reference design signs people in with their mobile number, so we map
/// the number to a Firebase Auth e-mail (`<number>@farmer.cassiaseed.app` or
/// `…@dealer.cassiaseed.app`) and use the PIN / password as the Firebase
/// password. The farmer app never shows these e-mails — the farmer only ever
/// types a phone number and a secret number.
class CassiaAccounts {
  CassiaAccounts._();

  static const String farmerDomain = 'farmer.cassiaseed.app';
  static const String dealerDomain = 'dealer.cassiaseed.app';

  /// Firestore collections the accounts live in.
  static const String farmersCollection = 'farmers';
  static const String dealersCollection = 'dealers';

  /// Turns whatever the farmer typed into a plain number with Pakistan's
  /// country code and no spaces: `0325 5557303` → `923255557303`,
  /// `+92 325…` → `923255557303`. Used as the stable key for the account.
  static String normalizePhone(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) {
      d = '92${d.substring(1)}';
    } else if (!d.startsWith('92') && d.length == 10) {
      d = '92$d';
    }
    return d;
  }

  /// A readable Pakistani mobile number must look like a local `03xx xxxxxxx`
  /// (11 digits) — i.e. `923…` and 12 digits once normalised.
  static bool isValidMobile(String raw) {
    final d = normalizePhone(raw);
    return d.length == 12 && d.startsWith('923');
  }

  static String farmerEmail(String phone) =>
      '${normalizePhone(phone)}@$farmerDomain';

  static String dealerEmail(String phone) =>
      '${normalizePhone(phone)}@$dealerDomain';

  /// The role of the signed-in user, read from their e-mail suffix.
  static AccountRole roleOf(User? user) {
    final email = user?.email ?? '';
    if (email.endsWith('@$dealerDomain')) return AccountRole.dealer;
    if (email.endsWith('@$farmerDomain')) return AccountRole.farmer;
    return AccountRole.none;
  }
}
