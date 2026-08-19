import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_lang.dart';
import '../../../core/api/error_messages.dart';
import '../../../core/storage/secure_storage.dart';

/// Auth state for the mobile app.
const Object _unset = Object();

bool _isBlank(String? value) => value == null || value.trim().isEmpty;

class _AuthProtocolException implements Exception {
  const _AuthProtocolException();
}

Map<String, dynamic> _requiredResponseMap(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const _AuthProtocolException();
  }
  return value;
}

bool _requiredBool(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! bool) throw const _AuthProtocolException();
  return value;
}

String _requiredString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! String || value.isEmpty) {
    throw const _AuthProtocolException();
  }
  return value;
}

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isProfileRefreshing;
  final bool profileResolved;
  final bool needsProfileSetup;
  final String locale; // 'en', 'ru', or 'tg'
  final String channel; // 'b2c' | 'b2b' — UX channel preference
  final bool channelChosen; // true once user has made a channel selection
  final String? role; // from GET /api/users/me — UI hint only, not security
  final String? name; // from GET /api/users/me — profile display
  final String? phone; // from GET /api/users/me — profile display
  final String? email; // from GET /api/users/me — profile display
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isProfileRefreshing = false,
    this.profileResolved = false,
    this.needsProfileSetup = false,
    this.locale = 'ru',
    this.channel = 'b2c',
    this.channelChosen = false,
    this.role,
    this.name,
    this.phone,
    this.email,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isProfileRefreshing,
    bool? profileResolved,
    bool? needsProfileSetup,
    String? locale,
    String? channel,
    bool? channelChosen,
    Object? role = _unset,
    Object? name = _unset,
    Object? phone = _unset,
    Object? email = _unset,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isProfileRefreshing: isProfileRefreshing ?? this.isProfileRefreshing,
      profileResolved: profileResolved ?? this.profileResolved,
      needsProfileSetup: needsProfileSetup ?? this.needsProfileSetup,
      locale: locale ?? this.locale,
      channel: channel ?? this.channel,
      channelChosen: channelChosen ?? this.channelChosen,
      role: identical(role, _unset) ? this.role : role as String?,
      name: identical(name, _unset) ? this.name : name as String?,
      phone: identical(phone, _unset) ? this.phone : phone as String?,
      email: identical(email, _unset) ? this.email : email as String?,
      error: error,
    );
  }
}

Future<AuthState> loadInitialAuthState(SecureStorage storage) async {
  try {
    final token = await storage.readAccessToken();
    final locale = await storage.readLocale() ?? 'ru';
    final channel = await storage.readChannel() ?? 'b2c';
    final channelChosen = await storage.readChannelChosen();
    return AuthState(
      isAuthenticated: token != null,
      profileResolved: token == null,
      locale: locale,
      channel: channel,
      channelChosen: channelChosen,
    );
  } on PlatformException {
    // A locked Linux keyring must not prevent the sign-in screen from opening.
    return const AuthState(profileResolved: true);
  }
}

/// AuthNotifier: manages OTP authentication flow and locale persistence.
///
/// OTP flow:
///   1. requestOtp(phone) → POST /api/auth/otp/request { phone }
///   2. verifyOtp(phone, code) → POST /api/auth/otp/verify { phone, code }
///      → on success: writes accessToken + refreshToken to SecureStorage
///
/// Locale: persisted in SecureStorage (not a profile PATCH endpoint in v1).
class AuthNotifier extends StateNotifier<AuthState> {
  final DioClient _client;
  final SecureStorage _storage;
  int _sessionEpoch = 0;
  int _refreshGeneration = 0;
  Future<void> _authStorageBarrier = Future<void>.value();

