import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_lang.dart';
import '../../../core/api/error_messages.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/review_models.dart';

/// State for the review list — used by BOTH the product-screen preview
/// section (first page only) and the full review-list screen (paginated).
///
/// T-24-06 (threat register): this state never computes `avgRating`/histogram
/// counts from the in-memory paginated `items` list — [distribution] always
/// comes verbatim from the server's histogram endpoint response.
class ReviewListState {
  final List<Review> items;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String sort; // 'newest' | 'rating'
  final int? ratingFilter;
  final bool hasPhotosFilter;
  final RatingDistribution? distribution;

  const ReviewListState({
    this.items = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.sort = 'newest',
    this.ratingFilter,
    this.hasPhotosFilter = false,
    this.distribution,
  });

  ReviewListState copyWith({
    List<Review>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    String? sort,
    int? ratingFilter,
    bool clearRatingFilter = false,
    bool? hasPhotosFilter,
    RatingDistribution? distribution,
  }) {
    return ReviewListState(
      items: items ?? this.items,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      sort: sort ?? this.sort,
      ratingFilter:
          clearRatingFilter ? null : (ratingFilter ?? this.ratingFilter),
      hasPhotosFilter: hasPhotosFilter ?? this.hasPhotosFilter,
      distribution: distribution ?? this.distribution,
    );
  }
}

/// ReviewListNotifier — cursor-pagination reader for
/// `GET /api/products/:id/reviews` (+ the histogram companion endpoint).
///
/// autoDispose because this is a per-screen-visit list (mirrors
/// `orderDetailProvider`'s autoDispose rationale) — `.family` keyed by
/// productId so the product screen's preview section and the full list
/// screen share the exact same provider/state per product.
class ReviewListNotifier extends StateNotifier<ReviewListState> {
  final DioClient _client;
  final String _productId;
  final String _locale;

  ReviewListNotifier({
    required DioClient client,
    required String productId,
    required String locale,
  })  : _client = client,
        _productId = productId,
        _locale = locale,
        super(const ReviewListState());

  Map<String, dynamic> get _filterQuery => {
        'sort': state.sort,
        'lang': apiLang(_locale),
        if (state.ratingFilter != null) 'rating': state.ratingFilter,
        if (state.hasPhotosFilter) 'hasPhotos': true,
      };

  /// Resets items/cursor and fetches page 1 + the histogram in parallel.
  Future<void> fetchFirstPage() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: const [],
      clearNextCursor: true,
    );
    try {
      final results = await Future.wait([
        _client.get(
          '/api/products/$_productId/reviews',
          queryParameters: _filterQuery,
        ),
        _client.get(
          '/api/products/$_productId/reviews/histogram',
          queryParameters: {'lang': apiLang(_locale)},
        ),
      ]);

      final page = ReviewPage.fromJson(
        results[0].data as Map<String, dynamic>,
      );
      final distribution = RatingDistribution.fromJson(
        results[1].data as Map<String, dynamic>,
      );

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        items: page.items,
        nextCursor: page.nextCursor,
        clearNextCursor: page.nextCursor == null,
        hasMore: page.nextCursor != null,
        distribution: distribution,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: errorCodeOf(e));
    }
  }

  /// Appends the next page using [ReviewListState.nextCursor]. No-ops if
  /// there is nothing more to load or a fetch is already in flight.
  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoadingMore || state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final res = await _client.get(
        '/api/products/$_productId/reviews',
        queryParameters: {..._filterQuery, 'cursor': state.nextCursor},
      );
      final page = ReviewPage.fromJson(res.data as Map<String, dynamic>);
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        clearNextCursor: page.nextCursor == null,
        hasMore: page.nextCursor != null,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: errorCodeOf(e));
    }
  }

  /// Changing any filter/sort resets the cursor and re-fetches page 1 (per
  /// UI-SPEC C-4: "Changing any filter resets the cursor and scrolls to top").
  Future<void> setSort(String sort) async {
    state = state.copyWith(sort: sort);
    await fetchFirstPage();
  }

  Future<void> setRatingFilter(int? star) async {
    state = state.copyWith(
      ratingFilter: star,
      clearRatingFilter: star == null,
    );
    await fetchFirstPage();
  }

  Future<void> setHasPhotosFilter(bool value) async {
    state = state.copyWith(hasPhotosFilter: value);
    await fetchFirstPage();
  }

  Future<bool> deleteReview(String reviewId) async {
    try {
      await _client.delete('/api/reviews/$reviewId');
      if (mounted) {
        state = state.copyWith(
          items: state.items
              .where((review) => review.id != reviewId)
              .toList(growable: false),
          clearError: true,
        );
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(error: errorCodeOf(e));
      }
      return false;
    }
  }
}

final reviewListProvider = StateNotifierProvider.autoDispose
    .family<ReviewListNotifier, ReviewListState, String>((ref, productId) {
  final client = ref.watch(dioClientProvider);
  final locale = ref.watch(authProvider).locale;
  return ReviewListNotifier(
      client: client, productId: productId, locale: locale)
    ..fetchFirstPage();
});
