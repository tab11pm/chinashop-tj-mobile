import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/wholesale_provider.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_tokens.dart';

/// WholesaleFactoriesScreen — list of active factories for verified sellers.
///
/// Shows all active factories with localized names, or — when [categoryId]
/// is set (navigated from a home-screen category chip) — only factories with
/// an active product in that category. [categoryTitle] overrides the AppBar
/// title to the category name in that case.
/// Tapping a factory navigates to its profile page.
class WholesaleFactoriesScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? categoryTitle;

  const WholesaleFactoriesScreen({super.key, this.categoryId, this.categoryTitle});

  @override
  ConsumerState<WholesaleFactoriesScreen> createState() =>
      _WholesaleFactoriesScreenState();
}

class _WholesaleFactoriesScreenState
    extends ConsumerState<WholesaleFactoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final factoriesAsync = ref.watch(wholesaleFactoriesProvider(widget.categoryId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.categoryTitle ?? l10n.b2bSectionFactories),
      ),
      body: factoriesAsync.when(
        loading: () => const LoadingState(),
        error: (err, _) => _buildError(context, ref, err, l10n),
        data: (factories) {
          return factories.isEmpty
              ? EmptyState(
                  icon: Icons.factory_outlined,
                  title: l10n.wholesaleCatalogEmptyTitle,
                  subtitle: l10n.wholesaleCatalogEmptyBody,
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(wholesaleFactoriesProvider(widget.categoryId).notifier)
                      .fetch(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpace.md),
                    itemCount: factories.length,
                    itemBuilder: (context, index) {
                      final factory = factories[index];
                      return _FactoryCard(
                        id: factory.id,
                        name: factory.name,
                        country: factory.country,
                        onTap: () =>
                            context.push(AppRoutes.wholesaleFactoryPath(factory.id)),
                      );
                    },
                  ),
                );
        },
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object err,
    AppLocalizations l10n,
  ) {
    if (err is DomainException && err.code == 'SELLER_NOT_VERIFIED') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpace.xl),
          child: EmptyState(
            icon: Icons.lock_outline,
            title: 'Access restricted',
            subtitle: 'You need to be a verified seller to view factories.',
          ),
        ),
      );
    }

    return AppErrorWidget(
      error: err,
      onRetry: () => ref
          .read(wholesaleFactoriesProvider(widget.categoryId).notifier)
          .fetch(),
    );
  }
}

/// _FactoryCard — factory list item with name and country.
class _FactoryCard extends StatelessWidget {
  final String id;
  final String name;
  final String? country;
  final VoidCallback onTap;

  const _FactoryCard({
    required this.id,
    required this.name,
    this.country,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentPlate,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: const Icon(
                  Icons.factory,
                  color: AppColors.accentDeep,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    if (country != null && country!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        country!,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
