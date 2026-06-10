import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

enum AuthStatus { splash, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _auth;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  AuthStatus _status = AuthStatus.splash;
  UserProfile? _profile;
  UserRole _claimRole = UserRole.student;
  String? _error;
  bool _busy = false;

  AuthProvider({AuthService? auth}) : _auth = auth ?? AuthService() {
    _authSub = _auth.authState.listen(_onAuth);
  }

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;

  /// Authoritative role — sourced from the JWT custom claim (`role`), set by the
  /// backend on activation. The profile doc mirrors it for display; security
  /// rules / Cloud Functions enforce via the claim. The user never picks it.
  UserRole get activeRole => _profile?.primaryRole ?? _claimRole;

  String? get error => _error;
  bool get busy => _busy;
  AuthService get service => _auth;

  Future<void> _onAuth(User? user) async {
    await _profileSub?.cancel();
    if (user == null) {
      _profile = null;
      _claimRole = UserRole.student;
      _status = AuthStatus.unauthenticated;
      _setBusy(false);
      return;
    }
    // Read the authoritative role from the JWT custom claim.
    try {
      final token = await user.getIdTokenResult();
      final claim = token.claims?['role'] as String?;
      if (claim != null) _claimRole = UserRoleX.fromId(claim);
    } catch (_) {/* offline / no claim yet — fall back to profile */}

    _profileSub = _auth.watchProfile(user.uid).listen((p) {
      _profile = p;
      _status = p == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      notifyListeners();
    });
  }

  Future<bool> signIn(String id, String password) async {
    _setBusy(true);
    try {
      await _auth.signIn(id, password);
      _setBusy(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendly(e.code);
      _setBusy(false);
      return false;
    } catch (e) {
      _error = 'Could not sign in. Check your connection and try again.';
      _setBusy(false);
      return false;
    }
  }

  Future<bool> redeem(String token, String password) async {
    _setBusy(true);
    try {
      await _auth.redeemSignupToken(token: token, password: password);
      _setBusy(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _setBusy(false);
      return false;
    }
  }

  Future<void> sendReset(String id) => _auth.sendPasswordReset(id);

  Future<void> signOut() async {
    _setBusy(false);
    _claimRole = UserRole.student;
    await _auth.signOut();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  String _friendly(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Incorrect ID or password.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'network-request-failed' => 'No connection. Check your network.',
        _ => 'Could not sign in. Please try again.',
      };

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
