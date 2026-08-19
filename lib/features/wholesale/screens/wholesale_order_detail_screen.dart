import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/wholesale_orders_provider.dart';
import '../widgets/wholesale_continue_payment_button.dart';
import '../../payment_receipts/utils/receipt_rejection_message.dart';
import '../../../shared/widgets/shipment_timeline.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';

/// WholesaleOrderDetailScreen — full order detail for a wholesale order.
///
/// UI-SPEC §Screen Inventory 4: WholesaleOrderDetailScreen (/wholesale/orders/:id)
/// States: loading / data / error
///
/// Zone-2 layout (reused verbatim from the accepted B2C order_screen):
///   cream page, dark status pill header, item rows with photo thumbs,
///   ShipmentTimeline for tracking, white total card.
class WholesaleOrderDetailScreen extends ConsumerWidget {
  const WholesaleOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final orderAsync = ref.watch(wholesaleOrderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('${l10n.wholesaleOrderDetailTitle} #${_shortId(orderId)}'),
        leading: const BackButton(),
      ),
      body: orderAsync.when(
        loading: () => const LoadingState(),
        error: (err, _) => AppErrorWidget(
          error: err,
          onRetry: () => ref
              .read(wholesaleOrderDetailProvider(orderId).notifier)
              .fetch(orderId),
        ),
        data: (order) => _OrderDetailBody(order: order, l10n: l10n),
      ),
    );
  }

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;
}

// ---------------------------------------------------------------------------
// Order detail body
// ---------------------------------------------------------------------------

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order, required this.l10n});

  final WholesaleOrder order;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        // Header — factory name + dark status pill (Zone-2: ink fill, icon +
        // white text), on the cream page, no card.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                order.factoryName,
                style: theme.textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            _DarkStatusPill(status: order.status, l10n: l10n),
          ],
        ),

        const SizedBox(height: AppSpace.lg),

        // Items — each row with a 60x60 thumb, on the cream page (no card
        // per item), matching the accepted B2C order_screen layout.
        ...order.items.map((item) => _OrderItemRow(item: item, l10n: l10n)),

        // Resume payment for an order placed but not yet paid. B2B pay is
        // group-scoped and the backend allows an idempotent re-initiate while
        // status == 'created' (D-03); this is the client entry point.
        // Suppressed while a receipt is under review. A rejected receipt shows
        // the operator reason and keeps the re-upload action nearby.
        if (order.status == 'created' && order.paymentGroupId != null) ...[
          const SizedBox(height: AppSpace.sm),
          if (order.hasReceiptInFlight)
            ReceiptUnderReviewPill(label: l10n.paymentUnderReview)
          else if (order.hasRejectedReceipt)
            ReceiptRejectedPanel(
              title: l10n.receiptRejectedTitle,
              body: l10n.receiptRejectedBody,
              reasonLabel: l10n.receiptRejectedReasonLabel,
              // Operator note if any, else a localized AI-category reason.
              reason: order.receiptRejectionReason ??
                  receiptRejectionMessage(l10n, order.receiptRejectionCategory),
              action: WholesaleContinuePaymentButton(
                  groupId: order.paymentGroupId!),
            )
          else
            WholesaleContinuePaymentButton(groupId: order.paymentGroupId!),
        ],

        const SizedBox(height: AppSpace.lg),
        const Divider(height: 1, color: AppColors.line),
        const SizedBox(height: AppSpace.lg),

        // Shipment tracking — on the cream page, no white card (matches B2C).
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
              currentStage: shipmentStageForOrderStatus(order.status),
              l10n: l10n),
        ],

        const SizedBox(height: AppSpace.lg),

        // White total card — Zone-2 footer.
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.wholesaleOrderTotalLabel,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              PriceTag(
                value: order.totalTjs,
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

        const SizedBox(height: AppSpace.xxl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dark status pill (Zone-2, reused pattern): ink fill, icon + white text.
// ---------------------------------------------------------------------------

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
      case 'at_cn_warehouse':
        return (l10n.stageCnWarehouse, Icons.warehouse_outlined);
      case 'in_transit':
        return (l10n.stageInTransit, Icons.flight_takeoff);
      case 'at_tj_warehouse':
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

// ---------------------------------------------------------------------------
// Order item row — 60x60 thumb + name/qty/tier + unit price (Zone-2 pattern)
// ---------------------------------------------------------------------------

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.l10n});

  final WholesaleOrderItem item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ItemThumb(imageUrl: item.imageUrl),
          const SizedBox(width: AppSpace.md),
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
                const SizedBox(height: 2),
                Text(
                  '${l10n.qty}: ${item.qty}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.inkMuted),
                ),
                const SizedBox(height: AppSpace.xs),
                // Applied tier label — "тир от N шт."
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentPlate,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    l10n.wholesaleTierApplied(item.appliedTierMinQty),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.accentDeep,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceTag(value: item.unitPriceTjsSnapshot),
              const SizedBox(height: 2),
              // Line total (qty × unit) — restored per WR-01.
              PriceTag(value: item.subtotalTjs),
            ],
          ),
        ],
      ),
    );
  }
}

/// Order item thumbnail — real photo with an on-brand placeholder fallback.
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
          child: Icon(Icons.inventory_2_outlined,
              size: 26, color: AppColors.accentDeep),
        ),
      );
}
