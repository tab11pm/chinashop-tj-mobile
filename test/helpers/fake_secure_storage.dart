import 'dart:async';
import 'dart:convert';

import 'package:pinshop_tj/core/storage/secure_storage.dart';

/// In-memory [SecureStorage] for unit tests — no platform channel needed.
///
/// Overrides all [SecureStorage] methods directly so there is no dependency
/// on [FlutterSecureStorage]'s platform channel.
class FakeSecureStorage extends SecureStorage {
  static const String channelKey = 'channel';
  static const String channelChosenKey = 'channel_chosen';
  static const String localeKey = 'locale';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String profileNameKey = 'profile_name';
  static const String profileEmailKey = 'profile_email';
  static const String profilePhoneKey = 'profile_phone';
  static String pickupCodeKey(String orderId) => 'pickup_code_$orderId';
  static String celebratedKey(String orderId) => 'celebrated_order_$orderId';

  final Map<String, String> data = {};
  bool clearProfileCacheCalled = false;

  FakeSecureStorage() : super();

  void seed(String key, String value) => data[key] = value;

  // ---------- Access Token ----------
  @override
  Future<String?> readAccessToken() async => data[accessTokenKey];
  @override
  Future<void> writeAccessToken(String token) async =>
      data[accessTokenKey] = token;

  // ---------- Refresh Token ----------
  @override
  Future<String?> readRefreshToken() async => data[refreshTokenKey];
  @override
  Future<void> writeRefreshToken(String token) async =>
      data[refreshTokenKey] = token;

  // ---------- Locale ----------
  @override
  Future<String?> readLocale() async => data[localeKey];
  @override
  Future<void> writeLocale(String locale) async => data[localeKey] = locale;

  // ---------- Channel ----------
  @override
  Future<String?> readChannel() async => data[channelKey];
  @override
  Future<void> writeChannel(String ch) async => data[channelKey] = ch;

  // ---------- Channel Chosen ----------
  @override
  Future<bool> readChannelChosen() async => data[channelChosenKey] == 'true';
  @override
  Future<void> writeChannelChosen(bool v) async =>
      data[channelChosenKey] = v.toString();

  // ---------- Profile Setup Cache ----------
  @override
  Future<String?> readProfileName() async => data[profileNameKey];
  @override
  Future<void> writeProfileName(String name) async =>
      data[profileNameKey] = name;

  @override
  Future<String?> readProfileEmail() async => data[profileEmailKey];
  @override
  Future<void> writeProfileEmail(String email) async =>
      data[profileEmailKey] = email;

  @override
  Future<String?> readProfilePhone() async => data[profilePhoneKey];
  @override
  Future<void> writeProfilePhone(String phone) async =>
      data[profilePhoneKey] = phone;

  @override
  Future<void> writePickupCode(
      String orderId, String code, String qrPayload) async {
    data[pickupCodeKey(orderId)] =
        jsonEncode({'code': code, 'qrPayload': qrPayload});
  }

  @override
  Future<Map<String, String>?> readPickupCode(String orderId) async {
    final raw = data[pickupCodeKey(orderId)];
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final code = decoded['code']?.toString();
    final qrPayload = decoded['qrPayload']?.toString();
    if (code == null || qrPayload == null) return null;
    return {'code': code, 'qrPayload': qrPayload};
  }

  @override
  Future<void> clearPickupCode(String orderId) async {
    data.remove(pickupCodeKey(orderId));
  }

  @override
  Future<bool> readCelebrated(String orderId) async =>
      data[celebratedKey(orderId)] == 'true';

  @override
  Future<void> writeCelebrated(String orderId) async {
    data[celebratedKey(orderId)] = 'true';
  }

  // ---------- Cleanup ----------
  @override
  Future<void> clearTokens() async {
    data.remove(accessTokenKey);
    data.remove(refreshTokenKey);
  }

  @override
  Future<void> clearProfileCache() async {
    clearProfileCacheCalled = true;
    data.remove(profileNameKey);
    data.remove(profileEmailKey);
    data.remove(profilePhoneKey);
  }

  @override
  Future<void> clearAll() async => data.clear();
}

/// Storage fake with deterministic gates around security-sensitive writes.
///
/// Tests use these gates to force the exact ordering that can occur with the
/// platform-backed secure store, while preserving the real storage side
/// effects inherited from [FakeSecureStorage].
class GatedFakeSecureStorage extends FakeSecureStorage {
  GatedFakeSecureStorage({
    this.accessTokenWriteGate,
    this.clearTokensGate,
  });

  final Completer<void>? accessTokenWriteGate;
  final Completer<void>? clearTokensGate;
  final Completer<void> accessTokenWriteStarted = Completer<void>();
  final Completer<void> clearTokensStarted = Completer<void>();

  @override
  Future<void> writeAccessToken(String token) async {
    if (!accessTokenWriteStarted.isCompleted) {
      accessTokenWriteStarted.complete();
    }
    await accessTokenWriteGate?.future;
    await super.writeAccessToken(token);
  }

  @override
  Future<void> clearTokens() async {
    if (!clearTokensStarted.isCompleted) clearTokensStarted.complete();
    await clearTokensGate?.future;
    await super.clearTokens();
  }
}
