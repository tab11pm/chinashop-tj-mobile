/// Reviews feature data models — plain `fromJson` classes, no part/codegen
/// (matches ProductDetail/OrderItem style elsewhere in this codebase).
///
/// `Review.author` is nullable — this is a DELIBERATE, required part of the
/// contract, not an oversight. The read-path list/histogram endpoints
/// (`GET /api/products/:id/reviews`) always include `author: {displayName}`,
/// but the write-path endpoints (`POST`/`PATCH /api/reviews`, backed by
/// `publicReviewSelect` in `apps/api/src/reviews/reviews.service.ts`) exclude
/// both `author` and owner-only association IDs. `Review.fromJson` MUST
/// tolerate an absent/null `author` key so write responses can be parsed
/// through this same model without throwing (24-03 write flow).
library;

class ReviewPhoto {
  final String id;
  final String url;

  const ReviewPhoto({required this.id, required this.url});

  factory ReviewPhoto.fromJson(Map<String, dynamic> json) {
    return ReviewPhoto(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

class ReviewAuthor {
  final String displayName;

  const ReviewAuthor({required this.displayName});

  factory ReviewAuthor.fromJson(Map<String, dynamic> json) {
    return ReviewAuthor(
      displayName: json['displayName']?.toString() ?? '',
    );
  }
}

class Review {
  final String id;
  final int rating;
  final String? text;
  final String language;
  final String createdAt; // ISO string — formatted via intl at render time.

  /// Nullable — see file-level doc comment. Within THIS plan's scope
  /// (review_list_provider.dart only ever calls the read-path list/histogram
  /// endpoints) `author` is always populated in practice, but every renderer
  /// must still null-guard rather than force-unwrap.
  final ReviewAuthor? author;
  final List<ReviewPhoto> photos;

  const Review({
    required this.id,
    required this.rating,
    this.text,
    required this.language,
    required this.createdAt,
    this.author,
    this.photos = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      // Integer rating — never money-string rules, never double.parse.
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      text: json['text']?.toString(),
      language: json['language']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      author: json['author'] == null
          ? null
          : ReviewAuthor.fromJson(json['author'] as Map<String, dynamic>),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => ReviewPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class OwnReview {
  final String orderItemId;
  final Review review;

  const OwnReview({required this.orderItemId, required this.review});

  factory OwnReview.fromJson(Map<String, dynamic> json) {
    return OwnReview(
      orderItemId: json['orderItemId']?.toString() ?? '',
      review: Review.fromJson(json),
    );
  }
}

/// Per-star (5..1) review count distribution, from
/// `GET /api/products/:id/reviews/histogram` — shape `{"5":n,"4":n,...,"1":n}`
/// (string keys from JSON, converted to int keys here).
class RatingDistribution {
  final Map<int, int> counts;

  const RatingDistribution({required this.counts});

  factory RatingDistribution.fromJson(Map<String, dynamic> json) {
    final counts = <int, int>{};
    for (final entry in json.entries) {
      final star = int.tryParse(entry.key);
      if (star == null) continue;
      counts[star] = (entry.value as num?)?.toInt() ?? 0;
    }
    return RatingDistribution(counts: counts);
  }

  int countFor(int star) => counts[star] ?? 0;

  int get totalCount => counts.values.fold(0, (sum, c) => sum + c);
}

/// Page wrapper matching `GET /api/products/:id/reviews` response shape
/// `{items, nextCursor}`.
class ReviewPage {
  final List<Review> items;
  final String? nextCursor;

  const ReviewPage({required this.items, this.nextCursor});

  factory ReviewPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <Review>[];
    return ReviewPage(
      items: items,
      nextCursor: json['nextCursor']?.toString(),
    );
  }
}
