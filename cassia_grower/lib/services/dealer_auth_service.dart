import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/dealer_account.dart';
import 'account_exception.dart';
import 'account_service.dart';

/// Signs dealers in and out and stores their account/application in Firestore.
///
/// A dealer signs in with their mobile number and a password (8+ characters).
/// Applying creates the Firebase Auth account and a `dealers/{uid}` document
/// with status `pending`; a company admin later approves it and sets the
/// balance, tier and awards (the dealer can only read those).
class DealerAuthService {
  DealerAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _dealers =>
      _db.collection(CassiaAccounts.dealersCollection);

  /// Creates the dealer's account and files their application.
  Future<void> apply({
    required String ownerName,
    required String phone,
    required String password,
    String businessName = '',
    String city = '',
    String district = '',
    String shopAddress = '',
    String products = '',
    String notes = '',
  }) async {
    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: CassiaAccounts.dealerEmail(phone),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AccountException(_mapSignUp(e.code));
    } catch (_) {
      throw const AccountException(AccountError.other);
    }

    final uid = cred.user!.uid;
    try {
      await cred.user!.updateDisplayName(ownerName);
      final account = DealerAccount(
        uid: uid,
        ownerName: ownerName,
        phone: CassiaAccounts.normalizePhone(phone),
        businessName: businessName,
        city: city,
        district: district,
        shopAddress: shopAddress,
        products: products,
        notes: notes,
      );
      await _dealers.doc(uid).set(account.toApplicationMap());
    } catch (_) {
      throw const AccountException(AccountError.other);
    }
  }

  /// Signs an existing dealer in.
  Future<void> login({required String phone, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: CassiaAccounts.dealerEmail(phone),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AccountException(_mapSignIn(e.code));
    } catch (_) {
      throw const AccountException(AccountError.other);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// The signed-in dealer's account, kept live.
  Stream<DealerAccount?> watchAccount(String uid) =>
      _dealers.doc(uid).snapshots().map(
            (doc) => doc.exists ? DealerAccount.fromDoc(doc) : null,
          );

  static AccountError _mapSignUp(String code) => switch (code) {
        'email-already-in-use' => AccountError.alreadyExists,
        'network-request-failed' => AccountError.network,
        _ => AccountError.other,
      };

  static AccountError _mapSignIn(String code) => switch (code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          AccountError.wrongCredentials,
        'network-request-failed' => AccountError.network,
        _ => AccountError.other,
      };
}
