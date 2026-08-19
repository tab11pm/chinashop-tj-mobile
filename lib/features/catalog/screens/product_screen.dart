import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/catalog_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../shared/widgets/price_tag.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';
import '../../../core/api/error_messages.dart';
import '../../reviews/widgets/review_preview_section.dart';

/// ProductScreen — product detail with variants, sticky add-to-cart bar.
class ProductScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  String? _selectedVariantId;
  int _quantity = 1;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesProvider.notifier).fetchFavorites();
      // Load the cart so the CTA knows whether the selected variant is in it.
      ref.read(cartProvider.notifier).fetchCart();
    });
  }

  Future<void> _addToCart(ProductDetail product) async {
    setState(() => _actionError = null);
    final variantId = _selectedVariantId ?? _defaultVariantId(product);
    if (variantId == null) {
      setState(() => _actionError = l10n.selectVariant);
      return;
    }
    try {
      await ref.read(cartProvider.notifier).addItem(
            productId: widget.productId,
            variantId: variantId,
            quantity: _quantity,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addedToCart),
          action: SnackBarAction(
            label: l10n.goToCart,
            onPressed: () => context.go(AppRoutes.cart),
          ),
        ),
      );
    } catch (e) {
      setState(() => _actionError = errorCodeOf(e));
    }
  }

  /// Change the cart line qty in place. Going below 1 removes the line.
  Future<void> _setCartQty(String variantId, int qty) async {
    try {
      if (qty < 1) {
        await ref.read(cartProvider.notifier).removeItem(variantId);
      } else {
        // updateItem is now fire-and-forget (optimistic + debounced) — no await.
        ref
            .read(cartProvider.notifier)
            .updateItem(variantId: variantId, quantity: qty);
      }
    } catch (e) {
      if (mounted) setState(() => _actionError = errorCodeOf(e));
    }
  }

  /// Remove the cart line entirely (the "Remove" button next to the stepper).
  Future<void> _removeFromCart(String variantId) async {
    try {
      await ref.read(cartProvider.notifier).removeItem(variantId);
    } catch (e) {
      if (mounted) setState(() => _actionError = errorCodeOf(e));
    }
  }

  Future<void> _toggleFavorite(bool isFav) async {
    try {
      final notifier = ref.read(favoritesProvider.notifier);
      isFav
          ? await notifier.removeFavorite(widget.productId)
          : await notifier.addFavorite(widget.productId);
    } catch (e) {
      setState(() => _actionError = errorCodeOf(e));
    }
  }

  late AppLocalizations l10n;

  ProductVariant? _selectedVariant(ProductDetail product) {
    if (product.variants.isEmpty) return null;
    return product.variants.firstWhere(
      (variant) => variant.id == _selectedVariantId,
      orElse: () => product.variants.firstWhere((variant) => variant.stock > 0,
          orElse: () => product.variants.first),
    );
  }

  String? _defaultVariantId(ProductDetail product) {
    if (product.variants.isEmpty) return null;
    return product.variants
        .firstWhere((variant) => variant.stock > 0,
            orElse: () => product.variants.first)
        .id;
  }

  String get _characteristicsLabel => l10n.characteristicsLabel;

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detailAsync = ref.watch(productDetailProvider(widget.productId));
    final cartState = ref.watch(cartProvider);
    final isFav = ref
        .watch(favoritesProvider)
        .favorites
        .any((f) => f.productId == widget.productId);
    final product = detailAsync.asData?.value;
    final selectedVariant = product == null ? null : _selectedVariant(product);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productTitle),
        leading: const BackButton(),
        actions: [
          // Favorite heart now lives on the image header (reference Phone B).
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.go(AppRoutes.cart),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const LoadingState(),
        error: (err, _) => AppErrorWidget(
          error: err,
          onRetry: () => ref.refresh(productDetailProvider(widget.productId)),
        ),
        data: (product) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _imageHeader(product, isFav)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        PriceTag(
                          value: product.priceTjs,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            letterSpacing: -0.4,
                            color: AppColors.accentDeep,
                          ),
                        ),
                        if (product.oldPriceTjs != null) ...[
                          const SizedBox(width: AppSpace.md),
                          Text(
                            product.oldPriceTjs!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.inkFaint,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.lg),
                      Text(product.description!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.inkMuted, height: 1.4)),
                    ],
                    if (product.variants.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xl),
                      ..._buildVariantGroups(
                        product: product,
                        selectedVariant: selectedVariant,
                        attributeLabel: _attributeLabel,
                      ),
                    ],
                    if (product.attributes.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xl),
                      _ProductCharacteristics(
                        title: _characteristicsLabel,
                        attributes: product.attributes,
                        attributeLabel: _attributeLabel,
                      ),
                    ],
                    const SizedBox(height: AppSpace.xl),
                    ReviewPreviewSection(
                      productId: widget.productId,
                      productName: product.name,
                      productImageUrl: product.imageUrls.isNotEmpty
                          ? product.imageUrls.first
                          : null,
                    ),
                    if (_actionError != null) ...[
                      const SizedBox(height: AppSpace.lg),
                      AppErrorWidget(error: _actionError!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          product == null ? null : _buildStickyBar(product, cartState),
    );
  }

  Widget _buildStickyBar(ProductDetail product, CartState cartState) {
    // Selected variant (defaults to the first). The CTA reflects whether THIS
    // variant is already in the cart; switching to a not-added variant or a
    // variantless product shows the "Add" stepper again.
    final selectedVariantId = _selectedVariantId ?? _defaultVariantId(product);
    final cartLineIndex = selectedVariantId == null
        ? -1
        : cartState.items.indexWhere((i) => i.variantId == selectedVariantId);
    final cartLine = cartLineIndex >= 0 ? cartState.items[cartLineIndex] : null;

    // In cart → a stepper bound to the cart line's qty (+/- call updateItem,
    // decrement stops at 1) alongside a "Remove" button that deletes the line.
    // Otherwise show the local-quantity stepper + "Add to cart".
    if (cartLine != null && selectedVariantId != null) {
      final cartQty = cartLine.quantity;
      return _StickyBar(
        quantity: cartQty,
        minQuantity: 1,
        onDec: () => _setCartQty(selectedVariantId, cartQty - 1),
        onInc: () => _setCartQty(selectedVariantId, cartQty + 1),
        inCart: true,
        loading: cartState.isLoading,
        addLabel: l10n.addToCart,
        onAdd: () => _addToCart(product),
        removeLabel: l10n.removeFromCart,
        onRemove: () => _removeFromCart(selectedVariantId),
      );
    }

    return _StickyBar(
      quantity: _quantity,
      minQuantity: 1,
      onDec: () =>
          setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
      onInc: () => setState(() => _quantity++),
      inCart: false,
      loading: cartState.isLoading,
      addLabel: l10n.addToCart,
      onAdd: () => _addToCart(product),
    );
  }

  /// Product image header with reference overlays: discount/badge chip
  /// (bottom-left) and a frosted favorite heart (top-right).
  Widget _imageHeader(ProductDetail product, bool isFav) {
    final String? badgeText =
        (product.discountPercent != null && product.discountPercent! > 0)
            ? '−${product.discountPercent}%'
            : (product.badge != null && product.badge!.trim().isNotEmpty
                ? product.badge!.trim()
                : null);

    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProductImageGallery(imageUrls: product.imageUrls),
          if (badgeText != null)
            Positioned(
              left: AppSpace.lg,
              bottom: AppSpace.lg,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.onAccent,
                  ),
                ),
              ),
            ),
          Positioned(
            top: AppSpace.md,
            right: AppSpace.lg,
            child: Material(
              color: Colors.transparent,
              child: InkResponse(
                onTap: () => _toggleFavorite(isFav),
                radius: 26,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.tap,
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(isFav),
                      size: 20,
                      color: isFav ? AppColors.danger : AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _attributeLabel(String key) {
    final normalized = key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final lower = normalized.toLowerCase();
    switch (lower) {
      case 'color':
      case 'colour':
        return l10n.attrColor;
      case 'size':
        return l10n.attrSize;
      case 'material':
        return l10n.attrMaterial;
      case 'weight':
        return l10n.attrWeight;
      case 'brand':
        return l10n.attrBrand;
      case 'model':
        return l10n.attrModel;
      case 'capacity':
        return l10n.attrCapacity;
      case 'storage':
        return l10n.attrStorage;
      case 'variant':
        return l10n.variantLabel;
      default:
        if (normalized.isEmpty) return key;
        return normalized[0].toUpperCase() + normalized.substring(1);
    }
  }

  /// Build grouped variant attribute sections (color swatches + option chips).
  List<Widget> _buildVariantGroups({
    required ProductDetail product,
    required ProductVariant? selectedVariant,
    required String Function(String) attributeLabel,
  }) {
    final groups = _extractVariantGroups(product.variants);
    if (groups.isEmpty) return [];

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      final key = entry.key;
      final values = entry.value;
      final isColor = _isColorAttribute(key);
      final selectedValue = selectedVariant?.attributes[key]?.toString();

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.lg),
          child: _VariantGroupSection(
            label: attributeLabel(key),
            selectedLabel: selectedValue,
            isColor: isColor,
            values: values,
            selectedValue: selectedValue,
            onSelected: (value) {
              // Find the best matching variant for the new selection.
              final newVariant = _findBestVariant(
                product.variants,
                key,
                value,
                selectedVariant,
              );
              if (newVariant != null && newVariant.stock > 0) {
                setState(() => _selectedVariantId = newVariant.id);
              }
            },
          ),
        ),
      );
    }
    return widgets;
  }

  /// Extract unique attribute values per key across all variants,
  /// preserving first-seen order.
  Map<String, List<String>> _extractVariantGroups(
      List<ProductVariant> variants) {
    final groups = <String, List<String>>{};
    for (final variant in variants) {
      for (final entry in variant.attributes.entries) {
        final value = _stringifyAttribute(entry.value);
        if (value == null || value.trim().isEmpty) continue;
        groups.putIfAbsent(entry.key, () => []);
        if (!groups[entry.key]!.contains(value)) {
          groups[entry.key]!.add(value);
        }
      }
    }
    return groups;
  }

  bool _isColorAttribute(String key) {
    final lower = key.toLowerCase();
    return lower == 'color' || lower == 'colour' || lower == 'цвет';
  }

  /// Find the best variant matching a new attribute selection, preferring
  /// the currently selected variant's other attribute values.
  ProductVariant? _findBestVariant(
    List<ProductVariant> variants,
    String changedKey,
    String changedValue,
    ProductVariant? current,
  ) {
    // Prefer: matches changed key + all other current attributes.
    if (current != null) {
      for (final v in variants) {
        if (v.attributes[changedKey]?.toString() == changedValue &&
            _matchesExcept(v.attributes, current.attributes, changedKey)) {
          return v;
        }
      }
    }
    // Fallback: just matches changed key.
    for (final v in variants) {
      if (v.attributes[changedKey]?.toString() == changedValue) {
        return v;
      }
    }
    return null;
  }

  bool _matchesExcept(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    String excludeKey,
  ) {
    for (final entry in a.entries) {
      if (entry.key == excludeKey) continue;
      if (_stringifyAttribute(entry.value) !=
          _stringifyAttribute(b[entry.key])) {
        return false;
      }
    }
    return true;
  }
}

