import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';
import '../../../shared/widgets/price_tag.dart';
import '../providers/wholesale_provider.dart';
import '../../../l10n/app_localizations.dart';

/// TierTableWidget — displays the full tier price table for a wholesale product.
///
/// UI-SPEC §Data Display Contracts — Mobile: Tier Table Display:
///   - entry-tier row (first in ASC-sorted list = smallest minQty):
///     Container color=accentPlate, text color=accentDeep
///   - priceTjs='0.00' → show as '– TJS' with inkFaint color (D-04 graceful)
///   - touch target ≥44dp per row (per iOS HIG / Android)
///
/// Selection mode: when [onTierSelected] is provided, each data row becomes
/// tappable (volume switcher) and the highlighted row is the one whose minQty
/// equals [selectedMinQty] (the active price tier) instead of the smallest
/// tier. When [onTierSelected] is null the table is display-only and the
/// entry tier (smallest minQty) is highlighted — the original behaviour.
class TierTableWidget extends StatelessWidget {
  const TierTableWidget({
    super.key,
    required this.tiers,
    this.selectedMinQty,
    this.onTierSelected,
  });

  final List<TierPriceRow> tiers;

  /// minQty of the currently active tier (drives the highlight in selection
  /// mode). Ignored when [onTierSelected] is null.
  final int? selectedMinQty;

  /// Called with the tapped tier's minQty. When null the table is read-only.
  final ValueChanged<int>? onTierSelected;

  static const String _unavailablePrice = '0.00';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (tiers.isEmpty) return const SizedBox.shrink();

    final selectable = onTierSelected != null;

    // Sort tiers ascending by minQty to identify the entry tier (smallest).
    final sorted = [...tiers]..sort((a, b) => a.minQty.compareTo(b.minQty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          l10n.wholesaleTiersTitle,
          style: theme.textTheme.titleLarge,
        ),
        // Selection hint — only in interactive mode.
        if (selectable) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            l10n.wholesaleTierSelectHint,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
        const SizedBox(height: AppSpace.sm),

        // Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header row
              _TierRow(
                qtyText: l10n.wholesaleTierQtyCol,
                headerPriceText: l10n.wholesaleTierPriceCol,
                isHeader: true,
                highlighted: false,
                selectable: selectable,
              ),
              const Divider(height: 1, color: AppColors.line),

              // Data rows
              for (int i = 0; i < sorted.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.line),
                _TierRow.data(
                  qtyText: '${sorted[i].minQty}',
                  priceValue: sorted[i].unitPriceTjs,
                  // Highlight the active tier in selection mode; otherwise the
                  // smallest (entry) tier, preserving the read-only behaviour.
                  highlighted: selectable
                      ? sorted[i].minQty == selectedMinQty
                      : i == 0,
                  selectable: selectable,
                  isPriceUnavailable:
                      sorted[i].unitPriceTjs == _unavailablePrice,
                  onTap: selectable
                      ? () => onTierSelected!(sorted[i].minQty)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TierRow extends StatelessWidget {
  /// Header row constructor: shows [headerPriceText] as plain text.
  const _TierRow({
    required this.qtyText,
    required this.headerPriceText,
    required this.isHeader,
    required this.highlighted,
    required this.selectable,
  })  : priceValue = null,
        isPriceUnavailable = false,
        onTap = null;

  /// Data row constructor: renders [priceValue] via PriceTag-style Nunito
  /// numerics (ink, "с"), or "– с" when [isPriceUnavailable].
  const _TierRow.data({
    required this.qtyText,
    required this.priceValue,
    required this.highlighted,
    required this.selectable,
    this.isPriceUnavailable = false,
    this.onTap,
  })  : isHeader = false,
        headerPriceText = null;

  final String qtyText;

  /// Header-only plain price column label.
  final String? headerPriceText;

  /// Data-row money string from the API — rendered via PriceTag styling.
  /// Never parsed to float (D-07).
  final String? priceValue;

  final bool isHeader;

  /// Whether this row is visually emphasised (active tier / entry tier).
  final bool highlighted;

  /// Whether the table is in interactive selection mode (affects leading
  /// indicator + tap ripple).
  final bool selectable;

  final bool isPriceUnavailable;
  final VoidCallback? onTap;

  // Leading column width reserved for the selection indicator, so the qty
  // column stays aligned between header and data rows in selection mode.
  static const double _indicatorWidth = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Highlighted: accentPlate bg, accentDeep text; header/default: surface.
    final bgColor = highlighted ? AppColors.accentPlate : AppColors.surface;

    // Qty column text style
    TextStyle? qtyStyle;

    if (isHeader) {
      // 12px w400 inkMuted
      qtyStyle = theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted);
    } else if (highlighted) {
      // 14px w700 accentDeep (labelLarge/titleMedium equiv)
      qtyStyle = theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.accentDeep,
        fontWeight: FontWeight.w700,
      );
    } else {
      // 14px w400 ink
      qtyStyle = theme.textTheme.bodyLarge?.copyWith(color: AppColors.ink);
    }

    // Price column — header is plain inkMuted text; data rows render via
    // PriceTag-style Nunito numerics (ink, "с"), dimmed when unavailable.
    final Widget priceWidget = isHeader
        ? Text(headerPriceText ?? '', style: qtyStyle)
        : isPriceUnavailable
            ? Text(
                '– с',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.inkFaint,
                ),
              )
            : PriceTag(
                value: priceValue ?? '0.00',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: -0.2,
                  color: highlighted ? AppColors.accentDeep : AppColors.ink,
                ),
              );

    final content = ConstrainedBox(
      // Minimum touch target 44dp per UI-SPEC
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            // Leading selection indicator (selection mode only). Header keeps
            // an empty slot of the same width to align the qty column.
            if (selectable)
              SizedBox(
                width: _indicatorWidth,
                child: isHeader
                    ? null
                    : Icon(
                        highlighted
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: highlighted
                            ? AppColors.accentDeep
                            : AppColors.inkMuted,
                      ),
              ),
            Expanded(
              child: Text(qtyText, style: qtyStyle),
            ),
            priceWidget,
          ],
        ),
      ),
    );

    // Interactive data rows: Material+InkWell for a clipped tap ripple.
    if (selectable && onTap != null) {
      return Material(
        color: bgColor,
        child: InkWell(onTap: onTap, child: content),
      );
    }
    return Container(color: bgColor, child: content);
  }
}
