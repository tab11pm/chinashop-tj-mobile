import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/reviews/widgets/review_preview_section.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import '../../helpers/fake_dio.dart';
import '../../helpers/fake_secure_storage.dart';

void main() {
  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Expected finder did not appear: $finder');
  }

  testWidgets('preview exposes owner edit/delete actions and hides self-report',
      (tester) async {
    final (dio, _) = fakeDio({
      'GET /api/users/me': (
        200,
        {
          'role': 'customer',
          'channel': 'b2c',
          'name': 'Aziz',
          'phone': '+992900000000',
          'email': 'aziz@example.test',
          'needsProfileSetup': false,
        },
      ),
      'GET /api/reviews/my-reports': (200, {'reports': []}),
      'GET /api/reviews/eligibility': (
        200,
        {
          'eligibleOrderItems': [],
          'reviewedOrderItemIds': ['item-1'],
          'reviewedReviews': [
            {
              'id': 'r1',
              'orderItemId': 'item-1',
              'rating': 5,
              'text': 'My review',
              'language': 'ru',
              'createdAt': '2026-07-01T00:00:00Z',
              'photos': [],
            },
          ],
        },
      ),
      'GET /api/products/prod-1/reviews': (
        200,
        {
          'items': [
            {
              'id': 'r1',
              'rating': 5,
              'text': 'My review',
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
    });
    final storage = FakeSecureStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authInitialStateProvider.overrideWithValue(
            const AuthState(
              isAuthenticated: true,
              profileResolved: true,
              channelChosen: true,
              role: 'customer',
            ),
          ),
          dioClientProvider.overrideWithValue(
            DioClient.withDio(dio, storage: storage),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ReviewPreviewSection(
              productId: 'prod-1',
              productName: 'Test product',
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('My review'));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Изменить отзыв'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
    expect(find.text('Пожаловаться'), findsNothing);
  });

  testWidgets(
      'preview injects an eligibility-only own review before the public rows',
      (tester) async {
    final (dio, _) = fakeDio({
      'GET /api/users/me': (
        200,
        {
          'role': 'customer',
          'channel': 'b2c',
          'name': 'Aziz',
          'phone': '+992900000000',
          'email': 'aziz@example.test',
          'needsProfileSetup': false,
        },
      ),
      'GET /api/reviews/my-reports': (200, {'reports': []}),
      'GET /api/reviews/eligibility': (
        200,
        {
          'eligibleOrderItems': [],
          'reviewedOrderItemIds': ['hidden-item'],
          'reviewedReviews': [
            {
              'id': 'hidden-review',
              'orderItemId': 'hidden-item',
              'rating': 1,
              'text': 'Eligibility-only review',
              'language': 'ru',
              'createdAt': '2026-06-01T00:00:00Z',
              'photos': [],
            },
          ],
        },
      ),
      'GET /api/products/prod-1/reviews': (
        200,
        {
          'items': [
            {
              'id': 'public-a',
              'rating': 5,
              'text': 'Public A',
              'language': 'ru',
              'createdAt': '2026-07-02T00:00:00Z',
              'author': {'displayName': 'A'},
              'photos': [],
            },
            {
              'id': 'public-b',
              'rating': 4,
              'text': 'Public B',
              'language': 'ru',
              'createdAt': '2026-07-01T00:00:00Z',
              'author': {'displayName': 'B'},
              'photos': [],
            },
          ],
          'nextCursor': 'next-public-page',
        },
      ),
      'GET /api/products/prod-1/reviews/histogram': (
        200,
        {'5': 1, '4': 1, '3': 0, '2': 0, '1': 0},
      ),
    });
    final storage = FakeSecureStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authInitialStateProvider.overrideWithValue(
            const AuthState(
              isAuthenticated: true,
              profileResolved: true,
              channelChosen: true,
              role: 'customer',
            ),
          ),
          dioClientProvider.overrideWithValue(
            DioClient.withDio(dio, storage: storage),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ReviewPreviewSection(
              productId: 'prod-1',
              productName: 'Test product',
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Eligibility-only review'));

    expect(find.text('Eligibility-only review'), findsOneWidget);
    expect(find.text('Public A'), findsOneWidget);
    expect(find.text('Public B'), findsNothing);
  });
}
