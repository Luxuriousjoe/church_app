import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ─── Tokens ─────────────────────────────────────────────────────────────
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.kAccessToken,  value: accessToken),
      _storage.write(key: AppConstants.kRefreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken()  => _storage.read(key: AppConstants.kAccessToken);
  static Future<String?> getRefreshToken() => _storage.read(key: AppConstants.kRefreshToken);

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.kAccessToken),
      _storage.delete(key: AppConstants.kRefreshToken),
    ]);
  }

  // ─── User ────────────────────────────────────────────────────────────────
  static Future<void> saveUser(UserModel user) async {
    await _storage.write(key: AppConstants.kUserData, value: user.toJsonString());
  }

  static Future<UserModel?> getUser() async {
    final s = await _storage.read(key: AppConstants.kUserData);
    if (s == null) return null;
    try { return UserModel.fromJsonString(s); } catch (_) { return null; }
  }

  static Future<void> clearUser() => _storage.delete(key: AppConstants.kUserData);

  // ─── Clear All ───────────────────────────────────────────────────────────
  static Future<void> clearAll() => _storage.deleteAll();
}
