import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/wholesale_cart_provider.dart';
import '../providers/wholesale_orders_provider.dart';
import '../../payment_receipts/providers/payment_receipt_provider.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/api/error_messages.dart';
import '../../../theme/app_tokens.dart';

/// WholesaleContinuePaymentButton — resume payment for a wholesale order that was
/// placed but never paid (status == 'created').
///
/// B2B payment is group-scoped: a checkout creates one PaymentGroup linking all
/// per-factory orders (D-03), and PaymentsService.initiateGroup permits an
/// idempotent re-initiate while every order in the group is still 'created'
/// (returns the same pending link). This button is the missing client entry
/// point — it reuses the wholesale checkout flow:
///   pay(groupId) → push(paymentReceipt, wholesale)
/// so a payment interrupted by lost connectivity can simply be resumed.
class WholesaleContinuePaymentButton extends ConsumerStatefulWidget {
  const WholesaleContinuePaymentButton({super.key, required this.groupId});

  /// The PaymentGroup id the order belongs to (WholesaleOrder.paymentGroupId).
  final String groupId;

  @override
  ConsumerState<WholesaleContinuePaymentButton> createState() =>
      _WholesaleContinuePaymentButtonState();
}

class _WholesaleContinuePaymentButtonState
    extends ConsumerState<WholesaleContinuePaymentButton> {
  bool _isProcessing = false;

  Future<void> _continuePayment() async {
    setState(() => _isProcessing = true);
    try {
      final initiation =
          await ref.read(wholesaleCartProvider.notifier).pay(widget.groupId);
      if (!mounted) return;
      // Mock auto-capture: an already-succeeded group has no link to open —
      // refresh the orders list rather than entering the receipt flow.
      if (initiation.redirectUrl == null && initiation.status == 'succeeded') {
        ref.invalidate(wholesaleOrdersProvider);
        context.go(AppRoutes.wholesaleOrders);
        return;
      }
      context.push(
        AppRoutes.paymentReceipt,
        extra: PaymentReceiptArgs(
          initiation: initiation,
          kind: PaymentFlowKind.wholesale,
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
                    strokeWidth: 2, color: AppColors.onAccent),
              )
            : const Icon(Icons.lock_outline, size: 18),
        label: Text(_isProcessing ? l10n.processing : l10n.continuePayment),
        onPressed: _isProcessing ? null : _continuePayment,
      ),
    );
  }
}

/// ReceiptUnderReviewPill — shown in place of the "continue payment" CTA once a
/// receipt has been uploaded and is being verified (checking/needs_review/approved).
///
/// The wholesale order stays `created` until the payment confirms, so the screens
/// use the latest receipt status (WholesaleOrder.hasReceiptInFlight) — not order
/// status — to swap the pay button for this non-interactive status indicator.
class ReceiptUnderReviewPill extends StatelessWidget {
  const ReceiptUnderReviewPill({super.key, required this.label});

  /// Localized status text (e.g. l10n.receiptCheckingTitle — "Проверяем чек…").
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentDeep,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.accentDeep,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// ReceiptRejectedPanel — shown for B2B orders after an operator rejects the
/// receipt. It surfaces the operator note and keeps the re-upload action nearby.
class ReceiptRejectedPanel extends StatelessWidget {
  const ReceiptRejectedPanel({
    super.key,
    required this.title,
    required this.body,
    required this.reasonLabel,
    required this.action,
    this.reason,
  });

  final String title;
  final String body;
  final String reasonLabel;
  final String? reason;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedReason = reason?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline,
                  size: 18, color: AppColors.danger),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
            ),
          ),
          if (normalizedReason != null && normalizedReason.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              '$reasonLabel $normalizedReason',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          action,
        ],
      ),
    );
  }
}
