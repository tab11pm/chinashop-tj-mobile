import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../cart/providers/cart_provider.dart';
import '../../payment_receipts/providers/payment_receipt_provider.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/api/error_messages.dart';

/// ContinuePaymentButton — lets the customer re-enter payment for an order that
/// was placed but never paid (status == 'created').
///
/// The backend already supports an idempotent re-initiate: POST
/// /api/payments/{orderId}/pay returns the same pending payment link while the
/// order is still in 'created' (PAYLINK-05). This button is the missing client
/// entry point — it reuses the exact checkout flow:
///   initiatePayment(orderId) → push(paymentReceipt, retail, orderId)
/// so a payment interrupted by lost connectivity can simply be resumed.
class ContinuePaymentButton extends ConsumerStatefulWidget {
  const ContinuePaymentButton({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ContinuePaymentButton> createState() =>
      _ContinuePaymentButtonState();
}

class _ContinuePaymentButtonState extends ConsumerState<ContinuePaymentButton> {
  bool _isProcessing = false;

  Future<void> _continuePayment() async {
    setState(() => _isProcessing = true);
    try {
      final initiation = await ref
          .read(cartProvider.notifier)
          .initiatePayment(widget.orderId);
      if (!mounted) return;
      // Mock auto-capture: an already-succeeded order has no link to open —
      // just refresh by going to the order detail rather than the receipt flow.
      if (initiation.redirectUrl == null && initiation.status == 'succeeded') {
        context.go(AppRoutes.orderPath(widget.orderId));
        return;
      }
      context.push(
        AppRoutes.paymentReceipt,
        extra: PaymentReceiptArgs(
          initiation: initiation,
          kind: PaymentFlowKind.retail,
          orderId: widget.orderId,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorCodeOf(e))),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isProcessing
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.lock_outline, size: 18),
        label: Text(_isProcessing ? l10n.processing : l10n.continuePayment),
        onPressed: _isProcessing ? null : _continuePayment,
      ),
    );
  }
}
