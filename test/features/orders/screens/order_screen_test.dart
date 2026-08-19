import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/orders/screens/order_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import 'package:pinshop_tj/router/app_router.dart';
import '../../../helpers/fake_dio.dart';
import '../../../helpers/fake_secure_storage.dart';

void main() {
  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    fail('Expected finder did not appear: $finder');
  }

  Widget harness({
    required Map<String, (int, Object?)> routes,
    required FakeSecureStorage storage,
    Duration celebrationDuration = const Duration(milliseconds: 500),
  }) {
    final (dio, _) = fakeDio(routes);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => OrderScreen(
            orderId: 'order-1',
            celebrationDuration: celebrationDuration,
          ),
        ),
        GoRoute(
          path: AppRoutes.pickupCode,
          builder: (context, state) => const Scaffold(
            body: Text('pickup-target'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  const readyRoute = {
    'GET /api/orders/order-1': (
      200,
      {
        'id': 'order-1',
        'status': 'ready',
        'totalTjs': '10.00',
        'createdAt': '2026-07-09T00:00:00Z',
        'items': [],
        'shipment': {'id': 's1', 'stage': 'ready', 'trackingNo': 'TR1'},
      }
    ),
  };

  const deliveredRoute = {
    'GET /api/orders/order-1': (
      200,
      {
        'id': 'order-1',
        'status': 'delivered',
        'totalTjs': '10.00',
        'createdAt': '2026-07-09T00:00:00Z',
        'items': [],
        'shipment': {'id': 's1', 'stage': 'delivered', 'trackingNo': 'TR1'},
      }
    ),
  };

  testWidgets('ready order shows pickup CTA and navigates to pickup route',
      (tester) async {
    await tester.pumpWidget(
      harness(routes: readyRoute, storage: FakeSecureStorage()),
    );
    await pumpUntilFound(tester, find.text('Show pickup code'));

    expect(find.text('Show pickup code'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_rounded), findsOneWidget);

    await tester.tap(find.text('Show pickup code'));
    await pumpUntilFound(tester, find.text('pickup-target'));
    expect(find.text('pickup-target'), findsOneWidget);
  });

  testWidgets('first delivered open shows celebration and writes flag',
      (tester) async {
    final storage = FakeSecureStorage();
    await tester.pumpWidget(
      harness(routes: deliveredRoute, storage: storage),
    );
    await pumpUntilFound(
        tester, find.text('Congratulations on your purchase!'));

    expect(find.text('Congratulations on your purchase!'), findsOneWidget);
    expect(await storage.readCelebrated('order-1'), isTrue);
    expect(find.text('Delivered'), findsWidgets);
  });

  testWidgets('already celebrated delivered order does not show celebration',
      (tester) async {
    final storage = FakeSecureStorage()
      ..seed(FakeSecureStorage.celebratedKey('order-1'), 'true');
    await tester.pumpWidget(
      harness(routes: deliveredRoute, storage: storage),
    );
    await pumpUntilFound(tester, find.text('Delivered'));

    expect(find.text('Congratulations on your purchase!'), findsNothing);
    expect(find.text('Delivered'), findsWidgets);
    await tester.pump();
  });

  testWidgets('partial cancellation keeps active line and verbatim manager message',
      (tester) async {
    await tester.pumpWidget(
      harness(
        storage: FakeSecureStorage(),
        routes: {
          'GET /api/orders/order-1': (
            200,
            {
              'id': 'order-1',
              'status': 'paid',
              'totalTjs': '30.00',
              'currentTotalTjs': '20.00',
              'cancelledTotalTjs': '10.00',
              'refundedTotalTjs': '10.00',
              'createdAt': '2026-07-30T00:00:00Z',
              'items': [
                {
                  'id': 'active',
                  'productId': 'p1',
                  'productName': 'Active item',
                  'qty': 1,
                  'unitPriceTjs': '20.00',
                },
                {
                  'id': 'cancelled',
                  'productId': 'p2',
                  'productName': 'Cancelled item',
                  'qty': 1,
                  'unitPriceTjs': '10.00',
                  'status': 'cancelled',
                  'cancellation': {
                    'reason': 'partner_rejected',
                    'customerMessage': 'Verbatim manager message',
                    'refund': {
                      'id': 'refund-1',
                      'amountTjs': '10.00',
                      'currency': 'TJS',
                      'status': 'succeeded',
                      'attemptCount': 1,
                    },
                  },
                },
              ],
            }
          ),
        },
      ),
    );
    await pumpUntilFound(tester, find.text('Verbatim manager message'));

    expect(find.text('Active items'), findsOneWidget);
    expect(find.text('Cancelled items'), findsOneWidget);
    expect(find.text('Verbatim manager message'), findsOneWidget);
    expect(find.textContaining('Refund completed · 10.00 TJS'), findsOneWidget);
    expect(find.text('Original total'), findsOneWidget);
    expect(find.text('Current total'), findsOneWidget);
    expect(find.text('Refunded total'), findsOneWidget);
  });
}
