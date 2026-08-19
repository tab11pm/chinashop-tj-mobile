// Pure-logic tests for AuthState — no widgets, no platform channels, so they
// run cleanly under `flutter test` without the flutter_secure_storage plugin.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';

import 'helpers/fake_dio.dart';
import 'helpers/fake_secure_storage.dart';

Future<void> waitUntil(
  bool Function() condition, {
  String reason = 'condition',
}) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw TestFailure('Timed out waiting for $reason');
}

class CountingClearFakeSecureStorage extends FakeSecureStorage {
  int clearTokensCalls = 0;
  int clearProfileCacheCalls = 0;

  @override
  Future<void> clearTokens() async {
    clearTokensCalls++;
    await super.clearTokens();
  }

  @override
  Future<void> clearProfileCache() async {
    clearProfileCacheCalls++;
    await super.clearProfileCache();
  }
}

class RefreshConnectionErrorAdapter extends FakeAdapter {
  RefreshConnectionErrorAdapter(super.routes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST' && options.path == '/api/auth/refresh') {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}

class LockedKeyringSecureStorage extends FakeSecureStorage {
  @override
  Future<String?> readAccessToken() => Future<String?>.error(
    PlatformException(code: 'KeyringLocked'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // flutter_secure_storage reads return null in tests (real plugin absent).
    const ch = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (call) async => null);
  });

  group('AuthState', () {
    test('defaults: unauthenticated, not loading, ru locale, no error', () {
      const s = AuthState();
      expect(s.isAuthenticated, isFalse);
      expect(s.isLoading, isFalse);
      expect(s.isProfileRefreshing, isFalse);
      expect(s.profileResolved, isFalse);
      expect(s.needsProfileSetup, isFalse);
      expect(s.locale, 'ru');
      expect(s.error, isNull);
    });

    test('copyWith overrides only the provided fields', () {
      const s = AuthState();
      final next = s.copyWith(isAuthenticated: true, locale: 'tg');
      expect(next.isAuthenticated, isTrue);
      expect(next.locale, 'tg');
      expect(next.needsProfileSetup, isFalse);
      // untouched field preserved
      expect(next.isLoading, isFalse);
    });

    test('copyWith clears error when omitted (error is not preserved)', () {
      const s = AuthState(error: 'boom');
      final next = s.copyWith(isLoading: true);
      expect(next.error, isNull);
      expect(next.isLoading, isTrue);
    });

    test('loadInitialAuthState reads persisted session before first frame',
        () async {
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'token')
        ..seed(FakeSecureStorage.localeKey, 'tg')
        ..seed(FakeSecureStorage.channelKey, 'b2b')
        ..seed(FakeSecureStorage.channelChosenKey, 'true');

      final state = await loadInitialAuthState(storage);

      expect(state.isAuthenticated, isTrue);
      expect(state.profileResolved, isFalse);
      expect(state.locale, 'tg');
      expect(state.channel, 'b2b');
      expect(state.channelChosen, isTrue);
    });

    test('loadInitialAuthState starts signed out when the keyring is locked',
        () async {
      final state = await loadInitialAuthState(LockedKeyringSecureStorage());

      expect(state.isAuthenticated, isFalse);
      expect(state.profileResolved, isTrue);
      expect(state.locale, 'ru');
      expect(state.channel, 'b2c');
      expect(state.channelChosen, isFalse);
    });
  });

  group('channel extension', () {
    test('AuthState default channel is b2c and channelChosen is false', () {
      const s = AuthState();
      expect(s.channel, 'b2c');
      expect(s.channelChosen, isFalse);
      expect(s.role, isNull);
    });

    test('setChannel writes to SecureStorage and updates state', () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'PATCH /api/users/me/channel': (200, {'channel': 'b2b'}),
        // _syncFromServer is NOT called because no access token in storage
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      // Force provider creation BEFORE delay so _initialize is triggered
      container.read(authProvider);

      // Wait for async _initialize to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(authProvider.notifier).setChannel('b2b');
      final state = container.read(authProvider);

      expect(state.channel, 'b2b');
      expect(state.channelChosen, isTrue);
      expect(storage.data[FakeSecureStorage.channelKey], 'b2b');
      expect(storage.data[FakeSecureStorage.channelChosenKey], 'true');
    });

    test('setLocale persists locally and patches authenticated server profile',
        () async {
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'token');
      final (dio, adapter) = fakeDio({
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'locale': 'tj',
            'name': 'User',
            'phone': '+992000000001',
            'needsProfileSetup': false,
          }
        ),
        'PATCH /api/users/me': (200, {'locale': 'ru'}),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(authProvider.notifier).setLocale('ru');

      expect(storage.data[FakeSecureStorage.localeKey], 'ru');
      final patch = adapter.requestTo('PATCH', '/api/users/me');
      expect(patch.data, {'locale': 'ru'});
    });

