import 'dart:async';
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/error_messages.dart';
import '../../auth/providers/auth_provider.dart'; // dioClientProvider

// ---------------------------------------------------------------------------
// Data models — money as strings; never parse to float (D-07 / CR-05).
// ---------------------------------------------------------------------------

/// PaymentInitiation — the result of POST /api/payments/:orderId/pay or
/// POST /api/wholesale/payment-groups/:groupId/pay.
///
/// Backend contract (payments.service.ts initiate/initiateGroup):
///   { paymentId, externalId, redirectUrl?, status, amountTjs }
///
/// `redirectUrl` is the pay.dc.tj link the user opens externally. It is ABSENT
/// when the mock provider auto-captured (status='succeeded'); the UI must NOT
/// assume opening the link means the payment is confirmed — the uploaded receipt
/// is the next, explicit step.
class PaymentInitiation {
  final String paymentId;
  final String? externalId;
  final String? redirectUrl;
  final String status; // 'pending' | 'succeeded'
  final String amountTjs; // MoneyString — never parse to float

  const PaymentInitiation({
    required this.paymentId,
    this.externalId,
    this.redirectUrl,
    required this.status,
    required this.amountTjs,
  });

  /// True when the provider returned a redirect link to open (dc_link path).
  bool get hasRedirect => redirectUrl != null && redirectUrl!.trim().isNotEmpty;

  factory PaymentInitiation.fromJson(Map<String, dynamic> json) {
    return PaymentInitiation(
      paymentId: json['paymentId']?.toString() ?? '',
      externalId: json['externalId']?.toString(),
      redirectUrl: json['redirectUrl']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      amountTjs: json['amountTjs']?.toString() ?? '0.00',
    );
  }
}

/// ReceiptUploadResult — the result of POST /api/payments/:paymentId/receipts.
///
/// Backend contract (payment-receipts.service.ts uploadReceipt):
///   { id, paymentId, status, createdAt }
/// where `status` is now 'checking' (Phase 17: flipped from awaiting_ai on upload).
class ReceiptUploadResult {
  final String receiptId;
  final String paymentId;
  final String
      status; // 'checking' | 'approved_by_ai' | 'needs_review' | 'rejected' | ...

  const ReceiptUploadResult({
    required this.receiptId,
    required this.paymentId,
    required this.status,
  });

  factory ReceiptUploadResult.fromJson(Map<String, dynamic> json) {
    return ReceiptUploadResult(
      // Backend serializes the row id as `id`, not `receiptId`.
      receiptId: (json['receiptId'] ?? json['id'])?.toString() ?? '',
      paymentId: json['paymentId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'checking',
    );
  }
}

/// Which checkout flow opened the receipt screen — decides where "Done" goes.
enum PaymentFlowKind { retail, wholesale }

/// Typed payload passed via GoRouter `extra` to the receipt-flow screen.
///
/// Carries ONLY the backend-provided [PaymentInitiation] plus a flow kind and an
/// optional retail orderId for post-upload navigation. No phone/token is placed
/// in the route (threat_model: "Mobile route leaks sensitive data").
class PaymentReceiptArgs {
  final PaymentInitiation initiation;
  final PaymentFlowKind kind;
  final String? orderId; // retail: navigate to this order after Done

  const PaymentReceiptArgs({
    required this.initiation,
    required this.kind,
    this.orderId,
  });
}

// ---------------------------------------------------------------------------
// Receipt upload flow status — drives the visible UI states.
// ---------------------------------------------------------------------------

/// Phase 17 Plan 04 (D-04): extended with AI-verification states.
///
/// State machine:
///   awaitingReceipt → uploading → checking → approvedByAi | needsReview | rejected
///                              ↘ error (upload failure)
///
/// `approvedManually` is mapped from backend `approved_manually` onto `approvedByAi`
/// for display purposes (both represent "payment confirmed").
enum ReceiptFlowStatus {
  awaitingReceipt, // link can be opened; no receipt selected yet
  uploading, // multipart upload in progress
  checking, // Phase 17: receipt uploaded, AI verification in progress
  approvedByAi, // Phase 17: AI (or manual admin) confirmed the payment
  needsReview, // Phase 17: AI inconclusive → manual review queued
  rejected, // Phase 17: receipt rejected; offer re-upload
  error, // upload rejected (DUPLICATE_RECEIPT, RECEIPT_FILE_INVALID, ...)
}

/// Maps a backend receipt status string to [ReceiptFlowStatus].
///
/// Terminal states: approvedByAi, rejected (polling stops). `needs_review`
/// stays pollable so a manual reject/approve can still reach the screen.
/// Non-terminal: checking (continue polling).
ReceiptFlowStatus _mapBackendStatus(String backendStatus) {
  switch (backendStatus) {
    case 'approved_by_ai':
    case 'approved_manually': // admin override → show same confirmed UI
      return ReceiptFlowStatus.approvedByAi;
    case 'needs_review':
      return ReceiptFlowStatus.needsReview;
    case 'rejected':
      return ReceiptFlowStatus.rejected;
    // WR-01: a backend `duplicate` receipt is terminal — map it to `rejected` so
    // polling stops. Without this case it fell through to `checking` and the client
    // polled for the full timeout, then mislabelled the duplicate as needsReview.
    case 'duplicate':
      return ReceiptFlowStatus.rejected;
    case 'checking':
    default:
      return ReceiptFlowStatus.checking;
  }
}

/// Whether [status] is a terminal state (polling should stop).
bool _isTerminal(ReceiptFlowStatus status) {
  return status == ReceiptFlowStatus.approvedByAi ||
      status == ReceiptFlowStatus.rejected;
}

class ReceiptUploadState {
  final ReceiptFlowStatus status;
  final String? errorCode;
  final ReceiptUploadResult? result;

