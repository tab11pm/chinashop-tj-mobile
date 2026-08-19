import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/notifications/screens/notifications_screen.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import 'package:pinshop_tj/router/app_router.dart';
import '../../../helpers/fake_dio.dart';
import '../../../helpers/fake_secure_storage.dart';

void main() {
  testWidgets('notification marks read and opens linked order', (tester) async {
    final (dio, adapter) = fakeDio({
      'GET /api/notifications': (
        200,
        [
          {
            'id': 'notification-1',
            'type': 'order_item_cancelled',
            'orderId': 'order-1',
            'orderItemId': 'item-1',
            'payload': {'customerMessage': 'Verbatim manager message'},
            'readAt': null,
            'createdAt': '2026-07-30T00:00:00Z',
          }
        ]
      ),
      'PATCH /api/notifications/notification-1/read': (
        200,
        {'id': 'notification-1', 'read': true}
      ),
    });
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.order,
          builder: (_, state) => Scaffold(
            body: Text('order-${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
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
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order item cancelled'), findsOneWidget);
    expect(find.text('Verbatim manager message'), findsOneWidget);
    await tester.tap(find.text('Order item cancelled'));
    await tester.pumpAndSettle();

    expect(find.text('order-order-1'), findsOneWidget);
    expect(
      adapter.requestCount(
        'PATCH',
        '/api/notifications/notification-1/read',
      ),
      1,
    );
  });
}
