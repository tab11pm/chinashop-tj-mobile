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
import '../providers/review_eligibility_provider.dart';
import '../providers/review_form_provider.dart';
import '../providers/review_list_provider.dart';
import '../providers/review_report_provider.dart';
import '../widgets/report_bottom_sheet.dart';
import '../widgets/review_card.dart';
import '../widgets/star_rating_display.dart';

/// ReviewPreviewSection — product-screen embedded section (UI-SPEC C-3).
///
/// Watches [reviewListProvider] (the SAME provider used by the full list
/// screen — first page only, sort=newest is the provider's default) for the
/// "2 latest reviews" and its distribution for the aggregate count. Manages
/// its own async state independently — a slow/failed review fetch must not
/// block the whole product screen (RESEARCH.md guidance).
///
/// This task does NOT render the "Оценить товар" write button — that ships
/// in 24-03, which depends on this file's structure but adds the
/// eligibility-gated CTA. See the TODO insertion comment below.
class ReviewPreviewSection extends ConsumerWidget {
  final String productId;

  /// Needed only to populate [ReviewFormArgs] when the eligibility-gated
  /// write CTA below navigates to the review form (Phase 24 Plan 03).
  final String productName;
  final String? productImageUrl;

  const ReviewPreviewSection({
    super.key,
    required this.productId,
    required this.productName,
    this.productImageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(reviewListProvider(productId));
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final dateLocale = Localizations.localeOf(context).languageCode;
    final myReportsAsync =
        isAuthenticated ? ref.watch(myReportsProvider(productId)) : null;
    final myReports = myReportsAsync?.asData?.value ?? const <MyReport>[];
    final eligibilityAsync = isAuthenticated
        ? ref.watch(reviewEligibilityProvider(productId))
        : null;
    // Keep the last confirmed owner/non-owner result across a failed refresh.
    final eligibility = eligibilityAsync?.value;
    final ownershipLookupFailed = eligibilityAsync?.hasError ?? false;

    if (state.isLoading && state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return AppErrorWidget(
        error: state.error!,
        onRetry: () =>
            ref.read(reviewListProvider(productId).notifier).fetchFirstPage(),
      );
    }

    final reviews = mergeOwnReviewsFirst(state.items, eligibility);
    final distribution = state.distribution;
    final totalCount = distribution?.totalCount ?? 0;

    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmptyState(
              icon: Icons.reviews_outlined,
              title: l10n.reviewsEmptyTitle,
              subtitle: l10n.reviewsEmptySubtitle,
            ),
            if (ownershipLookupFailed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(reviewEligibilityProvider(productId)),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retryButton),
                ),
              ),
            _WriteReviewCta(
              productId: productId,
              productName: productName,
              productImageUrl: productImageUrl,
            ),
          ],
        ),
      );
    }

    // Average across the visible distribution (server-provided counts only —
    // T-24-06: never computed from the in-memory paginated `items` list).
    double avgRating = 0;
    if (distribution != null && totalCount > 0) {
      var weighted = 0;
      for (final entry in distribution.counts.entries) {
        weighted += entry.key * entry.value;
      }
      avgRating = weighted / totalCount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(l10n.reviewsSectionTitle, style: theme.textTheme.titleLarge),
            const SizedBox(width: AppSpace.sm),
            Text(l10n.reviewCountLabel(totalCount),
                style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            StarRatingDisplay(rating: avgRating, size: 20),
            const SizedBox(width: AppSpace.sm),
            Text(
              avgRating.toStringAsFixed(1),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(l10n.reviewCountLabel(totalCount),
                style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        if (ownershipLookupFailed)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  ref.invalidate(reviewEligibilityProvider(productId)),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retryButton),
            ),
          ),
        for (final review in reviews.take(2)) ...[
          Builder(builder: (context) {
            final existingReport = _reportFor(myReports, review.id);
            final ownReview = eligibility?.ownReviewById(review.id);
            final canReport =
                isAuthenticated && eligibility != null && ownReview == null;
            return ReviewCard(
              review: review,
              isOwnReview: ownReview != null,
              isAuthenticated: canReport,
              isReported: existingReport != null,
              maxLines: 3,
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
                          productId: productId,
                          productName: productName,
                          productImageUrl: productImageUrl,
                          orderItemId: ownReview.orderItemId,
                          existingReview: ownReview.review,
                        ),
                      ),
              onDelete: ownReview == null
                  ? null
                  : () async {
                      final deleted = await ref
                          .read(reviewListProvider(productId).notifier)
                          .deleteReview(review.id);
                      if (!context.mounted) return;
                      if (!deleted) {
                        final error =
                            ref.read(reviewListProvider(productId)).error;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(localizedError(context, error))),
                        );
                        return;
                      }
                      ref.invalidate(reviewEligibilityProvider(productId));
                      ref.invalidate(myReportsProvider(productId));
                      unawaited(ref
                          .read(reviewListProvider(productId).notifier)
                          .fetchFirstPage());
                    },
              onReport: () => showReportBottomSheet(
                context,
                ref,
                reviewId: review.id,
                productId: productId,
                existingReport: existingReport,
              ),
              ownReviewLabel: l10n.reviewOpenExistingCta,
              editLabel: l10n.reviewFormTitleEdit,
              deleteLabel: l10n.deleteConfirmButton,
              reportLabel: l10n.reportMenuItem,
              changeReportLabel: l10n.editReportMenuItem,
              reportedLabel: l10n.reportedMarkerLabel,
              dateLocale: dateLocale,
            );
          }),
          const SizedBox(height: AppSpace.md),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push(AppRoutes.reviewListPath(productId)),
            child: Text(l10n.seeAllReviewsBtn(totalCount)),
          ),
        ),
        _WriteReviewCta(
          productId: productId,
          productName: productName,
          productImageUrl: productImageUrl,
        ),
      ],
    );
  }
}

/// Returns the caller's own report for [reviewId], if any — used to
/// pre-fill the report bottom sheet on re-open ("Изменить жалобу").
MyReport? _reportFor(List<MyReport> reports, String reviewId) {
  for (final report in reports) {
    if (report.reviewId == reviewId) return report;
  }
  return null;
}

/// Eligibility-gated "Оценить товар" CTA (D-02/D-03). Renders nothing on
/// loading/error/not-eligible — never a disabled state, never a hint, per
/// D-03. Uses the FIRST (oldest) eligible order-item (Open Question 1
/// default) when multiple delivered order-items for this product are open
/// to review.
class _WriteReviewCta extends ConsumerWidget {
  const _WriteReviewCta({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
  });

  final String productId;
  final String productName;
  final String? productImageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eligibilityAsync = ref.watch(reviewEligibilityProvider(productId));

    return eligibilityAsync.when(
      data: (eligibility) {
        if (eligibility.eligibleOrderItems.isEmpty) {
          return const SizedBox.shrink();
        }
        final orderItemId = eligibility.eligibleOrderItems.first.orderItemId;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpace.md),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(
                AppRoutes.reviewForm,
                extra: ReviewFormArgs(
                  productId: productId,
                  productName: productName,
                  productImageUrl: productImageUrl,
                  orderItemId: orderItemId,
                ),
              ),
              child: Text(l10n.reviewEntryCta),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
