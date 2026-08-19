import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/catalog_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';

/// CatalogScreen — search + category filter + paginated product grid.
///
/// APP-03: GET /api/products?q=&category=&page=&lang=
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogProvider.notifier).fetchCategories();
      ref.read(catalogProvider.notifier).fetchProducts(page: 1);
      ref.read(favoritesProvider.notifier).fetchFavorites();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(catalogProvider);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !state.isLoadingProducts &&
        state.hasMore) {
      ref.read(catalogProvider.notifier).fetchProducts(
            q: _searchController.text.trim(),
            categoryId: _selectedCategoryId,
            page: state.currentPage + 1,
            reset: false,
          );
    }
  }

  void _search() {
    ref.read(catalogProvider.notifier).fetchProducts(
          q: _searchController.text.trim(),
          categoryId: _selectedCategoryId,
          page: 1,
        );
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    ref.watch(favoritesProvider); // rebuild hearts on favorite changes
    final favNotifier = ref.read(favoritesProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogTitle),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _search(),
              textInputAction: TextInputAction.search,
            ),
          ),

          // Category chips
          if (catalogState.categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: catalogState.categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(l10n.allFilter),
                        selected: _selectedCategoryId == null,
                        onSelected: (_) {
                          setState(() => _selectedCategoryId = null);
                          _search();
                        },
                      ),
                    );
                  }
                  final cat = catalogState.categories[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: _selectedCategoryId == cat.id,
                      onSelected: (_) {
                        setState(() => _selectedCategoryId = cat.id);
                        _search();
                      },
                    ),
                  );
                },
              ),
            ),

          // Product grid
          Expanded(
            child: catalogState.isLoadingProducts && catalogState.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : catalogState.errorProducts != null && catalogState.products.isEmpty
                    ? AppErrorWidget(
                        error: catalogState.errorProducts!,
                        onRetry: _search,
                      )
                    : catalogState.products.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off,
                            title: l10n.noProductsFound,
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(catalogProvider.notifier).fetchProducts(
                                      q: _searchController.text.trim(),
                                      categoryId: _selectedCategoryId,
                                      page: 1,
                                    ),
                            child: GridView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.68,
                              ),
                              itemCount: catalogState.products.length +
                                  (catalogState.isLoadingProducts ? 2 : 0),
                              itemBuilder: (context, index) {
                                if (index >= catalogState.products.length) {
                                  return const Card(
                                    child: Center(
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }
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
                                  onAdd: () =>
                                      context.push(AppRoutes.productPath(p.id)),
                                  onTap: () =>
                                      context.push(AppRoutes.productPath(p.id)),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
