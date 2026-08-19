import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/delivered_celebration.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../shared/widgets/shipment_timeline.dart';
import '../../../theme/app_tokens.dart';
import '../../payment_receipts/utils/receipt_rejection_message.dart';
import '../../reviews/providers/review_eligibility_provider.dart';
import '../../reviews/providers/review_form_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/continue_payment_button.dart';

/// OrderScreen — order detail with full shipment tracking timeline.
class OrderScreen extends ConsumerStatefulWidget {
  final String orderId;
  final Duration celebrationDuration;

  const OrderScreen({
    super.key,
    required this.orderId,
    this.celebrationDuration = const Duration(milliseconds: 2500),
  });

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  bool _showCelebration = false;
  String? _celebrationCheckedOrderId;
  String? _celebrationWrittenOrderId;

  void _syncDeliveredCelebration(Order order) {
    if (order.status != 'delivered') return;
    if (_celebrationCheckedOrderId == order.id) return;
    _celebrationCheckedOrderId = order.id;
    final storage = ref.read(dioClientProvider).storage;
    unawaited(_showDeliveredCelebrationIfNeeded(order, storage));
  }

  Future<void> _showDeliveredCelebrationIfNeeded(
    Order order,
    SecureStorage storage,
  ) async {
    final celebrated = await storage.readCelebrated(order.id);
    if (!mounted || celebrated) return;
    if (_celebrationWrittenOrderId != order.id) {
      _celebrationWrittenOrderId = order.id;
      await storage.writeCelebrated(order.id);
    }
    if (mounted) {
      setState(() => _showCelebration = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(l10n.orderDetailTitle),
            leading: const BackButton(),
          ),
          body: orderAsync.when(
            loading: () => const LoadingState(),
            error: (err, _) => AppErrorWidget(
              error: err,
              onRetry: () => ref.refresh(orderDetailProvider(widget.orderId)),
            ),
            data: (order) {
              _syncDeliveredCelebration(order);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.orderNumber(order.id.length > 8
                                ? order.id.substring(0, 8)
                                : order.id),
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        _DarkStatusPill(status: order.status, l10n: l10n),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    if (order.items.any((item) => item.status != 'cancelled')) ...[
                      Text(l10n.orderActiveItems, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpace.sm),
                    ],
                    ...order.items
                        .where((item) => item.status != 'cancelled')
                        .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _ItemThumb(imageUrl: item.imageUrl),
                                  const SizedBox(width: AppSpace.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: theme.textTheme.titleMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${l10n.qty}: ${item.quantity}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  color: AppColors.inkMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  PriceTag(value: item.unitPriceTjs),
                                ],
                              ),
                              // D-01: order-item entry point — only when the
                              // order is delivered AND server eligibility
                              // says this specific order item can still be
                              // reviewed (editing happens from the review
                              // list only, per D-04).
                              if (order.status == 'delivered')
                                _OrderItemReviewCta(item: item),
                            ],
                          ),
                        )),
                    if (order.items.any((item) => item.status == 'cancelled')) ...[
                      const Divider(height: AppSpace.xl, color: AppColors.line),
                      Text(l10n.orderCancelledItems, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpace.sm),
                      ...order.items
                          .where((item) => item.status == 'cancelled')
                          .map((item) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: AppSpace.md),
                                padding: const EdgeInsets.all(AppSpace.md),
                                decoration: BoxDecoration(
                                  color: AppColors.line.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(AppRadii.card),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.sm),
                                    Text(
                                      item.cancellation?.customerMessage ?? '',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    if (item.cancellation?.refund != null) ...[
                                      const SizedBox(height: AppSpace.sm),
                                      Text(
                                        '${_refundStatusLabel(l10n, item.cancellation!.refund!.status)} · '
                                        '${item.cancellation!.refund!.amountTjs} ${item.cancellation!.refund!.currency}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )),
                    ],
                    if (order.status == 'created') ...[
                      const SizedBox(height: 16),
                      if (order.receiptReviewStatus == 'under_review')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 18, color: AppColors.accentHover),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.paymentUnderReview,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.accentHover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (order.receiptReviewStatus == 'rejected') ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 18, color: AppColors.danger),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.receiptRejectedTitle,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (order.receiptRejectionReason != null) ...[
                                      Text.rich(
                                        TextSpan(
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.danger,
                                          ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  '${l10n.receiptRejectedReasonLabel} ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            TextSpan(
                                              text: order.receiptRejectionReason!,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (receiptRejectionMessage(
                                            l10n,
                                            order.receiptRejectionCategory) !=
                                        null) ...[
                                      Text.rich(
                                        TextSpan(
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.danger,
                                          ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  '${l10n.receiptRejectedReasonLabel} ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            TextSpan(
                                              text: receiptRejectionMessage(
                                                l10n,
                                                order.receiptRejectionCategory,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        l10n.receiptRejectedBody,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ContinuePaymentButton(orderId: order.id),
                      ] else
                        ContinuePaymentButton(orderId: order.id),
                    ],
                    if (order.status == 'ready') ...[
                      const SizedBox(height: AppSpace.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.pickupCodePath(order.id)),
                          icon: const Icon(Icons.qr_code_rounded),
                          label: Text(l10n.showPickupCodeBtn),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpace.lg),
                    const Divider(height: 1, color: AppColors.line),
                    const SizedBox(height: AppSpace.lg),
                    Text(l10n.trackingTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpace.md),
                    if (order.shipment == null)
                      Text(
                        l10n.trackingNotAvailable,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.inkMuted),
                      )
                    else ...[
                      if (order.shipment!.trackingCode != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.qr_code_2,
                                size: 18, color: AppColors.inkMuted),
                            const SizedBox(width: AppSpace.sm),
                            Text('${l10n.trackingCodeLabel}: ',
                                style: theme.textTheme.bodyMedium),
                            Expanded(
                              child: Text(
                                order.shipment!.trackingCode!,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.lg),
                      ],
                      ShipmentTimeline(
                        currentStage:
                            shipmentStageForOrderStatus(order.status),
                        l10n: l10n,
                      ),
                    ],
                    const SizedBox(height: AppSpace.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.lg,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          _TotalRow(label: l10n.orderOriginalTotal, value: order.totalTjs),
                          const SizedBox(height: AppSpace.sm),
                          _TotalRow(label: l10n.orderCurrentTotal, value: order.currentTotalTjs),
                          if (order.cancelledTotalTjs != '0.00') ...[
                            const SizedBox(height: AppSpace.sm),
                            _TotalRow(
                              label: l10n.orderCancelledTotal,
                              value: order.cancelledTotalTjs,
                            ),
                          ],
                          if (order.refundedTotalTjs != '0.00') ...[
                            const SizedBox(height: AppSpace.sm),
                            _TotalRow(
                              label: l10n.orderRefundedTotal,
                              value: order.refundedTotalTjs,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
        if (_showCelebration)
          DeliveredCelebration(
            duration: widget.celebrationDuration,
            onDismissed: () {
              if (mounted) {
                setState(() => _showCelebration = false);
              }
            },
          ),
      ],
    );
  }
}

String _refundStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'pending':
      return l10n.refundStatusPending;
    case 'failed':
      return l10n.refundStatusFailed;
    case 'manual_required':
      return l10n.refundStatusManualRequired;
    case 'succeeded':
      return l10n.refundStatusSucceeded;
    default:
      return status;
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          PriceTag(value: value),
        ],
      );
}

class _DarkStatusPill extends StatelessWidget {
  const _DarkStatusPill({required this.status, required this.l10n});

  final String status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = _resolve(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  (String, IconData) _resolve(String s) {
    switch (s) {
      case 'created':
        return (l10n.statusCreated, Icons.schedule);
      case 'paid':
        return (l10n.statusPaid, Icons.payments_outlined);
      case 'placed_on_pinduoduo':
        return (l10n.statusOrdered, Icons.storefront_outlined);
      case 'at_cn_warehouse':
      case 'cn_warehouse':
        return (l10n.stageCnWarehouse, Icons.warehouse_outlined);
      case 'in_transit':
        return (l10n.stageInTransit, Icons.flight_takeoff);
      case 'at_tj_warehouse':
      case 'tj_warehouse':
        return (l10n.stageTjWarehouse, Icons.warehouse_outlined);
      case 'ready':
        return (l10n.stageReady, Icons.inventory_2_outlined);
      case 'delivered':
        return (l10n.stageDelivered, Icons.check_circle_outline);
      case 'cancelled':
        return (l10n.statusCancelled, Icons.cancel_outlined);
      case 'refunded':
        return (l10n.statusRefunded, Icons.replay);
      default:
        return (s, Icons.schedule);
    }
  }
}

/// Order-item "Оценить товар" entry point (D-01). Gates its own visibility
/// on `reviewEligibilityProvider(item.productId)` — only shown when
/// `item.id` appears in `eligibleOrderItems`; renders nothing while
/// loading/error or when already reviewed (D-03/D-04).
class _OrderItemReviewCta extends ConsumerWidget {
  const _OrderItemReviewCta({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eligibilityAsync =
        ref.watch(reviewEligibilityProvider(item.productId));

    return eligibilityAsync.when(
      data: (eligibility) {
        if (!eligibility.isOrderItemEligible(item.id)) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: AppSpace.sm, left: 72),
          child: OutlinedButton(
            onPressed: () => context.push(
              AppRoutes.reviewForm,
              extra: ReviewFormArgs(
                orderItemId: item.id,
                productId: item.productId,
                productName: item.productName,
                productImageUrl: item.imageUrl,
              ),
            ),
            child: Text(l10n.reviewEntryCta),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.image),
      child: SizedBox(
        width: 60,
        height: 60,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                fadeInDuration: AppMotion.enter,
                placeholder: (_, __) => const ColoredBox(color: AppColors.bg),
                errorWidget: (_, __, ___) => const _ThumbFallback(),
              )
            : const _ThumbFallback(),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.accentPlate,
        child: Center(
          child: Icon(
            Icons.inventory_2_outlined,
            size: 26,
            color: AppColors.accentDeep,
          ),
        ),
      );
}
