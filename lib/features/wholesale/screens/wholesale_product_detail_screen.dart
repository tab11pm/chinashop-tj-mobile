import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/wholesale_provider.dart';
import '../providers/wholesale_cart_provider.dart';
import '../widgets/tier_table_widget.dart';
import '../screens/wholesale_locked_screen.dart' show WholesaleLockedBody;
import '../../../core/api/api_exception.dart';
import '../../../core/api/error_messages.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_tokens.dart';

/// WholesaleProductDetailScreen — wholesale product info + TierTableWidget.
///
/// UI-SPEC §State Machine — Mobile: WholesaleProductDetailScreen:
///   loading → data (product info + tiers) → priceTjs='0.00' graceful → error
///
/// isFallback is transparent to buyer — no UI indication.
class WholesaleProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const WholesaleProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<WholesaleProductDetailScreen> createState() =>
      _WholesaleProductDetailScreenState();
}

class _WholesaleProductDetailScreenState
    extends ConsumerState<WholesaleProductDetailScreen> {
  // Quantity for add-to-cart. Initialized to the product MOQ once the detail
  // loads (see _syncQtyToMoq). null until first sync.
  int? _qty;

  @override
  void initState() {
    super.initState();
    // Load the cart so the CTA knows whether this product is already in it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(wholesaleCartProvider.notifier).fetchCart();
    });
  }

  /// Default qty to MOQ on first load; never below MOQ thereafter.
  void _syncQtyToMoq(int moq) {
    if (_qty == null || _qty! < moq) {
      // Defer the setState out of build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _qty = moq < 1 ? 1 : moq);
      });
    }
  }

  Future<void> _addToCart(WholesaleProductDetail product) async {
    final l10n = AppLocalizations.of(context)!;
    final qty = _qty ?? product.moq;
    // Client-side MOQ guard — the server validates again (MOQ_NOT_MET).
    if (qty < product.moq) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.wholesaleMoqError(product.moq))),
      );
      return;
    }
    try {
      await ref.read(wholesaleCartProvider.notifier).addItem(
            factoryProductId: product.id,
            qty: qty,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.wholesaleAddedToCart),
          action: SnackBarAction(
            label: l10n.goToCart,
            onPressed: () => context.go(AppRoutes.wholesaleCart),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = localizedMoqError(context, e) ?? localizedError(context, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  /// Change the cart line qty in place. Going below MOQ removes the line.
  Future<void> _setCartQty(WholesaleProductDetail product, int qty) async {
    try {
      if (qty < product.moq) {
        await ref.read(wholesaleCartProvider.notifier).removeItem(product.id);
      } else {
        // updateItem is fire-and-forget (debounced); no await needed.
        ref.read(wholesaleCartProvider.notifier).updateItem(
              factoryProductId: product.id,
              qty: qty,
            );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedError(context, e))),
      );
    }
  }

  /// Called when the user taps a tier row in the tier table.
  ///
  /// Always updates the local qty (drives the tier-table highlight and the
  /// "not in cart" stepper). If this product is ALREADY in the cart, the
  /// newly-selected tier's minQty is also pushed straight to the cart line
  /// (via [_setCartQty]) so the CTA bar and cart state stay in sync with the
  /// tier the user just tapped, instead of silently keeping the old tier's
  /// qty (see debug/b2b-tier-change-cart-sync.md).
  void _onTierSelected(WholesaleProductDetail product, int minQty) {
    setState(() => _qty = minQty);
    final cartState = ref.read(wholesaleCartProvider);
    final idx =
        cartState.items.indexWhere((i) => i.factoryProductId == product.id);
    if (idx >= 0 && cartState.items[idx].qty != minQty) {
      _setCartQty(product, minQty);
    }
  }

  /// Remove the cart line entirely (the "Remove" button next to the stepper).
  Future<void> _removeFromCart(WholesaleProductDetail product) async {
    try {
      await ref.read(wholesaleCartProvider.notifier).removeItem(product.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedError(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detailAsync = ref.watch(
      wholesaleProductDetailProvider(widget.productId),
    );
    final cartState = ref.watch(wholesaleCartProvider);
    final product = detailAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(''),
      ),
      body: detailAsync.when(
        loading: () => const LoadingState(),
        error: (err, _) => _buildError(context, ref, err, l10n),
        data: (product) {
          _syncQtyToMoq(product.moq);
          return _buildContent(context, theme, l10n, product);
        },
      ),
      bottomNavigationBar:
          product == null ? null : _buildAddToCartBar(l10n, cartState, product),
    );
  }

  Widget _buildAddToCartBar(
    AppLocalizations l10n,
    WholesaleCartState cartState,
    WholesaleProductDetail product,
  ) {
    // Is this product already in the cart? If so the CTA becomes a stepper bound
    // to the CART line's qty (+/- call updateItem (PATCH), decrement stops at
    // MOQ) next to a "Remove" button. Otherwise show the local-qty stepper +
    // "Add to cart".
    final idx =
        cartState.items.indexWhere((i) => i.factoryProductId == product.id);
    final cartItem = idx >= 0 ? cartState.items[idx] : null;

    if (cartItem != null) {
      final cartQty = cartItem.qty;
      return _AddToCartBar(
        quantity: cartQty,
        moq: product.moq,
        inCart: true,
        loading: cartState.isLoading,
        quantityLabel: l10n.wholesaleQuantityLabel,
        addLabel: l10n.wholesaleAddToCart,
        // In-cart stepper drives the cart line directly (qty ≥ MOQ); the
        // "Remove" button deletes the line.
        onDec: () => _setCartQty(product, cartQty - 1),
        onInc: () => _setCartQty(product, cartQty + 1),
        onAdd: () => _addToCart(product),
        onChanged: (v) => _setCartQty(product, v),
        removeLabel: l10n.removeFromCart,
        onRemove: () => _removeFromCart(product),
        totalTjs: cartItem.subtotalTjs,
      );
    }

    final currentQty = _qty ?? product.moq;
    return _AddToCartBar(
      quantity: currentQty,
      moq: product.moq,
      inCart: false,
      loading: cartState.isLoading,
      quantityLabel: l10n.wholesaleQuantityLabel,
      addLabel: l10n.wholesaleAddToCart,
      onDec: () => setState(() {
        final cur = _qty ?? product.moq;
        _qty = cur > product.moq ? cur - 1 : product.moq;
      }),
      onInc: () => setState(() => _qty = (_qty ?? product.moq) + 1),
      onAdd: () => _addToCart(product),
      onChanged: (v) => setState(() => _qty = v),
      totalTjs: _totalForQty(product, currentQty),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object err,
    AppLocalizations l10n,
  ) {
    if (err is DomainException && err.code == 'SELLER_NOT_VERIFIED') {
      return const WholesaleLockedBody();
    }
    return AppErrorWidget(
      error: err,
      onRetry: () => ref.refresh(
        wholesaleProductDetailProvider(widget.productId),
      ),
    );
  }

  /// minQty of the active price tier for the current quantity: the greatest
  /// tier minQty that is ≤ the selected qty. Falls back to the smallest tier
  /// (or product MOQ) when none qualifies.
  int _activeTierMinQty(WholesaleProductDetail product) {
    final qty = _qty ?? product.moq;
    if (product.tiers.isEmpty) return qty;
    final sorted = [...product.tiers]
      ..sort((a, b) => a.minQty.compareTo(b.minQty));
    var active = sorted.first.minQty;
    for (final t in sorted) {
      if (t.minQty <= qty) {
        active = t.minQty;
      } else {
        break;
      }
    }
    return active;
  }

  /// Entry-tier (smallest minQty) unit price — used for the headline price.
  /// Falls back to '0.00' (graceful, D-07) when there are no tiers.
  String _entryTierPriceTjs(WholesaleProductDetail product) {
    if (product.tiers.isEmpty) return '0.00';
    final sorted = [...product.tiers]
      ..sort((a, b) => a.minQty.compareTo(b.minQty));
    return sorted.first.unitPriceTjs;
  }

  String _activeUnitPriceTjs(WholesaleProductDetail product, int qty) {
    if (product.tiers.isEmpty) return '0.00';
    final sorted = [...product.tiers]
      ..sort((a, b) => a.minQty.compareTo(b.minQty));
    var active = sorted.first;
    for (final tier in sorted) {
      if (tier.minQty <= qty) {
        active = tier;
      } else {
        break;
      }
    }
    return active.unitPriceTjs;
  }

  String _totalForQty(WholesaleProductDetail product, int qty) {
    final unitTiins = _parseTiins(_activeUnitPriceTjs(product, qty));
    return _tiinsToString(unitTiins * qty);
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    WholesaleProductDetail product,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          if (product.images.isNotEmpty)
            SizedBox(
              height: 280,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: product.images.first,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(
                  color: AppColors.accentPlate,
                  child: const LoadingState(),
                ),
                errorWidget: (ctx, url, err) => Container(
                  color: AppColors.accentPlate,
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 72,
                    color: AppColors.accentDeep,
                  ),
                ),
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              color: AppColors.accentPlate,
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 72,
                color: AppColors.accentDeep,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  product.name,
                  style: theme.textTheme.headlineSmall,
                ),

                const SizedBox(height: AppSpace.sm),

                // Headline unit price — entry-tier (smallest) price, ink Nunito-900.
                PriceTag(
                  value: _entryTierPriceTjs(product),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),

                const SizedBox(height: AppSpace.md),

                // Factory row
                _InfoRow(
                  label: l10n.wholesaleFactoryLabel,
                  value: product.factory.name,
                  onTap: product.factoryId.isNotEmpty
                      ? () => context.push(
                            AppRoutes.wholesaleFactoryPath(product.factoryId),
                          )
                      : null,
                ),

                const SizedBox(height: AppSpace.sm),

                // MOQ chip — accent-plate tint, ink/green text (one-accent rule).
                _MoqChip(moq: product.moq),

                // Description (isFallback is transparent — D-07)
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    product.description!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpace.xl),

                // Tier table — tappable volume switcher. Selecting a tier sets
                // the quantity to that tier's minQty; the active tier (greatest
                // minQty ≤ current qty) is highlighted and the qty stepper syncs.
                TierTableWidget(
                  tiers: product.tiers,
                  selectedMinQty: _activeTierMinQty(product),
                  onTierSelected: (minQty) => _onTierSelected(product, minQty),
                ),

                const SizedBox(height: AppSpace.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// MOQ chip — accent-plate tint with ink/green text (one-accent rule),
/// matching the merchandising-chip style used across re-skinned screens.
class _MoqChip extends StatelessWidget {
  const _MoqChip({required this.moq});
  final int moq;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentPlate,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        AppLocalizations.of(context)!.wholesaleMoqChip(moq),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.accentDeep,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: onTap != null
              ? GestureDetector(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.accentDeep,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
        ),
      ],
    );
  }
}

