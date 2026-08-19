import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/wholesale_orders_provider.dart';
import '../widgets/wholesale_continue_payment_button.dart';
import '../../payment_receipts/utils/receipt_rejection_message.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/order_status_chip.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_tokens.dart';

/// WholesaleOrdersScreen — list of own wholesale orders.
///
/// UI-SPEC §Screen Inventory 3: WholesaleOrdersScreen (/wholesale/orders)
/// States: loading / empty / data / error
/// Order card: id chip + factory name + OrderStatusChip + total + createdAt
/// Mirrors the B2C orders list: cream page, token surfaces, OrderStatusChip.
class WholesaleOrdersScreen extends ConsumerWidget {
  const WholesaleOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(wholesaleOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(l10n.wholesaleOrdersTitle)),
      body: ordersAsync.when(
        loading: () => const LoadingState(),
        error: (err, _) => _buildError(context, ref, err),
        data: (orders) {
          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.wholesaleOrdersEmptyTitle,
              subtitle: l10n.wholesaleOrdersEmptyBody,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(wholesaleOrdersProvider.notifier).fetchOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(
                  order: order,
                  onTap: () => context
                      .push(AppRoutes.wholesaleOrderDetailPath(order.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object err) {
    // 403 / SELLER_NOT_VERIFIED — for orders, show generic error (user should
    // not be here without verification, but handle gracefully)
    return AppErrorWidget(
      error: err,
      onRetry: () => ref.read(wholesaleOrdersProvider.notifier).fetchOrders(),
    );
  }
}

// ---------------------------------------------------------------------------
// Order summary card — token surface (cream card, hairline border)
// ---------------------------------------------------------------------------

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final WholesaleOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final dateDisplay = _formatDate(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID chip + status chip
              Row(
                children: [
                  // ID chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      '#$shortId',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        // Canonical numeric/code family (UI-SPEC numeric ramp).
                        fontFamily: 'Nunito',
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              // Factory name
              Text(
                order.factoryName,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.xs),
              // Total + date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PriceTag(value: order.totalTjs, large: true),
                  Text(
                    dateDisplay,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.inkFaint),
                  ),
                ],
              ),
              // Quick resume-payment entry for unpaid wholesale orders.
              // Hidden once a receipt is under review. A rejected receipt shows
              // the operator reason and keeps the re-upload action nearby.
              if (order.status == 'created' &&
                  order.paymentGroupId != null) ...[
                const SizedBox(height: AppSpace.md),
                if (order.hasReceiptInFlight)
                  ReceiptUnderReviewPill(
                    label: AppLocalizations.of(context)!.paymentUnderReview,
                  )
                else if (order.hasRejectedReceipt)
                  ReceiptRejectedPanel(
                    title: AppLocalizations.of(context)!.receiptRejectedTitle,
                    body: AppLocalizations.of(context)!.receiptRejectedBody,
                    reasonLabel: AppLocalizations.of(context)!
                        .receiptRejectedReasonLabel,
                    // Operator note if any, else a localized AI-category reason.
                    reason: order.receiptRejectionReason ??
                        receiptRejectionMessage(AppLocalizations.of(context)!,
                            order.receiptRejectionCategory),
                    action: WholesaleContinuePaymentButton(
                        groupId: order.paymentGroupId!),
                  )
                else
                  WholesaleContinuePaymentButton(
                      groupId: order.paymentGroupId!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return isoDate.substring(0, isoDate.length > 10 ? 10 : isoDate.length);
    }
  }
}
