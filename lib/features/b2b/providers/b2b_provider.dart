import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_exception.dart';
import '../../auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

/// A wholesale (B2B) application as returned by GET /api/b2b/application.
///
/// All fields tolerate null/missing JSON keys: the self-view renders an empty
/// state for a null body (no active application) and a populated card otherwise.
class WholesaleApplication {
  final String id;
  final String status; // pending | approved | rejected | suspended
  final String shopName;
  final String taxId;
  final String city;
  final String? expectedVolume;
  final String? rejectionNote;
  final String? createdAt;

  const WholesaleApplication({
    required this.id,
    required this.status,
    required this.shopName,
    required this.taxId,
    required this.city,
    this.expectedVolume,
    this.rejectionNote,
    this.createdAt,
  });

  factory WholesaleApplication.fromJson(Map<String, dynamic> json) {
    return WholesaleApplication(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      shopName: json['shopName']?.toString() ?? '',
      taxId: json['taxId']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      expectedVolume: json['expectedVolume']?.toString(),
      rejectionNote: json['rejectionNote']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Drives the B2B self-view (GET /api/b2b/application) and submits new
/// applications (POST /api/b2b/apply).
///
/// State is `AsyncValue<WholesaleApplication?>`:
///   - loading           → request in flight
///   - data(application)  → an active application exists
///   - data(null)         → no active application (empty state)
///   - error(err)         → GET failed (rendered via AppErrorWidget + retry)
class ApplicationNotifier
    extends StateNotifier<AsyncValue<WholesaleApplication?>> {
  final DioClient _client;

  ApplicationNotifier({required DioClient client})
      : _client = client,
        super(const AsyncValue.loading());

  /// GET /api/b2b/application — returns the active application or null (D-08).
  ///
  /// `mounted` guards (matching payment_receipt_provider.dart's convention) are
  /// required here: this is an `autoDispose` provider, and callers that never
  /// `ref.watch` it (e.g. b2b_apply_screen.dart's `ref.read(...).apply()`) leave
  /// no active listener to keep it alive across the `await`. Riverpod may tear
  /// the notifier down mid-flight, and writing to `state` after that throws a
  /// bare StateError that must never be allowed to look like a failed request
  /// (b2b-apply-false-error-dup: the POST had already succeeded server-side).
  Future<void> fetch() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final res = await _client.get('/api/b2b/application');
      if (!mounted) return;
      final data = res.data;
      if (data is Map<String, dynamic> && data.isNotEmpty) {
        state = AsyncValue.data(WholesaleApplication.fromJson(data));
      } else {
        // null body / empty 200 → no active application
        state = const AsyncValue.data(null);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final err = e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load application'),
        StackTrace.current,
      );
    }
  }

  /// POST /api/b2b/apply — submits the business-data form.
  ///
  /// Sends only the business fields; status/role/phone are server-owned (D-09).
  /// Rethrows on DioException so the form's `catch (e) => errorCodeOf(e)` can map
  /// SELLER_APPLICATION_ALREADY_EXISTS (and others) to localized copy.
  Future<void> apply({
    required String shopName,
    required String taxId,
    required String city,
    String? expectedVolume,
  }) async {
    final body = <String, dynamic>{
      'shopName': shopName,
      'taxId': taxId,
      'city': city,
      if (expectedVolume != null && expectedVolume.isNotEmpty)
        'expectedVolume': expectedVolume,
    };
    await _client.post('/api/b2b/apply', data: body);
    // WR-03: refresh the self-view so the status screen reflects the new pending
    // row regardless of autoDispose timing (do not rely on disposal between screens).
    await fetch();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// autoDispose: when the status screen is popped no widget watches this, so the
/// notifier is disposed. Re-opening the screen rebuilds it and re-runs fetch()
/// — otherwise a freshly-submitted application would not appear without a
/// manual refresh (same rationale as orderDetailProvider).
final applicationProvider = StateNotifierProvider.autoDispose<
    ApplicationNotifier, AsyncValue<WholesaleApplication?>>((ref) {
  final client = ref.watch(dioClientProvider);
  return ApplicationNotifier(client: client)..fetch();
});
