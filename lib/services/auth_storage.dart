import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the "remember me" credentials (encrypted) and the small non-secret
/// flags (remember-me on, biometric-login on, a stable device id).
///
/// Credentials live in [FlutterSecureStorage] — Android Keystore / iOS Keychain
/// on device, WebCrypto on web. Flags live in [SharedPreferences].
class AuthStorage {
  AuthStorage._();
  static final AuthStorage instance = AuthStorage._();

  static const _kMobile = 'auth_mobile';
  static const _kPassword = 'auth_password';
  static const _kRemember = 'remember_me';
  static const _kBiometric = 'biometric_enabled';
  static const _kDeviceId = 'device_id';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ---- credentials (encrypted) ----

  Future<void> saveCredentials(String mobile, String password) async {
    await _secure.write(key: _kMobile, value: mobile);
    await _secure.write(key: _kPassword, value: password);
  }

  Future<({String mobile, String password})?> readCredentials() async {
    final m = await _secure.read(key: _kMobile);
    final p = await _secure.read(key: _kPassword);
    if (m == null || m.isEmpty || p == null || p.isEmpty) return null;
    return (mobile: m, password: p);
  }

  Future<void> clearCredentials() async {
    await _secure.delete(key: _kMobile);
    await _secure.delete(key: _kPassword);
  }

  // ---- flags ----

  Future<bool> getRememberMe() async =>
      (await SharedPreferences.getInstance()).getBool(_kRemember) ?? false;

  Future<void> setRememberMe(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kRemember, v);

  Future<bool> getBiometricEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_kBiometric) ?? false;

  Future<void> setBiometricEnabled(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kBiometric, v);

  /// A stable per-install id, generated once and reused (used for the backend
  /// biometric-device record).
  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kDeviceId);
    if (id == null || id.isEmpty) {
      final rnd = Random();
      final suffix = List.generate(8, (_) => rnd.nextInt(16).toRadixString(16)).join();
      id = 'dev-${DateTime.now().millisecondsSinceEpoch}-$suffix';
      await prefs.setString(_kDeviceId, id);
    }
    return id;
  }

  /// Forget everything (used on logout when the user opts out).
  Future<void> clearAll() async {
    await clearCredentials();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRemember);
    await prefs.remove(_kBiometric);
  }
}
