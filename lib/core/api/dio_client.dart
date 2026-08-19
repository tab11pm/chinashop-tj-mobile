import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// Coordinates interceptor token refreshes with the current in-memory auth
/// session. The interceptor captures one coordinator and ticket per refresh so
/// a later notifier replacement cannot make an old response current again.
class AuthRefreshCoordinator {
  const AuthRefreshCoordinator({
    required this.captureSessionTicket,
    required this.persistRefreshedTokens,
    required this.isSessionTicketCurrent,
  });

  final int Function() captureSessionTicket;
  final Future<bool> Function(
    int ticket,
    String accessToken,
    String refreshToken,
  ) persistRefreshedTokens;
  final bool Function(int ticket) isSessionTicketCurrent;
}

const String _authRequestOriginKey = 'pinshop.authRequestOrigin';

class _AuthRequestOrigin {
  const _AuthRequestOrigin({
    required this.coordinator,
    required this.sessionTicket,
  });

  final AuthRefreshCoordinator? coordinator;
  final int? sessionTicket;
}

/// AuthInterceptor: attaches Bearer token to every request; on 401 refreshes
/// the access token once via POST /api/auth/refresh then retries the original
/// request. Maps API { error, code } responses to DomainException.
///
/// Single-flight guard (_isRefreshing) prevents double-refresh on concurrent
/// 401s (matches the admin refreshInFlight singleton pattern per RESEARCH.md
/// Pattern 6 + T-7-12).
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorage _storage;
  bool _isRefreshing = false;

  /// Fired when refresh fails and the session is no longer recoverable.
  /// AuthNotifier registers this to flip auth state → the go_router redirect.
  void Function()? onSessionExpired;

  /// Present while an AuthNotifier owns this client. Standalone clients retain
  /// direct SecureStorage refresh persistence for backwards compatibility.
  AuthRefreshCoordinator? refreshCoordinator;

  AuthInterceptor(this._dio, this._storage);

  _AuthRequestOrigin _stampRequestOrigin(RequestOptions options) {
    return options.extra.putIfAbsent(_authRequestOriginKey, () {
      final coordinator = refreshCoordinator;
      return _AuthRequestOrigin(
        coordinator: coordinator,
        sessionTicket: coordinator?.captureSessionTicket(),
      );
    }) as _AuthRequestOrigin;
  }

  _AuthRequestOrigin? _requestOrigin(RequestOptions options) =>
      options.extra[_authRequestOriginKey] as _AuthRequestOrigin?;

  bool _isRequestOriginCurrent(_AuthRequestOrigin origin) {
    final coordinator = origin.coordinator;
    if (coordinator == null) return true;
    return identical(coordinator, refreshCoordinator) &&
        coordinator.isSessionTicketCurrent(origin.sessionTicket!);
  }

  DioException _staleRequestError(RequestOptions options) => DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        error: StateError('The originating auth session is no longer current.'),
      );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final origin = _stampRequestOrigin(options);
    final token = await _storage.readAccessToken();
    if (!_isRequestOriginCurrent(origin)) {
      handler.reject(_staleRequestError(options));
      return;
    }
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final origin = _requestOrigin(response.requestOptions);
    if (origin != null && !_isRequestOriginCurrent(origin)) {
      handler.reject(_staleRequestError(response.requestOptions));
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final origin = _requestOrigin(err.requestOptions);
    if (origin != null && !_isRequestOriginCurrent(origin)) {
      handler.next(err);
      return;
    }
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      final coordinator = origin?.coordinator;
      final sessionTicket = origin?.sessionTicket;
      try {
        final refreshToken = await _storage.readRefreshToken();
        if (origin != null && !_isRequestOriginCurrent(origin)) {
          handler.next(err);
          return;
        }
        if (refreshToken == null) {
          throw const DomainException(
            code: 'SESSION_EXPIRED',
            message: 'No refresh token. Please log in again.',
          );
        }

        // POST /api/auth/refresh rotates the complete token pair.
        final refreshRes = await _dio.post(
          '/api/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
        final newToken = refreshRes.data['accessToken'] as String;
        final newRefreshToken = refreshRes.data['refreshToken'] as String;
        if (coordinator == null) {
          await _storage.writeAccessToken(newToken);
          await _storage.writeRefreshToken(newRefreshToken);
        } else {
          final persisted = await coordinator.persistRefreshedTokens(
            sessionTicket!,
            newToken,
            newRefreshToken,
          );
          if (!persisted) {
            handler.next(err);
            return;
          }
        }

        if (origin != null && !_isRequestOriginCurrent(origin)) {
          handler.next(err);
          return;
        }

        // Retry the original failed request with the new token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newToken';
        final retryRes = await _dio.fetch(retryOptions);
        if (origin != null && !_isRequestOriginCurrent(origin)) {
          handler.next(err);
          return;
        }
        handler.resolve(retryRes);
        return;
      } catch (refreshError) {
        if (origin != null && !_isRequestOriginCurrent(origin)) {
          handler.next(err);
          return;
        }
        // Temporary transport/server failures do not prove that the refresh
        // token is invalid. Only an explicit auth failure (401), or the local
        // absence of a refresh credential, should drive the OTP redirect.
        final refreshWasUnauthorized = refreshError is DioException &&
            refreshError.response?.statusCode == 401;
        final refreshTokenMissing = refreshError is DomainException &&
            refreshError.code == 'SESSION_EXPIRED';
        if (refreshWasUnauthorized || refreshTokenMissing) {
          // AuthNotifier owns serialized token/profile-cache invalidation and
          // drives the router from the resulting in-memory state. Retain a
          // token-only fallback for clients used without an AuthNotifier.
          final callback = onSessionExpired;
          if (callback == null) {
            await _storage.clearTokens();
          } else {
            callback();
          }
        }
        handler.next(err);
        return;
      } finally {
        _isRefreshing = false;
      }
    }

    // Map API { error, code } body to DomainException for all error responses
    final body = err.response?.data;
    if (body is Map && body.containsKey('code')) {
      final domainErr = DomainException(
        code: body['code']?.toString() ?? 'UNKNOWN',
        message: body['error']?.toString() ?? 'An error occurred',
      );
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: domainErr,
          type: err.type,
        ),
      );
      return;
    }

    handler.next(err);
  }
}

