import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart'; // dioClientProvider
import '../models/review_models.dart';

/// Phase 24 Plan 03 (D-02): matches
/// `ReviewsService.getEligibility()` — `GET /api/reviews/eligibility?productId=`
/// response shape exactly:
///   { eligibleOrderItems: [{orderItemId, orderId, orderCreatedAt}],
///     reviewedOrderItemIds: [string],
///     reviewedReviews: [{id, orderItemId}] }
///
/// Never throws on an empty result server-side; on any client error
/// (including 401 for unauthenticated users) [reviewEligibilityProvider]
/// surfaces an `AsyncValue.error`. Review callers treat loading/error as
/// unknown ownership (no owner/report actions) and expose retry on error.
class EligibleOrderItem {
  final String orderItemId;
  final String orderId;
  final String orderCreatedAt;

  const EligibleOrderItem({
    required this.orderItemId,
    required this.orderId,
    required this.orderCreatedAt,
  });

  factory EligibleOrderItem.fromJson(Map<String, dynamic> json) {
    return EligibleOrderItem(
      orderItemId: json['orderItemId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderCreatedAt: json['orderCreatedAt']?.toString() ?? '',
    );
  }
}

class ReviewEligibility {
  final List<EligibleOrderItem> eligibleOrderItems;
  final List<String> reviewedOrderItemIds;
  final List<OwnReview> reviewedReviews;

  const ReviewEligibility({
    required this.eligibleOrderItems,
    required this.reviewedOrderItemIds,
    this.reviewedReviews = const [],
  });

  factory ReviewEligibility.fromJson(Map<String, dynamic> json) {
    return ReviewEligibility(
      eligibleOrderItems: (json['eligibleOrderItems'] as List<dynamic>?)
              ?.map(
                  (e) => EligibleOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      reviewedOrderItemIds: (json['reviewedOrderItemIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      reviewedReviews: (json['reviewedReviews'] as List<dynamic>?)
              ?.map((e) => OwnReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// True when [orderItemId] appears in [eligibleOrderItems].
  bool isOrderItemEligible(String orderItemId) =>
      eligibleOrderItems.any((item) => item.orderItemId == orderItemId);

  /// True when [orderItemId] already has a review by the caller.
  bool isOrderItemReviewed(String orderItemId) =>
      reviewedOrderItemIds.contains(orderItemId);

  OwnReview? ownReviewById(String reviewId) {
    for (final ownReview in reviewedReviews) {
      if (ownReview.review.id == reviewId) return ownReview;
    }
    return null;
  }
}

/// GET /api/reviews/eligibility?productId= — autoDispose.family keyed by
/// productId, matching the request-scoped lifetime of [reviewListProvider].
final reviewEligibilityProvider = FutureProvider.autoDispose
    .family<ReviewEligibility, String>((ref, productId) async {
  final client = ref.watch(dioClientProvider);
  final res = await client.get(
    '/api/reviews/eligibility',
    queryParameters: {'productId': productId},
  );
  return ReviewEligibility.fromJson(res.data as Map<String, dynamic>);
});

List<Review> mergeOwnReviewsFirst(
  List<Review> publicReviews,
  ReviewEligibility? eligibility,
) {
  final ownReviews = eligibility?.reviewedReviews ?? const <OwnReview>[];
  if (ownReviews.isEmpty) return publicReviews;

  final publicReviewsById = {
    for (final review in publicReviews) review.id: review,
  };
  final ownIds = ownReviews.map((own) => own.review.id).toSet();
  return [
    for (final own in ownReviews)
      publicReviewsById[own.review.id] ?? own.review,
    for (final review in publicReviews)
      if (!ownIds.contains(review.id)) review,
  ];
}
