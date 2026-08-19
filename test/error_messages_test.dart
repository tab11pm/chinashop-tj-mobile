import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/api_exception.dart';
import 'package:pinshop_tj/core/api/error_messages.dart';

void main() {
  group('errorCodeOf', () {
    test('DomainException → its code', () {
      expect(
        errorCodeOf(const DomainException(code: 'OUT_OF_STOCK', message: 'x')),
        'OUT_OF_STOCK',
      );
    });

    test('DioException wrapping a DomainException → that code', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/'),
        error: const DomainException(code: 'CONFLICT', message: 'x'),
      );
      expect(errorCodeOf(e), 'CONFLICT');
    });

    test('DioException without domain inner → NETWORK', () {
      final e = DioException(requestOptions: RequestOptions(path: '/'));
      expect(errorCodeOf(e), 'NETWORK');
    });

    test('bare code String passes through', () {
      expect(errorCodeOf('VALIDATION_FAILED'), 'VALIDATION_FAILED');
    });

    test('anything else → GENERIC', () {
      expect(errorCodeOf(42), 'GENERIC');
      expect(errorCodeOf(null), 'GENERIC');
    });
  });
}
