import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/features/wholesale/providers/wholesale_orders_provider.dart';

void main() {
  group('WholesaleOrder receipt review state', () {
    test('needs_review maps to under_review and suppresses pay CTA', () {
      final order = WholesaleOrder.fromJson({
        'id': 'order-1',
        'factoryName': 'Factory',
        'status': 'created',
        'totalTjs': '100.00',
        'createdAt': '2026-06-21T10:00:00.000Z',
        'paymentGroupId': 'group-1',
        'latestReceiptStatus': 'needs_review',
        'items': <Object>[],
      });

      expect(order.latestReceiptStatus, 'needs_review');
      expect(order.receiptReviewStatus, 'under_review');
      expect(order.hasReceiptInFlight, isTrue);
      expect(order.hasRejectedReceipt, isFalse);
      expect(order.receiptRejectionReason, isNull);
    });

    test('rejected preserves admin reason and allows re-upload CTA', () {
      final order = WholesaleOrder.fromJson({
        'id': 'order-1',
        'factoryName': 'Factory',
        'status': 'created',
        'totalTjs': '100.00',
        'createdAt': '2026-06-21T10:00:00.000Z',
        'paymentGroupId': 'group-1',
        'latestReceiptStatus': 'rejected',
        'receiptReviewStatus': 'rejected',
        'receiptRejectionReason': 'Amount does not match',
        'items': <Object>[],
      });

      expect(order.latestReceiptStatus, 'rejected');
      expect(order.receiptReviewStatus, 'rejected');
      expect(order.hasReceiptInFlight, isFalse);
      expect(order.hasRejectedReceipt, isTrue);
      expect(order.receiptRejectionReason, 'Amount does not match');
    });
  });
}
