import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Keys used in encrypted storage.
/// NEVER use SharedPreferences — tokens are secrets (T-7-10, D-06, RESEARCH.md Pitfall 7).
class _Keys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String locale = 'locale';
  static const String channel = 'channel';
  static const String channelChosen = 'channel_chosen';
  static const String profileName = 'profile_name';
  static const String profileEmail = 'profile_email';
  static const String profilePhone = 'profile_phone';

  static String pickupCode(String orderId) => 'pickup_code_$orderId';
  static String celebratedOrder(String orderId) => 'celebrated_order_$orderId';
}

/// Wraps flutter_secure_storage with typed read/write methods for:
/// - access token (JWT Bearer)
/// - refresh token (JWT rotation)
/// - locale preference (persisted between app restarts)
///
/// Uses AES-CBC encryption backed by Android KeyStore / iOS Keychain.
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage();

  // ---------- Access Token ----------

  Future<String?> readAccessToken() async {
    return _storage.read(key: _Keys.accessToken);
  }

  Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _Keys.accessToken, value: token);
  }

  // ---------- Refresh Token ----------

  Future<String?> readRefreshToken() async {
    return _storage.read(key: _Keys.refreshToken);
  }

  Future<void> writeRefreshToken(String token) async {
    await _storage.write(key: _Keys.refreshToken, value: token);
  }

  // ---------- Locale ----------

  Future<String?> readLocale() async {
    return _storage.read(key: _Keys.locale);
  }

  Future<void> writeLocale(String locale) async {
    await _storage.write(key: _Keys.locale, value: locale);
  }

  // ---------- Channel ----------

  Future<String?> readChannel() async {
    return _storage.read(key: _Keys.channel);
  }

  Future<void> writeChannel(String ch) async {
    await _storage.write(key: _Keys.channel, value: ch);
  }

  // ---------- Channel Chosen ----------

  Future<bool> readChannelChosen() async =>
      (await _storage.read(key: _Keys.channelChosen)) == 'true';

  Future<void> writeChannelChosen(bool v) async =>
      _storage.write(key: _Keys.channelChosen, value: v.toString());

  // ---------- Profile Setup Cache ----------

  Future<String?> readProfileName() async {
    return _storage.read(key: _Keys.profileName);
  }

  Future<void> writeProfileName(String name) async {
    await _storage.write(key: _Keys.profileName, value: name);
  }

  Future<String?> readProfileEmail() async {
    return _storage.read(key: _Keys.profileEmail);
  }

  Future<void> writeProfileEmail(String email) async {
    await _storage.write(key: _Keys.profileEmail, value: email);
  }

  Future<String?> readProfilePhone() async {
    return _storage.read(key: _Keys.profilePhone);
  }

  Future<void> writeProfilePhone(String phone) async {
    await _storage.write(key: _Keys.profilePhone, value: phone);
  }

  // ---------- Pickup Code Cache ----------

  Future<void> writePickupCode(
    String orderId,
    String code,
    String qrPayload,
  ) async {
    await _storage.write(
      key: _Keys.pickupCode(orderId),
      value: jsonEncode({'code': code, 'qrPayload': qrPayload}),
    );
  }

  Future<Map<String, String>?> readPickupCode(String orderId) async {
    final raw = await _storage.read(key: _Keys.pickupCode(orderId));
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final code = decoded['code']?.toString();
    final qrPayload = decoded['qrPayload']?.toString();
    if (code == null || qrPayload == null) return null;
    return {'code': code, 'qrPayload': qrPayload};
  }

  Future<void> clearPickupCode(String orderId) async {
    await _storage.delete(key: _Keys.pickupCode(orderId));
  }

  // ---------- Delivered Celebration Flag ----------

  Future<bool> readCelebrated(String orderId) async =>
      (await _storage.read(key: _Keys.celebratedOrder(orderId))) == 'true';

  Future<void> writeCelebrated(String orderId) async {
    await _storage.write(key: _Keys.celebratedOrder(orderId), value: 'true');
  }

  // ---------- Cleanup ----------

  /// Clears both tokens on logout or after a failed refresh.
  Future<void> clearTokens() async {
    await _storage.delete(key: _Keys.accessToken);
    await _storage.delete(key: _Keys.refreshToken);
  }

  /// Clears the cached name/phone/email on logout so a different account
  /// logging in on the same device never inherits a previous occupant's
  /// identity (cache keys here are not scoped per-user).
  Future<void> clearProfileCache() async {
    await _storage.delete(key: _Keys.profileName);
    await _storage.delete(key: _Keys.profileEmail);
    await _storage.delete(key: _Keys.profilePhone);
  }

  /// Clears all stored data (tokens + locale).
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