  /// Admin rejection reason — populated from the status endpoint when status == rejected
  /// (ADMREC-04 / Phase 18 Plan 04). Null when the receipt is in any other state.
  final String? reason;

  /// ISO-8601 timestamp of the rejection action — null when no rejection exists.
  final DateTime? reasonAt;

  /// Stable client-safe AI rejection category (for example `not_receipt`).
  final String? rejectionCategory;

  /// Receipt-only temporary block returned by the owner-scoped status endpoint.
  final DateTime? blockedUntil;

  const ReceiptUploadState({
    this.status = ReceiptFlowStatus.awaitingReceipt,
    this.errorCode,
    this.result,
    this.reason,
    this.reasonAt,
    this.rejectionCategory,
    this.blockedUntil,
  });

  ReceiptUploadState copyWith({
    ReceiptFlowStatus? status,
    String? errorCode,
    ReceiptUploadResult? result,
    // Pass Object() sentinel to explicitly preserve the existing value.
    // Use _keep for "keep current value" semantics in nullable fields.
    Object? reason = _ReceiptStateKeep.instance,
    Object? reasonAt = _ReceiptStateKeep.instance,
    Object? rejectionCategory = _ReceiptStateKeep.instance,
    Object? blockedUntil = _ReceiptStateKeep.instance,
  }) {
    return ReceiptUploadState(
      status: status ?? this.status,
      errorCode: errorCode,
      result: result ?? this.result,
      reason: identical(reason, _ReceiptStateKeep.instance)
          ? this.reason
          : reason as String?,
      reasonAt: identical(reasonAt, _ReceiptStateKeep.instance)
          ? this.reasonAt
          : reasonAt as DateTime?,
      rejectionCategory:
          identical(rejectionCategory, _ReceiptStateKeep.instance)
              ? this.rejectionCategory
              : rejectionCategory as String?,
      blockedUntil: identical(blockedUntil, _ReceiptStateKeep.instance)
          ? this.blockedUntil
          : blockedUntil as DateTime?,
    );
  }
}

/// Sentinel used in copyWith to distinguish "keep current value" from "set to null".
class _ReceiptStateKeep {
  const _ReceiptStateKeep._();
  static const instance = _ReceiptStateKeep._();
}

// ---------------------------------------------------------------------------
// Notifier — uploads a selected receipt file as multipart field `file`,
// then polls the status endpoint after upload (Phase 17 Plan 04 / D-04).
// ---------------------------------------------------------------------------

/// How often to poll the status endpoint after upload.
const _pollInterval = Duration(seconds: 3);

/// Maximum total polling time before surfacing a "still checking" CTA.
const _pollTimeout = Duration(minutes: 5);

class PaymentReceiptNotifier extends StateNotifier<ReceiptUploadState> {
  final DioClient _client;
  Timer? _pollTimer;

