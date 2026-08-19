import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ref
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/error_messages.dart';
import '../../../core/api/api_lang.dart';
import '../../auth/providers/auth_provider.dart';
import '../../catalog/providers/catalog_provider.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class FavoriteItem {
  final String id;
  final String productId;
  final ProductSummary product;

  const FavoriteItem({
    required this.id,
    required this.productId,
    required this.product,
  });

  factory FavoriteItem.fromJson(
    Map<String, dynamic> json, {
    String? apiBaseUrl,
  }) {
    final productJson = json['product'] as Map<String, dynamic>? ?? json;
    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      product: ProductSummary.fromJson(
        productJson,
        apiBaseUrl: apiBaseUrl,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class FavoritesState {
  final List<FavoriteItem> favorites;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.favorites = const [],
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<FavoriteItem>? favorites,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final DioClient _client;
  final Ref _ref;

  FavoritesNotifier({required DioClient client, required Ref ref})
      : _client = client,
        _ref = ref,
        super(const FavoritesState());

  /// GET /api/favorites?lang=
  Future<void> fetchFavorites() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get('/api/favorites', queryParameters: {
        'lang': apiLang(_ref.read(authProvider).locale),
      });
      final data = res.data;
      List<dynamic> list;
      if (data is Map && data.containsKey('items')) {
        list = data['items'] as List<dynamic>;
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      state = state.copyWith(
        isLoading: false,
        favorites: list
            .map((e) => FavoriteItem.fromJson(
                  e as Map<String, dynamic>,
                  apiBaseUrl: _client.dio.options.baseUrl,
                ))
            .toList(),
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: errorCodeOf(e));
    }
  }

  /// POST /api/favorites { productId } — idempotent: CONFLICT (already a
  /// favorite) is treated as success, not surfaced as an error.
  Future<void> addFavorite(String productId) async {
    try {
      await _client.post('/api/favorites', data: {'productId': productId});
      await fetchFavorites();
    } on DioException catch (e) {
      final domain =
          e.error is DomainException ? e.error as DomainException : null;
      if (domain?.code == 'CONFLICT') {
        // Already in favorites — just sync local state, no error.
        await fetchFavorites();
        return;
      }
      state = state.copyWith(error: errorCodeOf(e));
      rethrow;
    }
  }

  /// DELETE /api/favorites/{productId} — idempotent: NOT_FOUND (already
  /// removed) is treated as success.
  Future<void> removeFavorite(String productId) async {
    try {
      await _client.delete('/api/favorites/$productId');
      state = state.copyWith(
        favorites:
            state.favorites.where((f) => f.productId != productId).toList(),
      );
    } on DioException catch (e) {
      final domain =
          e.error is DomainException ? e.error as DomainException : null;
      if (domain?.code == 'NOT_FOUND') {
        state = state.copyWith(
          favorites:
              state.favorites.where((f) => f.productId != productId).toList(),
        );
        return;
      }
      state = state.copyWith(error: errorCodeOf(e));
    }
  }

  bool isFavorite(String productId) {
    return state.favorites.any((f) => f.productId == productId);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final client = ref.watch(dioClientProvider);
  return FavoritesNotifier(client: client, ref: ref);
});
