import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_lang.dart';
import '../../auth/providers/auth_provider.dart';
import '../../catalog/providers/catalog_provider.dart' show Category;

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// A single tier row in the wholesale price table.
/// unitPriceTjs is a MoneyString from the API — never parse to float.
class TierPriceRow {
  final int minQty;
  final String unitPriceTjs; // MoneyString — display as-is; '0.00' → '– TJS'

  const TierPriceRow({required this.minQty, required this.unitPriceTjs});

  factory TierPriceRow.fromJson(Map<String, dynamic> json) {
    return TierPriceRow(
      minQty: (json['minQty'] as num?)?.toInt() ?? 0,
      unitPriceTjs: json['unitPriceTjs']?.toString() ?? '0.00',
    );
  }
}

/// Summary item used in WholesaleCatalogScreen list.
class WholesaleProductItem {
  final String id;
  final String factoryId;
  final String name;
  final String? description;
  final String locale;
  final bool isFallback;
  final int moq;
  final List<String> images;
  final String entryPriceTjs; // MoneyString of the cheapest tier (entry)
  final int? entryTierMinQty;

  const WholesaleProductItem({
    required this.id,
    required this.factoryId,
    required this.name,
    this.description,
    required this.locale,
    required this.isFallback,
    required this.moq,
    required this.images,
    required this.entryPriceTjs,
    this.entryTierMinQty,
  });

  factory WholesaleProductItem.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>?)
            ?.map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    return WholesaleProductItem(
      id: json['id']?.toString() ?? '',
      factoryId: json['factoryId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      locale: json['locale']?.toString() ?? 'ru',
      isFallback: json['isFallback'] == true,
      moq: (json['moq'] as num?)?.toInt() ?? 1,
      images: images,
      entryPriceTjs: json['entryPriceTjs']?.toString() ?? '0.00',
      entryTierMinQty: (json['entryTierMinQty'] as num?)?.toInt(),
    );
  }
}

/// Nested factory summary inside WholesaleProductDetail.
class FactorySummary {
  final String id;
  final String name;
  final String? country;
  final String? shippingTjs;

  const FactorySummary({
    required this.id,
    required this.name,
    this.country,
    this.shippingTjs,
  });

  factory FactorySummary.fromJson(Map<String, dynamic> json) {
    return FactorySummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString(),
      shippingTjs: json['shippingTjs']?.toString(),
    );
  }
}

/// Full product detail with tier table — used in WholesaleProductDetailScreen.
class WholesaleProductDetail {
  final String id;
  final String factoryId;
  final FactorySummary factory;
  final String name;
  final String? description;
  final String locale;
  final bool isFallback;
  final int moq;
  final List<String> images;
  final Map<String, dynamic> attributes;
  final List<TierPriceRow> tiers;

  const WholesaleProductDetail({
    required this.id,
    required this.factoryId,
    required this.factory,
    required this.name,
    this.description,
    required this.locale,
    required this.isFallback,
    required this.moq,
    required this.images,
    required this.attributes,
    required this.tiers,
  });

  factory WholesaleProductDetail.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>?)
            ?.map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    final tiers = (json['tiers'] as List<dynamic>?)
            ?.map((e) => TierPriceRow.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final factoryJson = json['factory'] as Map<String, dynamic>? ?? {};
    return WholesaleProductDetail(
      id: json['id']?.toString() ?? '',
      factoryId: json['factoryId']?.toString() ?? '',
      factory: FactorySummary.fromJson(factoryJson),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      locale: json['locale']?.toString() ?? 'ru',
      isFallback: json['isFallback'] == true,
      moq: (json['moq'] as num?)?.toInt() ?? 1,
      images: images,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
      tiers: tiers,
    );
  }
}

/// Factory profile — used in FactoryProfileScreen (FCT-05).
class FactoryProfile {
  final String id;
  final String name;
  final String? country;
  final String? description;
  final String locale;
  final bool isFallback;
  final int? moqMin;
  final int? moqMax;

