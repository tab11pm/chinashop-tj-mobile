import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/error_messages.dart';
import '../../auth/providers/auth_provider.dart'; // dioClientProvider

/// Report category — mirrors `reviewReportCategories` in
/// `apps/api/src/reviews/dto/create-review-report.dto.ts` EXACTLY (5 literals,
/// this order). [toApiValue] maps back to the snake_case strings the backend
/// expects; [fromApiValue] parses the `GET /api/reviews/my-reports` response.
enum ReviewReportCategory {
  spamAdvertising,
  abusiveContent,
  falseOrIrrelevant,
  inappropriatePhoto,
  other,
}

extension ReviewReportCategoryApi on ReviewReportCategory {
  String toApiValue() {
    switch (this) {
      case ReviewReportCategory.spamAdvertising:
        return 'spam_advertising';
      case ReviewReportCategory.abusiveContent:
        return 'abusive_content';
      case ReviewReportCategory.falseOrIrrelevant:
        return 'false_or_irrelevant';
      case ReviewReportCategory.inappropriatePhoto:
        return 'inappropriate_photo';
      case ReviewReportCategory.other:
        return 'other';
    }
  }

  static ReviewReportCategory fromApiValue(String value) {
    switch (value) {
      case 'spam_advertising':
        return ReviewReportCategory.spamAdvertising;
      case 'abusive_content':
        return ReviewReportCategory.abusiveContent;
      case 'false_or_irrelevant':
        return ReviewReportCategory.falseOrIrrelevant;
      case 'inappropriate_photo':
        return ReviewReportCategory.inappropriatePhoto;
      default:
        return ReviewReportCategory.other;
    }
  }
}

/// One entry of the caller's own report state for a review, from
/// `GET /api/reviews/my-reports?productId=` (D-16) — response shape
/// `{ reports: [{reviewId, category, status}] }`.
class MyReport {
  final String reviewId;
  final ReviewReportCategory category;
  final String status; // 'open' | 'resolved'

  const MyReport({
    required this.reviewId,
    required this.category,
    required this.status,
  });

  factory MyReport.fromJson(Map<String, dynamic> json) {
    return MyReport(
      reviewId: json['reviewId']?.toString() ?? '',
      category: ReviewReportCategoryApi.fromApiValue(
        json['category']?.toString() ?? '',
      ),
      status: json['status']?.toString() ?? 'open',
    );
  }
}

/// GET /api/reviews/my-reports?productId= — autoDispose.family keyed by
/// productId, matching [reviewEligibilityProvider]'s shape.
///
/// On `DioException` (including 401 for an unauthenticated viewer) this lets
/// the error propagate as `AsyncValue.error` — callers treat that identically
/// to "no reports" for marker-rendering purposes. An unauthenticated viewer
/// never sees "Вы пожаловались"/report menu items at all (C-5's
/// "unauthenticated → ⋮ hidden" rule), handled at the call site, not here.
final myReportsProvider = FutureProvider.autoDispose
    .family<List<MyReport>, String>((ref, productId) async {
  final client = ref.watch(dioClientProvider);
  final res = await client.get(
    '/api/reviews/my-reports',
    queryParameters: {'productId': productId},
  );
  final body = res.data as Map<String, dynamic>;
  return (body['reports'] as List)
      .map((e) => MyReport.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Submit flow — POST /api/reviews/:id/reports (upsert per reviewId+reporter).
// ---------------------------------------------------------------------------

enum ReviewReportSubmitStatus { idle, submitting, success, error }

class ReviewReportSubmitState {
  final ReviewReportSubmitStatus status;
  final String? errorCode;

  const ReviewReportSubmitState({
    this.status = ReviewReportSubmitStatus.idle,
    this.errorCode,
  });

  ReviewReportSubmitState copyWith({
    ReviewReportSubmitStatus? status,
    String? errorCode,
  }) {
    return ReviewReportSubmitState(
      status: status ?? this.status,
      errorCode: errorCode,
    );
  }
}

class ReviewReportNotifier extends StateNotifier<ReviewReportSubmitState> {
  final DioClient _client;

  ReviewReportNotifier({required DioClient client})
      : _client = client,
        super(const ReviewReportSubmitState());

  /// POST /api/reviews/:reviewId/reports — server-side upsert scoped to
  /// `[reviewId, reporterUserId]` (Phase 23, unmodified). Returns `true` on
  /// success (create or update), `false` on any `DioException`.
  Future<bool> submit({
    required String reviewId,
    required ReviewReportCategory category,
    String? comment,
  }) async {
    state = state.copyWith(
        status: ReviewReportSubmitStatus.submitting, errorCode: null);
    try {
      await _client.post(
        '/api/reviews/$reviewId/reports',
        data: {
          'category': category.toApiValue(),
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      state = state.copyWith(status: ReviewReportSubmitStatus.success);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        status: ReviewReportSubmitStatus.error,
        errorCode: errorCodeOf(e),
      );
      return false;
    }
  }
}

/// autoDispose — a fresh notifier per bottom-sheet instance.
final reviewReportProvider = StateNotifierProvider.autoDispose<
    ReviewReportNotifier, ReviewReportSubmitState>((ref) {
  final client = ref.watch(dioClientProvider);
  return ReviewReportNotifier(client: client);
});
