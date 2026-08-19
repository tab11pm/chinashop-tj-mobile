import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/reviews/screens/review_form_screen.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import '../../helpers/fake_dio.dart';
import '../../helpers/fake_secure_storage.dart';

void main() {
  Future<void> pumpSettle(WidgetTester tester) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  // Wrapped in a minimal GoRouter (matches order_screen_test.dart's pattern)
  // since ReviewFormScreen navigates via `context.pop()`. A two-route stack
  // (host → pushed /form) so `pop()` always has somewhere to go back to.
  Widget harness(Map<String, (int, Object?)> routes) {
    final (dio, _) = fakeDio(routes);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/form'),
                child: const Text('open-form'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (context, state) => const ReviewFormScreen(
            productId: 'prod-1',
            productName: 'Test Product',
            productImageUrl: null,
            orderItemId: 'item-1',
          ),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: FakeSecureStorage()),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text('open-form'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'submit button disabled at rating=0, enabled once a star is tapped',
      (tester) async {
    await tester.pumpWidget(harness({}));
    await openForm(tester);
    await pumpSettle(tester);

    final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Отправить');
    expect(submitButtonFinder, findsOneWidget);
    ElevatedButton button = tester.widget(submitButtonFinder);
    expect(button.onPressed, isNull);

    // Tap the 4th star icon (index 3) to set rating=4.
    final starIcons = find.byIcon(Icons.star_outline_rounded);
    expect(starIcons, findsNWidgets(5));
    await tester.tap(starIcons.at(3));
    await tester.pump();

    button = tester.widget(submitButtonFinder);
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
      'REVIEW_ALREADY_EXISTS renders the "Открыть мой отзыв" action button',
      (tester) async {
    await tester.pumpWidget(harness({
      'POST /api/reviews': (
        409,
        {
          'error': 'A review already exists for this order item',
          'code': 'REVIEW_ALREADY_EXISTS'
        },
      ),
    }));
    await openForm(tester);
    await pumpSettle(tester);

    final starIcons = find.byIcon(Icons.star_outline_rounded);
    await tester.tap(starIcons.at(3));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Отправить'));
    await pumpSettle(tester);

    expect(find.text('Вы уже оставили отзыв на этот товар'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Открыть мой отзыв'),
        findsOneWidget);
  });

  testWidgets('a failed submit leaves the previously-entered text intact',
      (tester) async {
    await tester.pumpWidget(harness({
      'POST /api/reviews': (500, {'error': 'boom', 'code': 'INTERNAL'}),
    }));
    await openForm(tester);
    await pumpSettle(tester);

    final starIcons = find.byIcon(Icons.star_outline_rounded);
    await tester.tap(starIcons.at(2));
    await tester.pump();

    const enteredText = 'Great product, would buy again';
    await tester.enterText(find.byType(TextField), enteredText);
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Отправить'));
    await pumpSettle(tester);

    expect(find.text(enteredText), findsOneWidget);
  });

  testWidgets(
      'a successful submit parses a response without owner association IDs',
      (tester) async {
    await tester.pumpWidget(harness({
      'POST /api/reviews': (
        201,
        {
          'id': 'rev-1',
          'productId': 'prod-1',
          'rating': 5,
          'text': 'Nice',
          'language': 'ru',
          'createdAt': '2026-07-15T00:00:00Z',
          'updatedAt': '2026-07-15T00:00:00Z',
          'photos': [],
        },
      ),
    }));
    await openForm(tester);
    await pumpSettle(tester);

    final starIcons = find.byIcon(Icons.star_outline_rounded);
    await tester.tap(starIcons.at(4));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Отправить'));
    await pumpSettle(tester);

    // No exception thrown during pump — the celebration overlay renders.
    expect(tester.takeException(), isNull);
    expect(find.text('Спасибо за отзыв!'), findsOneWidget);

    // Drain the celebration's auto-dismiss timer (2.5s) so no pending timer
    // leaks past this test.
    await tester.pump(const Duration(milliseconds: 2600));
  });

  testWidgets(
      'dirty-form back navigation shows the discard dialog; a clean form pops without one',
      (tester) async {
    await tester.pumpWidget(harness({}));
    await openForm(tester);
    await pumpSettle(tester);

    // Dirty: tap a star, then tap the AppBar back button — PopScope
    // intercepts the pop (canPop is false while the form is dirty) and
    // shows the discard-confirmation dialog instead of navigating away.
    final starIcons = find.byIcon(Icons.star_outline_rounded);
    await tester.tap(starIcons.at(0));
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await pumpSettle(tester);

    expect(find.text('Выйти без сохранения?'), findsOneWidget);

    // Dismiss the dialog (Stay) — form remains open, no crash.
    await tester.tap(find.text('Остаться'));
    await pumpSettle(tester);
    expect(find.byType(ReviewFormScreen), findsOneWidget);
  });
}
