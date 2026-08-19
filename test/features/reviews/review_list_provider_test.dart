import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/reviews/providers/review_list_provider.dart';
import '../../helpers/fake_dio.dart';
import '../../helpers/fake_secure_storage.dart';

void main() {
  test('DELETE success is not rolled back by a later refresh failure',
      () async {
    final routes = <String, (int, Object?)>{
      'GET /api/products/prod-1/reviews': (
        200,
        {
          'items': [
            {
              'id': 'r1',
              'rating': 5,
              'text': 'Mine',
              'language': 'ru',
              'createdAt': '2026-07-01T00:00:00Z',
              'author': {'displayName': 'Aziz'},
              'photos': [],
            },
          ],
          'nextCursor': null,
        },
      ),
      'GET /api/products/prod-1/reviews/histogram': (
        200,
        {'5': 1, '4': 0, '3': 0, '2': 0, '1': 0},
      ),
      'DELETE /api/reviews/r1': (204, null),
    };
    final (dio, adapter) = fakeDio(routes);
    final notifier = ReviewListNotifier(
      client: DioClient.withDio(dio, storage: FakeSecureStorage()),
      productId: 'prod-1',
      locale: 'ru',
    );
    addTearDown(notifier.dispose);
    await notifier.fetchFirstPage();

    adapter.routes['GET /api/products/prod-1/reviews'] = (
      500,
      {'error': 'refresh failed', 'code': 'INTERNAL'},
    );
    final deleted = await notifier.deleteReview('r1');

    expect(deleted, isTrue);
    expect(notifier.state.items.where((review) => review.id == 'r1'), isEmpty);
    expect(
      adapter.captured
          .where((request) =>
              request.method == 'GET' &&
              request.path == '/api/products/prod-1/reviews')
          .length,
      1,
      reason: 'deleteReview must not own the independent read refresh',
    );

    await notifier.fetchFirstPage();
    expect(notifier.state.error, 'INTERNAL');
  });
}
