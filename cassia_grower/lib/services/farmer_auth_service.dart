import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/farmer_profile.dart';
import 'account_exception.dart';
import 'account_service.dart';

/// Signs farmers in and out and keeps their profile in Firestore.
///
/// A farmer signs in with their mobile number and a 6-digit secret number
/// (PIN). Behind the scenes the number becomes a Firebase Auth e-mail and the
/// PIN is the password — the farmer never sees that.
class FarmerAuthService {
  FarmerAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _farmers =>
      _db.collection(CassiaAccounts.farmersCollection);

  /// Creates the account and saves the farmer's profile. Throws an
  /// [AccountException] the screen can turn into a message.
  Future<void> register({
    required String name,
    required String phone,
    required String pin,
    String district = '',
    String town = '',
    String village = '',
    List<String> crops = const [],
  }) async {
    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: CassiaAccounts.farmerEmail(phone),
        password: pin,
      );
    } on FirebaseAuthException catch (e) {
      throw AccountException(_mapSignUp(e.code));
    } catch (_) {
      throw const AccountException(AccountError.other);
    }

    final uid = cred.user!.uid;
    try {
      await cred.user!.updateDisplayName(name);
      final profile = FarmerProfile(
        uid: uid,
        name: name,
        phone: CassiaAccounts.normalizePhone(phone),
        district: district,
        town: town,
        village: village,
        crops: crops,
      );
      await _farmers.doc(uid).set(profile.toCreateMap());
    } catch (_) {
      // The auth account exists but the profile write failed. Leave the
      // farmer signed in (their next open loads an empty profile) rather than
      // deleting the account they just made.
      throw const AccountException(AccountError.other);
    }
  }

  /// Signs an existing farmer in with their mobile number and secret number.
  Future<void> login({required String phone, required String pin}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: CassiaAccounts.farmerEmail(phone),
        password: pin,
      );
    } on FirebaseAuthException catch (e) {
      throw AccountException(_mapSignIn(e.code));
    } catch (_) {
      throw const AccountException(AccountError.other);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Updates just the farmer's location, so a farmer who registered before
  /// these fields existed (or who skipped them) can set their district and
  /// town from the Find a Dealer screen and get matched to nearby dealers.
  Future<void> updateLocation({
    required String uid,
    required String district,
    required String town,
  }) {
    return _farmers.doc(uid).set({
      'district': district,
      'town': town,
    }, SetOptions(merge: true));
  }

  /// The farmer's profile, read once (used by Find a Dealer to learn their
  /// district and town). Null if it hasn't been created yet.
  Future<FarmerProfile?> loadProfile(String uid) async {
    final doc = await _farmers.doc(uid).get();
    return doc.exists ? FarmerProfile.fromDoc(doc) : null;
  }

  /// The signed-in farmer's profile, kept live. Null until it loads or if
  /// nobody is signed in.
  Stream<FarmerProfile?> watchProfile(String uid) =>
      _farmers.doc(uid).snapshots().map(
            (doc) => doc.exists ? FarmerProfile.fromDoc(doc) : null,
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
