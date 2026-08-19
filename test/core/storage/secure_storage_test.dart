import 'package:flutter_test/flutter_test.dart';
import '../../helpers/fake_secure_storage.dart';

void main() {
  group('SecureStorage pickup cache', () {
    late FakeSecureStorage storage;

    setUp(() {
      storage = FakeSecureStorage();
    });

    test('writePickupCode then readPickupCode returns cached code and payload', () async {
      await storage.writePickupCode('order-1', '123456', 'pshp:123456');

      expect(
        await storage.readPickupCode('order-1'),
        {'code': '123456', 'qrPayload': 'pshp:123456'},
      );
    });

    test('readPickupCode returns null for unknown order', () async {
      expect(await storage.readPickupCode('order-unknown'), isNull);
    });

    test('clearPickupCode removes cached pickup data', () async {
      await storage.writePickupCode('order-1', '123456', 'pshp:123456');

      await storage.clearPickupCode('order-1');

      expect(await storage.readPickupCode('order-1'), isNull);
    });

    test('pickup cache is scoped per order id', () async {
      await storage.writePickupCode('order-1', '123456', 'pshp:123456');

      expect(await storage.readPickupCode('order-2'), isNull);
    });

    test('celebration flag defaults false and becomes true after write', () async {
      expect(await storage.readCelebrated('order-1'), isFalse);

      await storage.writeCelebrated('order-1');

      expect(await storage.readCelebrated('order-1'), isTrue);
    });
  });
}
