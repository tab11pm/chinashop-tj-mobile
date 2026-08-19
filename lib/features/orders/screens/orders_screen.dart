import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/orders_provider.dart';
import '../widgets/continue_payment_button.dart';
import '../../payment_receipts/utils/receipt_rejection_message.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../shared/widgets/order_status_chip.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_tokens.dart';

/// OrdersScreen — list of customer orders.
///
/// Layout follows the master demo `.ocard` block: a cream order card with a
/// top row (number · date · status pill), a body row (overlapping product
/// thumbnails · item names · total), and a green mini progress bar tracking
/// the placed → in-transit → delivered journey. Unpaid orders keep the
/// resume-payment entry and receipt-review states.
///
/// APP-03: GET /api/orders
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).fetchOrders();
    });
  }

  List<Order> _filteredOrders(List<Order> all) {
    switch (_selectedTab) {
      case 1: // In transit
        const inTransitStatuses = {
          'paid',
          'placed_on_pinduoduo',
          'at_cn_warehouse',
          'in_transit',
          'at_tj_warehouse',
          'ready',
        };
        return all
            .where((o) => inTransitStatuses.contains(o.status))
            .toList();
      case 2: // Paid
        const paidStatuses = {'paid', 'placed_on_pinduoduo'};
        return all.where((o) => paidStatuses.contains(o.status)).toList();
      case 3: // Delivered
        return all.where((o) => o.status == 'delivered').toList();
      default: // All (case 0)
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ordersState = ref.watch(ordersProvider);
    final filtered = _filteredOrders(ordersState.orders);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _OrdersHead(title: l10n.ordersTitle),
            _TabRow(
              selected: _selectedTab,
              labels: [
                l10n.ordersTabAll,
                l10n.ordersTabInTransit,
                l10n.ordersTabPaid,
                l10n.ordersTabDelivered,
              ],
              onSelect: (i) => setState(() => _selectedTab = i),
            ),
            Expanded(
              child: ordersState.isLoading && ordersState.orders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ordersState.error != null && ordersState.orders.isEmpty
                      ? AppErrorWidget(
                          error: ordersState.error!,
                          onRetry: () =>
                              ref.read(ordersProvider.notifier).fetchOrders(),
                        )
                      : ordersState.orders.isEmpty
                          ? EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: l10n.noOrders,
                              actionLabel: l10n.browseCatalog,
                              onAction: () => context.go(AppRoutes.catalog),
                            )
                          : RefreshIndicator(
                              onRefresh: () => ref
                                  .read(ordersProvider.notifier)
                                  .fetchOrders(),
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 2, 18, 12),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final order = filtered[index];
                                  return _OrderCard(
                                    order: order,
                                    onTap: () => context
                                        .push(AppRoutes.orderPath(order.id)),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.cart-head` style header reused for the orders screen.
class _OrdersHead extends StatelessWidget {
  const _OrdersHead({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        children: [
          if (canPop) ...[
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(Icons.chevron_left,
                    color: AppColors.ink, size: 22),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Onest',
              fontWeight: FontWeight.w700,
              fontSize: 19,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.ocard` — single order card.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shortId =
        order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final activeItems =
        order.items.where((item) => item.status != 'cancelled').toList();
    final cancelledItems =
        order.items.where((item) => item.status == 'cancelled').toList();
    final itemNames =
        activeItems.map((i) => i.productName).where((n) => n.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // .otop — number · date · status
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            l10n.orderNumber(shortId),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            _formatDate(order.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          if (order.status == 'ready')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentPlate,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Text(
                                l10n.readyForPickupBadge,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.accentDeep,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OrderStatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: 11),
                // .obody — thumbnails · names · total
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (activeItems.isNotEmpty) ...[
                      _ThumbStack(items: activeItems),
                      const SizedBox(width: 11),
                    ],
                    Expanded(
                      child: Text(
                        itemNames.join(', '),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.inkMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PriceTag(
                      value: order.currentTotalTjs,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                if (cancelledItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.orderCancelledItemCount(cancelledItems.length),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  Text(
                    '${l10n.orderOriginalTotal}: ${order.totalTjs} TJS · '
                    '${l10n.orderCurrentTotal}: ${order.currentTotalTjs} TJS',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
                // .oprog — green mini progress bar (hidden for terminal-cancel)
                if (_progress(order.status) != null) ...[
                  const SizedBox(height: 11),
                  _OrderProgress(
                    fraction: _progress(order.status)!,
                    status: order.status,
                  ),
                ],
                // Action buttons depend on order status.
                if (order.status == 'created') ...[
                  // Resume-payment entry + receipt-review states (unpaid only).
                  const SizedBox(height: 12),
                  if (order.receiptReviewStatus == 'under_review')
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 14, color: AppColors.accentHover),
                        const SizedBox(width: 4),
                        Text(
                          l10n.paymentUnderReview,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accentHover,
                          ),
                        ),
                      ],
                    )
                  else if (order.receiptReviewStatus == 'rejected') ...[
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 14, color: AppColors.danger),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            l10n.receiptRejectedTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (order.receiptRejectionReason != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.receiptRejectedReasonLabel} ${order.receiptRejectionReason!}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.danger),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (receiptRejectionMessage(
                            l10n, order.receiptRejectionCategory) !=
                        null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.receiptRejectedReasonLabel} ${receiptRejectionMessage(l10n, order.receiptRejectionCategory)!}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.danger),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    ContinuePaymentButton(orderId: order.id),
                  ] else
                    ContinuePaymentButton(orderId: order.id),
                ] else if (order.status == 'delivered') ...[
                  const SizedBox(height: 11),
                  _OrderActions(
                    primaryLabel: l10n.orderAgainBtn,
                    secondaryLabel: l10n.orderReviewBtn,
                    onTapPrimary: () {},
                    onTapSecondary: () {},
                  ),
                ] else if ({
                  'paid',
                  'placed_on_pinduoduo',
                  'at_cn_warehouse',
                  'in_transit',
                  'at_tj_warehouse',
                  'ready',
                }.contains(order.status)) ...[
                  const SizedBox(height: 11),
                  _OrderActions(
                    primaryLabel: l10n.orderTrackBtn,
                    secondaryLabel: l10n.orderHelpBtn,
                    onTapPrimary: () => context
                        .push(AppRoutes.orderPath(order.id)),
                    onTapSecondary: () {},
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Progress fraction for the placed → in-transit → delivered bar.
  /// Returns null for terminal cancel/refund states (no bar).
  double? _progress(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
      case 'refunded':
        return null;
      case 'created':
      case 'awaiting':
      case 'pending':
        return 0.12;
      case 'paid':
      case 'placed_on_pinduoduo':
        return 0.33;
      case 'at_cn_warehouse':
      case 'cn_warehouse':
        return 0.5;
      case 'in_transit':
      case 'picked_up':
        return 0.7;
      case 'at_tj_warehouse':
      case 'tj_warehouse':
      case 'at_destination_warehouse':
        return 0.85;
      case 'ready':
      case 'out_for_delivery':
        return 0.95;
      case 'delivered':
        return 1.0;
      default:
        return 0.33;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

/// `.othumbs` — overlapping product thumbnails with a "+N" overflow chip.
class _ThumbStack extends StatelessWidget {
  const _ThumbStack({required this.items});

  final List<OrderItem> items;

  static const double _size = 46;
  static const double _step = 36; // 46 − 10 overlap

  @override
  Widget build(BuildContext context) {
    final shown = items.take(2).toList();
    final overflow = items.length - shown.length;
    final tileCount = shown.length + (overflow > 0 ? 1 : 0);
    final width = (tileCount - 1) * _step + _size;

    final children = <Widget>[];
    for (var i = 0; i < shown.length; i++) {
      children.add(Positioned(
        left: i * _step,
        child: _Thumb(imageUrl: shown[i].imageUrl),
      ));
    }
    if (overflow > 0) {
      children.add(Positioned(
        left: shown.length * _step,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.line),
          ),
          alignment: Alignment.center,
          child: Text(
            '+$overflow',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
        ),
      ));
    }

    return SizedBox(
      width: width,
      height: _size,
      child: Stack(children: children),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ThumbStack._size,
      height: _ThumbStack._size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              fadeInDuration: AppMotion.enter,
              placeholder: (context, url) => const ColoredBox(
                color: AppColors.accentPlate,
              ),
              errorWidget: (context, url, error) => const ColoredBox(
                color: AppColors.accentPlate,
                child: Icon(Icons.image_outlined,
                    size: 18, color: AppColors.inkFaint),
              ),
            )
          : const ColoredBox(
              color: AppColors.accentPlate,
              child: Icon(Icons.image_outlined,
                  size: 18, color: AppColors.inkFaint),
            ),
    );
  }
}

/// `.ord-tabs` — 4-pill filter row (All / In transit / Paid / Delivered).
class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.ink : AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppRadii.pill),
                    border: Border.all(
                      color: i == selected ? AppColors.ink : AppColors.line,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color:
                          i == selected ? AppColors.bg : AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `.oprog .bar` — green mini progress bar.
class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.fraction, required this.status});

  final double fraction;
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Determine which step is current for highlighting.
    final step = _currentStep(status);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.line,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ProgressLabel(
              label: l10n.orderPlacedLabel,
              isActive: step >= 0,
            ),
            _ProgressLabel(
              label: l10n.ordersTabInTransit,
              isActive: step >= 1,
            ),
            _ProgressLabel(
              label: l10n.ordersTabDelivered,
              isActive: step >= 2,
            ),
          ],
        ),
      ],
    );
  }

  /// Returns 0 = placed, 1 = in-transit, 2 = delivered.
  int _currentStep(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 2;
      case 'at_cn_warehouse':
      case 'cn_warehouse':
      case 'in_transit':
      case 'picked_up':
      case 'at_tj_warehouse':
      case 'tj_warehouse':
      case 'at_destination_warehouse':
      case 'ready':
      case 'out_for_delivery':
        return 1;
      default:
        return 0;
    }
  }
}

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: isActive ? AppColors.accent : AppColors.inkMuted,
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onTapPrimary,
    required this.onTapSecondary,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onTapPrimary;
  final VoidCallback onTapSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTapPrimary,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.accentPlate,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTapSecondary,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: Text(
                secondaryLabel,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
