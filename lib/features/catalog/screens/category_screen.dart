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

/// CategoryScreen — products filtered by a specific category.
///
/// Uses its own [categoryProductsProvider] so it never overwrites the shared
/// [catalogProvider] state. This way HomeScreen keeps its full product list
/// when the user navigates back.
class CategoryScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(categoryProductsProvider(categoryId));
    ref.watch(favoritesProvider);
    final favNotifier = ref.read(favoritesProvider.notifier);

    final categories = ref.read(catalogProvider).categories;
    final cat = categories.where((c) => c.id == categoryId).firstOrNull;
    final title = cat?.name ?? l10n.categoryTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: const BackButton(),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (msg, _) => AppErrorWidget(
          error: msg.toString(),
          onRetry: () => ref.invalidate(categoryProductsProvider(categoryId)),
        ),
        data: (products) {
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.noProductsInCategory,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.68,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
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
          );
        },
      ),
    );
  }
}
