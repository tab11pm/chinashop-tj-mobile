import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/reviews/providers/review_eligibility_provider.dart';
import 'package:pinshop_tj/features/reviews/providers/review_form_provider.dart';
import 'package:pinshop_tj/features/reviews/screens/review_list_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import 'package:pinshop_tj/l10n/app_localizations_ru.dart';
import '../../helpers/fake_dio.dart';
import '../../helpers/fake_secure_storage.dart';

void main() {
  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    fail('Expected finder did not appear: $finder');
  }

  Map<String, (int, Object?)> withReviewShellRoutes(
    Map<String, (int, Object?)> routes,
  ) {
    return Map<String, (int, Object?)>.of(routes)
      ..putIfAbsent(
        'GET /api/users/me',
        () => (
          200,
          {
            'channel': 'b2c',
            'role': 'customer',
            'locale': 'ru',
            'needsProfileSetup': false,
          }
        ),
      )
      ..putIfAbsent('GET /api/reviews/my-reports', () => (200, {'reports': []}))
      ..putIfAbsent(
        'GET /api/reviews/eligibility',
        () => (
          200,
          {
            'eligibleOrderItems': [],
            'reviewedOrderItemIds': [],
            'reviewedReviews': [],
          },
        ),
      );
  }

  Widget harness(Map<String, (int, Object?)> routes) {
    final (dio, _) = fakeDio(withReviewShellRoutes(routes));
    final storage = FakeSecureStorage()
      ..seed(FakeSecureStorage.accessTokenKey, 'token')
      ..seed(FakeSecureStorage.localeKey, 'ru');
    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: storage),
        ),
        secureStorageProvider.overrideWithValue(storage),
      ],
      child: const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReviewListScreen(productId: 'prod-1'),
      ),
    );
  }

  ({Widget widget, FakeAdapter adapter}) authenticatedHarness(
    Map<String, (int, Object?)> routes,
  ) {
    final (dio, adapter) = fakeDio(routes);
    final storage = FakeSecureStorage();
    final router = GoRouter(
      initialLocation: '/reviews',
      routes: [
        GoRoute(
          path: '/reviews',
          builder: (context, state) =>
              const ReviewListScreen(productId: 'prod-1'),
        ),
        GoRoute(
          path: '/review-form',
          builder: (context, state) {
            final args = state.extra! as ReviewFormArgs;
            return Scaffold(
              body: Text(
                'edit:${args.orderItemId}:${args.existingReview?.id}',
              ),
            );
          },
        ),
      ],
    );
    return (
      adapter: adapter,
      widget: ProviderScope(
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
        child: MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  Map<String, (int, Object?)> ownerRoutes() => {
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
              }
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

  testWidgets('empty state renders when the provider returns zero items',
      (tester) async {
    await tester.pumpWidget(
      harness({
        'GET /api/products/prod-1/reviews': (
          200,
          {'items': [], 'nextCursor': null},
        ),
        'GET /api/products/prod-1/reviews/histogram': (
          200,
          {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
        ),
      }),
    );
    await pumpUntilFound(tester, find.byIcon(Icons.reviews_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.reviews_outlined), findsOneWidget);
  });

  testWidgets('tapping a histogram row re-fetches with rating and lang',
      (tester) async {
    final (dio, adapter) = fakeDio(withReviewShellRoutes({
      'GET /api/products/prod-1/reviews': (
        200,
        {
          'items': [
            {
              'id': 'r1',
              'rating': 5,
              'text': 'Great product',
              'language': 'ru',
              'createdAt': '2026-07-01T00:00:00Z',
              'author': {'displayName': 'Aziz'},
              'photos': [],
            }
          ],
          'nextCursor': null,
        },
      ),
      'GET /api/products/prod-1/reviews/histogram': (
        200,
        {'5': 1, '4': 0, '3': 0, '2': 0, '1': 0},
      ),
    }));
    final storage = FakeSecureStorage()
      ..seed(FakeSecureStorage.accessTokenKey, 'token')
      ..seed(FakeSecureStorage.localeKey, 'ru');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWithValue(
            DioClient.withDio(dio, storage: storage),
          ),
          secureStorageProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReviewListScreen(productId: 'prod-1'),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('Great product'));

    await tester.tap(find.text('5').first);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    final refetch = adapter.captured.where(
      (r) => r.method == 'GET' && r.path == '/api/products/prod-1/reviews',
    );
    expect(refetch.any((r) => r.query['rating'] == 5), isTrue);
    expect(refetch.every((r) => r.query['lang'] == 'ru'), isTrue);
  });

  testWidgets('own review shows edit/delete actions and no report action',
      (tester) async {
    await tester.pumpWidget(
      harness({
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
              }
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
                'author': {'displayName': 'Me'},
                'photos': [],
              }
            ],
            'nextCursor': null,
          },
        ),
        'GET /api/products/prod-1/reviews/histogram': (
          200,
          {'5': 1, '4': 0, '3': 0, '2': 0, '1': 0},
        ),
      }),
    );
    await pumpUntilFound(tester, find.text('My review'));
    await pumpUntilFound(tester, find.byIcon(Icons.more_vert));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsRu();
    expect(find.text(l10n.reportMenuItem), findsNothing);
    expect(find.text(l10n.reviewFormTitleEdit), findsOneWidget);
    expect(find.text(l10n.deleteConfirmButton), findsOneWidget);
  });

  testWidgets('own review remains manageable when hidden by public filters',
      (tester) async {
    await tester.pumpWidget(
      harness({
        'GET /api/reviews/eligibility': (
          200,
          {
            'eligibleOrderItems': [],
            'reviewedOrderItemIds': ['item-1'],
            'reviewedReviews': [
              {
                'id': 'r-old-locale',
                'orderItemId': 'item-1',
                'rating': 4,
                'text': 'My old locale review',
                'language': 'en',
                'createdAt': '2026-06-01T00:00:00Z',
                'photos': [],
              }
            ],
          },
        ),
        'GET /api/products/prod-1/reviews': (
          200,
          {'items': [], 'nextCursor': null},
        ),
        'GET /api/products/prod-1/reviews/histogram': (
          200,
          {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
        ),
      }),
    );

    await pumpUntilFound(tester, find.text('My old locale review'));
    await pumpUntilFound(tester, find.byIcon(Icons.more_vert));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsRu();
    expect(find.text(l10n.reviewFormTitleEdit), findsOneWidget);
    expect(find.text(l10n.deleteConfirmButton), findsOneWidget);
    expect(find.text(l10n.reportMenuItem), findsNothing);
  });

  testWidgets(
      'an owned review exposes edit/delete but never the self-report action',
      (tester) async {
    final harness = authenticatedHarness(ownerRoutes());
    await tester.pumpWidget(harness.widget);
    await pumpUntilFound(tester, find.text('My review'));

    expect(find.text('Aziz'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Изменить отзыв'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
    expect(find.text('Пожаловаться'), findsNothing);
  });

  testWidgets(
      'edit forwards the owner-only order item and review to the form route',
      (tester) async {
    final harness = authenticatedHarness(ownerRoutes());
    await tester.pumpWidget(harness.widget);
    await pumpUntilFound(tester, find.text('My review'));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Изменить отзыв'));
    await tester.pumpAndSettle();

    expect(find.text('edit:item-1:r1'), findsOneWidget);
  });

  testWidgets('delete calls the owner endpoint and refreshes the review list',
      (tester) async {
    final harness = authenticatedHarness(ownerRoutes());
    await tester.pumpWidget(harness.widget);
    await pumpUntilFound(tester, find.text('My review'));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(
      harness.adapter.captured
          .where((request) =>
              request.method == 'DELETE' && request.path == '/api/reviews/r1')
          .length,
      1,
    );
    expect(
      harness.adapter.captured
          .where((request) =>
              request.method == 'GET' &&
              request.path == '/api/products/prod-1/reviews')
          .length,
      greaterThanOrEqualTo(2),
    );
  });

  testWidgets('delete failure keeps the review and surfaces a localized error',
      (tester) async {
    final routes = ownerRoutes();
    routes['DELETE /api/reviews/r1'] = (
      500,
      {'error': 'delete failed', 'code': 'INTERNAL'},
    );
    final harness = authenticatedHarness(routes);
    await tester.pumpWidget(harness.widget);
    await pumpUntilFound(tester, find.text('My review'));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('My review'), findsOneWidget);
    expect(
      find.text('Что-то пошло не так. Попробуйте снова.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'eligibility-only hidden owner review is shown before the public page',
      (tester) async {
    final routes = ownerRoutes();
    routes['GET /api/reviews/eligibility'] = (
      200,
      {
        'eligibleOrderItems': [],
        'reviewedOrderItemIds': ['hidden-item'],
        'reviewedReviews': [
          {
            'id': 'hidden-review',
            'orderItemId': 'hidden-item',
            'rating': 1,
            'text': 'Hidden owner review',
            'language': 'ru',
            'createdAt': '2026-06-01T00:00:00Z',
            'photos': [],
          },
        ],
      },
    );
    routes['GET /api/products/prod-1/reviews'] = (
      200,
      {
        'items': [
          {
            'id': 'public-review',
            'rating': 5,
            'text': 'Public five star review',
            'language': 'ru',
            'createdAt': '2026-07-02T00:00:00Z',
            'author': {'displayName': 'Other'},
            'photos': [],
          },
        ],
        'nextCursor': null,
      },
    );

    final harness = authenticatedHarness(routes);
    await tester.pumpWidget(harness.widget);
    await pumpUntilFound(tester, find.text('Public five star review'));

    expect(find.text('Hidden owner review'), findsOneWidget);
    expect(find.text('Public five star review'), findsOneWidget);
  });

  testWidgets(
      'successful delete invalidates ownership even when the later refresh fails',
      (tester) async {
    final harness = authenticatedHarness(ownerRoutes());
    await tester.pumpWidget(harness.widget);
    await pumpUntilFound(tester, find.text('My review'));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    harness.adapter.routes['GET /api/products/prod-1/reviews'] = (
      500,
      {'error': 'refresh failed', 'code': 'INTERNAL'},
    );
    await tester.tap(find.text('Удалить'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      harness.adapter.captured
          .where((request) =>
              request.method == 'DELETE' && request.path == '/api/reviews/r1')
          .length,
      1,
    );
    expect(
      harness.adapter.captured
          .where((request) =>
              request.method == 'GET' &&
              request.path == '/api/reviews/eligibility')
          .length,
      greaterThanOrEqualTo(2),
    );
    expect(find.text('My review'), findsNothing);
  });

  testWidgets(
      'eligibility error offers retry then enables report for confirmed non-owner',
      (tester) async {
    final routes = ownerRoutes();
    routes['GET /api/reviews/eligibility'] = (
      500,
      {'error': 'ownership failed', 'code': 'INTERNAL'},
    );
    routes['GET /api/products/prod-1/reviews'] = (
      200,
      {
        'items': [
          {
            'id': 'foreign-review',
            'rating': 4,
            'text': 'Foreign review',
            'language': 'ru',
            'createdAt': '2026-07-02T00:00:00Z',
            'author': {'displayName': 'Other'},
            'photos': [],
          },
        ],
        'nextCursor': null,
      },
    );

    final harness = authenticatedHarness(routes);
    await tester.pumpWidget(harness.widget);
    await pumpUntilFound(tester, find.text('Foreign review'));

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.text('Повторить'), findsOneWidget);

    harness.adapter.routes['GET /api/reviews/eligibility'] = (
      200,
      {
        'eligibleOrderItems': [],
        'reviewedOrderItemIds': [],
        'reviewedReviews': [],
      },
    );
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Пожаловаться'), findsOneWidget);
  });

  testWidgets(
      'confirmed non-owner keeps report action when eligibility refresh fails',
      (tester) async {
    final routes = ownerRoutes();
    routes['GET /api/reviews/eligibility'] = (
      200,
      {
        'eligibleOrderItems': [],
        'reviewedOrderItemIds': [],
        'reviewedReviews': [],
      },
    );
    routes['GET /api/products/prod-1/reviews'] = (
      200,
      {
        'items': [
          {
            'id': 'foreign-review',
            'rating': 4,
            'text': 'Confirmed foreign review',
            'language': 'ru',
            'createdAt': '2026-07-02T00:00:00Z',
            'author': {'displayName': 'Other'},
            'photos': [],
          },
        ],
        'nextCursor': null,
      },
    );

    final harness = authenticatedHarness(routes);
    await tester.pumpWidget(harness.widget);
    await pumpUntilFound(tester, find.text('Confirmed foreign review'));

    harness.adapter.routes['GET /api/reviews/eligibility'] = (
      500,
      {'error': 'refresh failed', 'code': 'INTERNAL'},
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReviewListScreen)),
    );
    container.invalidate(reviewEligibilityProvider('prod-1'));
    await tester.pumpAndSettle();

    expect(find.text('Повторить'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Пожаловаться'), findsOneWidget);
  });
}
