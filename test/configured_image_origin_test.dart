import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/features/catalog/providers/catalog_provider.dart';

void main() {
  const objectPath = '/pinshop-images/products/p1/image.jpg';

  group('resolveProductImageUrl', () {
    test('uses an injected HTTPS origin for the known loopback mirror', () {
      expect(
        resolveProductImageUrl(
          'http://localhost:9000$objectPath',
          imageOrigin: 'https://images.pinshop.test/pinshop-images',
        ),
        'https://images.pinshop.test$objectPath',
      );
    });

    test('does not rewrite a legitimate remote CDN with the same bucket path',
        () {
      expect(
        resolveProductImageUrl(
          'https://cdn.example.com$objectPath',
          imageOrigin: 'https://images.pinshop.test/pinshop-images',
        ),
        'https://cdn.example.com$objectPath',
      );
    });

    test('rewrites an explicitly allowlisted old mirror origin', () {
      expect(
        resolveProductImageUrl(
          'https://old-mirror.pinshop.test$objectPath',
          imageOrigin: 'https://images.pinshop.test/pinshop-images',
          legacyMirrorOrigins: const {'https://old-mirror.pinshop.test'},
        ),
        'https://images.pinshop.test$objectPath',
      );
    });

    test('recognizes IPv4-mapped IPv6 loopback', () {
      expect(
        resolveProductImageUrl(
          'http://[::ffff:127.42.7.9]:9000$objectPath',
          imageOrigin: 'https://images.pinshop.test/pinshop-images',
        ),
        'https://images.pinshop.test$objectPath',
      );
    });

    test('gates host substitution behind the dev flag and a private API host',
        () {
      const source = 'http://127.0.0.1:9000$objectPath';
      expect(
        resolveProductImageUrl(
          source,
          apiBaseUrl: 'http://192.168.1.25:8080',
        ),
        source,
      );
      expect(
        resolveProductImageUrl(
          source,
          apiBaseUrl: 'http://192.168.1.25:8080',
          enableDevMirrorRewrite: true,
        ),
        'http://192.168.1.25:9000$objectPath',
      );
      expect(
        resolveProductImageUrl(
          source,
          apiBaseUrl: 'https://api.pinshop.tj',
          enableDevMirrorRewrite: true,
        ),
        source,
      );
    });
  });
}
