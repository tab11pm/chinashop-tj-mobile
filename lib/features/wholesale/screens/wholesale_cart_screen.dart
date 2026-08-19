import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/wholesale_cart_provider.dart';
import './wholesale_locked_screen.dart' show WholesaleLockedBody;
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_tokens.dart';
import '../../../shared/widgets/price_tag.dart';

/// WholesaleCartScreen — multi-factory wholesale cart.
///
/// UI-SPEC §Screen Inventory 1: WholesaleCartScreen (/wholesale/cart)
/// States: loading / empty / data / error
/// Tile: name + stepper (44dp, minus disabled@moq) + tier price + MOQ chip
/// Swipe-to-delete: endToStart, danger bg, snackbar undo
/// Sticky bottom: total + checkout CTA (disabled if empty or MOQ error)
/// 403 → WholesaleLockedBody inline
class WholesaleCartScreen extends ConsumerStatefulWidget {
  const WholesaleCartScreen({super.key});

  @override
  ConsumerState<WholesaleCartScreen> createState() =>
      _WholesaleCartScreenState();
}

class _WholesaleCartScreenState extends ConsumerState<WholesaleCartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wholesaleCartProvider.notifier).fetchCart();
    });
  }

  void _onQtyChanged(String factoryProductId, int newQty) {
    // Debounce now lives in the notifier (800ms); this is a simple pass-through.
    ref.read(wholesaleCartProvider.notifier).updateItem(
          factoryProductId: factoryProductId,
          qty: newQty,
        );
  }

  Future<void> _removeItem(WholesaleCartItem item) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(wholesaleCartProvider.notifier).removeItem(
          item.factoryProductId,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.wholesaleCartItemRemoveConfirm),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: l10n.wholesaleCartItemRemoveUndo,
            onPressed: () {
              // Re-add at original qty; server will validate MOQ
              ref.read(wholesaleCartProvider.notifier).addItem(
                    factoryProductId: item.factoryProductId,
                    qty: item.qty,
                  );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cartState = ref.watch(wholesaleCartProvider);
    final theme = Theme.of(context);

    if (cartState.isLoading && cartState.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.wholesaleCartTitle)),
        body: const LoadingState(),
      );
    }

    if (cartState.error != null && cartState.items.isEmpty) {
      // 403 / SELLER_NOT_VERIFIED
      if (cartState.error == 'SELLER_NOT_VERIFIED') {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.wholesaleCartTitle)),
          body: const WholesaleLockedBody(),
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(l10n.wholesaleCartTitle)),
        body: AppErrorWidget(
          error: cartState.error!,
          onRetry: () => ref.read(wholesaleCartProvider.notifier).fetchCart(),
        ),
      );
    }

    final items = cartState.items;
    final hasMoqError = items.any((i) => i.qty < i.moq);
    final byFactory = <String, List<WholesaleCartItem>>{};
    for (final item in items) {
      byFactory.putIfAbsent(item.factoryName, () => []).add(item);
    }

    // Compute total from subtotals (strings — do NOT parse to float).
    // We display the total as a sum string; actual total comes from checkout response.
    // For display purposes, build the total string from subtotals.
    final totalTjsDisplay = _buildTotalDisplay(items);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.wholesaleCartTitle)),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: l10n.wholesaleCartEmptyTitle,
              subtitle: l10n.wholesaleCartEmptyBody,
              actionLabel: l10n.wholesaleCatalogTitle,
              onAction: () => context.push(AppRoutes.wholesaleCatalog),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(wholesaleCartProvider.notifier).fetchCart(),
              child: ListView(
                padding: const EdgeInsets.only(
                  left: AppSpace.lg,
                  right: AppSpace.lg,
                  top: AppSpace.sm,
                  bottom: AppSpace.xxl + 80,
                ),
                children: [
                  for (final entry in byFactory.entries)
                    _FactoryCartGroup(
                      factoryName: entry.key,
                      items: entry.value,
                      onQtyChanged: _onQtyChanged,
                      onDelete: _removeItem,
                    ),
                ],
              ),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _StickyBottomBar(
              totalTjsDisplay: totalTjsDisplay,
              disabled: hasMoqError,
              onCheckout: () => context.push(AppRoutes.wholesaleCheckout),
              l10n: l10n,
              theme: theme,
            ),
    );
  }

  /// Build a display total string from string subtotals.
  /// The actual precise total is computed server-side; this is UI-only preview.
  /// Sums via integer minor-units (tiins = 1/100 TJS) — no float accumulation (CR-05).
  String _buildTotalDisplay(List<WholesaleCartItem> items) {
    if (items.isEmpty) return '0.00';
    int totalTiins = 0;
    for (final item in items) {
      totalTiins += _parseTiins(item.subtotalTjs);
    }
    return _tiinsToString(totalTiins);
  }

  /// Parse a MoneyString '123.45' into integer tiins (12345).
  ///
  /// The API contract guarantees scale-2 strings, but if an intermediate-scale
  /// value (e.g. '12.999') ever arrives we round the sub-tiin remainder
  /// half-up instead of truncating it (WR-06). All-integer arithmetic — no
  /// float is ever introduced (CR-05 / D-07).
  static int _parseTiins(String moneyStr) {
    final parts = moneyStr.split('.');
    final whole = int.tryParse(parts[0]) ?? 0;
    if (parts.length <= 1) return whole * 100;
    // Take the first 3 fractional digits (hundredths + thousandths) and
    // round half-up on the thousandths to land on a tiin (1/100) value.
    final frac3 = int.tryParse(parts[1].padRight(3, '0').substring(0, 3)) ?? 0;
    final frac = (frac3 + 5) ~/ 10;
    return whole * 100 + frac;
  }

  /// Convert integer tiins back to a '123.45' MoneyString.
  static String _tiinsToString(int tiins) {
    final tjs = tiins ~/ 100;
    final frac = tiins % 100;
    return '$tjs.${frac.toString().padLeft(2, '0')}';
  }
}

