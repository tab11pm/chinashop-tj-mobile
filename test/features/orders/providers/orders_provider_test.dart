import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/features/orders/providers/orders_provider.dart';

void main() {
  test('parses partial cancellation and keeps every money value as String', () {
    final order = Order.fromJson({
      'id': 'order-1',
      'status': 'paid',
      'totalTjs': '30.00',
      'currentTotalTjs': '20.00',
      'cancelledTotalTjs': '10.00',
      'refundedTotalTjs': '0.00',
      'createdAt': '2026-07-30T00:00:00Z',
      'items': [
        {
          'id': 'item-active',
          'productId': 'product-1',
          'productName': 'Active item',
          'qty': 1,
          'unitPriceTjs': '20.00',
          'status': 'active',
        },
        {
          'id': 'item-cancelled',
          'productId': 'product-2',
          'productName': 'Cancelled item',
          'qty': 1,
          'unitPriceTjs': '10.00',
          'status': 'cancelled',
          'cancellation': {
            'reason': 'out_of_stock',
            'customerMessage': 'Verbatim manager message',
            'cancelledAt': '2026-07-30T01:00:00Z',
            'refund': {
              'id': 'refund-1',
              'amountTjs': '10.00',
              'currency': 'TJS',
              'status': 'pending',
              'attemptCount': 1,
            },
          },
        },
      ],
    });

    expect(order.totalTjs, isA<String>());
    expect(order.currentTotalTjs, '20.00');
    expect(order.cancelledTotalTjs, '10.00');
    expect(order.refundedTotalTjs, isA<String>());
    expect(order.items, hasLength(2));
    expect(order.items.last.cancellation!.customerMessage,
        'Verbatim manager message');
    expect(order.items.last.cancellation!.refund!.amountTjs, isA<String>());
    expect(order.items.last.cancellation!.refund!.status, 'pending');
  });

  for (final status in ['pending', 'failed', 'manual_required', 'succeeded']) {
    test('parses $status refund without dropping sibling lines', () {
      final order = Order.fromJson({
        'id': 'order-$status',
        'status': status == 'succeeded' ? 'paid' : 'paid',
        'totalTjs': '12.00',
        'createdAt': '',
        'items': [
          {
            'id': 'active',
            'productId': 'p1',
            'productName': 'Active',
            'qty': 1,
            'unitPriceTjs': '7.00',
          },
          {
            'id': 'cancelled',
            'productId': 'p2',
            'productName': 'Cancelled',
            'qty': 1,
            'unitPriceTjs': '5.00',
            'status': 'cancelled',
            'cancellation': {
              'reason': 'other',
              'customerMessage': 'Cancelled by manager',
              'refund': {
                'id': 'refund',
                'amountTjs': '5.00',
                'currency': 'TJS',
                'status': status,
                'attemptCount': 1,
              },
            },
          },
        ],
      });
      expect(order.items, hasLength(2));
      expect(order.items.last.cancellation!.refund!.status, status);
    });
  }
}