  AuthNotifier({
    required DioClient client,
    required SecureStorage storage,
    AuthState? initialState,
  })  : _client = client,
        _storage = storage,
        super(initialState ?? const AuthState()) {
    // Bridge: when the Dio interceptor fails to refresh, flip auth state so the
    // go_router redirect (which reads in-memory state, not storage) fires.
    _client.onSessionExpired = _handleSessionExpired;
    _client.authRefreshCoordinator = AuthRefreshCoordinator(
      captureSessionTicket: () => _sessionEpoch,
      persistRefreshedTokens: _persistRefreshedTokens,
      isSessionTicketCurrent: _isCurrentSession,
    );
    if (initialState == null) {
      _initialize();
    } else if (initialState.isAuthenticated) {
      unawaited(refreshFromServer());
    }
  }

  /// Called by the Dio AuthInterceptor when a refresh fails irrecoverably.
  void _handleSessionExpired() {
    unawaited(_invalidateSession('SESSION_EXPIRED'));
  }

  bool _isCurrentSession(int epoch) => mounted && epoch == _sessionEpoch;

  bool _isCurrentRefresh(int epoch, int generation) =>
      _isCurrentSession(epoch) && generation == _refreshGeneration;

  Future<T> _serializeAuthStorage<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _authStorageBarrier = _authStorageBarrier.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<bool> _persistRefreshedTokens(
    int epoch,
    String accessToken,
    String refreshToken,
  ) async {
    if (!_isCurrentSession(epoch)) return false;
    return _serializeAuthStorage(() async {
      if (!_isCurrentSession(epoch)) return false;
      await _storage.writeAccessToken(accessToken);
      if (!_isCurrentSession(epoch)) return false;
      await _storage.writeRefreshToken(refreshToken);
      return _isCurrentSession(epoch);
    });
  }

  Future<void> _invalidateSession(String? error) async {
    if (!mounted) return;
    final epoch = ++_sessionEpoch;
    _refreshGeneration++;
    final cleared = await _serializeAuthStorage(() async {
      if (!_isCurrentSession(epoch)) return false;
      await _storage.clearTokens();
      if (!_isCurrentSession(epoch)) return false;
      await _storage.clearProfileCache();
      return _isCurrentSession(epoch);
    });
    if (!cleared || !_isCurrentSession(epoch)) return;
    state = state.copyWith(
      isAuthenticated: false,
      isLoading: false,
      isProfileRefreshing: false,
      profileResolved: true,
      needsProfileSetup: false,
      role: null,
      name: null,
      phone: null,
      email: null,
      error: error,
    );
  }

  @override
  void dispose() {
    _client.onSessionExpired = null;
    _client.authRefreshCoordinator = null;
    super.dispose();
  }

  /// Initialize: check if we have an access token (resume session) + load locale + channel.
  Future<void> _initialize() async {
    final epoch = _sessionEpoch;
    final token = await _storage.readAccessToken();
    if (!_isCurrentSession(epoch)) return;
    final locale = await _storage.readLocale() ?? 'ru';
    if (!_isCurrentSession(epoch)) return;
    final channel = await _storage.readChannel() ?? 'b2c';
    if (!_isCurrentSession(epoch)) return;
    final channelChosen = await _storage.readChannelChosen();
    if (!_isCurrentSession(epoch)) return;
    state = state.copyWith(
      isAuthenticated: token != null,
      profileResolved: token == null,
      locale: locale,
      channel: channel,
      channelChosen: channelChosen,
    );
    // Background sync with server if we have a token
    if (token != null) unawaited(refreshFromServer());
  }