  const FactoryProfile({
    required this.id,
    required this.name,
    this.country,
    this.description,
    required this.locale,
    required this.isFallback,
    this.moqMin,
    this.moqMax,
  });

  factory FactoryProfile.fromJson(Map<String, dynamic> json) {
    final moqRange = json['moqRange'] as Map<String, dynamic>?;
    return FactoryProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString(),
      description: json['description']?.toString(),
      locale: json['locale']?.toString() ?? 'ru',
      isFallback: json['isFallback'] == true,
      moqMin: (moqRange?['min'] as num?)?.toInt() ??
          (json['moq'] as num?)?.toInt(),
      moqMax: (moqRange?['max'] as num?)?.toInt(),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifiers
// ---------------------------------------------------------------------------

/// Drives WholesaleCatalogScreen: GET /api/wholesale/catalog?lang=
///
/// State is AsyncValue<List<WholesaleProductItem>>:
///   - loading → request in flight
///   - data([]) → empty catalog
///   - data([...]) → product list
///   - error(DomainException{code:'SELLER_NOT_VERIFIED'}) → 403 gate
///   - error(other) → network / server error
class WholesaleCatalogNotifier
    extends StateNotifier<AsyncValue<List<WholesaleProductItem>>> {
  final DioClient _client;
  final Ref _ref;

  WholesaleCatalogNotifier({required DioClient client, required Ref ref})
      : _client = client,
        _ref = ref,
        super(const AsyncValue.loading());

  String get _apiLang => apiLang(_ref.read(authProvider).locale);

  Future<void> fetch({String? categoryId, String? q}) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get(
        '/api/wholesale/catalog',
        queryParameters: {
          'lang': _apiLang,
          if (categoryId != null) 'categoryId': categoryId,
          if (q != null && q.isNotEmpty) 'q': q,
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
      final products = items
          .map((e) => WholesaleProductItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(products);
    } on DioException catch (e) {
      final err = e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load wholesale catalog'),
        StackTrace.current,
      );
    }
  }
}

final wholesaleCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final locale = ref.watch(authProvider).locale;
  final res = await client.get(
    '/api/categories',
    queryParameters: {'lang': apiLang(locale), 'channel': 'b2b'},
  );
  final list = res.data as List<dynamic>;
  return list
      .map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Drives WholesaleProductDetailScreen: GET /api/wholesale/catalog/:id?lang=
class WholesaleProductDetailNotifier
    extends StateNotifier<AsyncValue<WholesaleProductDetail>> {
  final DioClient _client;
  final String _locale;

  WholesaleProductDetailNotifier(
      {required DioClient client, required String locale})
      : _client = client,
        _locale = locale,
        super(const AsyncValue.loading());

  Future<void> fetch(String productId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get(
        '/api/wholesale/catalog/$productId',
        queryParameters: {'lang': apiLang(_locale)},
      );
      state =
          AsyncValue.data(WholesaleProductDetail.fromJson(res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      final err = e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load product detail'),
        StackTrace.current,
      );
    }
  }
}

/// Drives FactoryProfileScreen: GET /api/wholesale/factories/:id?lang=
class FactoryProfileNotifier
    extends StateNotifier<AsyncValue<FactoryProfile>> {
  final DioClient _client;
  final String _locale;

  FactoryProfileNotifier({required DioClient client, required String locale})
      : _client = client,
        _locale = locale,
        super(const AsyncValue.loading());

  Future<void> fetch(String factoryId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get(
        '/api/wholesale/factories/$factoryId',
        queryParameters: {'lang': apiLang(_locale)},
      );
      state =
          AsyncValue.data(FactoryProfile.fromJson(res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      final err = e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load factory profile'),
        StackTrace.current,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Wholesale catalog list. autoDispose so 403-gate state clears on pop.
final wholesaleCatalogProvider = StateNotifierProvider.autoDispose<
    WholesaleCatalogNotifier, AsyncValue<List<WholesaleProductItem>>>((ref) {
  final client = ref.watch(dioClientProvider);
  return WholesaleCatalogNotifier(client: client, ref: ref)..fetch();
});

/// Wholesale product detail — family by productId.
final wholesaleProductDetailProvider = StateNotifierProvider.autoDispose
    .family<WholesaleProductDetailNotifier, AsyncValue<WholesaleProductDetail>,
        String>((ref, productId) {
  final client = ref.watch(dioClientProvider);
  final locale = ref.watch(authProvider).locale;
  return WholesaleProductDetailNotifier(client: client, locale: locale)
    ..fetch(productId);
});

/// Factory profile — family by factoryId.
final factoryProfileProvider = StateNotifierProvider.autoDispose
    .family<FactoryProfileNotifier, AsyncValue<FactoryProfile>, String>(
        (ref, factoryId) {
  final client = ref.watch(dioClientProvider);
  final locale = ref.watch(authProvider).locale;
  return FactoryProfileNotifier(client: client, locale: locale)
    ..fetch(factoryId);
});

/// Factory list item — used in WholesaleFactoriesScreen.
class FactoryListItem {
  final String id;
  final String name;
  final String? country;
  final String locale;
  final bool isFallback;

  const FactoryListItem({
    required this.id,
    required this.name,
    this.country,
    required this.locale,
    required this.isFallback,
  });

  factory FactoryListItem.fromJson(Map<String, dynamic> json) {
    return FactoryListItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString(),
      locale: json['locale']?.toString() ?? 'ru',
      isFallback: json['isFallback'] == true,
    );
  }
}

/// Drives WholesaleFactoriesScreen: GET /api/wholesale/factories?lang=&categoryId=
class WholesaleFactoriesNotifier
    extends StateNotifier<AsyncValue<List<FactoryListItem>>> {
  final DioClient _client;
  final String _locale;
  final String? _categoryId;

  WholesaleFactoriesNotifier({
    required DioClient client,
    required String locale,
    String? categoryId,
  })  : _client = client,
        _locale = locale,
        _categoryId = categoryId,
        super(const AsyncValue.loading());

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get(
        '/api/wholesale/factories',
        queryParameters: {
          'lang': apiLang(_locale),
          if (_categoryId != null) 'categoryId': _categoryId,
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
      final factories = items
          .map((e) => FactoryListItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(factories);
    } on DioException catch (e) {
      final err = e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load factories'),
        StackTrace.current,
      );
    }
  }
}

/// Wholesale factories list, optionally scoped to a category. Keyed by
/// categoryId (null = all factories) so each home-screen chip / "Все" link
/// gets its own cached list. autoDispose so 403-gate state clears on pop.
final wholesaleFactoriesProvider = StateNotifierProvider.autoDispose
    .family<WholesaleFactoriesNotifier, AsyncValue<List<FactoryListItem>>, String?>(
        (ref, categoryId) {
  final client = ref.watch(dioClientProvider);
  final locale = ref.watch(authProvider).locale;
  return WholesaleFactoriesNotifier(
    client: client,
    locale: locale,
    categoryId: categoryId,
  )..fetch();
});

/// Factory category item with a live count of factories offering products in
/// it — used for the B2B home screen's "Заводы" category chips.
class FactoryCategoryItem {
  final String id;
  final String slug;
  final String name;
  final int factoryCount;

  const FactoryCategoryItem({
    required this.id,
    required this.slug,
    required this.name,
    required this.factoryCount,
  });

  factory FactoryCategoryItem.fromJson(Map<String, dynamic> json) {
    return FactoryCategoryItem(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      factoryCount: (json['factoryCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Drives the home-screen factory-category chips: GET /api/wholesale/factory-categories?lang=
final wholesaleFactoryCategoriesProvider =
    FutureProvider.autoDispose<List<FactoryCategoryItem>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final locale = ref.watch(authProvider).locale;
  final res = await client.get(
    '/api/wholesale/factory-categories',
    queryParameters: {'lang': apiLang(locale)},
  );
  final data = res.data;
  final items = data is List ? data : (data['items'] as List<dynamic>? ?? []);
  return items
      .map((e) => FactoryCategoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});
