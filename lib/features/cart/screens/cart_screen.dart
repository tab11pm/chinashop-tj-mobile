import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_tokens.dart';

/// CartScreen — view/modify cart items, proceed to checkout.
///
/// Layout follows the master demo `.cart-*` block: a custom cream header with
/// item-count badge, `.citem` rows (74×74 thumbnail · name · price · inline
/// quantity stepper · top-right delete), and a `.cart-foot` totals footer with
/// a full-width green checkout CTA.
///
/// APP-03:
///   GET /api/cart/items
///   PATCH /api/cart/items/{itemId} { quantity }
///   DELETE /api/cart/items/{itemId}
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cartState = ref.watch(cartProvider);

    // No AppBar — the cream `.cart-head` IS the top of the screen (demo structure).
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _CartHead(itemCount: cartState.items.length),
            Expanded(
              child: cartState.isLoading && cartState.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : cartState.error != null && cartState.items.isEmpty
                      ? AppErrorWidget(
                          error: cartState.error!,
                          onRetry: () =>
                              ref.read(cartProvider.notifier).fetchCart(),
                        )
                      : cartState.items.isEmpty
                          ? EmptyState(
                              icon: Icons.shopping_cart_outlined,
                              title: l10n.cartEmpty,
                              actionLabel: l10n.browseCatalog,
                              onAction: () => context.go(AppRoutes.catalog),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  ref.read(cartProvider.notifier).fetchCart(),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                                itemCount: cartState.items.length,
                                itemBuilder: (context, index) {
                                  final item = cartState.items[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 11),
                                    child: _CartItemCard(
                                      item: item,
                                      onIncrement: () => ref
                                          .read(cartProvider.notifier)
                                          .updateItem(
                                            variantId: item.variantId ?? '',
                                            quantity: item.quantity + 1,
                                          ),
                                      onDecrement: item.quantity > 1
                                          ? () => ref
                                              .read(cartProvider.notifier)
                                              .updateItem(
                                                variantId: item.variantId ?? '',
                                                quantity: item.quantity - 1,
                                              )
                                          : null,
                                      onRemove: () => ref
                                          .read(cartProvider.notifier)
                                          .removeItem(item.variantId ?? ''),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
            if (cartState.items.isNotEmpty) ...[
              if (cartState.discountTotalTjs != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: _CartPromoBanner(text: l10n.cartPromoLine),
                ),
              _CartFoot(
                itemCount: cartState.items.length,
                totalTjs: cartState.totalTjs,
                discountTotalTjs: cartState.discountTotalTjs,
                fxRate: cartState.fxRate,
                onCheckout: () => context.push(AppRoutes.checkout),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `.cart-head` — back button + title + item-count badge.
class _CartHead extends StatelessWidget {
  const _CartHead({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                child: const Icon(
                  Icons.chevron_left,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            l10n.cartTitle,
            style: const TextStyle(
              fontFamily: 'Onest',
              fontWeight: FontWeight.w700,
              fontSize: 19,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          if (itemCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                l10n.itemCount(itemCount),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.citem` — single cart row: thumbnail · name · price · qty stepper · delete.
class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.onAccent),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail — 74×74, radius 13 (.cimg)
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: 74,
                    height: 74,
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            fadeInDuration: AppMotion.enter,
                            placeholder: (context, url) =>
                                const _ThumbPlaceholder(),
                            errorWidget: (context, url, error) =>
                                const _ThumbPlaceholder(),
                          )
                        : const _ThumbPlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),
                // Body: name (top) + price/qty row (bottom) (.cbody)
                Expanded(
                  child: SizedBox(
                    height: 74,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          // leave room for the top-right delete button
                          padding: const EdgeInsets.only(right: 28),
                          child: Text(
                            item.productName,
                            style: const TextStyle(
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              height: 1.3,
                              color: AppColors.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        // .cbot — price + inline quantity stepper
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Struck-through "was" price + discount badge
                                  if (item.compareAtPriceTjs != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        children: [
                                          Text(
                                            item.compareAtPriceTjs!,
                                            style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
                                              color: AppColors.inkMuted,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          if (item.discountPercent != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accentPlate,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadii.pill),
                                              ),
                                              child: Text(
                                                '-${item.discountPercent}%',
                                                style: const TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                  color: AppColors.accentDeep,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  PriceTag(
                                    value: item.unitPriceTjs,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _QtyStepper(
                              quantity: item.quantity,
                              onIncrement: onIncrement,
                              onDecrement: onDecrement,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // .cdel — top-right delete chip
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.qty` — inline stepper: − [n] + inside a hairline cream pill.
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: onDecrement,
            enabled: onDecrement != null,
          ),
          SizedBox(
            width: 26,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.ink,
              ),
            ),
          ),
          _QtyButton(icon: Icons.add, onTap: onIncrement, enabled: true),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.ink : AppColors.inkFaint,
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.accentPlate,
      child: Center(
        child: Icon(Icons.image_outlined, color: AppColors.inkFaint, size: 22),
      ),
    );
  }
}

/// Parse a MoneyString '123.45' (or an FX rate '1.5') into integer tiins
/// (12345 / 150). Pure integer arithmetic — no float (D-07). Local mirror of
/// the private `_parseTiins` in cart_provider.dart.
int _parseTjsTiins(String s) {
  final parts = s.split('.');
  final whole = int.tryParse(parts[0]) ?? 0;
  final frac = parts.length > 1
      ? int.tryParse(parts[1].padRight(2, '0').substring(0, 2)) ?? 0
      : 0;
  return whole * 100 + frac;
}

/// `.cart-promo` — green plate reassuring the user discounts are already applied.
class _CartPromoBanner extends StatelessWidget {
  const _CartPromoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentPlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined,
              color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.accentDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.cart-foot` — subtotal row, total row, and full-width green checkout CTA.
class _CartFoot extends StatelessWidget {
  const _CartFoot({
    required this.itemCount,
    required this.totalTjs,
    required this.discountTotalTjs,
    required this.fxRate,
    required this.onCheckout,
  });

  final int itemCount;
  final String totalTjs;
  final String? discountTotalTjs;
  final String fxRate;
  final VoidCallback onCheckout;

  /// Approximate CNY total for the FX line, computed with integer tiins only
  /// (D-07 — no float). Returns null when fxRate is unavailable ('0').
  /// fxRate is CNY→TJS, so CNY ≈ TJS / fxRate. The single division is on
  /// integers; rounding to a whole CNY is by remainder check, not float.
  String? _approxCny() {
    final fxTiins = _parseTjsTiins(fxRate);
    if (fxTiins <= 0) return null;
    final totalTiins = _parseTjsTiins(totalTjs);
    // CNY in tiins = (TJS_tiins / 100) / (fx_tiins / 100) * 100 = TJS_tiins*100 / fx_tiins
    final cnyTiins = (totalTiins * 100) ~/ fxTiins;
    final cnyRounded = cnyTiins ~/ 100 + ((cnyTiins % 100) >= 50 ? 1 : 0);
    return '$cnyRounded';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cny = _approxCny();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // .srow — items subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.itemCount(itemCount),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  PriceTag(
                    value: totalTjs,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              // .srow — discount (green) shown only when a discount is present
              if (discountTotalTjs != null)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.cartDiscount,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      Text(
                        '−$discountTotalTjs',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              // .stot — grand total
              Container(
                margin: const EdgeInsets.only(top: 9),
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.orderTotal,
                      style: const TextStyle(
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    PriceTag(
                      value: totalTjs,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              // FX line — informational; rate is locked at order (future tense)
              if (cny != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.cartFxLine(cny),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 13),
              // .cart-cta — full-width green checkout
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF05140B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: onCheckout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.checkoutButton),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
