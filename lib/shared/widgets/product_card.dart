import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../theme/app_tokens.dart';
import 'price_tag.dart';
import 'pressable.dart';

/// ProductCard — reusable product listing card (re-skinned to the reference
/// mockup: rounded image, discount badge, favorite heart, struck-through old
/// price, and a soft-green "add" affordance).
///
/// - priceTjs / oldPriceTjs: money strings from API — rendered via PriceTag /
///   raw text (NEVER double.parse — D-07).
/// - imageUrl: nullable; on-brand placeholder if null/fails.
/// - badge / discountPercent: optional merchandising chips (Phase 21).
/// - onToggleFavorite / isFavorite: optional heart affordance.
/// - onAdd: optional "+ to cart" affordance (defaults to opening the product).
/// - Pressable (pressed-scale) tactile feedback throughout.
class ProductCard extends StatelessWidget {
  final String productId;
  final String name;
  final String? imageUrl;

  /// Money string from API (e.g., "45.50"). NEVER pass a parsed double.
  final String priceTjs;

  /// Struck-through "was" price (money string) — null hides it (Phase 21).
  final String? oldPriceTjs;

  /// Discount percent (0–100) — null hides the badge (Phase 21).
  final int? discountPercent;

  /// Marketing label (e.g. "Хит") — shown when there is no discount badge.
  final String? badge;

  final String? status;
  final VoidCallback? onTap;

  /// Favorite state + toggle. When [onToggleFavorite] is null the heart is hidden.
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  /// "+ to cart" affordance. When null the add button is hidden.
  final VoidCallback? onAdd;

  /// Localized label for the add button (e.g. "В корзину").
  final String? addLabel;

  /// Rating aggregate (Phase 24, C-1). ratingCount == 0 → the rating row is
  /// entirely absent (D-14), not an empty placeholder.
  final double? avgRating;
  final int ratingCount;

  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.priceTjs,
    this.oldPriceTjs,
    this.discountPercent,
    this.badge,
    this.status,
    this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.onAdd,
    this.addLabel,
    this.avgRating,
    this.ratingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final nameStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.3,
      fontSize: 13,
    );
    // Reserve exactly two lines for the name so every card has an identical
    // text-block height — keeps the grid rows even and overflow-proof.
    final nameLineHeight =
        (nameStyle?.fontSize ?? 13) * (nameStyle?.height ?? 1.3);
    final nameBlockHeight =
        MediaQuery.textScalerOf(context).scale(nameLineHeight) * 2;

    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image zone with overlays (badge + heart) ──────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          fadeInDuration: AppMotion.enter,
                          placeholder: (context, url) => const ColoredBox(
                            color: AppColors.bg,
                            child: LoadingDot(),
                          ),
                          errorWidget: (context, url, error) =>
                              const _ImagePlaceholder(),
                        )
                      : const _ImagePlaceholder(),

                  // Discount / marketing badge — top-left (one accent per
                  // component: a single chip wins the spot).
                  if (_badgeText != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _CardBadge(text: _badgeText!),
                    ),

                  // Favorite heart — top-right (optional).
                  if (onToggleFavorite != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _HeartButton(
                        isFavorite: isFavorite,
                        onTap: onToggleFavorite!,
                      ),
                    ),
                ],
              ),
            ),

            // ── Body: name, price (+old), add ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: nameBlockHeight,
                    child: Text(
                      name,
                      style: nameStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ratingCount > 0 && avgRating != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    _RatingLine(
                      avgRating: avgRating!,
                      ratingCount: ratingCount,
                    ),
                  ],
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(child: PriceTag(value: priceTjs, large: true)),
                      if (oldPriceTjs != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          oldPriceTjs!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkFaint,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (onAdd != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    _AddButton(label: addLabel ?? '+', onTap: onAdd!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Discount % wins the badge slot; otherwise fall back to a marketing badge.
  String? get _badgeText {
    if (discountPercent != null && discountPercent! > 0) {
      return '−$discountPercent%';
    }
    if (badge != null && badge!.trim().isNotEmpty) return badge!.trim();
    return null;
  }
}

/// Small pill badge — reference style: near-white surface with GREEN text
/// (the discount/label sits on a light chip, not a solid green fill).
class _CardBadge extends StatelessWidget {
  const _CardBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: AppColors.accentDeep,
        ),
      ),
    );
  }
}

/// Frosted heart toggle button (favorite). Animates the icon swap.
class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.tap,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isFavorite),
              size: 17,
              color: isFavorite ? AppColors.danger : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft-green "add" button matching the reference card CTA.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentPlate,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 15, color: AppColors.accentDeep),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: AppColors.accentDeep,
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

/// Compact catalog rating line (UI-SPEC C-1): `★ 4.6 (12)`. Only rendered by
/// the caller when ratingCount > 0 (D-14 — zero reviews means the row is
/// entirely absent, not an empty placeholder).
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.avgRating, required this.ratingCount});
  final double avgRating;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    final locale =
        _intlNumberLocale(Localizations.localeOf(context).languageCode);
    final formatted = NumberFormat('0.0', locale).format(avgRating);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.rating),
        const SizedBox(width: AppSpace.xs),
        Text(
          formatted,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: AppColors.ink,
          ),
        ),
        Text(
          ' ($ratingCount)',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }

  String _intlNumberLocale(String locale) => locale == 'tg' ? 'ru' : locale;
}

/// Small centered dot-spinner for image placeholders.
class LoadingDot extends StatelessWidget {
  const LoadingDot({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accentBorder),
        ),
      );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.accentPlate,
      child: Center(
        child: Icon(Icons.inventory_2_outlined,
            size: 44, color: AppColors.accentDeep),
      ),
    );
  }
}
