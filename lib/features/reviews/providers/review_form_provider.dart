import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/error_messages.dart';
import '../../auth/providers/auth_provider.dart'; // dioClientProvider
import '../models/review_models.dart';

/// Typed payload passed via GoRouter `extra` to the review form route
/// (`AppRoutes.reviewForm`) — mirrors `PaymentReceiptArgs`'s pattern of
/// keeping non-URL-safe/verbose data out of the path.
class ReviewFormArgs {
  final String productId;
  final String productName;
  final String? productImageUrl;
  final String orderItemId;
  final Review? existingReview;

  const ReviewFormArgs({
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.orderItemId,
    this.existingReview,
  });
}

/// review_form_provider.dart — write-side submit flow for the review form
/// screen (Phase 24 Plan 03, D-09..D-12).
///
/// Mirrors `PaymentReceiptNotifier`'s state-machine shape
/// (idle→submitting→success|error), but this notifier deliberately holds NO
/// rating/text/photos of its own — those live in the SCREEN's local `State`
/// so a failed submit naturally preserves them for retry (D-18). The only
/// caller-visible payload is [ReviewFormState.result], used exclusively to
/// confirm success and trigger provider invalidation/navigation — never to
/// render review authorship (the write-path response has no `author` key;
/// see `review_models.dart`'s file-level doc comment).
enum ReviewFormStatus { idle, submitting, success, error }

class ReviewFormState {
  final ReviewFormStatus status;
  final String? errorCode;
  final Review? result;

  const ReviewFormState({
    this.status = ReviewFormStatus.idle,
    this.errorCode,
    this.result,
  });

  ReviewFormState copyWith({
    ReviewFormStatus? status,
    String? errorCode,
    Review? result,
  }) {
    return ReviewFormState(
      status: status ?? this.status,
      errorCode: errorCode,
      result: result ?? this.result,
    );
  }
}

class ReviewFormNotifier extends StateNotifier<ReviewFormState> {
  final DioClient _client;

  ReviewFormNotifier({required DioClient client})
      : _client = client,
        super(const ReviewFormState());

  /// Submits a create (`POST /api/reviews`) or update
  /// (`PATCH /api/reviews/:id`) as ONE multipart request.
  ///
  /// Field name contract (matches `FilesInterceptor('photos', 5, ...)` on
  /// both the create and update controller handlers): the multipart field
  /// MUST be the literal plural string `'photos'`.
  ///
  /// [photosChanged] controls whether the edit path includes the `photos`
  /// field at all: `ReviewsService.update()` treats `files === undefined`
  /// (field entirely absent from the multipart body) as "keep existing
  /// photos" vs an explicit empty array as "clear all photos". Passing
  /// `photosChanged: false` in edit mode omits the field so the server hits
  /// the `undefined` branch, never silently wiping photos on a rating/text-
  /// only edit (T-24-10).
  Future<Review?> submit({
    required bool isEdit,
    String? reviewId,
    required String orderItemId,
    required int rating,
    String? text,
    required List<XFile> photos,
    bool photosChanged = true,
  }) async {
    state =
        state.copyWith(status: ReviewFormStatus.submitting, errorCode: null);
    try {
      final formData = FormData.fromMap({
        if (!isEdit) 'orderItemId': orderItemId,
        'rating': rating.toString(),
        if (text != null && text.isNotEmpty) 'text': text,
        if (!isEdit || photosChanged)
          'photos': [
            for (final p in photos)
              await MultipartFile.fromFile(p.path, filename: p.name),
          ],
      });

      final res = isEdit
          ? await _client.patch('/api/reviews/$reviewId', data: formData)
          : await _client.post('/api/reviews', data: formData);

      // Mutation responses exclude `author` and owner-only association IDs.
      // Review.fromJson tolerates the absent author; edit targeting comes only
      // from the authenticated eligibility response.
      final result = Review.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(status: ReviewFormStatus.success, result: result);
      return result;
    } on DioException catch (e) {
      // Do NOT clear rating/text/photos — this notifier never held them.
      state = state.copyWith(
        status: ReviewFormStatus.error,
        errorCode: errorCodeOf(e),
      );
      return null;
    }
  }

  /// Resets back to idle — used when the form screen re-enters edit mode
  /// (e.g. after a REVIEW_ALREADY_EXISTS redirect) or is re-shown fresh.
  void reset() {
    state = const ReviewFormState();
  }
}

/// autoDispose — a fresh notifier per form-screen instance, matching
/// `paymentReceiptProvider`.
final reviewFormProvider =
    StateNotifierProvider.autoDispose<ReviewFormNotifier, ReviewFormState>(
        (ref) {
  final client = ref.watch(dioClientProvider);
  return ReviewFormNotifier(client: client);
});
