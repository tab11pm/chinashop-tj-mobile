import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';

/// OrderStatusChip — localized, token-tinted status pill for order.status.
///
/// Labels come from AppLocalizations (tj/ru/en). Colors map to four semantic
/// tones built from design tokens (neutral / progress / success / danger),
/// keeping the app green-centric instead of an off-token rainbow.
class OrderStatusChip extends StatelessWidget {
  final String status;

  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, tone) = _resolve(l10n, status.toLowerCase());
    final c = _toneColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.$1,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: c.$2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.$3,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (String, _Tone) _resolve(AppLocalizations l10n, String s) {
    switch (s) {
      case 'created':
        return (l10n.statusCreated, _Tone.neutral);
      case 'paid':
        return (l10n.statusPaid, _Tone.progress);
      case 'placed_on_pinduoduo':
        return (l10n.statusOrdered, _Tone.progress);
      case 'at_cn_warehouse':
      case 'cn_warehouse':
        return (l10n.stageCnWarehouse, _Tone.progress);
      case 'in_transit':
      case 'picked_up':
        return (l10n.stageInTransit, _Tone.progress);
      case 'at_tj_warehouse':
      case 'tj_warehouse':
      case 'at_destination_warehouse':
        return (l10n.stageTjWarehouse, _Tone.progress);
      case 'ready':
      case 'out_for_delivery':
        return (l10n.stageReady, _Tone.success);
      case 'delivered':
        return (l10n.stageDelivered, _Tone.success);
      case 'awaiting':
      case 'pending':
        return (l10n.stageAwaiting, _Tone.neutral);
      case 'cancelled':
        return (l10n.statusCancelled, _Tone.danger);
      case 'refunded':
        return (l10n.statusRefunded, _Tone.danger);
      default:
        return (s, _Tone.neutral);
    }
  }

  /// (background, border, text)
  (Color, Color, Color) _toneColors(_Tone t) {
    switch (t) {
      case _Tone.success:
        return (
          AppColors.accentPlate,
          AppColors.accentBorder,
          AppColors.accentDeep
        );
      case _Tone.progress:
        return (
          AppColors.accent.withValues(alpha: 0.10),
          AppColors.accent.withValues(alpha: 0.30),
          AppColors.accentHover,
        );
      case _Tone.danger:
        return (
          AppColors.danger.withValues(alpha: 0.10),
          AppColors.danger.withValues(alpha: 0.30),
          AppColors.danger,
        );
      case _Tone.neutral:
        return (AppColors.bg, AppColors.line, AppColors.inkMuted);
    }
  }
}

enum _Tone { neutral, progress, success, danger }