/// Sticky bottom bar: MOQ-aware quantity stepper.
///
/// Not in cart: local-qty stepper + "Add to cart" CTA (lower bound is the
/// product MOQ instead of 1).
/// In cart: a stepper bound to the CART line's qty (+/- call updateItem (PATCH),
/// decrement stops at MOQ) next to a "Remove" button that deletes the line. The
/// count is driven by the re-fetched cart line, so it stays synced.
class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.quantity,
    required this.moq,
    required this.inCart,
    required this.loading,
    required this.quantityLabel,
    required this.addLabel,
    required this.onDec,
    required this.onInc,
    required this.onAdd,
    required this.onChanged,
    required this.totalTjs,
    this.removeLabel,
    this.onRemove,
  });

  final int quantity;
  final int moq;
  final bool inCart;
  final bool loading;
  final String quantityLabel;
  final String addLabel;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onAdd;
  final ValueChanged<int> onChanged;
  final String totalTjs;
  final String? removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md + bottomInset),
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
            Row(
              children: [
                _Stepper(
                  quantity: quantity,
                  moq: moq,
                  quantityLabel: quantityLabel,
                  onDec: onDec,
                  onInc: onInc,
                  onChanged: onChanged,
                  decEnabled: !loading && quantity > moq,
                  // In cart, onChanged performs a cart PATCH → commit on blur only.
                  cartBound: inCart,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: inCart
                        // In cart: a "Remove" button next to the cart-bound stepper.
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: AppColors.onAccent,
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(removeLabel ?? ''),
                            onPressed:
                                (loading || onRemove == null) ? null : onRemove,
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                            label: Text(addLabel),
                            onPressed: loading ? null : onAdd,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.wholesaleOrderTotalLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.inkMuted),
                ),
                PriceTag(
                  value: totalTjs,
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
          ],
        ),
      ),
    );
  }
}

