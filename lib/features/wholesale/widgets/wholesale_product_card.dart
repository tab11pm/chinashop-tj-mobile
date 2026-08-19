import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../theme/app_tokens.dart';

/// WholesaleProductCard — used in WholesaleCatalogScreen grid.
///
/// Mirrors the B2C ProductCard layout: cream surface, image zone on top,
/// name + PriceTag below. MOQ badge is a Stack/Positioned overlay on the
/// image (top-left, dark b2b-band fill + white text), matching the demo
/// `.wcard .moq` slot — same slot B2C ProductCard uses for its discount badge.
class WholesaleProductCard extends StatelessWidget {
  const WholesaleProductCard({
    super.key,
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.entryPriceTjs,
    required this.moq,
    this.entryTierMinQty,
    this.onTap,
  });

  final String productId;
  final String name;
  final String? imageUrl;

  /// MoneyString from API — never parse to float.
  final String entryPriceTjs;
  final int moq;
  final int? entryTierMinQty;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image zone with MOQ badge overlay (mirrors ProductCard badge slot)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          fadeInDuration: AppMotion.enter,
                          placeholder: (context, url) => const ColoredBox(
                            color: AppColors.accentPlate,
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const _ImagePlaceholder(),
                        )
                      : const _ImagePlaceholder(),

                  // MOQ badge — top-left overlay, dark b2b-band fill, white
                  // text (one-accent-per-component: business-ink wins the slot).
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _MoqChip(moq: moq),
                  ),
                ],
              ),
            ),

            // Body: name, price
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  PriceTag(value: entryPriceTjs, large: true),
                  const SizedBox(height: 7),
                  _TierStrip(minQty: entryTierMinQty ?? moq),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierStrip extends StatelessWidget {
  const _TierStrip({required this.minQty});
  final int minQty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentPlate,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        AppLocalizations.of(context)!.wholesaleTierApplied(minQty),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.accentDeep,
        ),
      ),
    );
  }
}

/// MOQ badge — dark b2b-band fill (#10241B) + white text, absolutely
/// positioned top-left over the product image. Matches `.wcard .moq` in
/// the master demo (font-weight:800, font-size:9.5px, border-radius:7px).
class _MoqChip extends StatelessWidget {
  const _MoqChip({required this.moq});
  final int moq;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.b2bBand,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        AppLocalizations.of(context)!.wholesaleMoqChip(moq),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 9.5,
          color: AppColors.onAccent,
        ),
      ),
    );
  }
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
