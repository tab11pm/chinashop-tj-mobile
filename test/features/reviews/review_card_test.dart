import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pinshop_tj/features/reviews/models/review_models.dart';
import 'package:pinshop_tj/features/reviews/widgets/review_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  Widget harness({required String dateLocale}) {
    return MaterialApp(
      home: Scaffold(
        body: ReviewCard(
          review: const Review(
            id: 'review-1',
            rating: 4,
            text: 'Матн',
            language: 'tj',
            createdAt: '2026-07-01T00:00:00Z',
            author: ReviewAuthor(displayName: 'Фарид'),
          ),
          isOwnReview: false,
          isAuthenticated: false,
          isReported: false,
          ownReviewLabel: 'Мой отзыв',
          editLabel: 'Изменить',
          deleteLabel: 'Удалить',
          reportLabel: 'Пожаловаться',
          changeReportLabel: 'Изменить жалобу',
          reportedLabel: 'Вы пожаловались',
          dateLocale: dateLocale,
        ),
      ),
    );
  }

  testWidgets('renders date when Flutter locale is Tajik tg', (tester) async {
    await tester.pumpWidget(harness(dateLocale: 'tg'));

    expect(tester.takeException(), isNull);
    expect(find.text('Матн'), findsOneWidget);
  });
}