  /// Re-sync channel + role from the server (GET /api/users/me).
  ///
  /// Public so screens can pull the latest role after a server-side change the
  /// client can't observe locally — e.g. an admin approving the wholesale
  /// application flips User.role to 'wholesale_seller'. Screens that watch
  /// authProvider (B2B home/profile) then rebuild and unlock automatically.
  /// Keeps an already-authoritative profile state on refresh failure. Session
  /// bootstrap failures remain unresolved and expose PROFILE_LOAD_FAILED.
  Future<bool> refreshFromServer() async {
    final epoch = _sessionEpoch;
    final generation = ++_refreshGeneration;
    if (!_isCurrentRefresh(epoch, generation)) return false;
    state = state.copyWith(isProfileRefreshing: true);
    try {
      final res = await _client.get('/api/users/me');
      if (!_isCurrentRefresh(epoch, generation)) return false;
      final data = _requiredResponseMap(res.data);
      final needsProfileSetup = _requiredBool(data, 'needsProfileSetup');
      final serverChannel = data['channel'] as String? ?? state.channel;
      final serverLocale = data['locale']?.toString();
      final serverRole = data['role'] as String?;
      final serverName = data['name'] as String?;
      final serverPhone = data['phone'] as String?;
      final serverEmail = data['email'] as String?;
      final cachedPhone = await _storage.readProfilePhone();
      if (!_isCurrentRefresh(epoch, generation)) return false;
      final useCachedProfile =
          !_isBlank(serverPhone) && cachedPhone == serverPhone;
      final cachedName =
          useCachedProfile ? await _storage.readProfileName() : null;
      if (!_isCurrentRefresh(epoch, generation)) return false;
      final cachedEmail =
          useCachedProfile ? await _storage.readProfileEmail() : null;
      if (!_isCurrentRefresh(epoch, generation)) return false;
      final resolvedName = _isBlank(serverName) ? cachedName : serverName;
      final resolvedEmail = _isBlank(serverEmail) ? cachedEmail : serverEmail;
      final cacheCommitted = await _serializeAuthStorage(() async {
        if (!_isCurrentRefresh(epoch, generation)) return false;
        await _storage.writeChannel(serverChannel);
        if (!_isCurrentRefresh(epoch, generation)) return false;
        if (!_isBlank(serverPhone) &&
            !_isBlank(resolvedName) &&
            !_isBlank(resolvedEmail)) {
          await _storage.writeProfilePhone(serverPhone!);
          if (!_isCurrentRefresh(epoch, generation)) return false;
          await _storage.writeProfileName(resolvedName!);
          if (!_isCurrentRefresh(epoch, generation)) return false;
          await _storage.writeProfileEmail(resolvedEmail!);
          if (!_isCurrentRefresh(epoch, generation)) return false;
        }
        return true;
      });
      if (!cacheCommitted || !_isCurrentRefresh(epoch, generation)) {
        return false;
      }
      state = state.copyWith(
        isProfileRefreshing: false,
        profileResolved: true,
        needsProfileSetup: needsProfileSetup,
        channel: serverChannel,
        locale: serverLocale == null ? state.locale : uiLang(serverLocale),
        role: serverRole,
        name: resolvedName,
        phone: serverPhone,
        email: resolvedEmail,
      );
      return true;
    } catch (_) {
      if (!_isCurrentRefresh(epoch, generation)) return false;
      final error = !state.profileResolved
          ? state.error == 'PROFILE_PROTOCOL_ERROR'
              ? 'PROFILE_PROTOCOL_ERROR'
              : 'PROFILE_LOAD_FAILED'
          : state.error;
      state = state.copyWith(
        isProfileRefreshing: false,
        error: error,
      );
      return false;
    }
  }

