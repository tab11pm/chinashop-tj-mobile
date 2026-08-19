import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/cart/providers/cart_provider.dart';
import 'package:pinshop_tj/features/wholesale/providers/wholesale_cart_provider.dart';
import 'package:pinshop_tj/features/payment_receipts/providers/payment_receipt_provider.dart';

import 'helpers/fake_dio.dart';

/// Tests for the payment-receipt provider — verify the upload request is
/// multipart with field `file` (threat_model: "Upload wrong field or non-file"),
/// that PaymentInitiation parses the backend contract, and that an upload error
/// surfaces a code without faking success.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  ProviderContainer makeContainer(
    Map<String, (int, Object?)> routes,
    void Function(FakeAdapter) capture,
  ) {
    final (dio, adapter) = fakeDio(routes);
    capture(adapter);
    final c = ProviderContainer(overrides: [
      dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
    ]);
    addTearDown(c.dispose);
    // Keep the autoDispose provider alive for the duration of the test so the
    // notifier is not disposed between read(notifier) and read(provider).
    c.listen(paymentReceiptProvider, (_, __) {}, fireImmediately: true);
    return c;
  }

  test('PaymentInitiation.fromJson parses paymentId/redirectUrl/status/amount', () {
    final init = PaymentInitiation.fromJson({
      'paymentId': 'pay1',
      'externalId': 'dc-link-pay-o1',
      'redirectUrl': 'http://pay.dc.tj/?a=992900000000&s=20.00&c=&f1=124&f2=&f3=',
      'status': 'pending',
      'amountTjs': '20.00',
    });
    expect(init.paymentId, 'pay1');
    expect(init.hasRedirect, isTrue);
    expect(init.status, 'pending');
    expect(init.amountTjs, '20.00'); // money kept as string
  });

  test('PaymentInitiation.hasRedirect is false when redirectUrl absent (mock auto-capture)', () {
    final init = PaymentInitiation.fromJson({
      'paymentId': 'pay1',
      'status': 'succeeded',
      'amountTjs': '20.00',
    });
    expect(init.hasRedirect, isFalse);
  });

  test('uploadReceipt sends multipart with field `file` and parses awaiting_ai',
      () async {
    late FakeAdapter adapter;
    final c = makeContainer({
      'POST /api/payments/pay1/receipts': (
        201,
        {'id': 'rec1', 'paymentId': 'pay1', 'status': 'awaiting_ai'},
      ),
    }, (a) => adapter = a);

    // Write a temp file to upload (image_picker yields a real file path).
    final tmp = File('${Directory.systemTemp.path}/receipt_test.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

    final result = await c.read(paymentReceiptProvider.notifier).uploadReceipt(
          paymentId: 'pay1',
          filePath: tmp.path,
        );

    expect(result, isNotNull);
    expect(result!.status, 'awaiting_ai');
    expect(result.receiptId, 'rec1');

    // The outgoing body is a multipart FormData with a single field named `file`.
    final req = adapter.requestTo('POST', '/api/payments/pay1/receipts');
    expect(req.data, isA<FormData>());
    final form = req.data as FormData;
    expect(form.files.map((e) => e.key), contains('file'));

    // Phase 17: state advances to `checking` after upload (not awaitingReview).
    // The poll starts in background; we only verify the immediate post-upload state.
    expect(c.read(paymentReceiptProvider).status,
        ReceiptFlowStatus.checking);
  });

  test('uploadReceipt surfaces DUPLICATE_RECEIPT without faking success',
      () async {
    final c = makeContainer({
      'POST /api/payments/pay1/receipts': (
        409,
        {'error': 'duplicate', 'code': 'DUPLICATE_RECEIPT'},
      ),
    }, (_) {});

    final tmp = File('${Directory.systemTemp.path}/receipt_dup.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

    final result = await c.read(paymentReceiptProvider.notifier).uploadReceipt(
          paymentId: 'pay1',
          filePath: tmp.path,
        );

    expect(result, isNull);
    final state = c.read(paymentReceiptProvider);
    expect(state.status, ReceiptFlowStatus.error);
    expect(state.errorCode, 'DUPLICATE_RECEIPT');
  });

  test('retail initiatePayment returns PaymentInitiation with redirectUrl (drives receipt flow)',
      () async {
    final c = makeContainer({
      'POST /api/payments/o1/pay': (
        201,
        {
          'paymentId': 'pay1',
          'externalId': 'dc-link-pay-o1',
          'redirectUrl': 'http://pay.dc.tj/?a=992&s=20.00&c=&f1=124&f2=&f3=',
          'status': 'pending',
          'amountTjs': '20.00',
        },
      ),
    }, (_) {});

    final init = await c.read(cartProvider.notifier).initiatePayment('o1');
    expect(init.paymentId, 'pay1');
    expect(init.hasRedirect, isTrue); // checkout screen can open the link
    expect(init.amountTjs, '20.00');
  });

  test('wholesale pay returns PaymentInitiation (drives receipt flow)', () async {
    final c = makeContainer({
      'POST /api/wholesale/payment-groups/g1/pay': (
        201,
        {
          'paymentId': 'pg-pay1',
          'redirectUrl': 'http://pay.dc.tj/?a=992&s=99.00&c=&f1=124&f2=&f3=',
          'status': 'pending',
          'amountTjs': '99.00',
        },
      ),
    }, (_) {});

    final init = await c.read(wholesaleCartProvider.notifier).pay('g1');
    expect(init.paymentId, 'pg-pay1');
    expect(init.hasRedirect, isTrue);
    expect(init.amountTjs, '99.00');
  });

  // Phase 17 Plan 04 (D-04): poll mapping — checking → approved_by_ai
  test(
      'poll transitions: checking → approvedByAi on approved_by_ai status response',
      () async {
    // Arrange: upload returns checking; status endpoint returns approved_by_ai
    // on first poll. We use a two-route fake that models the sequence.
    final (dio, adapter) = fakeDio({
      'POST /api/payments/pay2/receipts': (
        201,
        {'id': 'rec2', 'paymentId': 'pay2', 'status': 'checking'},
      ),
      'GET /api/payments/pay2/receipts/rec2/status': (
        200,
        {'receiptId': 'rec2', 'paymentId': 'pay2', 'status': 'approved_by_ai'},
      ),
    });
    final c = ProviderContainer(overrides: [
      dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
    ]);
    addTearDown(c.dispose);
    // Keep autoDispose provider alive (Phase 16-03 gotcha).
    c.listen(paymentReceiptProvider, (_, __) {}, fireImmediately: true);

    final tmp = File('${Directory.systemTemp.path}/receipt_poll.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

    // Act: upload — should set state to checking and start polling
    await c.read(paymentReceiptProvider.notifier).uploadReceipt(
          paymentId: 'pay2',
          filePath: tmp.path,
        );

    // Immediately after upload the state must be `checking`.
    expect(c.read(paymentReceiptProvider).status, ReceiptFlowStatus.checking);

    // Wait for first poll (interval 3s + some slack) — use fake async or
    // pump the timer. Since FakeAdapter is synchronous, we advance via
    // Future.delayed to let the Timer.periodic fire.
    await Future.delayed(const Duration(seconds: 4));

    // The poll should have fired and updated state to approvedByAi.
    expect(c.read(paymentReceiptProvider).status,
        ReceiptFlowStatus.approvedByAi);

    // Verify the GET /status was called.
    expect(
      adapter.captured.any((r) =>
          r.method == 'GET' &&
          r.path.contains('/status')),
      isTrue,
    );
  });
}
