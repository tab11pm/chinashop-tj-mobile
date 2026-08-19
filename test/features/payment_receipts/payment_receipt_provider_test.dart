import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/payment_receipts/providers/payment_receipt_provider.dart';

import '../../helpers/fake_dio.dart';

/// Tests for Phase 18 Plan 04 additions:
///   - ReceiptUploadState stores rejection reason and reasonAt when status == rejected
///   - Poll transitions check → rejected and stores reason from status endpoint
///   - Reupload (reset + upload) from rejected state reuses the same paymentId
///     and does NOT initiate a new payment
///   - reason is null when status is not rejected (approvedByAi, needsReview, etc.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  ProviderContainer makeContainer(
    Map<String, (int, Object?)> routes,
  ) {
    final (dio, _) = fakeDio(routes);
    final c = ProviderContainer(overrides: [
      dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
    ]);
    addTearDown(c.dispose);
    // Keep autoDispose provider alive (Phase 16-03 gotcha).
    c.listen(paymentReceiptProvider, (_, __) {}, fireImmediately: true);
    return c;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADMREC-04: ReceiptUploadState stores reason/reasonAt from status endpoint
  // ─────────────────────────────────────────────────────────────────────────

  test(
    'ADMREC-04: ReceiptUploadState has reason and reasonAt fields (null by default)',
    () {
      const state = ReceiptUploadState();
      expect(state.reason, isNull);
      expect(state.reasonAt, isNull);
    },
  );

  test(
    'ADMREC-04: copyWith preserves reason and reasonAt',
    () {
      const initial = ReceiptUploadState(
        status: ReceiptFlowStatus.rejected,
        reason: 'Amount mismatch',
        reasonAt: null,
      );
      final next = initial.copyWith(status: ReceiptFlowStatus.rejected);
      // copyWith without explicit reason/reasonAt preserves existing values
      expect(next.reason, 'Amount mismatch');
    },
  );

  test(
    'ADMREC-04: poll to rejected status stores reason from backend response',
    () async {
      final (dio, adapter) = fakeDio({
        'POST /api/payments/pay3/receipts': (
          201,
          {'id': 'rec3', 'paymentId': 'pay3', 'status': 'checking'},
        ),
        'GET /api/payments/pay3/receipts/rec3/status': (
          200,
          {
            'receiptId': 'rec3',
            'paymentId': 'pay3',
            'status': 'rejected',
            'reason': 'Screenshot amount does not match',
            'reasonAt': '2026-06-18T12:00:00.000Z',
            'rejectionCategory': 'not_receipt',
            'blockedUntil': '2026-06-18T18:00:00.000Z',
          },
        ),
      });
      final c = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
      ]);
      addTearDown(c.dispose);
      c.listen(paymentReceiptProvider, (_, __) {}, fireImmediately: true);

      final tmp = File('${Directory.systemTemp.path}/receipt_rejected.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

      await c.read(paymentReceiptProvider.notifier).uploadReceipt(
            paymentId: 'pay3',
            filePath: tmp.path,
          );

      expect(c.read(paymentReceiptProvider).status, ReceiptFlowStatus.checking);

      // Wait for first poll to fire.
      await Future.delayed(const Duration(seconds: 4));

      final state = c.read(paymentReceiptProvider);
      expect(state.status, ReceiptFlowStatus.rejected);
      // reason must be stored so the UI can display it.
      expect(state.reason, 'Screenshot amount does not match');
      expect(state.reasonAt, isNotNull);
      expect(state.rejectionCategory, 'not_receipt');
      expect(state.blockedUntil, isNotNull);

      // Verify the GET /status was called.
      expect(
        adapter.captured
            .any((r) => r.method == 'GET' && r.path.contains('/status')),
        isTrue,
      );
    },
  );

  test(
    'ADMREC-04: reason is null when poll returns approvedByAi (no rejection)',
    () async {
      final c = makeContainer({
        'POST /api/payments/pay4/receipts': (
          201,
          {'id': 'rec4', 'paymentId': 'pay4', 'status': 'checking'},
        ),
        'GET /api/payments/pay4/receipts/rec4/status': (
          200,
          {
            'receiptId': 'rec4',
            'paymentId': 'pay4',
            'status': 'approved_by_ai',
            'reason': null,
            'reasonAt': null,
          },
        ),
      });

      final tmp = File('${Directory.systemTemp.path}/receipt_approved.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

      await c.read(paymentReceiptProvider.notifier).uploadReceipt(
            paymentId: 'pay4',
            filePath: tmp.path,
          );

      await Future.delayed(const Duration(seconds: 4));

      final state = c.read(paymentReceiptProvider);
      expect(state.status, ReceiptFlowStatus.approvedByAi);
      expect(state.reason, isNull);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // WR-01: backend `duplicate` status is terminal (maps to rejected, stops poll)
  // ─────────────────────────────────────────────────────────────────────────

  test(
    'WR-01: poll returning backend status=duplicate transitions to rejected (terminal, polling stops)',
    () async {
      final c = makeContainer({
        'POST /api/payments/pay-dup/receipts': (
          201,
          {'id': 'rec-dup', 'paymentId': 'pay-dup', 'status': 'checking'},
        ),
        'GET /api/payments/pay-dup/receipts/rec-dup/status': (
          200,
          {
            'receiptId': 'rec-dup',
            'paymentId': 'pay-dup',
            'status': 'duplicate',
          },
        ),
      });

      final tmp = File('${Directory.systemTemp.path}/receipt_duplicate.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

      await c.read(paymentReceiptProvider.notifier).uploadReceipt(
            paymentId: 'pay-dup',
            filePath: tmp.path,
          );

      // Wait for first poll to fire.
      await Future.delayed(const Duration(seconds: 4));

      // `duplicate` must be terminal — it maps to rejected, so polling stops
      // instead of running until the 5-minute timeout and mislabelling it.
      final state = c.read(paymentReceiptProvider);
      expect(state.status, ReceiptFlowStatus.rejected);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // ADMREC-04: reupload from rejected state reuses same paymentId
  // ─────────────────────────────────────────────────────────────────────────

  test(
    'ADMREC-04: reset() from rejected clears reason and transitions to awaitingReceipt',
    () {
      final c = makeContainer({});
      final notifier = c.read(paymentReceiptProvider.notifier);

      // Simulate landing in rejected state with a reason.
      notifier.setRejected(
          reason: 'Blurry image',
          reasonAt: DateTime.parse('2026-06-18T12:00:00Z'));

      final rejectedState = c.read(paymentReceiptProvider);
      expect(rejectedState.status, ReceiptFlowStatus.rejected);
      expect(rejectedState.reason, 'Blurry image');

      // reset() must clear the reason and return to awaitingReceipt.
      notifier.reset();

      final resetState = c.read(paymentReceiptProvider);
      expect(resetState.status, ReceiptFlowStatus.awaitingReceipt);
      expect(resetState.reason, isNull);
      expect(resetState.reasonAt, isNull);
    },
  );

  test(
    'ADMREC-04: upload after reset reuses the same paymentId (no new payment initiation)',
    () async {
      const samePaymentId = 'pay-rejected-reupload';
      late FakeAdapter adapter;
      final (dio, captured) = fakeDio({
        'POST /api/payments/$samePaymentId/receipts': (
          201,
          {'id': 'rec-reup1', 'paymentId': samePaymentId, 'status': 'checking'},
        ),
      });
      adapter = captured;

      final c = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
      ]);
      addTearDown(c.dispose);
      c.listen(paymentReceiptProvider, (_, __) {}, fireImmediately: true);

      final notifier = c.read(paymentReceiptProvider.notifier);

      // Simulate being in rejected state.
      notifier.setRejected(reason: 'Wrong amount', reasonAt: null);
      notifier.reset();

      final tmp = File('${Directory.systemTemp.path}/receipt_reupload.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

      // Upload a replacement using the SAME paymentId.
      final result = await notifier.uploadReceipt(
        paymentId: samePaymentId,
        filePath: tmp.path,
      );

      expect(result, isNotNull);
      expect(result!.paymentId, samePaymentId);
      expect(c.read(paymentReceiptProvider).status, ReceiptFlowStatus.checking);

      // Assert the upload POST went to the SAME payment endpoint.
      final req =
          adapter.requestTo('POST', '/api/payments/$samePaymentId/receipts');
      expect(req.data, isA<FormData>());
    },
  );
}
