import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../catalog/providers/catalog_provider.dart' show Category;
import '../providers/wholesale_provider.dart';
import '../widgets/wholesale_product_card.dart';
import './wholesale_locked_screen.dart' show WholesaleLockedBody;
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_tokens.dart';

/// WholesaleCatalogScreen — wholesale product list for verified sellers.
///
/// UI-SPEC §State Machine — Mobile: WholesaleCatalogScreen states:
///   loading → 403/SELLER_NOT_VERIFIED → empty → data → error
///
/// 403 / SELLER_NOT_VERIFIED gate: replaces the entire body with
/// WholesaleLockedScreen (EmptyState-like with lock icon + apply CTA).
/// The screen itself is accessible by direct URL — guard is API-side (Phase 13).
class WholesaleCatalogScreen extends ConsumerStatefulWidget {
  const WholesaleCatalogScreen({super.key});

  @override
  ConsumerState<WholesaleCatalogScreen> createState() =>
      _WholesaleCatalogScreenState();
}

class _WholesaleCatalogScreenState extends ConsumerState<WholesaleCatalogScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() {
    return ref.read(wholesaleCatalogProvider.notifier).fetch(
          categoryId: _selectedCategoryId,
          q: _searchController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalogAsync = ref.watch(wholesaleCatalogProvider);
    final categoriesAsync = ref.watch(wholesaleCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.wholesaleCatalogTitle),
      ),
      body: Column(
        children: [
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
                          _fetch();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _fetch(),
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: catalogAsync.when(
              loading: () => const LoadingState(),
              error: (err, _) => _buildError(context, ref, err, l10n),
              data: (products) {
                return Column(
                  children: [
                    _CategoryChips(
                      categoriesAsync: categoriesAsync,
                      selectedCategoryId: _selectedCategoryId,
                      onSelected: (categoryId) {
                        setState(() => _selectedCategoryId = categoryId);
                        _fetch();
                      },
                    ),
                    Expanded(
                      child: products.isEmpty
                          ? EmptyState(
                              icon: _searchController.text.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.inventory_2_outlined,
                              title: _searchController.text.isNotEmpty
                                  ? l10n.noProductsFound
                                  : l10n.wholesaleCatalogEmptyTitle,
                              subtitle: _searchController.text.isNotEmpty
                                  ? null
                                  : l10n.wholesaleCatalogEmptyBody,
                            )
                          : RefreshIndicator(
                              onRefresh: _fetch,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(AppSpace.md),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: AppSpace.sm,
                                  mainAxisSpacing: AppSpace.sm,
                                  childAspectRatio: 0.68,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final p = products[index];
                                  return WholesaleProductCard(
                                    productId: p.id,
                                    name: p.name,
                                    imageUrl: p.images.isNotEmpty
                                        ? p.images.first
                                        : null,
                                    entryPriceTjs: p.entryPriceTjs,
                                    moq: p.moq,
                                    entryTierMinQty: p.entryTierMinQty,
                                    onTap: () => context.push(
                                        AppRoutes.wholesaleProductPath(p.id)),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object err,
    AppLocalizations l10n,
  ) {
    // 403 / SELLER_NOT_VERIFIED → WholesaleLockedBody (inline in body, no extra Scaffold)
    if (err is DomainException && err.code == 'SELLER_NOT_VERIFIED') {
      return const WholesaleLockedBody();
    }

    return AppErrorWidget(
      error: err,
      onRetry: _fetch,
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final AsyncValue<List<Category>> categoriesAsync;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categoriesAsync,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = categoriesAsync.when(
      data: (value) => value,
      loading: () => const <Category>[],
      error: (error, stackTrace) => const <Category>[],
    );
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final isSelected = index == 0
              ? selectedCategoryId == null
              : selectedCategoryId == categories[index - 1].id;
          final label = index == 0
              ? l10n.allFilter
              : categories[index - 1].name;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(
                index == 0 ? null : categories[index - 1].id,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ink : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: isSelected ? AppColors.ink : AppColors.line,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.surface : AppColors.inkMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
