import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinshop_tj/core/api/dio_client.dart';
import 'package:pinshop_tj/features/auth/providers/auth_provider.dart';
import 'package:pinshop_tj/features/reviews/widgets/report_bottom_sheet.dart';
import 'package:pinshop_tj/l10n/app_localizations.dart';
import '../../helpers/fake_dio.dart';
import '../../helpers/fake_secure_storage.dart';

void main() {
  Future<void> pumpSettle(WidgetTester tester) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Widget harness(Map<String, (int, Object?)> routes) {
    final (dio, _) = fakeDio(routes);
    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(
          DioClient.withDio(dio, storage: FakeSecureStorage()),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showReportBottomSheet(
                    context,
                    ref,
                    reviewId: 'review-1',
                    productId: 'product-1',
                  ),
                  child: const Text('open-sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('open-sheet'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'submit button disabled with no category selected, enabled once one is chosen',
      (tester) async {
    await tester.pumpWidget(harness({}));
    await openSheet(tester);
    await pumpSettle(tester);

    final submitButtonFinder =
        find.widgetWithText(ElevatedButton, 'Отправить жалобу');
    expect(submitButtonFinder, findsOneWidget);
    ElevatedButton button = tester.widget(submitButtonFinder);
    expect(button.onPressed, isNull);

    await tester.tap(find.text('Спам или реклама'));
    await tester.pump();

    button = tester.widget(submitButtonFinder);
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
      'successful submit closes the sheet and shows the confirmation snackbar',
      (tester) async {
    await tester.pumpWidget(harness({
      'POST /api/reviews/review-1/reports': (200, {'id': 'report-1'}),
    }));
    await openSheet(tester);
    await pumpSettle(tester);

    await tester.tap(find.text('Оскорбительное содержание'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Отправить жалобу'));
    await pumpSettle(tester);

    expect(find.text('Пожаловаться на отзыв'), findsNothing);
    expect(find.text('Жалоба отправлена'), findsOneWidget);
  });
}
