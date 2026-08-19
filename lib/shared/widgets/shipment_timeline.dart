import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_tokens.dart';

/// Maps an [OrderStatus] value (the aggregated source of truth the badge uses)
/// to the [ShipmentTimeline] stage key. This is the inverse of the backend's
/// STAGE_TO_STATUS map (apps/api/src/orders/order-state-machine.ts).
///
/// Why not read shipment.stage directly? Since Phase 30 the parcel-scan flow
/// (ScanService) advances `order.status` and `parcel.stage`, but never advances
/// the legacy `Shipment.stage` row — it stays frozen at 'awaiting' from order
/// creation. Driving the timeline from `order.status` keeps the badge and the
/// timeline reading a single, authoritative source.
///
///   created / paid / placed_on_pinduoduo -> awaiting
///   at_cn_warehouse                       -> cn_warehouse
///   in_transit                            -> in_transit
///   at_tj_warehouse                       -> tj_warehouse
///   ready                                 -> ready
///   delivered                             -> delivered
///
/// cancelled / refunded (and any unknown value) have no forward pipeline step;
/// they fall back to 'awaiting' so the timeline shows the initial step rather
/// than a misleading "delivered". Terminal-state UI is conveyed by the badge.
String shipmentStageForOrderStatus(String orderStatus) {
  switch (orderStatus) {
    case 'created':
    case 'paid':
    case 'placed_on_pinduoduo':
      return 'awaiting';
    case 'at_cn_warehouse':
      return 'cn_warehouse';
    case 'in_transit':
      return 'in_transit';
    case 'at_tj_warehouse':
      return 'tj_warehouse';
    case 'ready':
      return 'ready';
    case 'delivered':
      return 'delivered';
    default:
      // cancelled / refunded / unknown — show the initial pipeline step.
      return 'awaiting';
  }
}

/// ShipmentTimeline — the full shipment pipeline as a vertical stepped timeline.
///
/// Stages before the current one are green (done), the current one is highlighted
/// and animates in, future stages are muted. Shared by the retail order detail
/// (B2C) and the wholesale order detail (B2B) so both flows track a shipment the
/// same way. Keyed on the canonical [ShipmentStage] enum values
/// (awaiting · cn_warehouse · in_transit · tj_warehouse · ready · delivered).
///
/// Callers derive [currentStage] from `order.status` via
/// [shipmentStageForOrderStatus] — NOT from the stale `shipment.stage` field.
class ShipmentTimeline extends StatelessWidget {
  const ShipmentTimeline({
    super.key,
    required this.currentStage,
    required this.l10n,
  });

  final String currentStage;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final stages = <MapEntry<String, String>>[
      MapEntry('awaiting', l10n.stageAwaiting),
      MapEntry('cn_warehouse', l10n.stageCnWarehouse),
      MapEntry('in_transit', l10n.stageInTransit),
      MapEntry('tj_warehouse', l10n.stageTjWarehouse),
      MapEntry('ready', l10n.stageReady),
      MapEntry('delivered', l10n.stageDelivered),
    ];
    var current = stages.indexWhere((s) => s.key == currentStage);
    if (current < 0) current = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stages.length; i++)
          _StageRow(
            label: stages[i].value,
            state: i < current
                ? _StageState.done
                : (i == current ? _StageState.current : _StageState.future),
            isLast: i == stages.length - 1,
            doneConnector: i < current,
          ),
      ],
    );
  }
}

enum _StageState { done, current, future }

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.state,
    required this.isLast,
    required this.doneConnector,
  });

  final String label;
  final _StageState state;
  final bool isLast;
  final bool doneConnector;

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _StageState.current;
    final isDone = state == _StageState.done;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                _dot(isCurrent, isDone),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: doneConnector ? AppColors.accent : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.lg, top: 1),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? AppColors.accentDeep
                      : (isDone ? AppColors.ink : AppColors.inkFaint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool isCurrent, bool isDone) {
    // Reference Zone 2: current node = green pulse-ring (animated), done node =
    // solid green with a soft glow + check, future = hollow on a hairline.
    if (isCurrent) return const _PulseDot();
    if (isDone) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.check, size: 15, color: Colors.white),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.line, width: 2),
      ),
    );
  }
}

/// Current-stage node — a green dot wrapped in a continuously pulsing ring
/// (reference Zone 2 "pulse-ring" token).
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Ring expands from 5px to 9px and fades as it grows.
        final spread = 5.0 + 4.0 * _ctrl.value;
        final alpha = 0.18 * (1 - _ctrl.value) + 0.06;
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: alpha),
                blurRadius: 0,
                spreadRadius: spread,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.local_shipping_outlined,
                size: 13, color: AppColors.accentHover),
          ),
        );
      },
    );
  }
}
