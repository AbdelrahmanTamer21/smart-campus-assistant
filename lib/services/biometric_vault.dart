import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores sign-in credentials in the device keychain/keystore for Face ID /
/// Touch ID unlock after the user opts in via "Remember me".
class BiometricVault {
  static const _idKey = 'campus_vault_id';
  static const _passwordKey = 'campus_vault_password';
  static const _enabledKey = 'biometric_unlock_enabled';

  static const _secure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<bool> hasCredentials() async {
    final id = await _secure.read(key: _idKey);
    final password = await _secure.read(key: _passwordKey);
    return id != null && id.isNotEmpty && password != null && password.isNotEmpty;
  }

  Future<bool> canUseBiometricLogin() async =>
      (await isEnabled()) && (await hasCredentials());

  Future<void> save({required String idNumber, required String password}) async {
    await _secure.write(key: _idKey, value: idNumber.trim());
    await _secure.write(key: _passwordKey, value: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
  }

  /// Disables unlock and removes stored credentials.
  Future<void> clear() async {
    await _secure.delete(key: _idKey);
    await _secure.delete(key: _passwordKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, true);
      return;
    }
    await clear();
  }

  Future<({String idNumber, String password})?> readCredentials() async {
    if (!await canUseBiometricLogin()) return null;
    final id = await _secure.read(key: _idKey);
    final password = await _secure.read(key: _passwordKey);
    if (id == null || password == null || id.isEmpty || password.isEmpty) {
      return null;
    }
    return (idNumber: id, password: password);
  }
}