int _parseTiins(String moneyStr) {
  final parts = moneyStr.split('.');
  final whole = int.tryParse(parts[0]) ?? 0;
  if (parts.length <= 1) return whole * 100;
  final frac3 = int.tryParse(parts[1].padRight(3, '0').substring(0, 3)) ?? 0;
  final frac = (frac3 + 5) ~/ 10;
  return whole * 100 + frac;
}

String _tiinsToString(int tiins) {
  final tjs = tiins ~/ 100;
  final frac = tiins % 100;
  return '$tjs.${frac.toString().padLeft(2, '0')}';
}

class _Stepper extends StatefulWidget {
  const _Stepper({
    required this.quantity,
    required this.moq,
    required this.quantityLabel,
    required this.onDec,
    required this.onInc,
    required this.onChanged,
    required this.decEnabled,
    this.cartBound = false,
  });

  final int quantity;
  final int moq;
  final String quantityLabel;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final ValueChanged<int> onChanged;
  final bool decEnabled;

  /// When true (in-cart), [onChanged] performs a cart PATCH, so typed edits are
  /// committed only on blur/submit — not per keystroke.
  final bool cartBound;

  @override
  State<_Stepper> createState() => _StepperState();
}

class _StepperState extends State<_Stepper> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.quantity}');
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        _clampAndCommit();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clampAndCommit() {
    var value = int.tryParse(_ctrl.text);
    if (value == null || value < widget.moq) {
      value = widget.moq;
    }
    _ctrl.text = '$value';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    widget.onChanged(value);
  }

  @override
  void didUpdateWidget(_Stepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != int.tryParse(_ctrl.text)) {
      _ctrl.text = '${widget.quantity}';
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = Semantics(
      label: widget.quantityLabel,
      child: SizedBox(
        width: 52,
        child: TextField(
          controller: _ctrl,
          focusNode: _focus,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          // In-cart, onChanged performs a cart PATCH, so we only commit on
          // blur/submit — not per keystroke.
          onChanged: widget.cartBound
              ? null
              : (raw) {
                  final v = int.tryParse(raw);
                  if (v != null) widget.onChanged(v);
                },
          onSubmitted: (_) => _clampAndCommit(),
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, widget.onDec, enabled: widget.decEnabled),
          field,
          _btn(Icons.add, widget.onInc),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, {bool enabled = true}) =>
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 20),
        color: AppColors.accentDeep,
      );
}