/// Swipeable product gallery used in the detail header. The API preserves the
/// source ordering, so the first image stays the product's primary image.
class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;
    if (images.isEmpty) return const _ImageFallback(height: 320);

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) => Semantics(
            label: 'Product image ${index + 1} of ${images.length}',
            image: true,
            child: CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              fadeInDuration: AppMotion.enter,
              placeholder: (ctx, url) => const ColoredBox(
                color: AppColors.bg,
                child: LoadingState(),
              ),
              errorWidget: (ctx, url, err) => const _ImageFallback(height: 320),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            right: AppSpace.lg,
            bottom: AppSpace.lg,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.56),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  '${_currentIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        color: AppColors.accentPlate,
        child: const Center(
          child: Icon(Icons.inventory_2_outlined,
              size: 72, color: AppColors.accentDeep),
        ),
      );
}

/// A variant attribute group — renders as color swatches or option chips.
class _VariantGroupSection extends StatelessWidget {
  const _VariantGroupSection({
    required this.label,
    required this.selectedLabel,
    required this.isColor,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final String? selectedLabel;
  final bool isColor;
  final List<String> values;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: theme.textTheme.titleSmall),
            const SizedBox(width: AppSpace.sm),
            if (selectedLabel != null)
              Text(
                selectedLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        isColor
            ? _ColorSwatches(
                values: values,
                selected: selectedValue,
                onSelected: onSelected,
              )
            : _OptionChips(
                values: values,
                selected: selectedValue,
                onSelected: onSelected,
              ),
      ],
    );
  }
}