  PaymentReceiptNotifier({required DioClient client})
      : _client = client,
        super(const ReceiptUploadState());

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// POST /api/payments/{paymentId}/receipts — multipart/form-data, field `file`.
  ///
  /// On success (Phase 17): status is `checking`; starts polling
  /// GET /api/payments/{paymentId}/receipts/{receiptId}/status every 3 s
  /// until a terminal state is reached or the 5-minute cap expires.
  ///
  /// [filePath] is a local image path from image_picker; [fileName] is used for
  /// the multipart filename (the backend stores under a generated safe key and
  /// never trusts the client filename, but Dio needs a name for the part header).
  Future<ReceiptUploadResult?> uploadReceipt({
    required String paymentId,
    required String filePath,
    String fileName = 'receipt.jpg',
  }) async {
    state = state.copyWith(
      status: ReceiptFlowStatus.uploading,
      errorCode: null,
    );
    try {
      final formData = FormData.fromMap({
        // Field name MUST be `file` — FileInterceptor('file') on the backend.
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final res = await _client.post(
        '/api/payments/$paymentId/receipts',
        data: formData,
      );
      final result = ReceiptUploadResult.fromJson(
        res.data as Map<String, dynamic>,
      );

      // Phase 17: upload returns `checking`; start polling.
      state = state.copyWith(
        status: ReceiptFlowStatus.checking,
        result: result,
      );
      _startPolling(paymentId: paymentId, receiptId: result.receiptId);
      return result;
    } on DioException catch (e) {
      // DUPLICATE_RECEIPT / RECEIPT_FILE_INVALID / PAYMENT_NOT_PENDING /
      // RECEIPT_NOT_FOUND — surfaced as a localizable code.
      state = state.copyWith(
        status: ReceiptFlowStatus.error,
        errorCode: errorCodeOf(e),
      );
      return null;
    }
  }

  /// Start periodic polling of the status endpoint.
  ///
  /// Stops when a terminal state is reached or [_pollTimeout] elapses.
  /// On timeout surfaces [ReceiptFlowStatus.needsReview] with a "still checking"
  /// error code so the UI can show the manual-review CTA.
  void _startPolling({required String paymentId, required String receiptId}) {
    _pollTimer?.cancel();
    final deadline = DateTime.now().add(_pollTimeout);

    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (DateTime.now().isAfter(deadline)) {
        timer.cancel();
        // Timeout: receipt is still being checked; surface manual-review CTA.
        if (mounted) {
          state = state.copyWith(status: ReceiptFlowStatus.needsReview);
        }
        return;
      }

      try {
        final res = await _client.get(
          '/api/payments/$paymentId/receipts/$receiptId/status',
        );
        if (!mounted) {
          timer.cancel();
          return;
        }
        final body = res.data as Map<String, dynamic>;
        final backendStatus = body['status']?.toString() ?? 'checking';
        final newStatus = _mapBackendStatus(backendStatus);

        // ADMREC-04: store admin rejection reason when backend returns one.
        String? reason;
        DateTime? reasonAt;
        String? rejectionCategory;
        DateTime? blockedUntil;
        if (newStatus == ReceiptFlowStatus.rejected) {
          reason = body['reason']?.toString();
          final rawAt = body['reasonAt']?.toString();
          reasonAt = rawAt != null ? DateTime.tryParse(rawAt) : null;
          rejectionCategory = body['rejectionCategory']?.toString();
          final rawBlockedUntil = body['blockedUntil']?.toString();
          blockedUntil = rawBlockedUntil != null
              ? DateTime.tryParse(rawBlockedUntil)
              : null;
        }

        state = state.copyWith(
          status: newStatus,
          reason: reason,
          reasonAt: reasonAt,
          rejectionCategory: rejectionCategory,
          blockedUntil: blockedUntil,
        );

        if (_isTerminal(newStatus)) {
          timer.cancel();
        }
      } on DioException catch (e) {
        // RECEIPT_NOT_FOUND (404): receipt was deleted or IDOR — stop polling.
        if (e.response?.statusCode == 404) {
          timer.cancel();
          if (mounted) {
            state = state.copyWith(
              status: ReceiptFlowStatus.error,
              errorCode: errorCodeOf(e),
            );
          }
        }
        // Other errors (network): keep polling until timeout.
      }
    });
  }

  /// Reset back to awaiting-receipt so the user can re-pick after an error or rejection.
  ///
  /// Clears reason/reasonAt so the previous rejection note is not shown while the
  /// replacement receipt is being selected/uploaded (ADMREC-04).
  void reset() {
    _pollTimer?.cancel();
    state = const ReceiptUploadState();
  }

  /// Set the rejected state with an explicit admin reason — used in tests and when
  /// the screen navigates back to a payment that was already rejected (ADMREC-04).
  void setRejected({String? reason, DateTime? reasonAt}) {
    _pollTimer?.cancel();
    state = ReceiptUploadState(
      status: ReceiptFlowStatus.rejected,
      reason: reason,
      reasonAt: reasonAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider — autoDispose so each receipt flow screen gets a fresh notifier.
// ---------------------------------------------------------------------------

final paymentReceiptProvider = StateNotifierProvider.autoDispose<
    PaymentReceiptNotifier, ReceiptUploadState>((ref) {
  final client = ref.watch(dioClientProvider);
  return PaymentReceiptNotifier(client: client);
});
