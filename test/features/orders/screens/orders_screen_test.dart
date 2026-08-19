import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/orders/screens/orders_screen.dart';
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

  Widget harness(Map<String, (int, Object?)> routes) {
    final (dio, _) = fakeDio(routes);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const OrdersScreen()),
        GoRoute(
          path: AppRoutes.order,
          builder: (context, state) => Scaffold(
            body: Text('order-target-${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: FakeSecureStorage()),
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

  testWidgets('ready order shows ready-for-pickup badge and still navigates',
      (tester) async {
    await tester.pumpWidget(
      harness({
        'GET /api/orders': (
          200,
          [
            {
              'id': 'order-1',
              'status': 'ready',
              'totalTjs': '15.00',
              'createdAt': '2026-07-09T00:00:00Z',
              'items': [
                {
                  'id': 'item-1',
                  'productId': 'prod-1',
                  'productName': 'Bag',
                  'qty': 1,
                  'unitPriceTjs': '15.00',
                }
              ],
              'shipment': {'id': 's1', 'stage': 'ready', 'trackingNo': 'TR1'},
            }
          ],
        ),
      }),
    );
    await pumpUntilFound(tester, find.text('Ready for pickup'));

    expect(find.text('Ready for pickup'), findsWidgets);

    await tester.tap(find.textContaining('Order #'));
    await pumpUntilFound(tester, find.text('order-target-order-1'));
    expect(find.text('order-target-order-1'), findsOneWidget);
  });

  testWidgets('non-ready order does not render ready-for-pickup badge',
      (tester) async {
    await tester.pumpWidget(
      harness({
        'GET /api/orders': (
          200,
          [
            {
              'id': 'order-2',
              'status': 'paid',
              'totalTjs': '20.00',
              'createdAt': '2026-07-09T00:00:00Z',
              'items': [
                {
                  'id': 'item-2',
                  'productId': 'prod-2',
                  'productName': 'Cup',
                  'qty': 1,
                  'unitPriceTjs': '20.00',
                }
              ],
              'shipment': {'id': 's2', 'stage': 'paid', 'trackingNo': 'TR2'},
            }
          ],
        ),
      }),
    );
    await pumpUntilFound(tester, find.textContaining('Order #'));

    expect(find.text('Ready for pickup'), findsNothing);
  });

  testWidgets('partial cancellation shows retained total and cancelled count',
      (tester) async {
    await tester.pumpWidget(
      harness({
        'GET /api/orders': (
          200,
          [
            {
              'id': 'order-partial',
              'status': 'paid',
              'totalTjs': '30.00',
              'currentTotalTjs': '20.00',
              'cancelledTotalTjs': '10.00',
              'refundedTotalTjs': '0.00',
              'createdAt': '2026-07-30T00:00:00Z',
              'items': [
                {
                  'id': 'active',
                  'productId': 'p1',
                  'productName': 'Active bag',
                  'qty': 1,
                  'unitPriceTjs': '20.00',
                },
                {
                  'id': 'cancelled',
                  'productId': 'p2',
                  'productName': 'Cancelled cup',
                  'qty': 1,
                  'unitPriceTjs': '10.00',
                  'status': 'cancelled',
                  'cancellation': {
                    'reason': 'out_of_stock',
                    'customerMessage': 'No longer available',
                  },
                },
              ],
            }
          ],
        ),
      }),
    );
    await pumpUntilFound(tester, find.text('1 cancelled item'));

    expect(find.text('1 cancelled item'), findsOneWidget);
    expect(find.textContaining('Original total: 30.00 TJS'), findsOneWidget);
    expect(find.textContaining('Current total: 20.00 TJS'), findsOneWidget);
    expect(find.text('Cancelled cup'), findsNothing);
  });
}
