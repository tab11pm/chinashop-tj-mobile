import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/api_exception.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/orders/providers/pickup_code_provider.dart';
import '../../../helpers/fake_dio.dart';
import '../../../helpers/fake_secure_storage.dart';

class ThrowingAdapter implements HttpClientAdapter {
  ThrowingAdapter(this.type, {this.body});

  final DioExceptionType type;
  final Object? body;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    throw DioException(
      requestOptions: options,
      type: type,
      error: body,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('PickupCodeNotifier', () {
    Future<PickupCode> waitForLoaded(
      ProviderContainer container,
      String orderId,
    ) async {
      for (var attempt = 0; attempt < 20; attempt++) {
        final state = container.read(pickupCodeProvider(orderId));
        if (state.hasValue) {
          return state.requireValue;
        }
        if (state.hasError) {
          Error.throwWithStackTrace(state.error!, state.stackTrace!);
        }
        await Future<void>.delayed(Duration.zero);
      }
      fail('pickupCodeProvider($orderId) did not finish loading');
    }

    test('successful fetch stores code and returns fromCache=false', () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'GET /api/orders/order-1/pickup-code': (
          200,
          {'code': '123456', 'qrPayload': 'pshp:123456'}
        ),
      });
      final notifier =
          PickupCodeNotifier(client: DioClient.withDio(dio, storage: storage));

      await notifier.fetchPickupCode('order-1');

      expect(notifier.state.requireValue.code, '123456');
      expect(notifier.state.requireValue.qrPayload, 'pshp:123456');
      expect(notifier.state.requireValue.fromCache, isFalse);
      expect(
        await storage.readPickupCode('order-1'),
        {'code': '123456', 'qrPayload': 'pshp:123456'},
      );
    });

    test('network error falls back to cached code only', () async {
      final storage = FakeSecureStorage()
        ..seed(
          FakeSecureStorage.pickupCodeKey('order-1'),
          '{"code":"654321","qrPayload":"pshp:654321"}',
        );
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = ThrowingAdapter(DioExceptionType.connectionError);
      final notifier =
          PickupCodeNotifier(client: DioClient.withDio(dio, storage: storage));

      await notifier.fetchPickupCode('order-1');

      expect(notifier.state.requireValue.code, '654321');
      expect(notifier.state.requireValue.qrPayload, 'pshp:654321');
      expect(notifier.state.requireValue.fromCache, isTrue);
    });

    test('network error without cache becomes generic error', () async {
      final storage = FakeSecureStorage();
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = ThrowingAdapter(DioExceptionType.connectionError);
      final notifier =
          PickupCodeNotifier(client: DioClient.withDio(dio, storage: storage));

      await notifier.fetchPickupCode('order-1');

      expect(notifier.state.hasError, isTrue);
      expect(notifier.state.error, isA<Exception>());
    });

    test('server/domain error is not treated as offline fallback', () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'GET /api/orders/order-1/pickup-code': (
          404,
          {'error': 'Pickup not ready', 'code': 'PICKUP_NOT_READY'}
        ),
      });
      final notifier =
          PickupCodeNotifier(client: DioClient.withDio(dio, storage: storage));

      await notifier.fetchPickupCode('order-1');

      expect(notifier.state.hasError, isTrue);
      expect(notifier.state.error, isA<DomainException>());
      expect(
        (notifier.state.error as DomainException).code,
        'PICKUP_NOT_READY',
      );
    });

    test('provider family is keyed independently per orderId', () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'GET /api/orders/order-1/pickup-code': (
          200,
          {'code': '111111', 'qrPayload': 'pshp:111111'}
        ),
        'GET /api/orders/order-2/pickup-code': (
          200,
          {'code': '222222', 'qrPayload': 'pshp:222222'}
        ),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
      ]);
      addTearDown(container.dispose);

      container.listen(
        pickupCodeProvider('order-1'),
        (_, __) {},
        fireImmediately: true,
      );
      container.listen(
        pickupCodeProvider('order-2'),
        (_, __) {},
        fireImmediately: true,
      );
      expect((await waitForLoaded(container, 'order-1')).code, '111111');
      expect((await waitForLoaded(container, 'order-2')).code, '222222');
    });
  });
}
