import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/api_lang.dart';

void main() {
  group('apiLang', () {
    test('maps tg (UI) → tj (backend)', () {
      expect(apiLang('tg'), 'tj');
    });
    test('passes ru/en through unchanged', () {
      expect(apiLang('ru'), 'ru');
      expect(apiLang('en'), 'en');
    });
  });
}
