import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/notifications/providers/notifications_provider.dart';
import '../../../helpers/fake_dio.dart';
import '../../../helpers/fake_secure_storage.dart';

void main() {
  test('lists customer-safe unique notifications and marks one read', () async {
    final (dio, adapter) = fakeDio({
      'GET /api/notifications': (
        200,
        [
          {
            'id': 'notification-1',
            'type': 'order_item_cancelled',
            'orderId': 'order-1',
            'orderItemId': 'item-1',
            'payload': {
              'customerMessage': 'Verbatim manager message',
              'amountTjs': '5.00',
            },
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
    final notifier =
        NotificationsNotifier(
          client: DioClient.withDio(dio, storage: FakeSecureStorage()),
        );

    await notifier.fetchNotifications();
    expect(notifier.state.notifications, hasLength(1));
    expect(
      notifier.state.notifications.single.payload['customerMessage'],
      'Verbatim manager message',
    );
    expect(notifier.state.notifications.single.payload['amountTjs'],
        isA<String>());

    await notifier.markRead('notification-1');
    expect(notifier.state.notifications.single.isRead, isTrue);
    expect(
      adapter.requestCount(
        'PATCH',
        '/api/notifications/notification-1/read',
      ),
      1,
    );
  });
}
