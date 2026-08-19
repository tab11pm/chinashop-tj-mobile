import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/favorites_provider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';

/// FavoritesScreen — grid of favorited products.
///
/// APP-03:
///   GET /api/favorites
///   DELETE /api/favorites/{productId}
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesProvider.notifier).fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favState = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favoritesTitle),
        leading: const BackButton(),
      ),
      body: favState.isLoading && favState.favorites.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : favState.error != null && favState.favorites.isEmpty
              ? AppErrorWidget(
                  error: favState.error!,
                  onRetry: () =>
                      ref.read(favoritesProvider.notifier).fetchFavorites(),
                )
              : favState.favorites.isEmpty
                  ? EmptyState(
                      icon: Icons.favorite_border,
                      title: l10n.favoritesEmpty,
                      actionLabel: l10n.browseCatalog,
                      onAction: () => context.go(AppRoutes.catalog),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(favoritesProvider.notifier).fetchFavorites(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: favState.favorites.length,
                        itemBuilder: (context, index) {
                          final fav = favState.favorites[index];
                          final p = fav.product;
                          // Everything here is a favorite → heart filled; tapping
                          // it removes (the card's own heart replaces the old
                          // separate remove button).
                          return ProductCard(
                            productId: fav.productId,
                            name: p.name,
                            imageUrl: p.imageUrl,
                            priceTjs: p.priceTjs,
                            oldPriceTjs: p.oldPriceTjs,
                            discountPercent: p.discountPercent,
                            badge: p.badge,
                            avgRating: p.avgRating,
                            ratingCount: p.ratingCount,
                            isFavorite: true,
                            onToggleFavorite: () => ref
                                .read(favoritesProvider.notifier)
                                .removeFavorite(fav.productId),
                            onTap: () =>
                                context.push(AppRoutes.productPath(fav.productId)),
                          );
                        },
                      ),
                    ),
    );
  }
}
