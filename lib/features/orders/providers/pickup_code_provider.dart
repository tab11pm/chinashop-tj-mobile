import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';

class PickupCode {
  final String code;
  final String qrPayload;
  final bool fromCache;

  const PickupCode({
    required this.code,
    required this.qrPayload,
    required this.fromCache,
  });

  PickupCode copyWith({
    String? code,
    String? qrPayload,
    bool? fromCache,
  }) {
    return PickupCode(
      code: code ?? this.code,
      qrPayload: qrPayload ?? this.qrPayload,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class PickupCodeNotifier extends StateNotifier<AsyncValue<PickupCode>> {
  PickupCodeNotifier({required DioClient client})
      : _client = client,
        super(const AsyncValue.loading());

  final DioClient _client;

  Future<void> fetchPickupCode(String orderId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get('/api/orders/$orderId/pickup-code');
      final data = res.data as Map<String, dynamic>;
      final code = data['code']?.toString() ?? '';
      final qrPayload = data['qrPayload']?.toString() ?? '';
      await _client.storage.writePickupCode(orderId, code, qrPayload);
      state = AsyncValue.data(
        PickupCode(code: code, qrPayload: qrPayload, fromCache: false),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cached = await _client.storage.readPickupCode(orderId);
        if (cached != null) {
          state = AsyncValue.data(
            PickupCode(
              code: cached['code']!,
              qrPayload: cached['qrPayload']!,
              fromCache: true,
            ),
          );
          return;
        }
      }

      final err = e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load pickup code'),
        StackTrace.current,
      );
    }
  }
}

final pickupCodeProvider = StateNotifierProvider.autoDispose
    .family<PickupCodeNotifier, AsyncValue<PickupCode>, String>(
  (ref, orderId) {
    final client = ref.watch(dioClientProvider);
    return PickupCodeNotifier(client: client)..fetchPickupCode(orderId);
  },
);
