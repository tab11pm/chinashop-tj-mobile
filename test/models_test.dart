import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/features/cart/providers/cart_provider.dart';
import 'package:pinshop_tj/features/orders/providers/orders_provider.dart';
import 'package:pinshop_tj/features/catalog/providers/catalog_provider.dart';
import 'package:pinshop_tj/features/profile/providers/profile_provider.dart';
import 'package:pinshop_tj/features/favorites/providers/favorites_provider.dart';

/// Contract tests: these lock the exact mobile↔API field mappings that broke
/// during phase 8.2 (qty vs quantity, trackingNo vs trackingCode, images vs
/// imageUrls, enriched product fields). Money stays a String (D-07).
void main() {
  group('ProductSummary image origin policy', () {
    String? resolve(String imageUrl) => resolveProductImageUrl(
          imageUrl,
          apiBaseUrl: 'http://192.168.1.25:8080',
          enableDevMirrorRewrite: true,
        );

    test('rewrites the full IPv4 loopback range for the known dev mirror', () {
      expect(
        resolve('http://127.42.7.9:9000/pinshop-images/products/p1/a.jpg'),
        'http://192.168.1.25:9000/pinshop-images/products/p1/a.jpg',
      );
    });

    test('rewrites IPv6 loopback for the known dev mirror', () {
      expect(
        resolve('http://[::1]:9000/pinshop-images/products/p1/a.jpg'),
        'http://192.168.1.25:9000/pinshop-images/products/p1/a.jpg',
      );
    });

    test('leaves remote CDN and invalid URLs unchanged', () {
      expect(resolve('https://cdn.example.com/a.jpg'),
          'https://cdn.example.com/a.jpg');
      expect(resolve('not a valid URL'), 'not a valid URL');
    });

    test('does not rewrite unexpected scheme, path, or port', () {
      expect(
        resolve('ftp://127.0.0.1:9000/pinshop-images/products/p1/a.jpg'),
        'ftp://127.0.0.1:9000/pinshop-images/products/p1/a.jpg',
      );
      expect(
        resolve('http://127.0.0.1:9000/other-bucket/products/p1/a.jpg'),
        'http://127.0.0.1:9000/other-bucket/products/p1/a.jpg',
      );
      expect(
        resolve('http://127.0.0.1:9001/pinshop-images/products/p1/a.jpg'),
        'http://127.0.0.1:9001/pinshop-images/products/p1/a.jpg',
      );
    });
  });

  group('CartItem.fromJson', () {
    test('reads qty (not quantity) + enriched fields', () {
      final item = CartItem.fromJson({
        'id': 'i1',
        'productId': 'p1',
        'variantId': 'v1',
        'productName': 'Phone case',
        'imageUrl': 'http://x/i.jpg',
        'qty': 3,
        'unitPriceTjs': '10.00',
        'subtotalTjs': '30.00',
      });
      expect(item.quantity, 3);
      expect(item.variantId, 'v1');
      expect(item.productName, 'Phone case');
      expect(item.subtotalTjs, '30.00');
      expect(item.unitPriceTjs, '10.00'); // string, not parsed
    });
  });

  group('Order / OrderItem / Shipment fromJson', () {
    test('OrderItem reads qty + productName', () {
      final oi = OrderItem.fromJson({
        'id': 'oi1',
        'productId': 'p1',
        'productName': 'Lamp',
        'qty': 2,
        'unitPriceTjs': '5.50',
      });
      expect(oi.quantity, 2);
      expect(oi.productName, 'Lamp');
      expect(oi.unitPriceTjs, '5.50');
    });

    test('Shipment reads trackingNo into trackingCode', () {
      final s = Shipment.fromJson({
        'id': 's1',
        'stage': 'in_transit',
        'trackingNo': 'TR-123',
      });
      expect(s.stage, 'in_transit');
      expect(s.trackingCode, 'TR-123');
    });

    test('Order parses nested items + shipment', () {
      final o = Order.fromJson({
        'id': 'o1',
        'status': 'paid',
        'totalTjs': '40.00',
        'createdAt': '2026-06-10T00:00:00Z',
        'items': [
          {
            'id': 'oi1',
            'productId': 'p1',
            'productName': 'Lamp',
            'qty': 1,
            'unitPriceTjs': '40.00'
          }
        ],
        'shipment': {'id': 's1', 'stage': 'awaiting', 'trackingNo': null},
      });
      expect(o.status, 'paid');
      expect(o.totalTjs, '40.00');
      expect(o.items.single.productName, 'Lamp');
      expect(o.shipment?.stage, 'awaiting');
    });
  });

  group('ProductDetail.fromJson', () {
    test('maps images → imageUrls and parses variants', () {
      final p = ProductDetail.fromJson({
        'id': 'p1',
        'name': 'Bag',
        'description': 'nice',
        'images': ['a.jpg', 'b.jpg'],
        'priceTjs': '99.99',
        'variants': [
          {
            'id': 'v1',
            'sku': 'S',
            'priceTjs': '99.99',
            'stock': 5,
            'attributes': <String, dynamic>{},
          }
        ],
      });
      expect(p.imageUrls, ['a.jpg', 'b.jpg']);
      expect(p.priceTjs, '99.99');
      expect(p.variants.single.id, 'v1');
    });

    test('hides technical OTAPI attributes from customer characteristics', () {
      final p = ProductDetail.fromJson({
        'id': 'p1',
        'name': 'Speaker',
        'images': <String>[],
        'priceTjs': '998.32',
        'attributes': {
          'brand': 'Fever',
          'material': 'Wood',
          'sourceName': 'raw title',
          'sourceDescription': 'raw source description',
          'sourceCategoryIds': ['121472013'],
          'imageUrls': ['https://img.alicdn.com/a.jpg'],
          'searchHash': {'title': 'raw search payload'},
          'otapi': {
            'searchHash': {'title': 'raw search payload'},
            'enrichmentStatus': 'enriched',
            'sourceCategoryIds': ['121472013'],
          },
        },
      });

      expect(p.attributes, {
        'brand': 'Fever',
        'material': 'Wood',
      });
    });

    test('drops raw pid/vid configurators from variant option attributes', () {
      final variant = ProductVariant.fromJson({
        'id': 'v1',
        'sku': null,
        'priceTjs': '998.32',
        'stock': 5,
        'attributes': {
          'configurators': [
            {'Pid': '1627207', 'Vid': '21789357261'}
          ],
        },
      });

      expect(variant.attributes, isEmpty);
    });

    test('keeps meaningful variant attributes and configurators', () {
      final variant = ProductVariant.fromJson({
        'id': 'v1',
        'sku': null,
        'priceTjs': '998.32',
        'stock': 5,
        'attributes': {
          'color': 'black',
          'configurators': [
            {'Pid': 'Цвет', 'Vid': 'Черный'},
            {'Pid': '1627207', 'Vid': '21789357261'},
          ],
        },
      });

      expect(variant.attributes, {
        'color': 'black',
        'Цвет': 'Черный',
      });
    });
  });

  group('UserAddress.fromJson', () {
    test('builds displayLine', () {
      final a = UserAddress.fromJson({
        'id': 'a1',
        'region': 'GBAO',
        'city': 'Khorog',
        'line': 'Lenin 1',
        'phone': '+992...',
      });
      expect(a.displayLine, 'GBAO, Khorog, Lenin 1');
    });
  });

  group('FavoriteItem.fromJson', () {
    test('reads enriched nested product', () {
      final f = FavoriteItem.fromJson({
        'id': 'f1',
        'productId': 'p1',
        'product': {
          'id': 'p1',
          'name': 'Watch',
          'imageUrl': 'w.jpg',
          'priceTjs': '120.00',
        },
      });
      expect(f.productId, 'p1');
      expect(f.product.name, 'Watch');
      expect(f.product.priceTjs, '120.00');
    });
  });
}
