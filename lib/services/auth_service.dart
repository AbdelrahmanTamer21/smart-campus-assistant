import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_config.dart';
import '../models/user_profile.dart';

/// Wraps Firebase Auth + the user profile record. University ID maps to a
/// synthetic email (`{idNumber}@campus.local`); the visible identity is the ID.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _functions = functions ?? _defaultFunctions();

  static FirebaseFunctions _defaultFunctions() {
    if (AppConfig.useEmulator) return FirebaseFunctions.instance;
    // redeemSignupToken is deployed in us-central1.
    return FirebaseFunctions.instanceFor(region: 'us-central1');
  }

  static String emailFor(String idNumber) => '${idNumber.trim()}@campus.local';

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String idNumber, String password) {
    return _auth.signInWithEmailAndPassword(
        email: emailFor(idNumber), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String idNumber) =>
      _auth.sendPasswordResetEmail(email: emailFor(idNumber));

  /// Loads the institutional record bound to the signed-in [authUid].
  Future<UserProfile?> loadProfile(String authUid) async {
    final q = await _db
        .collection('users')
        .where('authUid', isEqualTo: authUid)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return UserProfile.fromDoc(q.docs.first);
  }

  Stream<UserProfile?> watchProfile(String authUid) {
    return _db
        .collection('users')
        .where('authUid', isEqualTo: authUid)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : UserProfile.fromDoc(s.docs.first));
  }

  /// Redeems a one-time QR activation token: server-side it creates the auth
  /// user, binds it to the existing record, and marks the token used.
  Future<void> redeemSignupToken({
    required String token,
    required String password,
  }) async {
    try {
      final callable = _functions.httpsCallable('redeemSignupToken');
      final res = await callable.call({'token': token, 'password': password});
      final data = Map<String, dynamic>.from(res.data as Map);
      final idNumber = data['idNumber'] as String;
      await _auth.signInWithEmailAndPassword(
          email: emailFor(idNumber), password: password);
    } on FirebaseFunctionsException catch (e) {
      // Callable blocked or unavailable → secure-enough client-side redeem.
      if (_useClientRedeem(e)) {
        await _redeemClientSide(token: token, password: password);
      } else {
        throw _AuthFailure(_friendlyFunctions(e));
      }
    }
  }

  bool _useClientRedeem(FirebaseFunctionsException e) => const {
        'unimplemented',
        'not-found',
        'internal',
        'unavailable',
        'deadline-exceeded',
        'permission-denied',
        'failed-precondition',
      }.contains(e.code);

  String _friendlyFunctions(FirebaseFunctionsException e) => switch (e.code) {
        'not-found' => 'This activation code is invalid.',
        'failed-precondition' => e.message ?? 'This code can no longer be used.',
        'invalid-argument' =>
          e.message ?? 'Enter a valid code and an 8+ character password.',
        'already-exists' => 'This account is already activated. Try signing in.',
        _ => e.message ?? 'Could not activate. Please try again.',
      };

  /// Blaze-free fallback: validate + bind the record, then create the auth
  /// account. Less secure than the callable (noted in plan).
  Future<void> _redeemClientSide({
    required String token,
    required String password,
  }) async {
    final tokenRef = _db.collection('signupTokens').doc(token);
    final snap = await tokenRef.get();
    if (!snap.exists) throw _AuthFailure('This activation code is invalid.');
    final t = snap.data()!;
    if (t['used'] == true) throw _AuthFailure('This code has already been used.');
    final expires = (t['expiresAt'] as Timestamp?)?.toDate();
    if (expires != null && expires.isBefore(DateTime.now())) {
      throw _AuthFailure('This code has expired. Ask your admin for a new one.');
    }
    final recordId = t['targetUserDocId'] as String;
    final idNumber = t['idNumber'] as String;

    final rec = await _db.collection('users').doc(recordId).get();
    if (!rec.exists || rec.data()?['status'] != 'unclaimed') {
      throw _AuthFailure('This account is already activated. Try signing in.');
    }

    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
          email: emailFor(idNumber), password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw _AuthFailure('This account is already activated. Try signing in.');
      }
      rethrow;
    }

    try {
      await _db.collection('users').doc(recordId).update({
        'authUid': cred.user!.uid,
        'status': 'active',
      });
      await tokenRef.update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw _AuthFailure(
            'Activation could not be completed. Ask your admin to try again.');
      }
      rethrow;
    }
  }
}

class _AuthFailure implements Exception {
  final String message;
  _AuthFailure(this.message);
  @override
  String toString() => message;
}