String _sumSubtotals(List<WholesaleCartItem> items) {
  var totalTiins = 0;
  for (final item in items) {
    totalTiins += _WholesaleCartScreenState._parseTiins(item.subtotalTjs);
  }
  return _WholesaleCartScreenState._tiinsToString(totalTiins);
}

// ---------------------------------------------------------------------------
// Cart item tile with stepper and swipe-to-delete
// ---------------------------------------------------------------------------

class _FactoryCartGroup extends StatelessWidget {
  const _FactoryCartGroup({
    required this.factoryName,
    required this.items,
    required this.onQtyChanged,
    required this.onDelete,
  });

  final String factoryName;
  final List<WholesaleCartItem> items;
  final void Function(String factoryProductId, int newQty) onQtyChanged;
  final Future<void> Function(WholesaleCartItem item) onDelete;

  @override
  Widget build(BuildContext context) {
    final subtotal = _sumSubtotals(items);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.b2bBand,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            child: Row(
              children: [
                const Icon(Icons.factory_outlined,
                    size: 16, color: AppColors.onAccent),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    factoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.onAccent,
                    ),
                  ),
                ),
                Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8FA89C),
                  ),
                ),
              ],
            ),
          ),
          for (final item in items)
            _CartItemTile(
              key: ValueKey(item.factoryProductId),
              item: item,
              onQtyChanged: (newQty) =>
                  onQtyChanged(item.factoryProductId, newQty),
              onDelete: () => onDelete(item),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.wholesaleFactorySubtotalLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.inkMuted),
                ),
                PriceTag(value: subtotal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    super.key,
    required this.item,
    required this.onQtyChanged,
    required this.onDelete,
  });

  final WholesaleCartItem item;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasMoqError = item.qty < item.moq;

    return Dismissible(
      key: ValueKey(item.factoryProductId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.danger,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        child: Semantics(
          label: l10n.wholesaleCartRemoveItemA11y,
          child: const Icon(Icons.delete_outline, color: AppColors.onAccent),
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.line),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name
              Text(
                item.productName,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.xs),
              // Factory name
              Text(
                item.factoryName,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpace.sm),
              // Stepper row + price
              Row(
                children: [
                  // Quantity stepper
                  _QuantityStepper(
                    qty: item.qty,
                    moq: item.moq,
                    onQtyChanged: onQtyChanged,
                  ),
                  const Spacer(),
                  // Per-unit tier price + tier label
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PriceTag(
                        value: item.unitPriceTjs,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.accentDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.appliedTierMinQty != null)
                        Text(
                          l10n.wholesaleTierApplied(item.appliedTierMinQty!),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                    ],
                  ),
                ],
              ),
              // MOQ inline error
              if (hasMoqError) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  l10n.wholesaleMoqError(item.moq),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quantity stepper — 44dp touch targets, minus disabled at qty==moq
// ---------------------------------------------------------------------------

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.qty,
    required this.moq,
    required this.onQtyChanged,
  });

  final int qty;
  final int moq;
  final ValueChanged<int> onQtyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isAtMin = qty <= moq;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus button
        Semantics(
          label: l10n.wholesaleCartDecreaseQtyA11y,
          child: SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: const Icon(Icons.remove),
              onPressed: isAtMin ? null : () => onQtyChanged(qty - 1),
              color: isAtMin ? AppColors.inkFaint : AppColors.ink,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        // Quantity display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
          child: Text(
            '$qty',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Plus button
        Semantics(
          label: l10n.wholesaleCartIncreaseQtyA11y,
          child: SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onQtyChanged(qty + 1),
              color: AppColors.accentDeep,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky bottom bar — total + CTA
// ---------------------------------------------------------------------------

class _StickyBottomBar extends StatelessWidget {
  const _StickyBottomBar({
    required this.totalTjsDisplay,
    required this.disabled,
    required this.onCheckout,
    required this.l10n,
    required this.theme,
  });

  final String totalTjsDisplay;
  final bool disabled;
  final VoidCallback onCheckout;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.line)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.wholesaleOrderTotalLabel,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.inkMuted),
                ),
                PriceTag(
                  value: totalTjsDisplay,
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
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: disabled ? null : onCheckout,
                child: Text(l10n.wholesaleCartCheckoutCta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
