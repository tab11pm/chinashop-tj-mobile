import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/api/error_messages.dart';
import '../../../theme/app_tokens.dart';
import '../../payment_receipts/providers/payment_receipt_provider.dart';

/// CheckoutScreen — confirm a retail pickup order, then initiate payment.
///
/// APP-03 + SPEC.md Flow 1:
///   POST /api/orders {} → orderId; staff assigns pickup afterwards.
///   POST /api/payments/{orderId}/pay → payment initiated
///   On success: navigate to /order/{orderId}
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessing = false;
  String? _error;

  Future<void> _placeOrderAndPay() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Flush pending qty debounce BEFORE checkout so the server cart is
      // authoritative at order creation (D-03: qty must be up to date).
      await ref.read(cartProvider.notifier).flushPending();

      // Step 1: POST /api/orders {}; staff assigns pickup after checkout.
      final orderId = await ref.read(cartProvider.notifier).checkout();

      // Step 2: POST /api/payments/{orderId}/pay → PaymentInitiation
      final initiation =
          await ref.read(cartProvider.notifier).initiatePayment(orderId);

      // Step 3: go to the payment-link + receipt flow. We DO NOT navigate
      // straight to order tracking — opening the link is not confirmation; the
      // receipt upload is the explicit next step (PAYLINK-03). The order screen
      // is reached from there only after a successful upload (Done).
      if (mounted) {
        context.push(
          AppRoutes.paymentReceipt,
          extra: PaymentReceiptArgs(
            initiation: initiation,
            kind: PaymentFlowKind.retail,
            orderId: orderId,
          ),
        );
        // Allow the user to re-enter checkout cleanly if they back out.
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() {
        _error = errorCodeOf(e);
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkoutTitle),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Text(l10n.orderSummary, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...cartState.items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('${l10n.qty}: ${item.quantity}',
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      PriceTag(value: item.subtotalTjs),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpace.sm),
            // Order total row
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg, vertical: AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.accentPlate.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.accentBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.orderTotal,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  PriceTag(
                    value: cartState.totalTjs,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.line),
                boxShadow: AppShadows.soft,
              ),
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Row(children: [
                const Icon(Icons.storefront_outlined, color: AppColors.accent),
                const SizedBox(width: AppSpace.md),
                Expanded(
                    child: Text(l10n.pickupInformation,
                        style: theme.textTheme.bodyMedium)),
              ]),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpace.lg),
              AppErrorWidget(error: _error!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _isProcessing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_outline, size: 18),
                  label: Text(
                      _isProcessing ? l10n.processing : l10n.placeOrderAndPay),
                  onPressed: _isProcessing || cartState.items.isEmpty
                      ? null
                      : _placeOrderAndPay,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                l10n.paymentDisclaimer,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.inkFaint, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