/// DioClient — singleton HTTP client for the PinShop TJ API.
///
/// Base URL is injected via --dart-define=API_URL=https://... at build/run time (D-07).
/// Falls back to http://localhost:8080 for local development.
class DioClient {
  static DioClient? _instance;

  final Dio dio;
  final SecureStorage _storage;
  final AuthInterceptor _authInterceptor;

  DioClient._({
    required this.dio,
    required SecureStorage storage,
    required AuthInterceptor authInterceptor,
  })  : _storage = storage,
        _authInterceptor = authInterceptor;

  factory DioClient({SecureStorage? storage}) {
    _instance ??= DioClient._create(storage: storage ?? SecureStorage());
    return _instance!;
  }

  /// Register a callback invoked when the session expires (refresh failed).
  /// AuthNotifier uses this to drive the logout redirect.
  set onSessionExpired(void Function()? cb) =>
      _authInterceptor.onSessionExpired = cb;

  /// Register or clear notifier-owned refresh coordination.
  set authRefreshCoordinator(AuthRefreshCoordinator? coordinator) =>
      _authInterceptor.refreshCoordinator = coordinator;

  factory DioClient._create({required SecureStorage storage}) {
    const apiUrl = String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:8080',
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final interceptor = AuthInterceptor(dio, storage);
    dio.interceptors.add(interceptor);
    return DioClient._(
      dio: dio,
      storage: storage,
      authInterceptor: interceptor,
    );
  }

  /// Test seam: build a client around a caller-provided [Dio] (e.g. one whose
  /// httpClientAdapter is a fake/mock). Keeps the same AuthInterceptor so the
  /// API `{ error, code }` → DomainException mapping is exercised in tests.
  @visibleForTesting
  factory DioClient.withDio(Dio dio, {SecureStorage? storage}) {
    final s = storage ?? SecureStorage();
    final interceptor = AuthInterceptor(dio, s);
    dio.interceptors.add(interceptor);
    return DioClient._(dio: dio, storage: s, authInterceptor: interceptor);
  }

  /// Expose the SecureStorage for providers that need to read/write tokens.
  SecureStorage get storage => _storage;

  /// Convenience GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  /// Convenience POST
  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return dio.post<T>(path, data: data);
  }

  /// Convenience PATCH
  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return dio.patch<T>(path, data: data);
  }

  /// Convenience DELETE
  Future<Response<T>> delete<T>(String path, {dynamic data}) {
    return dio.delete<T>(path, data: data);
  }
}
