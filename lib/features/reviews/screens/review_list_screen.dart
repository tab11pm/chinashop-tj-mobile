import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../theme/app_tokens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/review_models.dart';
import '../providers/review_eligibility_provider.dart';
import '../providers/review_form_provider.dart';
import '../providers/review_list_provider.dart';
import '../providers/review_report_provider.dart';
import '../widgets/rating_histogram.dart';
import '../widgets/report_bottom_sheet.dart';
import '../widgets/review_card.dart';
import '../widgets/star_rating_display.dart';

/// ReviewListScreen — full paginated review list (UI-SPEC C-4).
///
/// Rating summary block (average + star row + count + tappable histogram)
/// + horizontally-scrollable sort/filter chip row + infinite-scroll review
/// cards, prefetching the next cursor page ~600px before the list end.
class ReviewListScreen extends ConsumerStatefulWidget {
  final String productId;

  const ReviewListScreen({super.key, required this.productId});

  @override
  ConsumerState<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends ConsumerState<ReviewListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(reviewListProvider(widget.productId).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(reviewListProvider(widget.productId));
    final notifier = ref.read(reviewListProvider(widget.productId).notifier);
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final dateLocale = Localizations.localeOf(context).languageCode;
    final hasActiveFilters = state.ratingFilter != null ||
        state.hasPhotosFilter ||
        state.sort != 'newest';
    final myReportsAsync =
        isAuthenticated ? ref.watch(myReportsProvider(widget.productId)) : null;
    final myReports = myReportsAsync?.asData?.value ?? const <MyReport>[];
    final eligibilityAsync = isAuthenticated
        ? ref.watch(reviewEligibilityProvider(widget.productId))
        : null;
    // AsyncValue.value retains the last confirmed ownership result during a
    // failed refresh. A first-load error still yields null (unknown).
    final eligibility = eligibilityAsync?.value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.allReviewsTitle, style: theme(context).headlineSmall),
      ),
      body: _buildBody(
        context: context,
        l10n: l10n,
        state: state,
        notifier: notifier,
        isAuthenticated: isAuthenticated,
        dateLocale: dateLocale,
        hasActiveFilters: hasActiveFilters,
        myReports: myReports,
        eligibility: eligibility,
        ownershipLookupFailed: eligibilityAsync?.hasError ?? false,
        onRetryOwnership: () =>
            ref.invalidate(reviewEligibilityProvider(widget.productId)),
      ),
    );
  }

  TextTheme theme(BuildContext context) => Theme.of(context).textTheme;

  /// Returns the caller's own report for [reviewId], if any — used to
  /// pre-fill the report bottom sheet on re-open ("Изменить жалобу").
  MyReport? _reportFor(List<MyReport> reports, String reviewId) {
    for (final report in reports) {
      if (report.reviewId == reviewId) return report;
    }
    return null;
  }

  Widget _buildBody({
    required BuildContext context,
    required AppLocalizations l10n,
    required ReviewListState state,
    required ReviewListNotifier notifier,
    required bool isAuthenticated,
    required String dateLocale,
    required bool hasActiveFilters,
    required List<MyReport> myReports,
    required ReviewEligibility? eligibility,
    required bool ownershipLookupFailed,
    required VoidCallback onRetryOwnership,
  }) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpace.lg),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpace.lg),
        itemBuilder: (context, index) => const _SkeletonCard(),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return AppErrorWidget(
        error: state.error!,
        onRetry: notifier.fetchFirstPage,
      );
    }

    final reviews = mergeOwnReviewsFirst(state.items, eligibility);

    if (reviews.isEmpty && hasActiveFilters) {
      return EmptyState(
        icon: Icons.reviews_outlined,
        title: l10n.reviewsEmptyFilteredTitle,
        subtitle: l10n.reviewsEmptyFilteredSubtitle,
        actionLabel: l10n.resetFiltersBtn,
        onAction: () async {
          await notifier.setRatingFilter(null);
          await notifier.setHasPhotosFilter(false);
          await notifier.setSort('newest');
        },
      );
    }

    if (reviews.isEmpty) {
      return EmptyState(
        icon: Icons.reviews_outlined,
        title: l10n.reviewsEmptyTitle,
        subtitle: l10n.reviewsEmptySubtitle,
      );
    }

    final distribution = state.distribution;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: _RatingSummary(
              distribution: distribution,
              selectedStar: state.ratingFilter,
              onSelectStar: notifier.setRatingFilter,
              l10n: l10n,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: _FilterChipRow(
              l10n: l10n,
              sort: state.sort,
              ratingFilter: state.ratingFilter,
              hasPhotosFilter: state.hasPhotosFilter,
              onSetSort: notifier.setSort,
              onSetRatingFilter: notifier.setRatingFilter,
              onSetHasPhotosFilter: notifier.setHasPhotosFilter,
            ),
          ),
        ),
        if (ownershipLookupFailed)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onRetryOwnership,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retryButton),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpace.lg)),
        SliverList.separated(
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpace.lg),
          itemBuilder: (context, index) {
            final review = reviews[index];
            final existingReport = _reportFor(myReports, review.id);
            final ownReview = eligibility?.ownReviewById(review.id);
            final canReport =
                isAuthenticated && eligibility != null && ownReview == null;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: ReviewCard(
                review: review,
                isOwnReview: ownReview != null,
                isAuthenticated: canReport,
                isReported: existingReport != null,
                onTapPhoto: (photoIndex) => context.push(
                  AppRoutes.photoGallery,
                  extra: PhotoGalleryArgs(
                    photos: review.photos,
                    startIndex: photoIndex,
                  ),
                ),
                onEdit: ownReview == null
                    ? null
                    : () => context.push(
                          AppRoutes.reviewForm,
                          extra: ReviewFormArgs(
                            productId: widget.productId,
                            productName: l10n.productTitle,
                            productImageUrl: null,
                            orderItemId: ownReview.orderItemId,
                            existingReview: ownReview.review,
                          ),
                        ),
                onDelete: ownReview == null
                    ? null
                    : () async {
                        final deleted = await notifier.deleteReview(review.id);
                        if (!context.mounted) return;
                        if (!deleted) {
                          final error = ref
                              .read(reviewListProvider(widget.productId))
                              .error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(localizedError(context, error))),
                          );
                          return;
                        }
                        ref.invalidate(
                          reviewEligibilityProvider(widget.productId),
                        );
                        ref.invalidate(myReportsProvider(widget.productId));
                        unawaited(notifier.fetchFirstPage());
                      },
                onReport: () => showReportBottomSheet(
                  context,
                  ref,
                  reviewId: review.id,
                  productId: widget.productId,
                  existingReport: existingReport,
                ),
                ownReviewLabel: l10n.reviewOpenExistingCta,
                editLabel: l10n.reviewFormTitleEdit,
                deleteLabel: l10n.deleteConfirmButton,
                reportLabel: l10n.reportMenuItem,
                changeReportLabel: l10n.editReportMenuItem,
                reportedLabel: l10n.reportedMarkerLabel,
                dateLocale: dateLocale,
              ),
            );
          },
        ),
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.accent),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xl)),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.distribution,
    required this.selectedStar,
    required this.onSelectStar,
    required this.l10n,
  });

  final RatingDistribution? distribution;
  final int? selectedStar;
  final ValueChanged<int?> onSelectStar;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final total = distribution?.totalCount ?? 0;
    double avgRating = 0;
    if (distribution != null && total > 0) {
      var weighted = 0;
      for (final entry in distribution!.counts.entries) {
        weighted += entry.key * entry.value;
      }
      avgRating = weighted / total;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  height: 1.1,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              StarRatingDisplay(rating: avgRating, size: 20),
              const SizedBox(height: AppSpace.xs),
              Text(l10n.reviewCountLabel(total),
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.lg),
        Expanded(
          flex: 2,
          child: distribution == null
              ? const SizedBox.shrink()
              : RatingHistogram(
                  distribution: distribution!,
                  selectedStar: selectedStar,
                  onSelectStar: onSelectStar,
                ),
        ),
      ],
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.l10n,
    required this.sort,
    required this.ratingFilter,
    required this.hasPhotosFilter,
    required this.onSetSort,
    required this.onSetRatingFilter,
    required this.onSetHasPhotosFilter,
  });

  final AppLocalizations l10n;
  final String sort;
  final int? ratingFilter;
  final bool hasPhotosFilter;
  final ValueChanged<String> onSetSort;
  final ValueChanged<int?> onSetRatingFilter;
  final ValueChanged<bool> onSetHasPhotosFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.sortNewestChip),
            selected: sort == 'newest',
            onSelected: (_) => onSetSort('newest'),
          ),
          const SizedBox(width: AppSpace.sm),
          ChoiceChip(
            label: Text(l10n.sortRatingChip),
            selected: sort == 'rating',
            onSelected: (_) => onSetSort('rating'),
          ),
          const SizedBox(width: AppSpace.sm),
          for (var star = 5; star >= 1; star--) ...[
            ChoiceChip(
              label: Text('$star★'),
              selected: ratingFilter == star,
              onSelected: (selected) =>
                  onSetRatingFilter(selected ? star : null),
            ),
            const SizedBox(width: AppSpace.sm),
          ],
          ChoiceChip(
            label: Text(l10n.hasPhotosChip),
            selected: hasPhotosFilter,
            onSelected: onSetHasPhotosFilter,
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
      ),
    );
  }
}
