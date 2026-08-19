import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/orders/screens/pickup_code_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import '../../../helpers/fake_secure_storage.dart';

class PickupAdapter implements HttpClientAdapter {
  PickupAdapter({
    required this.orderBody,
    this.pickupBody,
    this.pickupStatus = 200,
    this.throwConnection = false,
  });

  final Map<String, dynamic> orderBody;
  final Map<String, dynamic>? pickupBody;
  final int pickupStatus;
  final bool throwConnection;
  int pickupCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/pickup-code')) {
      pickupCalls++;
      if (throwConnection) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return ResponseBody.fromString(
        jsonEncode(pickupBody),
        pickupStatus,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(orderBody),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakePickupEffects implements PickupScreenEffects {
  int engageCalls = 0;
  int restoreCalls = 0;

  @override
  Future<void> engage() async {
    engageCalls++;
  }

  @override
  Future<void> restore() async {
    restoreCalls++;
  }
}

void main() {
  const readyOrder = {
    'id': 'order-1',
    'status': 'ready',
    'totalTjs': '10.00',
    'createdAt': '2026-07-09T00:00:00Z',
    'items': [],
    'shipment': {'id': 's1', 'stage': 'ready', 'trackingNo': 'TR1'},
  };

  const deliveredOrder = {
    'id': 'order-1',
    'status': 'delivered',
    'totalTjs': '10.00',
    'createdAt': '2026-07-09T00:00:00Z',
    'items': [],
    'shipment': {'id': 's1', 'stage': 'delivered', 'trackingNo': 'TR1'},
  };

  Widget harness({
    required HttpClientAdapter adapter,
    required FakeSecureStorage storage,
    PickupScreenEffects? effects,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PickupCodeScreen(
          orderId: 'order-1',
          effects: effects ?? const DefaultPickupScreenEffects(),
        ),
      ),
    );
  }

  testWidgets('engages and restores pickup screen effects', (tester) async {
    final effects = FakePickupEffects();
    final storage = FakeSecureStorage();
    final adapter = PickupAdapter(
      orderBody: readyOrder,
      pickupBody: {'code': '123456', 'qrPayload': 'pshp:123456'},
    );

    await tester.pumpWidget(
      harness(adapter: adapter, storage: storage, effects: effects),
    );
    await tester.pumpAndSettle();

    expect(effects.engageCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(effects.restoreCalls, 1);
  });

  testWidgets('renders QR and grouped code without offline banner',
      (tester) async {
    final storage = FakeSecureStorage();
    final adapter = PickupAdapter(
      orderBody: readyOrder,
      pickupBody: {'code': '123456', 'qrPayload': 'pshp:123456'},
    );

    await tester.pumpWidget(harness(adapter: adapter, storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('123 456'), findsOneWidget);
    expect(find.text('No connection — showing the saved code'), findsNothing);
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('renders cached QR with offline banner on network failure',
      (tester) async {
    final storage = FakeSecureStorage()
      ..seed(
        FakeSecureStorage.pickupCodeKey('order-1'),
        '{"code":"654321","qrPayload":"pshp:654321"}',
      );
    final adapter = PickupAdapter(orderBody: readyOrder, throwConnection: true);

    await tester.pumpWidget(harness(adapter: adapter, storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('654 321'), findsOneWidget);
    expect(find.text('No connection — showing the saved code'), findsOneWidget);
  });

  testWidgets('renders error state and retry re-requests pickup code',
      (tester) async {
    final storage = FakeSecureStorage();
    final adapter = PickupAdapter(
      orderBody: readyOrder,
      pickupBody: {'error': 'Pickup not ready', 'code': 'PICKUP_NOT_READY'},
      pickupStatus: 404,
    );

    await tester.pumpWidget(harness(adapter: adapter, storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    final before = adapter.pickupCalls;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(adapter.pickupCalls, greaterThan(before));
  });

  testWidgets('delivered order shows delivered state and clears cached code',
      (tester) async {
    final storage = FakeSecureStorage()
      ..seed(
        FakeSecureStorage.pickupCodeKey('order-1'),
        '{"code":"777777","qrPayload":"pshp:777777"}',
      );
    final adapter = PickupAdapter(orderBody: deliveredOrder);

    await tester.pumpWidget(harness(adapter: adapter, storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Order delivered'), findsOneWidget);
    expect(find.text('Thank you for your purchase!'), findsOneWidget);
    expect(find.text('777 777'), findsNothing);
    expect(await storage.readPickupCode('order-1'), isNull);
  });
}
