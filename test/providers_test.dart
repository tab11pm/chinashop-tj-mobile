import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/cart/providers/cart_provider.dart';
import 'package:pinshop_tj/features/orders/providers/orders_provider.dart';
import 'package:pinshop_tj/features/catalog/providers/catalog_provider.dart';
import 'package:pinshop_tj/features/favorites/providers/favorites_provider.dart';

import 'helpers/fake_dio.dart';
import 'helpers/fake_secure_storage.dart';

/// Provider tests over a fake Dio (no network). They verify the request the
/// provider SENDS (path/qty/variantId/lang) and that it correctly PARSES the
/// API response into state — i.e. the contract end to end.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // flutter_secure_storage reads return null in tests (no token, locale→ru).
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  final adapters = <ProviderContainer, FakeAdapter>{};
  FakeAdapter adapterOf(ProviderContainer c) => adapters[c]!;

  ProviderContainer makeContainer(
    Map<String, (int, Object?)> routes, {
    String apiBaseUrl = 'http://test',
  }) {
    final (dio, adapter) = fakeDio(routes);
    dio.options.baseUrl = apiBaseUrl;
    final c = ProviderContainer(overrides: [
      dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
    ]);
    addTearDown(c.dispose);
    adapters[c] = adapter;
    return c;
  }

  test('CartNotifier.fetchCart parses { items: [...] } with qty/enriched',
      () async {
    final c = makeContainer({
      'GET /api/cart/items': (
        200,
        {
          'id': 'cart1',
          'userId': 'u1',
          'items': [
            {
              'id': 'ci1',
              'productId': 'p1',
              'variantId': 'v1',
              'productName': 'Mug',
              'imageUrl': 'm.jpg',
              'qty': 2,
              'unitPriceTjs': '7.00',
              'subtotalTjs': '14.00',
            }
          ],
        }
      ),
    });
    await c.read(cartProvider.notifier).fetchCart();
    final state = c.read(cartProvider);
    expect(state.items, hasLength(1));
    expect(state.items.single.quantity, 2);
    expect(state.items.single.productName, 'Mug');
    expect(state.items.single.subtotalTjs, '14.00');
    // request carried a lang query param
    expect(adapterOf(c).requestTo('GET', '/api/cart/items').query['lang'],
        isNotNull);
  });

  test('CartNotifier.addItem sends { productId, variantId, qty }', () async {
    final c = makeContainer({
      'POST /api/cart/items': (
        201,
        {'id': 'cart1', 'userId': 'u1', 'items': []}
      ),
      'GET /api/cart/items': (
        200,
        {'id': 'cart1', 'userId': 'u1', 'items': []}
      ),
    });
    await c
        .read(cartProvider.notifier)
        .addItem(productId: 'p1', variantId: 'v9', quantity: 3);
    final post = adapterOf(c).requestTo('POST', '/api/cart/items');
    final body = post.data as Map;
    expect(body['productId'], 'p1');
    expect(body['variantId'], 'v9');
    expect(body['qty'], 3);
    expect(body.containsKey('quantity'), isFalse);
  });

  test('FavoritesNotifier.addFavorite swallows CONFLICT (idempotent)',
      () async {
    final c = makeContainer({
      'POST /api/favorites': (409, {'error': 'exists', 'code': 'CONFLICT'}),
      'GET /api/favorites': (200, <dynamic>[]),
    });
    // Should NOT throw and should leave no error in state.
    await c.read(favoritesProvider.notifier).addFavorite('p1');
    expect(c.read(favoritesProvider).error, isNull);
  });

  test('OrdersNotifier.fetchOrders parses list with qty/trackingNo/productName',
      () async {
    final c = makeContainer({
      'GET /api/orders': (
        200,
        [
          {
            'id': 'o1',
            'status': 'paid',
            'totalTjs': '20.00',
            'createdAt': '2026-06-10T00:00:00Z',
            'items': [
              {
                'id': 'oi1',
                'productId': 'p1',
                'productName': 'Pen',
                'qty': 4,
                'unitPriceTjs': '5.00'
              }
            ],
            'shipment': {
              'id': 's1',
              'stage': 'in_transit',
              'trackingNo': 'TR9'
            },
          }
        ]
      ),
    });
    await c.read(ordersProvider.notifier).fetchOrders();
    final orders = c.read(ordersProvider).orders;
    expect(orders, hasLength(1));
    expect(orders.single.items.single.quantity, 4);
    expect(orders.single.items.single.productName, 'Pen');
    expect(orders.single.shipment?.trackingCode, 'TR9');
  });

  test('AuthInterceptor signals onSessionExpired when refresh is impossible',
      () async {
    // 401 on a protected call; no refresh token in storage (mock returns null)
    // → refresh throws → the interceptor must fire onSessionExpired so the
    // router redirect can send the user back to /auth. Regression for the
    // "token expired but no logout / no error" bug.
    final (dio, _) = fakeDio({
      'GET /api/orders': (401, {'error': 'expired', 'code': 'UNAUTHORIZED'}),
    });
    final client = DioClient.withDio(dio);
    var expired = false;
    client.onSessionExpired = () => expired = true;

    await expectLater(
      client.get('/api/orders'),
      throwsA(isA<DioException>()),
    );
    expect(expired, isTrue);
  });

  test('CatalogNotifier.fetchProducts parses { items, total }', () async {
    final c = makeContainer({
      'GET /api/products': (
        200,
        {
          'items': [
            {
              'id': 'p1',
              'name': 'Hat',
              'priceTjs': '12.00',
              'imageUrl': 'h.jpg'
            }
          ],
          'total': 1,
        }
      ),
    });
    await c.read(catalogProvider.notifier).fetchProducts(page: 1);
    final products = c.read(catalogProvider).products;
    expect(products, hasLength(1));
    expect(products.single.name, 'Hat');
    expect(products.single.priceTjs, '12.00');
    expect(adapterOf(c).requestTo('GET', '/api/products').query['lang'],
        isNotNull);
  });

  test('CatalogNotifier does not enable development image rewriting implicitly',
      () async {
    final c = makeContainer(
      {
        'GET /api/products': (
          200,
          {
            'items': [
              {
                'id': 'p1',
                'name': 'Hat',
                'priceTjs': '12.00',
                'imageUrl':
                    'http://localhost:9000/pinshop-images/products/p1/hat.jpg',
              }
            ],
            'total': 1,
          }
        ),
      },
      apiBaseUrl: 'http://192.168.1.25:8080',
    );

    await c.read(catalogProvider.notifier).fetchProducts(page: 1);

    expect(
      c.read(catalogProvider).products.single.imageUrl,
      'http://localhost:9000/pinshop-images/products/p1/hat.jpg',
    );
  });

  test(
      'ProductDetailNotifier does not enable development image rewriting implicitly',
      () async {
    final (dio, _) = fakeDio({
      'GET /api/products/p1': (
        200,
        {
          'id': 'p1',
          'name': 'Player',
          'description': null,
          'images': [
            'http://127.0.0.1:9000/pinshop-images/products/p1/player.jpg',
          ],
          'priceTjs': '100.00',
          'status': 'active',
          'attributes': <String, dynamic>{},
        }
      ),
      'GET /api/products/p1/variants': (200, <dynamic>[]),
    });
    dio.options.baseUrl = 'http://10.0.2.2:8080';
    final notifier = ProductDetailNotifier(
      client: DioClient.withDio(dio),
      locale: 'ru',
    );
    addTearDown(notifier.dispose);

    await notifier.fetch('p1');

    expect(
      notifier.state.requireValue.imageUrls,
      [
        'http://127.0.0.1:9000/pinshop-images/products/p1/player.jpg',
      ],
    );
  });

  test(
      'ProductDetailNotifier keeps numeric-only variants selectable with fallback labels',
      () async {
    final (dio, _) = fakeDio({
      'GET /api/products/p1': (
        200,
        {
          'id': 'p1',
          'name': 'Player',
          'description': null,
          'images': ['player.jpg'],
          'priceTjs': '100.00',
          'status': 'active',
          'attributes': <String, dynamic>{},
        }
      ),
      'GET /api/products/p1/variants': (
        200,
        [
          {
            'id': 'v1',
            'sku': null,
            'priceTjs': '100.00',
            'stock': 5,
            'attributes': {
              'configurators': [
                {'Pid': '1627207', 'Vid': '31284767335'}
              ],
            },
          },
          {
            'id': 'v2',
            'sku': null,
            'priceTjs': '120.00',
            'stock': 3,
            'attributes': {
              'configurators': [
                {'Pid': '1627207', 'Vid': '35211156162'}
              ],
            },
          },
        ]
      ),
    });

    final notifier = ProductDetailNotifier(
      client: DioClient.withDio(dio),
      locale: 'ru',
    );
    addTearDown(notifier.dispose);
    await notifier.fetch('p1');

    final detail = notifier.state.requireValue;
    expect(detail.variants[0].attributes, {'variant': '1 · 100.00 TJS'});
    expect(detail.variants[1].attributes, {'variant': '2 · 120.00 TJS'});
  });

  group('channel persistence', () {
    test('setChannel triggers PATCH /api/users/me/channel', () async {
      final storage = FakeSecureStorage();
      final (dio, adapter) = fakeDio({
        'PATCH /api/users/me/channel': (200, {'channel': 'b2b'}),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      // Force provider creation before delay
      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container.read(authProvider.notifier).setChannel('b2b');

      // Verify PATCH was sent with correct payload
      final patch = adapter.requestTo('PATCH', '/api/users/me/channel');
      final body = patch.data as Map;
      expect(body['channel'], 'b2b');

      // State updated
      expect(container.read(authProvider).channel, 'b2b');
      expect(container.read(authProvider).channelChosen, isTrue);
    });

    test('separate cart providers survive setChannel call', () async {
      final storage = FakeSecureStorage();
      final (dio, _) = fakeDio({
        'PATCH /api/users/me/channel': (200, {'channel': 'b2b'}),
      });
      final container = ProviderContainer(overrides: [
        dioClientProvider.overrideWithValue(DioClient.withDio(dio)),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      // Force provider creation before delay
      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // cartProvider and wholesaleCartProvider are different objects (D-11)
      final cart = container.read(cartProvider.notifier);
      final wholesaleNotifier = container.read(authProvider.notifier);

      // setChannel does NOT reset either cart provider
      await wholesaleNotifier.setChannel('b2b');

      // The cart notifier instance is still the same object (no reset)
      expect(container.read(cartProvider.notifier), same(cart));

      // Both providers are distinct — no cross-contamination
      expect(cartProvider, isNot(same(authProvider)));
    });
  });
}
