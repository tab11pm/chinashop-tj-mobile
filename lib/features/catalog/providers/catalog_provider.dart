import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/error_messages.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_lang.dart';

const _configuredImageOrigin = String.fromEnvironment('IMAGE_ORIGIN');
const _configuredLegacyMirrorOrigins =
    String.fromEnvironment('IMAGE_LEGACY_MIRROR_ORIGINS');
const _enableDevMirrorRewrite =
    bool.fromEnvironment('ENABLE_DEV_IMAGE_REWRITE');
const _mirrorBucketPath = '/pinshop-images/';
const _devMirrorPort = 9000;

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class Category {
  final String id;
  final String name;
  final String? imageUrl;

  const Category({required this.id, required this.name, this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class ProductSummary {
  final String id;
  final String name;
  final String? imageUrl;
  final String priceTjs; // Money string from API — never parse to float (D-07)
  final String?
      oldPriceTjs; // struck-through "was" price (Phase 21) — money string
  final int? discountPercent; // 0–100 discount % (Phase 21), null = no discount
  final String? badge; // marketing chip label (Phase 21), e.g. "Хит"
  final String status;
  final String? categoryId;

  /// Rating aggregate (Phase 22/23) — null avgRating or ratingCount == 0 means
  /// the product has zero reviews yet (D-14: card rating line is absent, not
  /// an empty placeholder).
  final double? avgRating;
  final int ratingCount;

  const ProductSummary({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.priceTjs,
    this.oldPriceTjs,
    this.discountPercent,
    this.badge,
    required this.status,
    this.categoryId,
    this.avgRating,
    this.ratingCount = 0,
  });

  factory ProductSummary.fromJson(
    Map<String, dynamic> json, {
    String? apiBaseUrl,
  }) {
    return ProductSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: _publicImageUrl(
        json['imageUrl']?.toString(),
        apiBaseUrl: apiBaseUrl,
      ),
      priceTjs: json['priceTjs']?.toString() ?? '0.00',
      oldPriceTjs: json['oldPriceTjs']?.toString(),
      discountPercent: (json['discountPercent'] as num?)?.toInt(),
      badge: json['badge']?.toString(),
      status: json['status']?.toString() ?? 'active',
      categoryId: json['categoryId']?.toString(),
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductVariant {
  final String id;
  final String sku;
  final Map<String, dynamic> attributes;
  final String priceTjs;
  final int stock;

  const ProductVariant({
    required this.id,
    required this.sku,
    required this.attributes,
    required this.priceTjs,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      attributes: _customerVariantAttributes(json['attributes']),
      priceTjs: json['priceTjs']?.toString() ?? '0.00',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductDetail {
  final String id;
  final String name;
  final String? description;
  final List<String> imageUrls;
  final Map<String, dynamic> attributes;
  final String priceTjs;
  final String? oldPriceTjs; // struck-through "was" price (Phase 21)
  final int? discountPercent; // 0–100 discount % (Phase 21), null = no discount
  final String? badge; // marketing chip label (Phase 21)
  final String status;
  final String? categoryId;
  final List<ProductVariant> variants;

  const ProductDetail({
    required this.id,
    required this.name,
    this.description,
    required this.imageUrls,
    this.attributes = const {},
    required this.priceTjs,
    this.oldPriceTjs,
    this.discountPercent,
    this.badge,
    required this.status,
    this.categoryId,
    required this.variants,
  });

  factory ProductDetail.fromJson(
    Map<String, dynamic> json, {
    String? apiBaseUrl,
  }) {
    final images = (json['images'] as List<dynamic>?)
            ?.map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .map((url) => _publicImageUrl(url, apiBaseUrl: apiBaseUrl)!)
            .toList() ??
        [];
    final variants = (json['variants'] as List<dynamic>?)
            ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ProductDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrls: images,
      attributes: _customerProductAttributes(json['attributes']),
      priceTjs: json['priceTjs']?.toString() ?? '0.00',
      oldPriceTjs: json['oldPriceTjs']?.toString(),
      discountPercent: (json['discountPercent'] as num?)?.toInt(),
      badge: json['badge']?.toString(),
      status: json['status']?.toString() ?? 'active',
      categoryId: json['categoryId']?.toString(),
      variants: variants,
    );
  }
}

String? _publicImageUrl(String? imageUrl, {String? apiBaseUrl}) {
  return resolveProductImageUrl(
    imageUrl,
    apiBaseUrl: apiBaseUrl,
    imageOrigin: _configuredImageOrigin,
    legacyMirrorOrigins:
        _parseLegacyMirrorOrigins(_configuredLegacyMirrorOrigins),
    enableDevMirrorRewrite: _enableDevMirrorRewrite,
  );
}

String? resolveProductImageUrl(
  String? imageUrl, {
  String? apiBaseUrl,
  String? imageOrigin,
  Set<String> legacyMirrorOrigins = const {},
  bool enableDevMirrorRewrite = false,
}) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return imageUrl;
  }

  final imageUri = Uri.tryParse(imageUrl);
  if (!_isAbsoluteHttpUri(imageUri) ||
      !imageUri!.path.startsWith(_mirrorBucketPath)) {
    return imageUrl;
  }

  final isLoopbackMirror = imageUri.scheme == 'http' &&
      imageUri.port == _devMirrorPort &&
      _isLoopbackHost(imageUri.host);
  final sourceOrigin = _normalizedOrigin(imageUri);
  final isAllowlistedLegacyMirror = sourceOrigin != null &&
      legacyMirrorOrigins
          .map(_parseAllowlistedOrigin)
          .whereType<String>()
          .contains(sourceOrigin);
  final configuredOrigin = _validConfiguredImageOrigin(imageOrigin);
  if (configuredOrigin != null &&
      (isLoopbackMirror || isAllowlistedLegacyMirror)) {
    final suffix = imageUri.path.substring(_mirrorBucketPath.length);
    final originPath = configuredOrigin.path.endsWith('/')
        ? configuredOrigin.path.substring(0, configuredOrigin.path.length - 1)
        : configuredOrigin.path;
    return configuredOrigin
        .replace(
          path: '$originPath/$suffix',
          query: imageUri.hasQuery ? imageUri.query : null,
          fragment: imageUri.hasFragment ? imageUri.fragment : null,
        )
        .toString();
  }

  final apiUri = apiBaseUrl == null ? null : Uri.tryParse(apiBaseUrl);
  if (!enableDevMirrorRewrite ||
      !isLoopbackMirror ||
      !_isAbsoluteHttpUri(apiUri) ||
      !_isPrivateDevHost(apiUri!.host)) {
    return imageUrl;
  }

  return imageUri.replace(host: apiUri.host).toString();
}

Uri? _validConfiguredImageOrigin(String? configuredOrigin) {
  if (configuredOrigin == null || configuredOrigin.trim().isEmpty) return null;
  final origin = Uri.tryParse(configuredOrigin.trim());
  if (!_isAbsoluteHttpUri(origin) ||
      origin!.userInfo.isNotEmpty ||
      origin.hasQuery ||
      origin.hasFragment) {
    return null;
  }
  final path = origin.path.endsWith('/') && origin.path.length > 1
      ? origin.path.substring(0, origin.path.length - 1)
      : origin.path;
  if (path != '/pinshop-images') return null;
  return origin.replace(path: path);
}

Set<String> _parseLegacyMirrorOrigins(String configuredOrigins) {
  return configuredOrigins
      .split(',')
      .map(_parseAllowlistedOrigin)
      .whereType<String>()
      .toSet();
}

String? _parseAllowlistedOrigin(String value) {
  final uri = Uri.tryParse(value.trim());
  if (!_isAbsoluteHttpUri(uri) ||
      uri!.userInfo.isNotEmpty ||
      uri.path.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  return _normalizedOrigin(uri);
}

String? _normalizedOrigin(Uri uri) {
  if (!_isAbsoluteHttpUri(uri)) return null;
  final defaultPort = (uri.scheme == 'http' && uri.port == 80) ||
      (uri.scheme == 'https' && uri.port == 443);
  return '${uri.scheme}://${uri.host}${defaultPort ? '' : ':${uri.port}'}';
}

bool _isAbsoluteHttpUri(Uri? uri) =>
    uri != null &&
    (uri.scheme == 'http' || uri.scheme == 'https') &&
    uri.host.isNotEmpty;

bool _isLoopbackHost(String host) {
  final normalized = host.toLowerCase();
  if (normalized == 'localhost' ||
      normalized == '::1' ||
      normalized == '0.0.0.0') {
    return true;
  }
  if (normalized.startsWith('::ffff:')) {
    final mapped = normalized.substring('::ffff:'.length);
    if (_isIpv4Loopback(mapped)) return true;
    final words = mapped.split(':');
    if (words.length == 2) {
      final high = int.tryParse(words[0], radix: 16);
      final low = int.tryParse(words[1], radix: 16);
      return high != null &&
          low != null &&
          high >= 0 &&
          high <= 0xffff &&
          low >= 0 &&
          low <= 0xffff &&
          (high >> 8) == 127;
    }
  }
  return _isIpv4Loopback(normalized);
}

bool _isIpv4Loopback(String host) {
  final octets = host.split('.');
  return octets.length == 4 &&
      octets.first == '127' &&
      octets.every((part) {
        final value = int.tryParse(part);
        return value != null && value >= 0 && value <= 255;
      });
}

bool _isPrivateDevHost(String host) {
  final octets = host.split('.').map(int.tryParse).toList();
  if (octets.length != 4 || octets.any((value) => value == null)) return false;
  final values = octets.cast<int>();
  if (values.any((value) => value < 0 || value > 255)) return false;
  return values[0] == 10 ||
      (values[0] == 172 && values[1] >= 16 && values[1] <= 31) ||
      (values[0] == 192 && values[1] == 168);
}

Map<String, dynamic> _customerProductAttributes(dynamic raw) {
  final attributes = _readAttributes(raw);
  final visible = <String, dynamic>{};
  for (final entry in attributes.entries) {
    if (_isTechnicalProductAttribute(entry.key)) continue;
    visible[entry.key] = entry.value;
  }
  return visible;
}

Map<String, dynamic> _customerVariantAttributes(dynamic raw) {
  final attributes = _readAttributes(raw);
  final visible = <String, dynamic>{};
  for (final entry in attributes.entries) {
    if (_isTechnicalVariantAttribute(entry.key)) continue;
    if (entry.key.toLowerCase() == 'configurators') {
      visible.addAll(_meaningfulConfigurators(entry.value));
      continue;
    }
    visible[entry.key] = entry.value;
  }
  return visible;
}

Map<String, dynamic> _readAttributes(dynamic raw) {
  if (raw is! Map) return {};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

bool _isTechnicalProductAttribute(String key) {
  const hidden = {
    'sourceName',
    'sourceDescription',
    'oldPriceTjs',
    'discountPercent',
    'badge',
    'sourceCategoryId',
    'sourceCategoryIds',
    'searchHash',
    'otapi',
    'image',
    'images',
    'imageUrl',
    'imageUrls',
    'categoryId',
    'enrichmentStatus',
  };
  return hidden.contains(key);
}

bool _isTechnicalVariantAttribute(String key) {
  const hidden = {
    'pid',
    'vid',
    'sourceVariantId',
    'sourceVariantIds',
    'sourceSkuId',
    'skuId',
  };
  return hidden.contains(key.toLowerCase());
}

Map<String, dynamic> _meaningfulConfigurators(dynamic raw) {
  if (raw is! List) return {};
  final visible = <String, dynamic>{};
  for (final item in raw) {
    if (item is! Map) continue;
    final label =
        (item['Pid'] ?? item['pid'] ?? item['name'])?.toString().trim();
    final value =
        (item['Vid'] ?? item['vid'] ?? item['value'])?.toString().trim();
    if (label == null || label.isEmpty || value == null || value.isEmpty) {
      continue;
    }
    if (_looksLikeTechnicalId(label) || _looksLikeTechnicalId(value)) {
      continue;
    }
    visible[label] = value;
  }
  return visible;
}

bool _looksLikeTechnicalId(String value) {
  return RegExp(r'^\d{5,}$').hasMatch(value);
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CatalogState {
  final List<Category> categories;
  final List<ProductSummary> products;
  final bool isLoadingCategories;
  final bool isLoadingProducts;
  final String? errorCategories;
  final String? errorProducts;
  final int currentPage;
  final bool hasMore;

  const CatalogState({
    this.categories = const [],
    this.products = const [],
    this.isLoadingCategories = false,
    this.isLoadingProducts = false,
    this.errorCategories,
    this.errorProducts,
    this.currentPage = 1,
    this.hasMore = true,
  });

  CatalogState copyWith({
    List<Category>? categories,
    List<ProductSummary>? products,
    bool? isLoadingCategories,
    bool? isLoadingProducts,
    String? errorCategories,
    String? errorProducts,
    int? currentPage,
    bool? hasMore,
  }) {
    return CatalogState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      errorCategories: errorCategories,
      errorProducts: errorProducts,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier — shared catalog state (Home + Catalog tabs)
// ---------------------------------------------------------------------------

class CatalogNotifier extends StateNotifier<CatalogState> {
  final DioClient _client;
  final Ref _ref;

  CatalogNotifier({required DioClient client, required Ref ref})
      : _client = client,
        _ref = ref,
        super(const CatalogState());

  /// Current API locale, read dynamically so a locale change is picked up
  /// without recreating the notifier (which would wipe loaded products).
  String get _apiLang => apiLang(_ref.read(authProvider).locale);

  /// GET /api/categories
  Future<void> fetchCategories() async {
    state = state.copyWith(isLoadingCategories: true, errorCategories: null);
    try {
      final res = await _client
          .get('/api/categories', queryParameters: {'lang': _apiLang});
      final list = res.data as List<dynamic>;
      state = state.copyWith(
        isLoadingCategories: false,
        categories: list
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoadingCategories: false, errorCategories: msg);
    }
  }

  /// GET /api/products?q=&category=&page=&lang=
  Future<void> fetchProducts({
    String? q,
    String? categoryId,
    int page = 1,
    bool reset = true,
  }) async {
    state = state.copyWith(isLoadingProducts: true, errorProducts: null);
    try {
      final res = await _client.get(
        '/api/products',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (categoryId != null) 'category': categoryId,
          'page': page,
          'lang': _apiLang,
        },
      );

      final data = res.data;
      List<dynamic> items;
      if (data is Map && data.containsKey('items')) {
        items = data['items'] as List<dynamic>;
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }

      final newProducts = items
          .map((e) => ProductSummary.fromJson(
                e as Map<String, dynamic>,
                apiBaseUrl: _client.dio.options.baseUrl,
              ))
          .toList();

      state = state.copyWith(
        isLoadingProducts: false,
        products: reset ? newProducts : [...state.products, ...newProducts],
        currentPage: page,
        hasMore: newProducts.isNotEmpty,
      );
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoadingProducts: false, errorProducts: msg);
    }
  }
}

// ---------------------------------------------------------------------------
// Category products — isolated provider so CategoryScreen never overwrites
// the shared catalogProvider state (which would break HomeScreen on back-navigate).
// ---------------------------------------------------------------------------

class CategoryProductsNotifier
    extends StateNotifier<AsyncValue<List<ProductSummary>>> {
  final DioClient _client;
  final String _locale;

  CategoryProductsNotifier({required DioClient client, required String locale})
      : _client = client,
        _locale = locale,
        super(const AsyncValue.loading());

  Future<void> fetch(String categoryId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get(
        '/api/products',
        queryParameters: {
          'category': categoryId,
          'page': 1,
          'lang': apiLang(_locale),
        },
      );

      final data = res.data;
      List<dynamic> items;
      if (data is Map && data.containsKey('items')) {
        items = data['items'] as List<dynamic>;
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }

      state = AsyncValue.data(
        items
            .map((e) => ProductSummary.fromJson(
                  e as Map<String, dynamic>,
                  apiBaseUrl: _client.dio.options.baseUrl,
                ))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = AsyncValue.error(msg, StackTrace.current);
    }
  }
}

final categoryProductsProvider = StateNotifierProvider.family<
    CategoryProductsNotifier, AsyncValue<List<ProductSummary>>, String>(
  (ref, categoryId) {
    final client = ref.watch(dioClientProvider);
    final locale = ref.watch(authProvider).locale;
    return CategoryProductsNotifier(client: client, locale: locale)
      ..fetch(categoryId);
  },
);

// ---------------------------------------------------------------------------
// Product detail — family provider
// ---------------------------------------------------------------------------

class ProductDetailNotifier extends StateNotifier<AsyncValue<ProductDetail>> {
  final DioClient _client;
  final String _locale;

  ProductDetailNotifier({required DioClient client, required String locale})
      : _client = client,
        _locale = locale,
        super(const AsyncValue.loading());

  Future<void> fetch(String productId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get(
        '/api/products/$productId',
        queryParameters: {'lang': apiLang(_locale)},
      );

      // Fetch variants separately
      List<ProductVariant> variants = [];
      try {
        final varRes = await _client.get('/api/products/$productId/variants');
        final varList = varRes.data as List<dynamic>;
        variants = varList.indexed.map((item) {
          final index = item.$1;
          final entry = item.$2;
          final variant = ProductVariant.fromJson(
            entry as Map<String, dynamic>,
          );
          // Raw OTAPI PID/VID configurators have no customer-facing labels.
          // When there are several such SKUs, still expose a deterministic
          // choice rather than silently making every option unselectable.
          if (variant.attributes.isEmpty && varList.length > 1) {
            return ProductVariant(
              id: variant.id,
              sku: variant.sku,
              attributes: {'variant': '${index + 1} · ${variant.priceTjs} TJS'},
              priceTjs: variant.priceTjs,
              stock: variant.stock,
            );
          }
          return variant;
        }).toList();
      } catch (_) {
        // variants optional — proceed without them
      }

      final detail = ProductDetail.fromJson({
        ...(res.data as Map<String, dynamic>),
        'variants': variants
            .map((v) => {
                  'id': v.id,
                  'sku': v.sku,
                  'attributes': v.attributes,
                  'priceTjs': v.priceTjs,
                  'stock': v.stock,
                })
            .toList(),
      }, apiBaseUrl: _client.dio.options.baseUrl);

      state = AsyncValue.data(detail);
    } on DioException catch (e) {
      final err =
          e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load product'),
        StackTrace.current,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final catalogProvider =
    StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final client = ref.watch(dioClientProvider);
  final notifier = CatalogNotifier(client: client, ref: ref);
  // Refetch when the locale changes — without recreating the notifier (which
  // would clear loaded products). Only the locale field is observed.
  ref.listen(authProvider.select((s) => s.locale), (prev, next) {
    if (prev != next) {
      notifier.fetchCategories();
      notifier.fetchProducts(page: 1);
    }
  });
  return notifier;
});

final productDetailProvider = StateNotifierProvider.family<
    ProductDetailNotifier, AsyncValue<ProductDetail>, String>(
  (ref, productId) {
    final client = ref.watch(dioClientProvider);
    final locale = ref.watch(authProvider).locale;
    return ProductDetailNotifier(client: client, locale: locale)
      ..fetch(productId);
  },
);