    test('setChannel rolls back state on PATCH failure', () async {
      final storage = FakeSecureStorage();
      // No access token → isAuthenticated = false
      final (dio, _) = fakeDio({
        'PATCH /api/users/me/channel': (
          500,
          {'error': 'fail', 'code': 'INTERNAL'}
        ),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      // Force provider creation BEFORE delay
      container.read(authProvider);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // setChannel('b2b') should throw and roll back channel to 'b2c' (the default)
      await expectLater(
        container.read(authProvider.notifier).setChannel('b2b'),
        throwsException,
      );

      final state = container.read(authProvider);
      // Should have rolled back to the previous value ('b2c' default)
      expect(state.channel, 'b2c');
    });

    test('_initialize reads channel and channelChosen from SecureStorage',
        () async {
      final storage = FakeSecureStorage();
      storage.seed(FakeSecureStorage.channelKey, 'b2b');
      storage.seed(FakeSecureStorage.channelChosenKey, 'true');
      // No access token → _syncFromServer is not called

      final (dio, _) = fakeDio({});
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      // Force provider creation (and trigger _initialize) BEFORE the delay
      container.read(authProvider);

      // Wait for async _initialize to complete (multiple microtask ticks)
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(authProvider);
      expect(state.channel, 'b2b');
      expect(state.channelChosen, isTrue);
    });

    test('session expiry resets backend profile setup state', () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'GET /api/orders': (401, {'error': 'expired', 'code': 'UNAUTHORIZED'}),
        'POST /api/auth/refresh': (
          401,
          {'error': 'expired', 'code': 'SESSION_EXPIRED'},
        ),
      });
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
          needsProfileSetup: true,
          role: 'customer',
          name: 'User',
          phone: '+992000000002',
          email: 'user@example.com',
        ),
      );
      addTearDown(notifier.dispose);

      await expectLater(client.get('/api/orders'), throwsException);
      await waitUntil(
        () => notifier.state.error == 'SESSION_EXPIRED',
        reason: 'session expiry invalidation',
      );

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.needsProfileSetup, isFalse);
      expect(notifier.state.role, isNull);
      expect(notifier.state.name, isNull);
      expect(notifier.state.phone, isNull);
      expect(notifier.state.email, isNull);
      expect(notifier.state.error, 'SESSION_EXPIRED');
    });

    test('missing refresh token invalidates the persisted auth session',
        () async {
      final storage = CountingClearFakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'expired-access-token')
        ..seed(FakeSecureStorage.profileNameKey, 'User');
      final (dio, adapter) = fakeDio({
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': 'User',
            'needsProfileSetup': false,
          },
        ),
        'GET /api/orders': (
          401,
          {'error': 'expired', 'code': 'UNAUTHORIZED'},
        ),
      });
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
          name: 'User',
        ),
      );
      addTearDown(notifier.dispose);
      await waitUntil(
        () => adapter.requestCount('GET', '/api/users/me') == 1,
        reason: 'initial profile refresh',
      );

      await expectLater(
          client.get('/api/orders'), throwsA(isA<DioException>()));
      await waitUntil(
        () => notifier.state.error == 'SESSION_EXPIRED',
        reason: 'missing refresh-token invalidation',
      );

      expect(adapter.requestCount('POST', '/api/auth/refresh'), 0);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(storage.clearTokensCalls, 1);
      expect(storage.clearProfileCacheCalls, 1);
      expect(storage.data, isNot(contains(FakeSecureStorage.accessTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.refreshTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileNameKey)));
    });

    test(
        'verifyOtp refreshes profile identity for the newly authenticated account',
        () async {
      final storage = FakeSecureStorage();
      storage.seed(FakeSecureStorage.accessTokenKey, 'old-token');
      final (dio, adapter) = fakeDio({
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': 'Old User',
            'phone': '+992000000001',
            'needsProfileSetup': false,
          }
        ),
        'POST /api/auth/otp/verify': (
          200,
          {
            'accessToken': 'new-token',
            'refreshToken': 'new-refresh-token',
            'expiresIn': 3600,
            'isNewUser': false,
            'needsProfileSetup': false,
          }
        ),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(authProvider).name, 'Old User');

      adapter.routes['GET /api/users/me'] = (
        200,
        {
          'channel': 'b2c',
          'role': 'customer',
          'name': 'New User',
          'phone': '+992000000002',
          'needsProfileSetup': false,
        }
      );

      await container
          .read(authProvider.notifier)
          .verifyOtp('+992000000002', '123456');

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.profileResolved, isTrue);
      expect(state.name, 'New User');
      expect(state.phone, '+992000000002');
    });

    test('completeProfile consumes the backend profile-setup result', () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'POST /api/auth/otp/verify': (
          200,
          {
            'accessToken': 'new-token',
            'refreshToken': 'new-refresh-token',
            'expiresIn': 3600,
            'isNewUser': true,
            'needsProfileSetup': true,
          }
        ),
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': null,
            'phone': '+992000000002',
            'email': null,
            'needsProfileSetup': true,
          }
        ),
        'PATCH /api/users/me': (
          200,
          {
            'name': '',
            'email': '',
            'needsProfileSetup': false,
          }
        ),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(authProvider.notifier)
          .verifyOtp('+992000000002', '123456');

      expect(container.read(authProvider).needsProfileSetup, isTrue);

      await container.read(authProvider.notifier).completeProfile('', '');

      final state = container.read(authProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.name, '');
      expect(state.email, '');
      expect(state.needsProfileSetup, isFalse);
    });

    test('backend profile state overrides cached display identity', () async {
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'token')
        ..seed(FakeSecureStorage.profileNameKey, 'Cached User')
        ..seed(FakeSecureStorage.profileEmailKey, 'cached@example.com')
        ..seed(FakeSecureStorage.profilePhoneKey, '+992000000002');
      final (dio, _) = fakeDio({
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': null,
            'phone': '+992000000002',
            'email': null,
            'needsProfileSetup': true,
          }
        ),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.name, 'Cached User');
      expect(state.email, 'cached@example.com');
      expect(state.needsProfileSetup, isTrue);
    });

    test('blank identity stays complete when backend says setup is not needed',
        () async {
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'token');
      final (dio, _) = fakeDio({
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': null,
            'phone': '+992000000002',
            'email': null,
            'needsProfileSetup': false,
          }
        ),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(authProvider);
      expect(state.profileResolved, isTrue);
      expect(state.needsProfileSetup, isFalse);
    });

    test('populated identity still needs setup when backend says it does',
        () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'POST /api/auth/otp/verify': (
          200,
          {
            'accessToken': 'token',
            'refreshToken': 'refresh',
            'expiresIn': 3600,
            'isNewUser': false,
            'needsProfileSetup': true,
          }
        ),
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': 'Complete Looking User',
            'phone': '+992000000002',
            'email': 'user@example.com',
            'needsProfileSetup': true,
          }
        ),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container
          .read(authProvider.notifier)
          .verifyOtp('+992000000002', '123456');

      expect(container.read(authProvider).needsProfileSetup, isTrue);
    });

    test(
        'OTP profile state remains authoritative when following GET is malformed',
        () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'POST /api/auth/otp/verify': (
          200,
          {
            'accessToken': 'token',
            'refreshToken': 'refresh',
            'expiresIn': 3600,
            'isNewUser': true,
            'needsProfileSetup': true,
          }
        ),
        'GET /api/users/me': (200, {'needsProfileSetup': 'true'}),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container
          .read(authProvider.notifier)
          .verifyOtp('+992000000002', '123456');

      final state = container.read(authProvider);
      expect(state.profileResolved, isTrue);
      expect(state.needsProfileSetup, isTrue);
    });

    test('session bootstrap GET failure leaves profile unresolved', () async {
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'token');
      final (dio, _) = fakeDio({
        'GET /api/users/me': (500, {'error': 'failed', 'code': 'INTERNAL'}),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(authProvider);
      expect(state.profileResolved, isFalse);
      expect(state.needsProfileSetup, isFalse);
      expect(state.error, 'PROFILE_LOAD_FAILED');
    });

    test('logout clears tokens, profile cache, and in-memory identity',
        () async {
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'refresh')
        ..seed(FakeSecureStorage.profileNameKey, 'Cached User')
        ..seed(FakeSecureStorage.profileEmailKey, 'cached@example.com')
        ..seed(FakeSecureStorage.profilePhoneKey, '+992000000002');
      final (dio, _) = fakeDio({
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': 'User',
            'phone': '+992000000002',
            'email': 'user@example.com',
            'needsProfileSetup': true,
          }
        ),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container.read(authProvider.notifier).logout();

      final state = container.read(authProvider);
      expect(storage.clearProfileCacheCalled, isTrue);
      expect(storage.data, isNot(contains(FakeSecureStorage.accessTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.refreshTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileNameKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileEmailKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profilePhoneKey)));
      expect(state.isAuthenticated, isFalse);
      expect(state.needsProfileSetup, isFalse);
      expect(state.role, isNull);
      expect(state.name, isNull);
      expect(state.phone, isNull);
      expect(state.email, isNull);
    });

    test('OTP rejects malformed profile flags before replacing the session',
        () async {
      for (final body in <Object?>[
        {
          'accessToken': 'new-token',
          'refreshToken': 'new-refresh',
          'isNewUser': true,
        },
        {
          'accessToken': 'new-token',
          'refreshToken': 'new-refresh',
          'isNewUser': true,
          'needsProfileSetup': 'true',
        },
        'not-a-map',
      ]) {
        final storage = FakeSecureStorage();
        final (dio, _) = fakeDio({
          'POST /api/auth/otp/verify': (200, body),
        });
        final notifier = AuthNotifier(
          client: DioClient.withDio(dio, storage: storage),
          storage: storage,
          initialState: const AuthState(profileResolved: true),
        );
        addTearDown(notifier.dispose);

        await expectLater(
          notifier.verifyOtp('+992000000002', '123456'),
          throwsA(anything),
        );

        expect(notifier.state.error, 'AUTH_PROTOCOL_ERROR');
        expect(notifier.state.isAuthenticated, isFalse);
        expect(storage.data, isNot(contains(FakeSecureStorage.accessTokenKey)));
        expect(
          storage.data,
          isNot(contains(FakeSecureStorage.refreshTokenKey)),
        );
      }
    });

    test('GET malformed profile flags remain an unresolved load failure',
        () async {
      for (final body in <Object?>[
        {'channel': 'b2c'},
        {'channel': 'b2c', 'needsProfileSetup': 'false'},
        'not-a-map',
      ]) {
        final storage = FakeSecureStorage();
        final (dio, _) = fakeDio({'GET /api/users/me': (200, body)});
        final notifier = AuthNotifier(
          client: DioClient.withDio(dio, storage: storage),
          storage: storage,
          initialState: const AuthState(profileResolved: false),
        );
        addTearDown(notifier.dispose);

        final result = await notifier.refreshFromServer();
        expect(result, isFalse);
        expect(notifier.state.profileResolved, isFalse);
        expect(notifier.state.error, 'PROFILE_LOAD_FAILED');
      }
    });

    test('malformed PATCH reconciles completion from a successful GET',
        () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'PATCH /api/users/me': (200, {'name': 'User'}),
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': 'User',
            'phone': '+992000000002',
            'email': 'user@example.com',
            'needsProfileSetup': false,
          }
        ),
      });
      final notifier = AuthNotifier(
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
        initialState: const AuthState(
          profileResolved: true,
          needsProfileSetup: true,
        ),
      );
      addTearDown(notifier.dispose);

      await notifier.completeProfile('User', 'user@example.com');

      expect(notifier.state.profileResolved, isTrue);
      expect(notifier.state.needsProfileSetup, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('malformed PATCH plus failed reconciliation exposes protocol error',
        () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'PATCH /api/users/me': (200, 'not-a-map'),
        'GET /api/users/me': (500, {'error': 'failed', 'code': 'INTERNAL'}),
      });
      final notifier = AuthNotifier(
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
        initialState: const AuthState(
          profileResolved: true,
          needsProfileSetup: true,
        ),
      );
      addTearDown(notifier.dispose);

      await notifier.completeProfile('User', 'user@example.com');

      expect(notifier.state.profileResolved, isFalse);
      expect(notifier.state.needsProfileSetup, isTrue);
      expect(notifier.state.error, 'PROFILE_PROTOCOL_ERROR');
    });

    test('pending profile GET cannot repopulate identity after logout',
        () async {
      final pendingProfile = Completer<(int, Object?)>();
      final storage = FakeSecureStorage();
      final (dio, adapter) = fakeDio(
        {
          'POST /api/auth/otp/verify': (
            200,
            {
              'accessToken': 'token-a',
              'refreshToken': 'refresh-a',
              'isNewUser': false,
              'needsProfileSetup': false,
            }
          ),
          'GET /api/users/me': (
            200,
            {
              'channel': 'b2c',
              'role': 'customer',
              'name': 'Account A',
              'phone': '+992000000001',
              'email': 'a@example.com',
              'needsProfileSetup': false,
            }
          ),
        },
      );
      final notifier = AuthNotifier(
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
        initialState: const AuthState(profileResolved: true),
      );
      addTearDown(notifier.dispose);
      await notifier.verifyOtp('+992000000001', '123456');

      adapter.asyncRoutes['GET /api/users/me'] = () => pendingProfile.future;
      final staleRefresh = notifier.refreshFromServer();
      await waitUntil(
        () => adapter.requestCount('GET', '/api/users/me') == 2,
        reason: 'stale account A GET to start',
      );

      await notifier.logout();
      pendingProfile.complete((
        200,
        {
          'channel': 'b2b',
          'role': 'wholesale_seller',
          'name': 'Late Account A',
          'phone': '+992000000001',
          'email': 'late-a@example.com',
          'needsProfileSetup': true,
        }
      ));
      await staleRefresh;

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.needsProfileSetup, isFalse);
      expect(notifier.state.name, isNull);
      expect(storage.data, isNot(contains(FakeSecureStorage.profileNameKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileEmailKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profilePhoneKey)));
    });

    test('pending account A GET cannot overwrite authoritative OTP account B',
        () async {
      final pendingAccountA = Completer<(int, Object?)>();
      final storage = FakeSecureStorage();
      final (dio, adapter) = fakeDio({
        'POST /api/auth/otp/verify': (
          200,
          {
            'accessToken': 'token-a',
            'refreshToken': 'refresh-a',
            'isNewUser': false,
            'needsProfileSetup': false,
          }
        ),
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': 'Account A',
            'phone': '+992000000001',
            'email': 'a@example.com',
            'needsProfileSetup': false,
          }
        ),
      });
      final notifier = AuthNotifier(
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
        initialState: const AuthState(profileResolved: true),
      );
      addTearDown(notifier.dispose);
      await notifier.verifyOtp('+992000000001', '123456');

      adapter.asyncRoutes['GET /api/users/me'] = () => pendingAccountA.future;
      final staleRefresh = notifier.refreshFromServer();
      await waitUntil(
        () => adapter.requestCount('GET', '/api/users/me') == 2,
        reason: 'account A refresh to start',
      );
      adapter.asyncRoutes.remove('GET /api/users/me');
      adapter.routes['POST /api/auth/otp/verify'] = (
        200,
        {
          'accessToken': 'token-b',
          'refreshToken': 'refresh-b',
          'isNewUser': true,
          'needsProfileSetup': true,
        }
      );
      adapter.routes['GET /api/users/me'] = (
        200,
        {
          'channel': 'b2c',
          'role': 'customer',
          'name': 'Account B',
          'phone': '+992000000002',
          'email': 'b@example.com',
          'needsProfileSetup': true,
        }
      );

      await notifier.verifyOtp('+992000000002', '654321');
      pendingAccountA.complete((
        200,
        {
          'channel': 'b2b',
          'role': 'wholesale_seller',
          'name': 'Late Account A',
          'phone': '+992000000001',
          'email': 'late-a@example.com',
          'needsProfileSetup': false,
        }
      ));
      await staleRefresh;

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.needsProfileSetup, isTrue);
      expect(notifier.state.name, 'Account B');
      expect(notifier.state.phone, '+992000000002');
      expect(notifier.state.channel, 'b2c');
      expect(storage.data[FakeSecureStorage.profileNameKey], 'Account B');
      expect(storage.data[FakeSecureStorage.profileEmailKey], 'b@example.com');
      expect(storage.data[FakeSecureStorage.profilePhoneKey], '+992000000002');
    });

    test(
        'session expiry while loading clears all auth storage and loading flags',
        () async {
      final pendingProfile = Completer<(int, Object?)>();
      addTearDown(() {
        if (!pendingProfile.isCompleted) {
          pendingProfile.complete((
            500,
            {
              'error': 'failed',
              'code': 'INTERNAL',
            }
          ));
        }
      });
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'refresh')
        ..seed(FakeSecureStorage.profileNameKey, 'Cached User')
        ..seed(FakeSecureStorage.profileEmailKey, 'cached@example.com')
        ..seed(FakeSecureStorage.profilePhoneKey, '+992000000002');
      final (dio, adapter) = fakeDio(
        {
          'GET /api/orders': (
            401,
            {'error': 'expired', 'code': 'UNAUTHORIZED'}
          ),
          'POST /api/auth/refresh': (
            401,
            {'error': 'expired', 'code': 'SESSION_EXPIRED'}
          ),
        },
        asyncRoutes: {
          'GET /api/users/me': () => pendingProfile.future,
        },
      );
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          isLoading: true,
          profileResolved: false,
          needsProfileSetup: true,
          name: 'User',
          phone: '+992000000002',
          email: 'user@example.com',
        ),
      );
      addTearDown(notifier.dispose);
      await waitUntil(
        () => adapter.requestCount('GET', '/api/users/me') == 1,
        reason: 'profile refresh to start',
      );

      await expectLater(client.get('/api/orders'), throwsException);
      await waitUntil(
        () => notifier.state.error == 'SESSION_EXPIRED',
        reason: 'serialized session invalidation',
      );

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.profileResolved, isTrue);
      expect(notifier.state.needsProfileSetup, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isProfileRefreshing, isFalse);
      expect(storage.data, isNot(contains(FakeSecureStorage.accessTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.refreshTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileNameKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileEmailKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profilePhoneKey)));

      pendingProfile.complete((500, {'error': 'late', 'code': 'INTERNAL'}));
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.error, 'SESSION_EXPIRED');
    });

    test('refresh 5xx preserves persisted session tokens', () async {
      final storage = CountingClearFakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'access-token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'refresh-token');
      final (dio, adapter) = fakeDio({
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'needsProfileSetup': false,
          }
        ),
        'GET /api/orders': (
          401,
          {'error': 'expired', 'code': 'UNAUTHORIZED'},
        ),
        'POST /api/auth/refresh': (
          500,
          {'error': 'temporary failure', 'code': 'INTERNAL'},
        ),
      });
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
        ),
      );
      addTearDown(notifier.dispose);
      await waitUntil(
        () => adapter.requestCount('GET', '/api/users/me') == 1,
        reason: 'initial profile refresh',
      );

      await expectLater(
          client.get('/api/orders'), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isAuthenticated, isTrue);
      expect(storage.clearTokensCalls, 0);
      expect(storage.data[FakeSecureStorage.accessTokenKey], 'access-token');
      expect(storage.data[FakeSecureStorage.refreshTokenKey], 'refresh-token');
    });

    test('refresh connection error preserves persisted session tokens',
        () async {
      final storage = CountingClearFakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'access-token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'refresh-token');
      final adapter = RefreshConnectionErrorAdapter({
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'needsProfileSetup': false,
          }
        ),
        'GET /api/orders': (
          401,
          {'error': 'expired', 'code': 'UNAUTHORIZED'},
        ),
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter;
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
        ),
      );
      addTearDown(notifier.dispose);
      await waitUntil(
        () => adapter.requestCount('GET', '/api/users/me') == 1,
        reason: 'initial profile refresh',
      );

      await expectLater(
          client.get('/api/orders'), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isAuthenticated, isTrue);
      expect(storage.clearTokensCalls, 0);
      expect(storage.data[FakeSecureStorage.accessTokenKey], 'access-token');
      expect(storage.data[FakeSecureStorage.refreshTokenKey], 'refresh-token');
    });

    test(
        'logout fences a late interceptor refresh token write and protected retry',
        () async {
      final pendingRefresh = Completer<(int, Object?)>();
      addTearDown(() {
        if (!pendingRefresh.isCompleted) {
          pendingRefresh.complete((
            500,
            {'error': 'cancelled', 'code': 'INTERNAL'},
          ));
        }
      });
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'old-access-token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'old-refresh-token')
        ..seed(FakeSecureStorage.profileNameKey, 'Old User')
        ..seed(FakeSecureStorage.profileEmailKey, 'old@example.com')
        ..seed(FakeSecureStorage.profilePhoneKey, '+992000000001');
      final (dio, adapter) = fakeDio(
        {
          'GET /api/users/me': (
            200,
            {
              'channel': 'b2c',
              'role': 'customer',
              'name': 'Old User',
              'phone': '+992000000001',
              'email': 'old@example.com',
              'needsProfileSetup': false,
            }
          ),
          'GET /api/orders': (
            401,
            {'error': 'expired', 'code': 'UNAUTHORIZED'},
          ),
        },
        asyncRoutes: {
          'POST /api/auth/refresh': () => pendingRefresh.future,
        },
      );
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
          name: 'Old User',
          phone: '+992000000001',
          email: 'old@example.com',
        ),
      );
      addTearDown(notifier.dispose);
      await waitUntil(
        () =>
            adapter.requestCount('GET', '/api/users/me') == 1 &&
            !notifier.state.isProfileRefreshing,
        reason: 'initial profile refresh',
      );

      final protectedRequest = client.get('/api/orders');
      await waitUntil(
        () => adapter.requestCount('POST', '/api/auth/refresh') == 1,
        reason: 'interceptor refresh to start',
      );
      await notifier.logout();
      pendingRefresh.complete((200, {'accessToken': 'late-access-token'}));

      await expectLater(protectedRequest, throwsException);
      await Future<void>.delayed(Duration.zero);

      expect(adapter.requestCount('GET', '/api/orders'), 1);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.error, isNull);
      expect(storage.data, isNot(contains(FakeSecureStorage.accessTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.refreshTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileNameKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileEmailKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profilePhoneKey)));
    });

    test('logout ignores a late interceptor refresh failure', () async {
      final pendingRefresh = Completer<(int, Object?)>();
      addTearDown(() {
        if (!pendingRefresh.isCompleted) {
          pendingRefresh.complete((
            500,
            {'error': 'cancelled', 'code': 'INTERNAL'},
          ));
        }
      });
      final storage = CountingClearFakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'old-access-token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'old-refresh-token')
        ..seed(FakeSecureStorage.profileNameKey, 'Old User')
        ..seed(FakeSecureStorage.profileEmailKey, 'old@example.com')
        ..seed(FakeSecureStorage.profilePhoneKey, '+992000000001');
      final (dio, adapter) = fakeDio(
        {
          'GET /api/users/me': (
            200,
            {
              'channel': 'b2c',
              'role': 'customer',
              'name': 'Old User',
              'phone': '+992000000001',
              'email': 'old@example.com',
              'needsProfileSetup': false,
            }
          ),
          'GET /api/orders': (
            401,
            {'error': 'expired', 'code': 'UNAUTHORIZED'},
          ),
        },
        asyncRoutes: {
          'POST /api/auth/refresh': () => pendingRefresh.future,
        },
      );
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
          name: 'Old User',
          phone: '+992000000001',
          email: 'old@example.com',
        ),
      );
      addTearDown(notifier.dispose);
      await waitUntil(
        () =>
            adapter.requestCount('GET', '/api/users/me') == 1 &&
            !notifier.state.isProfileRefreshing,
        reason: 'initial profile refresh',
      );

      final protectedRequest = client.get('/api/orders');
      await waitUntil(
        () => adapter.requestCount('POST', '/api/auth/refresh') == 1,
        reason: 'interceptor refresh to start',
      );
      await notifier.logout();
      expect(storage.clearTokensCalls, 1);
      expect(storage.clearProfileCacheCalls, 1);
      expect(notifier.state.error, isNull);

      pendingRefresh.complete((
        500,
        {'error': 'late failure', 'code': 'SESSION_EXPIRED'},
      ));
      await expectLater(protectedRequest, throwsException);
      await Future<void>.delayed(Duration.zero);

      expect(adapter.requestCount('GET', '/api/orders'), 1);
      expect(storage.clearTokensCalls, 1);
      expect(storage.clearProfileCacheCalls, 1);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.error, isNull);
      expect(storage.data, isNot(contains(FakeSecureStorage.accessTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.refreshTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileNameKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileEmailKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profilePhoneKey)));
    });

    test('account replacement ignores the originating account 401', () async {
      final pendingAccountAResponse = Completer<(int, Object?)>();
      addTearDown(() {
        if (!pendingAccountAResponse.isCompleted) {
          pendingAccountAResponse.complete((
            500,
            {'error': 'cancelled', 'code': 'INTERNAL'},
          ));
        }
      });
      var profileReads = 0;
      final storage = CountingClearFakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'access-a')
        ..seed(FakeSecureStorage.refreshTokenKey, 'refresh-a')
        ..seed(FakeSecureStorage.profileNameKey, 'Account A')
        ..seed(FakeSecureStorage.profileEmailKey, 'a@example.com')
        ..seed(FakeSecureStorage.profilePhoneKey, '+992000000001');
      final (dio, adapter) = fakeDio(
        {
          'POST /api/auth/otp/verify': (
            200,
            {
              'accessToken': 'access-b',
              'refreshToken': 'refresh-b',
              'isNewUser': false,
              'needsProfileSetup': false,
            }
          ),
          'POST /api/auth/refresh': (
            200,
            {
              'accessToken': 'late-account-a-access',
              'refreshToken': 'late-account-a-refresh',
            },
          ),
        },
        asyncRoutes: {
          'GET /api/users/me': () async {
            profileReads++;
            return profileReads == 1
                ? (
                    200,
                    {
                      'channel': 'b2c',
                      'role': 'customer',
                      'name': 'Account A',
                      'phone': '+992000000001',
                      'email': 'a@example.com',
                      'needsProfileSetup': false,
                    },
                  )
                : (
                    200,
                    {
                      'channel': 'b2c',
                      'role': 'customer',
                      'name': 'Account B',
                      'phone': '+992000000002',
                      'email': 'b@example.com',
                      'needsProfileSetup': false,
                    },
                  );
          },
          'GET /api/orders': () => pendingAccountAResponse.future,
        },
      );
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
          name: 'Account A',
          phone: '+992000000001',
          email: 'a@example.com',
        ),
      );
      addTearDown(notifier.dispose);
      await waitUntil(
        () => profileReads == 1 && !notifier.state.isProfileRefreshing,
        reason: 'account A profile refresh',
      );

      final accountARequest = client.get('/api/orders');
      await waitUntil(
        () => adapter.requestCount('GET', '/api/orders') == 1,
        reason: 'account A protected request dispatch',
      );
      await notifier.verifyOtp('+992000000002', '654321');
      expect(notifier.state.name, 'Account B');
      expect(storage.data[FakeSecureStorage.accessTokenKey], 'access-b');
      expect(storage.data[FakeSecureStorage.refreshTokenKey], 'refresh-b');

      pendingAccountAResponse.complete((
        401,
        {'error': 'expired A', 'code': 'UNAUTHORIZED'},
      ));
      await expectLater(accountARequest, throwsException);
      await Future<void>.delayed(Duration.zero);

      expect(adapter.requestCount('POST', '/api/auth/refresh'), 0);
      expect(adapter.requestCount('GET', '/api/orders'), 1);
      expect(storage.clearTokensCalls, 0);
      expect(storage.clearProfileCacheCalls, 0);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.name, 'Account B');
      expect(notifier.state.error, isNull);
      expect(storage.data[FakeSecureStorage.accessTokenKey], 'access-b');
      expect(storage.data[FakeSecureStorage.refreshTokenKey], 'refresh-b');
      expect(storage.data[FakeSecureStorage.profileNameKey], 'Account B');
      expect(storage.data[FakeSecureStorage.profileEmailKey], 'b@example.com');
      expect(
        storage.data[FakeSecureStorage.profilePhoneKey],
        '+992000000002',
      );
    });

    test('logout and account B login reject account A successful response',
        () async {
      final pendingAccountAResponse = Completer<(int, Object?)>();
      addTearDown(() {
        if (!pendingAccountAResponse.isCompleted) {
          pendingAccountAResponse.complete((
            500,
            {'error': 'cancelled', 'code': 'INTERNAL'},
          ));
        }
      });
      var profileReads = 0;
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'access-a')
        ..seed(FakeSecureStorage.refreshTokenKey, 'refresh-a')
        ..seed(FakeSecureStorage.profileNameKey, 'Account A')
        ..seed(FakeSecureStorage.profileEmailKey, 'a@example.com')
        ..seed(FakeSecureStorage.profilePhoneKey, '+992000000001');
      final (dio, adapter) = fakeDio(
        {
          'POST /api/auth/otp/verify': (
            200,
            {
              'accessToken': 'access-b',
              'refreshToken': 'refresh-b',
              'isNewUser': false,
              'needsProfileSetup': false,
            }
          ),
        },
        asyncRoutes: {
          'GET /api/users/me': () async {
            profileReads++;
            return profileReads == 1
                ? (
                    200,
                    {
                      'channel': 'b2c',
                      'role': 'customer',
                      'name': 'Account A',
                      'phone': '+992000000001',
                      'email': 'a@example.com',
                      'needsProfileSetup': false,
                    },
                  )
                : (
                    200,
                    {
                      'channel': 'b2c',
                      'role': 'customer',
                      'name': 'Account B',
                      'phone': '+992000000002',
                      'email': 'b@example.com',
                      'needsProfileSetup': false,
                    },
                  );
          },
          'GET /api/orders': () => pendingAccountAResponse.future,
        },
      );
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
          name: 'Account A',
          phone: '+992000000001',
          email: 'a@example.com',
        ),
      );
      addTearDown(notifier.dispose);
      await waitUntil(
        () => profileReads == 1 && !notifier.state.isProfileRefreshing,
        reason: 'account A profile refresh',
      );

      final accountARequest = client.get('/api/orders');
      await waitUntil(
        () => adapter.requestCount('GET', '/api/orders') == 1,
        reason: 'account A protected request dispatch',
      );
      await notifier.logout();
      await notifier.verifyOtp('+992000000002', '654321');
      expect(notifier.state.name, 'Account B');

      pendingAccountAResponse.complete((
        200,
        {
          'items': [
            {'id': 'account-a-order'},
          ],
        },
      ));

      await expectLater(
        accountARequest,
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.name, 'Account B');
      expect(storage.data[FakeSecureStorage.accessTokenKey], 'access-b');
      expect(storage.data[FakeSecureStorage.refreshTokenKey], 'refresh-b');
    });

    test('logout discards a protected retry response already in flight',
        () async {
      final pendingRetry = Completer<(int, Object?)>();
      addTearDown(() {
        if (!pendingRetry.isCompleted) {
          pendingRetry.complete((
            500,
            {'error': 'cancelled', 'code': 'INTERNAL'},
          ));
        }
      });
      var protectedAttempts = 0;
      final storage = CountingClearFakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'old-access-token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'old-refresh-token')
        ..seed(FakeSecureStorage.profileNameKey, 'Old User')
        ..seed(FakeSecureStorage.profileEmailKey, 'old@example.com')
        ..seed(FakeSecureStorage.profilePhoneKey, '+992000000001');
      final (dio, adapter) = fakeDio(
        {
          'GET /api/users/me': (
            200,
            {
              'channel': 'b2c',
              'role': 'customer',
              'name': 'Old User',
              'phone': '+992000000001',
              'email': 'old@example.com',
              'needsProfileSetup': false,
            }
          ),
          'POST /api/auth/refresh': (
            200,
            {
              'accessToken': 'refreshed-access-token',
              'refreshToken': 'refreshed-refresh-token',
            },
          ),
        },
        asyncRoutes: {
          'GET /api/orders': () async {
            protectedAttempts++;
            return protectedAttempts == 1
                ? (
                    401,
                    {'error': 'expired', 'code': 'UNAUTHORIZED'},
                  )
                : await pendingRetry.future;
          },
        },
      );
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
          name: 'Old User',
          phone: '+992000000001',
          email: 'old@example.com',
        ),
      );
      addTearDown(notifier.dispose);
      await waitUntil(
        () =>
            adapter.requestCount('GET', '/api/users/me') == 1 &&
            !notifier.state.isProfileRefreshing,
        reason: 'initial profile refresh',
      );

      final protectedRequest = client.get('/api/orders');
      await waitUntil(
        () =>
            adapter.requestCount('POST', '/api/auth/refresh') == 1 &&
            adapter.requestCount('GET', '/api/orders') == 2,
        reason: 'protected retry dispatch',
      );
      await notifier.logout();
      expect(storage.clearTokensCalls, 1);
      expect(storage.clearProfileCacheCalls, 1);

      pendingRetry.complete((
        200,
        {'items': <Object?>[]},
      ));
      await expectLater(protectedRequest, throwsException);
      await Future<void>.delayed(Duration.zero);

      expect(adapter.requestCount('POST', '/api/auth/refresh'), 1);
      expect(adapter.requestCount('GET', '/api/orders'), 2);
      expect(storage.clearTokensCalls, 1);
      expect(storage.clearProfileCacheCalls, 1);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.error, isNull);
      expect(storage.data, isNot(contains(FakeSecureStorage.accessTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.refreshTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileNameKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profileEmailKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.profilePhoneKey)));
    });

    test('standalone interceptor persists rotated tokens and retries',
        () async {
      var protectedAttempts = 0;
      var refreshAttempts = 0;
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'old-access-token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'old-refresh-token');
      final (dio, adapter) = fakeDio(
        const {},
        asyncRoutes: {
          'POST /api/auth/refresh': () async {
            refreshAttempts++;
            return (
              200,
              {
                'accessToken': 'new-access-token-$refreshAttempts',
                'refreshToken': 'new-refresh-token-$refreshAttempts',
              },
            );
          },
          'GET /api/orders': () async {
            protectedAttempts++;
            return protectedAttempts.isOdd
                ? (
                    401,
                    {'error': 'expired', 'code': 'UNAUTHORIZED'},
                  )
                : (
                    200,
                    {'items': <Object?>[]},
                  );
          },
        },
      );
      final client = DioClient.withDio(dio, storage: storage);

      final firstResponse = await client.get('/api/orders');
      final secondResponse = await client.get('/api/orders');

      expect(firstResponse.statusCode, 200);
      expect(secondResponse.statusCode, 200);
      expect(adapter.requestCount('GET', '/api/orders'), 4);
      expect(adapter.requestCount('POST', '/api/auth/refresh'), 2);
      expect(
        adapter.captured
            .where(
              (request) =>
                  request.method == 'POST' &&
                  request.path == '/api/auth/refresh',
            )
            .map((request) => (request.data as Map)['refreshToken'])
            .toList(),
        ['old-refresh-token', 'new-refresh-token-1'],
      );
      expect(
        storage.data[FakeSecureStorage.accessTokenKey],
        'new-access-token-2',
      );
      expect(
        storage.data[FakeSecureStorage.refreshTokenKey],
        'new-refresh-token-2',
      );
    });

    test('logout clear runs after an already-started token write', () async {
      final accessWriteGate = Completer<void>();
      final storage = GatedFakeSecureStorage(
        accessTokenWriteGate: accessWriteGate,
      );
      final (dio, _) = fakeDio({
        'POST /api/auth/otp/verify': (
          200,
          {
            'accessToken': 'late-token',
            'refreshToken': 'late-refresh',
            'isNewUser': true,
            'needsProfileSetup': true,
          }
        ),
      });
      final notifier = AuthNotifier(
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
        initialState: const AuthState(profileResolved: true),
      );
      addTearDown(notifier.dispose);

      final verification = notifier.verifyOtp('+992000000002', '123456');
      await storage.accessTokenWriteStarted.future;
      final invalidation = notifier.logout();
      accessWriteGate.complete();
      await Future.wait([verification, invalidation]);

      expect(notifier.state.isAuthenticated, isFalse);
      expect(storage.data, isNot(contains(FakeSecureStorage.accessTokenKey)));
      expect(storage.data, isNot(contains(FakeSecureStorage.refreshTokenKey)));
    });

    test('stale logout clear cannot erase a newer OTP session', () async {
      final clearTokensGate = Completer<void>();
      final storage = GatedFakeSecureStorage(clearTokensGate: clearTokensGate)
        ..seed(FakeSecureStorage.accessTokenKey, 'old-token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'old-refresh');
      final (dio, adapter) = fakeDio({
        'POST /api/auth/otp/verify': (
          200,
          {
            'accessToken': 'token-b',
            'refreshToken': 'refresh-b',
            'isNewUser': false,
            'needsProfileSetup': false,
          }
        ),
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': 'Account B',
            'phone': '+992000000002',
            'email': 'b@example.com',
            'needsProfileSetup': false,
          }
        ),
      });
      final notifier = AuthNotifier(
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
        initialState: const AuthState(profileResolved: true),
      );
      addTearDown(notifier.dispose);

      final staleLogout = notifier.logout();
      await storage.clearTokensStarted.future;
      final replacement = notifier.verifyOtp('+992000000002', '123456');
      await waitUntil(
        () => adapter.requestCount('POST', '/api/auth/otp/verify') == 1,
        reason: 'replacement OTP response',
      );
      // Let the verified response drain its microtasks. The replacement token
      // write must still be queued behind the in-progress invalidation clear.
      await Future<void>.delayed(Duration.zero);
      expect(storage.accessTokenWriteStarted.isCompleted, isFalse);
      clearTokensGate.complete();
      await Future.wait([staleLogout, replacement]);

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.name, 'Account B');
      expect(storage.data[FakeSecureStorage.accessTokenKey], 'token-b');
      expect(storage.data[FakeSecureStorage.refreshTokenKey], 'refresh-b');
    });

    test('logout fences late completeProfile success and failure', () async {
      for (final lateResponse in <(int, Object?)>[
        (
          200,
          {
            'name': 'Late User',
            'email': 'late@example.com',
            'needsProfileSetup': false,
          }
        ),
        (500, {'error': 'late failure', 'code': 'INTERNAL'}),
      ]) {
        final pendingPatch = Completer<(int, Object?)>();
        final storage = FakeSecureStorage()
          ..seed(FakeSecureStorage.accessTokenKey, 'token')
          ..seed(FakeSecureStorage.refreshTokenKey, 'refresh')
          ..seed(FakeSecureStorage.profileNameKey, 'Cached User');
        final (dio, adapter) = fakeDio(
          const {},
          asyncRoutes: {
            'PATCH /api/users/me': () => pendingPatch.future,
          },
        );
        final notifier = AuthNotifier(
          client: DioClient.withDio(dio, storage: storage),
          storage: storage,
          initialState: const AuthState(
            profileResolved: true,
            needsProfileSetup: true,
          ),
        );
        addTearDown(notifier.dispose);

        final completion = notifier.completeProfile(
          'Late User',
          'late@example.com',
        );
        await waitUntil(
          () => adapter.requestCount('PATCH', '/api/users/me') == 1,
          reason: 'profile completion to start',
        );
        await notifier.logout();
        pendingPatch.complete(lateResponse);
        await completion;

        expect(notifier.state.isAuthenticated, isFalse);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNull);
        expect(notifier.state.name, isNull);
        expect(storage.data, isNot(contains(FakeSecureStorage.profileNameKey)));
        expect(
            storage.data, isNot(contains(FakeSecureStorage.profileEmailKey)));
      }
    });

    test('stale request failure cannot overwrite session-expired state',
        () async {
      final pendingOtp = Completer<(int, Object?)>();
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.accessTokenKey, 'token')
        ..seed(FakeSecureStorage.refreshTokenKey, 'refresh');
      final (dio, adapter) = fakeDio(
        {
          'GET /api/orders': (
            401,
            {'error': 'expired', 'code': 'UNAUTHORIZED'}
          ),
          'POST /api/auth/refresh': (
            401,
            {'error': 'expired', 'code': 'SESSION_EXPIRED'}
          ),
        },
        asyncRoutes: {
          'POST /api/auth/otp/request': () => pendingOtp.future,
        },
      );
      final client = DioClient.withDio(dio, storage: storage);
      final notifier = AuthNotifier(
        client: client,
        storage: storage,
        initialState: const AuthState(
          isAuthenticated: true,
          profileResolved: true,
        ),
      );
      addTearDown(notifier.dispose);

      final request = notifier.requestOtp('+992000000002');
      await waitUntil(
        () => adapter.requestCount('POST', '/api/auth/otp/request') == 1,
        reason: 'OTP request to start',
      );
      await expectLater(client.get('/api/orders'), throwsException);
      await waitUntil(
        () => notifier.state.error == 'SESSION_EXPIRED',
        reason: 'session expiry',
      );
      pendingOtp.complete((500, {'error': 'late', 'code': 'LATE_FAILURE'}));
      await request;

      expect(notifier.state.error, 'SESSION_EXPIRED');
      expect(notifier.state.isLoading, isFalse);
    });

    test('newer same-session refresh wins when responses complete out of order',
        () async {
      final older = Completer<(int, Object?)>();
      final newer = Completer<(int, Object?)>();
      addTearDown(() {
        if (!older.isCompleted) {
          older.complete((500, {'error': 'failed', 'code': 'INTERNAL'}));
        }
        if (!newer.isCompleted) {
          newer.complete((500, {'error': 'failed', 'code': 'INTERNAL'}));
        }
      });
      var requestIndex = 0;
      final storage = FakeSecureStorage();
      final (dio, adapter) = fakeDio(
        const {},
        asyncRoutes: {
          'GET /api/users/me': () =>
              requestIndex++ == 0 ? older.future : newer.future,
        },
      );
      final notifier = AuthNotifier(
        client: DioClient.withDio(dio, storage: storage),
        storage: storage,
        initialState: const AuthState(profileResolved: false),
      );
      addTearDown(notifier.dispose);

      final olderRefresh = notifier.refreshFromServer();
      final newerRefresh = notifier.refreshFromServer();
      await waitUntil(
        () => adapter.requestCount('GET', '/api/users/me') == 2,
        reason: 'both refreshes to start',
      );
      expect(notifier.state.isProfileRefreshing, isTrue);

      newer.complete((
        200,
        {
          'channel': 'b2c',
          'role': 'customer',
          'name': 'Newer User',
          'phone': '+992000000002',
          'email': 'newer@example.com',
          'needsProfileSetup': false,
        }
      ));
      expect(await newerRefresh, isTrue);
      expect(notifier.state.isProfileRefreshing, isFalse);

      older.complete((
        200,
        {
          'channel': 'b2b',
          'role': 'wholesale_seller',
          'name': 'Older User',
          'phone': '+992000000001',
          'email': 'older@example.com',
          'needsProfileSetup': true,
        }
      ));
      expect(await olderRefresh, isFalse);

      expect(notifier.state.name, 'Newer User');
      expect(notifier.state.channel, 'b2c');
      expect(notifier.state.needsProfileSetup, isFalse);
      expect(storage.data[FakeSecureStorage.profileNameKey], 'Newer User');
      expect(
        storage.data[FakeSecureStorage.profileEmailKey],
        'newer@example.com',
      );
      expect(
        storage.data[FakeSecureStorage.profilePhoneKey],
        '+992000000002',
      );
    });

    test(
        'completed profile is reused after logout and OTP login with the same phone',
        () async {
      final storage = FakeSecureStorage();
      var otpVerifies = 0;
      var profileCompleted = false;
      final (dio, _) = fakeDio({}, asyncRoutes: {
        'POST /api/auth/otp/verify': () async {
          otpVerifies++;
          return (
            200,
            {
              'accessToken': 'token-$otpVerifies',
              'refreshToken': 'refresh-$otpVerifies',
              'expiresIn': 3600,
              'isNewUser': otpVerifies == 1,
              'needsProfileSetup': !profileCompleted,
            }
          );
        },
        'GET /api/users/me': () async => (
              200,
              {
                'channel': 'b2c',
                'role': 'customer',
                'name': profileCompleted ? 'New User' : null,
                'phone': '+992000000002',
                'email': profileCompleted ? 'new@example.com' : null,
                'needsProfileSetup': !profileCompleted,
              }
            ),
        'PATCH /api/users/me': () async {
          profileCompleted = true;
          return (
            200,
            {
              'channel': 'b2c',
              'role': 'customer',
              'name': 'New User',
              'phone': '+992000000002',
              'email': 'new@example.com',
              'needsProfileSetup': false,
            }
          );
        },
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container
          .read(authProvider.notifier)
          .verifyOtp('+992000000002', '123456');
      await container
          .read(authProvider.notifier)
          .completeProfile('New User', 'new@example.com');

      await container.read(authProvider.notifier).logout();
      await container
          .read(authProvider.notifier)
          .verifyOtp('+992000000002', '123456');

      final state = container.read(authProvider);
      expect(state.name, 'New User');
      expect(state.email, 'new@example.com');
      expect(state.needsProfileSetup, isFalse);
    });

    test('cached profile is not reused for a different phone', () async {
      final storage = FakeSecureStorage()
        ..seed(FakeSecureStorage.profileNameKey, 'First User')
        ..seed(FakeSecureStorage.profileEmailKey, 'first@example.com')
        ..seed(FakeSecureStorage.profilePhoneKey, '+992000000001');
      final (dio, _) = fakeDio({
        'POST /api/auth/otp/verify': (
          200,
          {
            'accessToken': 'token',
            'refreshToken': 'refresh',
            'expiresIn': 3600,
            'isNewUser': true,
            'needsProfileSetup': true,
          }
        ),
        'GET /api/users/me': (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'name': null,
            'phone': '+992000000002',
            'email': null,
            'needsProfileSetup': true,
          }
        ),
        'PATCH /api/users/me': (200, {'locale': 'ru'}),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container
          .read(authProvider.notifier)
          .verifyOtp('+992000000002', '123456');

      final state = container.read(authProvider);
      expect(state.name, isNull);
      expect(state.email, isNull);
      expect(state.needsProfileSetup, isTrue);
    });
  });
}