  /// Step 1: Request OTP SMS to the given phone number.
  /// POST /api/auth/otp/request { phone }
  Future<void> requestOtp(String phone) async {
    final epoch = _sessionEpoch;
    if (!_isCurrentSession(epoch)) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.post('/api/auth/otp/request', data: {'phone': phone});
      if (!_isCurrentSession(epoch)) return;
      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      if (!_isCurrentSession(epoch)) return;
      state = state.copyWith(isLoading: false, error: errorCodeOf(e));
      rethrow;
    } catch (e) {
      if (!_isCurrentSession(epoch)) return;
      state = state.copyWith(isLoading: false, error: errorCodeOf(e));
      rethrow;
    }
  }

  /// Step 2: Verify OTP code and obtain JWT tokens.
  /// POST /api/auth/otp/verify { phone, code }
  /// → { accessToken, refreshToken, expiresIn, isNewUser, needsProfileSetup }
  Future<void> verifyOtp(String phone, String code) async {
    var operationEpoch = _sessionEpoch;
    if (!_isCurrentSession(operationEpoch)) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        '/api/auth/otp/verify',
        data: {'phone': phone, 'code': code},
      );
      if (!_isCurrentSession(operationEpoch)) return;
      final data = _requiredResponseMap(res.data);
      final accessToken = _requiredString(data, 'accessToken');
      final refreshToken = _requiredString(data, 'refreshToken');
      final needsProfileSetup = _requiredBool(data, 'needsProfileSetup');
      if (!_isCurrentSession(operationEpoch)) return;
      operationEpoch = ++_sessionEpoch;
      _refreshGeneration++;
      final tokensCommitted = await _serializeAuthStorage(() async {
        if (!_isCurrentSession(operationEpoch)) return false;
        await _storage.writeAccessToken(accessToken);
        if (!_isCurrentSession(operationEpoch)) return false;
        await _storage.writeRefreshToken(refreshToken);
        return _isCurrentSession(operationEpoch);
      });
      if (!tokensCommitted || !_isCurrentSession(operationEpoch)) return;
      await _syncLocaleToServer(state.locale);
      if (!_isCurrentSession(operationEpoch)) return;
      state = state.copyWith(
        isAuthenticated: true,
        isProfileRefreshing: false,
        profileResolved: true,
        needsProfileSetup: needsProfileSetup,
        role: null,
        name: null,
        phone: null,
        email: null,
      );
      await refreshFromServer();
      if (_isCurrentSession(operationEpoch)) {
        state = state.copyWith(isLoading: false);
      }
    } on _AuthProtocolException {
      if (!_isCurrentSession(operationEpoch)) return;
      state = state.copyWith(
        isLoading: false,
        error: 'AUTH_PROTOCOL_ERROR',
      );
      rethrow;
    } on DioException catch (e) {
      if (!_isCurrentSession(operationEpoch)) return;
      state = state.copyWith(isLoading: false, error: errorCodeOf(e));
      rethrow;
    } catch (e) {
      if (!_isCurrentSession(operationEpoch)) return;
      state = state.copyWith(isLoading: false, error: errorCodeOf(e));
      rethrow;
    }
  }

  /// Log out: clear tokens, update auth state.
  Future<void> logout() async {
    await _invalidateSession(null);
  }

  /// Complete the post-OTP "знакомство" step (Auth-3 in the design demo):
  /// PATCH /api/users/me { name, email }.
  /// On success consumes the backend's `needsProfileSetup` result so routing
  /// follows the authoritative profile state.
  Future<void> completeProfile(String name, String email) async {
    final epoch = _sessionEpoch;
    if (!_isCurrentSession(epoch)) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.patch(
        '/api/users/me',
        data: {'name': name, 'email': email},
      );
      if (!_isCurrentSession(epoch)) return;
      late final Map<String, dynamic> data;
      late final bool needsProfileSetup;
      try {
        data = _requiredResponseMap(res.data);
        needsProfileSetup = _requiredBool(data, 'needsProfileSetup');
      } on _AuthProtocolException {
        final reconciled = await refreshFromServer();
        if (!_isCurrentSession(epoch)) return;
        if (reconciled) {
          state = state.copyWith(isLoading: false);
          return;
        }
        state = state.copyWith(
          isLoading: false,
          profileResolved: false,
          error: 'PROFILE_PROTOCOL_ERROR',
        );
        return;
      }
      final resolvedName = data['name']?.toString() ?? name;
      final resolvedEmail = data['email']?.toString() ?? email;
      final resolvedPhone =
          data.containsKey('phone') ? data['phone']?.toString() : state.phone;
      final cacheCommitted = await _serializeAuthStorage(() async {
        if (!_isCurrentSession(epoch)) return false;
        await _storage.writeProfileName(resolvedName);
        if (!_isCurrentSession(epoch)) return false;
        await _storage.writeProfileEmail(resolvedEmail);
        if (!_isCurrentSession(epoch)) return false;
        if (!_isBlank(resolvedPhone)) {
          await _storage.writeProfilePhone(resolvedPhone!);
          if (!_isCurrentSession(epoch)) return false;
        }
        return true;
      });
      if (!cacheCommitted || !_isCurrentSession(epoch)) return;
      state = state.copyWith(
        isLoading: false,
        profileResolved: true,
        needsProfileSetup: needsProfileSetup,
        name: resolvedName,
        phone: data.containsKey('phone') ? data['phone']?.toString() : _unset,
        email: resolvedEmail,
      );
    } on DioException catch (e) {
      if (!_isCurrentSession(epoch)) return;
      state = state.copyWith(isLoading: false, error: errorCodeOf(e));
      rethrow;
    } catch (e) {
      if (!_isCurrentSession(epoch)) return;
      state = state.copyWith(isLoading: false, error: errorCodeOf(e));
      rethrow;
    }
  }

  /// Persist the selected locale to SecureStorage and update state.
  /// This is the v1 locale storage mechanism (no PATCH /api/profile yet).
  Future<void> setLocale(String locale) async {
    final epoch = _sessionEpoch;
    try {
      final committed = await _serializeAuthStorage(() async {
        if (!_isCurrentSession(epoch)) return false;
        await _storage.writeLocale(locale);
        return _isCurrentSession(epoch);
      });
      if (!committed || !_isCurrentSession(epoch)) return;
      state = state.copyWith(locale: locale);
      if (state.isAuthenticated) {
        await _syncLocaleToServer(locale);
        if (!_isCurrentSession(epoch)) return;
      }
    } catch (_) {
      if (!_isCurrentSession(epoch)) return;
      rethrow;
    }
  }

  Future<void> _syncLocaleToServer(String locale) async {
    await _client.patch('/api/users/me', data: {'locale': apiLang(locale)});
  }

  /// Switch channel optimistically: writes to SecureStorage + updates state BEFORE
  /// the PATCH request so GoRouter redirect fires immediately (no shell flash).
  /// On PATCH failure: rolls back storage + state and rethrows so caller can show SnackBar.
  ///
  /// IMPORTANT: does NOT reset cartProvider or wholesaleCartProvider (D-11).
  Future<void> setChannel(String channel) async {
    final epoch = _sessionEpoch;
    final previous = state.channel;
    try {
      // Optimistic update — BEFORE await PATCH (T-15-06: no redirect loop)
      final committed = await _serializeAuthStorage(() async {
        if (!_isCurrentSession(epoch)) return false;
        await _storage.writeChannel(channel);
        if (!_isCurrentSession(epoch)) return false;
        await _storage.writeChannelChosen(true);
        return _isCurrentSession(epoch);
      });
      if (!committed || !_isCurrentSession(epoch)) return;
      state = state.copyWith(channel: channel, channelChosen: true);
      // Background PATCH to persist on server
      await _client.patch('/api/users/me/channel', data: {'channel': channel});
      if (!_isCurrentSession(epoch)) return;
    } catch (_) {
      if (!_isCurrentSession(epoch)) return;
      // Rollback on error
      final rolledBack = await _serializeAuthStorage(() async {
        if (!_isCurrentSession(epoch)) return false;
        await _storage.writeChannel(previous);
        return _isCurrentSession(epoch);
      });
      if (!rolledBack || !_isCurrentSession(epoch)) return;
      state = state.copyWith(channel: previous);
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(storage: storage);
});

final authInitialStateProvider = Provider<AuthState?>((ref) => null);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    client: ref.watch(dioClientProvider),
    storage: ref.watch(secureStorageProvider),
    initialState: ref.watch(authInitialStateProvider),
  );
});
