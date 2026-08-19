import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/catalog_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';

/// HomeScreen — main app landing page.
///
/// APP-03: Shows featured products (GET /api/products?page=1&lang=locale).
/// Bottom nav links to /catalog, /cart, /orders, /favorites, /profile.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogProvider.notifier).fetchProducts(page: 1);
      ref.read(catalogProvider.notifier).fetchCategories();
      ref.read(favoritesProvider.notifier).fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogState = ref.watch(catalogProvider);
    ref.watch(favoritesProvider); // rebuild hearts on favorite changes
    final favNotifier = ref.read(favoritesProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push(AppRoutes.favorites),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(catalogProvider.notifier).fetchProducts(page: 1),
        child: CustomScrollView(
          slivers: [
            // Search bar — visible soft block (reference "storybook" header).
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.sm),
                child: _SearchBar(
                  hint: l10n.searchHint,
                  onTap: () => context.go(AppRoutes.catalog),
                ),
              ),
            ),

            // Hero / streak banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.md),
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentHover],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.card_giftcard_outlined,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.onboardingTitle,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.onboardingSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categories row
            if (catalogState.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(l10n.categories, style: theme.textTheme.titleLarge),
                    ),
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: catalogState.categories.length,
                        itemBuilder: (context, index) {
                          final cat = catalogState.categories[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              label: Text(cat.name),
                              onPressed: () =>
                                  context.push(AppRoutes.categoryPath(cat.id)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // New arrivals header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.newArrivals, style: theme.textTheme.titleLarge),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.catalog),
                      child: Text(l10n.seeAll),
                    ),
                  ],
                ),
              ),
            ),

            // Products
            if (catalogState.isLoadingProducts && catalogState.products.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (catalogState.errorProducts != null && catalogState.products.isEmpty)
              SliverFillRemaining(
                child: AppErrorWidget(
                  error: catalogState.errorProducts!,
                  onRetry: () =>
                      ref.read(catalogProvider.notifier).fetchProducts(page: 1),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = catalogState.products[index];
                      final isFav = favNotifier.isFavorite(p.id);
                      return ProductCard(
                        productId: p.id,
                        name: p.name,
                        imageUrl: p.imageUrl,
                        priceTjs: p.priceTjs,
                        oldPriceTjs: p.oldPriceTjs,
                        discountPercent: p.discountPercent,
                        badge: p.badge,
                        avgRating: p.avgRating,
                        ratingCount: p.ratingCount,
                        isFavorite: isFav,
                        onToggleFavorite: () {
                          if (isFav) {
                            favNotifier.removeFavorite(p.id);
                          } else {
                            favNotifier.addFavorite(p.id);
                          }
                        },
                        addLabel: l10n.addToCart,
                        onAdd: () => context.push(AppRoutes.productPath(p.id)),
                        onTap: () => context.push(AppRoutes.productPath(p.id)),
                      );
                    },
                    childCount: catalogState.products.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

/// Soft, tappable search field that routes to the catalog (reference header).
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.image),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 19, color: AppColors.inkFaint),
            const SizedBox(width: AppSpace.sm),
            Text(
              hint,
              style: const TextStyle(
                color: AppColors.inkFaint,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