/// Color swatch selector — colored circles matching the design mockup.
class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  static const _colorMap = <String, Color>{
    'чёрный': Color(0xFF1A2B23),
    'black': Color(0xFF1A2B23),
    'белый': Color(0xFFF5F5F0),
    'white': Color(0xFFF5F5F0),
    'синий': Color(0xFF2BA0FF),
    'blue': Color(0xFF2BA0FF),
    'красный': Color(0xFFFF705D),
    'red': Color(0xFFFF705D),
    'зелёный': Color(0xFF22C55E),
    'green': Color(0xFF22C55E),
    'серый': Color(0xFF9CA3AF),
    'grey': Color(0xFF9CA3AF),
    'gray': Color(0xFF9CA3AF),
    'розовый': Color(0xFFF472B6),
    'pink': Color(0xFFF472B6),
    'жёлтый': Color(0xFFFBBF24),
    'yellow': Color(0xFFFBBF24),
    'коричневый': Color(0xFF92400E),
    'brown': Color(0xFF92400E),
    'оранжевый': Color(0xFFF97316),
    'orange': Color(0xFFF97316),
    'фиолетовый': Color(0xFF8B5CF6),
    'purple': Color(0xFF8B5CF6),
  };

  Color _resolveColor(String value) {
    final lower = value.toLowerCase().trim();
    return _colorMap[lower] ?? _hashColor(value);
  }

  Color _hashColor(String value) {
    final hash = value.hashCode;
    return Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.md,
      runSpacing: AppSpace.sm,
      children: [
        for (final value in values)
          GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: AppMotion.tap,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _resolveColor(value),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == value
                      ? AppColors.accent
                      : AppColors.line,
                  width: selected == value ? 2 : 1,
                ),
                boxShadow: selected == value
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: selected == value
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Option chip selector — text chips for non-color attributes.
class _OptionChips extends StatelessWidget {
  const _OptionChips({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final value in values)
          GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: AppMotion.tap,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected == value
                    ? AppColors.accentPlate
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.control),
                border: Border.all(
                  color: selected == value
                      ? AppColors.accent
                      : AppColors.line,
                  width: selected == value ? 1.5 : 1,
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selected == value
                      ? AppColors.accentDeep
                      : AppColors.ink,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductCharacteristics extends StatelessWidget {
  const _ProductCharacteristics({
    required this.title,
    required this.attributes,
    required this.attributeLabel,
  });

  final String title;
  final Map<String, dynamic> attributes;
  final String Function(String key) attributeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _displayAttributes(attributes).entries.toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpace.sm),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _CharacteristicRow(
                  label: attributeLabel(rows[i].key),
                  value: rows[i].value,
                  showDivider: i < rows.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CharacteristicRow extends StatelessWidget {
  const _CharacteristicRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, String> _displayAttributes(Map<String, dynamic> attributes) {
  final entries = <String, String>{};
  const hidden = {
    'sourceName',
    'sourceDescription',
    'oldPriceTjs',
    'discountPercent',
    'badge',
  };
  for (final entry in attributes.entries) {
    if (hidden.contains(entry.key)) continue;
    final value = _stringifyAttribute(entry.value);
    if (value == null || value.trim().isEmpty) continue;
    entries[entry.key] = value;
  }
  return entries;
}

String? _stringifyAttribute(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value
        .map(_stringifyAttribute)
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .join(', ');
  }
  if (value is Map) {
    return value.entries
        .map((entry) {
          final nested = _stringifyAttribute(entry.value);
          return nested == null || nested.trim().isEmpty
              ? null
              : '${entry.key}: $nested';
        })
        .whereType<String>()
        .join(', ');
  }
  return value.toString();
}

/// Sticky bottom bar.
///
/// Not in cart: local-quantity stepper + full-width "Add to cart" CTA.
/// In cart: a stepper bound to the CART line's qty (+/- call updateItem, the
/// decrement stops at [minQuantity]) next to a "Remove" button that deletes the
/// line. The count is driven by the re-fetched cart line, so it stays synced.
class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.quantity,
    required this.minQuantity,
    required this.onDec,
    required this.onInc,
    required this.inCart,
    required this.loading,
    required this.addLabel,
    required this.onAdd,
    this.removeLabel,
    this.onRemove,
  });

  final int quantity;
  final int minQuantity;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final bool inCart;
  final bool loading;
  final String addLabel;
  final VoidCallback onAdd;
  final String? removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
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
        child: Row(
          children: [
            _Stepper(
              quantity: quantity,
              decEnabled: !loading && quantity > minQuantity,
              incEnabled: !loading,
              onDec: onDec,
              onInc: onInc,
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
                          foregroundColor: Colors.white,
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
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.onDec,
    required this.onInc,
    required this.decEnabled,
    required this.incEnabled,
  });
  final int quantity;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final bool decEnabled;
  final bool incEnabled;

  @override
  Widget build(BuildContext context) {
    final count = AnimatedSwitcher(
      duration: AppMotion.tap,
      child: SizedBox(
        key: ValueKey(quantity),
        width: 28,
        child: Text('$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
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
          _btn(Icons.remove, onDec, enabled: decEnabled),
          count,
          _btn(Icons.add, onInc, enabled: incEnabled),
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
